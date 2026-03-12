{-# LANGUAGE GADTs #-}
{-# LANGUAGE OverloadedStrings #-}
module Main where

import Control.Concurrent (forkIO, newEmptyMVar, newQSem, putMVar, signalQSem, takeMVar, waitQSem)
import Control.Exception (IOException, try)
import Control.Monad (forM, forM_, when)
import Data.Bits (xor)
import qualified Data.ByteString as BS
import Data.Char (isAlphaNum, isDigit, isSpace, ord, toLower)
import Data.Foldable (foldl')
import qualified Data.List as L
import qualified Data.Map.Strict as M
import Data.Maybe (fromMaybe)
import qualified Data.Set as S
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import qualified Data.Text.IO as TIO
import Data.Word (Word64)
import Numeric (showHex)
import System.Directory (doesDirectoryExist, doesFileExist, getFileSize, listDirectory, pathIsSymbolicLink)
import System.Environment (getArgs)
import System.Exit (die, exitFailure)
import System.FilePath ((</>), takeFileName)
import System.IO (hPutStrLn, stderr)
import Text.Read (readMaybe)

data ScanMode = ScanAll | ScanHaskellOnly
  deriving (Eq, Show)

data InputMode = CrawlFilesystem | ReadPathsFromStdin
  deriving (Eq, Show)

data OutputMode = OutputReport | OutputSummary | OutputFiles | OutputLines | OutputNgrams | OutputChars | OutputNotes
  deriving (Eq, Show)

data ParseAction = Run Config | Help

data Config = Config
  { cfgRoot :: FilePath
  , cfgWorkers :: Int
  , cfgNgramSize :: Int
  , cfgMinOccurrences :: Int
  , cfgMaxItems :: Int
  , cfgMaxFileBytes :: Integer
  , cfgMaxFiles :: Maybe Int
  , cfgScanMode :: ScanMode
  , cfgInputMode :: InputMode
  , cfgOutputMode :: OutputMode
  , cfgHaskellify :: Bool
  , cfgFailOnHits :: Bool
  , cfgDebug :: Bool
  }
  deriving (Show)

data FileKind = Textual | Binaryish | Skipped | Failed
  deriving (Eq, Show)

data FileReport = FileReport
  { frPath :: FilePath
  , frSize :: Integer
  , frHash :: Maybe Word64
  , frKind :: FileKind
  , frUsedHaskellMode :: Bool
  , frLineCounts :: M.Map T.Text Int
  , frCharCounts :: M.Map Char Int
  , frNgramCounts :: M.Map T.Text Int
  , frNote :: Maybe String
  }

data Aggregate = Aggregate
  { agTotalFiles :: Int
  , agTextFiles :: Int
  , agBinaryFiles :: Int
  , agSkippedFiles :: Int
  , agFailedFiles :: Int
  , agHaskellFiles :: Int
  , agHaskellNormalizedFiles :: Int
  , agFileGroups :: M.Map (Integer, Word64) [FilePath]
  , agLineStats :: M.Map T.Text (Int, Int)
  , agNgramStats :: M.Map T.Text (Int, Int)
  , agCharStats :: M.Map Char Int
  , agNotes :: [(FilePath, String)]
  }

data ScanResult = ScanResult
  { srConfig :: Config
  , srDiscovered :: [FilePath]
  , srSelected :: [FilePath]
  , srReports :: [FileReport]
  , srAggregate :: Aggregate
  }

data Command a where
  DebugLog :: String -> Command ()
  GatherPaths :: Config -> Command [FilePath]
  AnalyzePaths :: Config -> [FilePath] -> [FilePath] -> Command ScanResult
  RenderResult :: OutputMode -> ScanResult -> Command ()
  EnforceHitPolicy :: ScanResult -> Command ()

data Program a where
  PureP :: a -> Program a
  StepP :: Command b -> (b -> Program a) -> Program a

instance Functor Program where
  fmap f program = program >>= pure . f

instance Applicative Program where
  pure = PureP
  (<*>) ff fa = ff >>= (<$> fa)

instance Monad Program where
  PureP value >>= k = k value
  StepP command next >>= k = StepP command (\value -> next value >>= k)

defaultConfig :: Config
defaultConfig = Config
  { cfgRoot = "."
  , cfgWorkers = 8
  , cfgNgramSize = 5
  , cfgMinOccurrences = 2
  , cfgMaxItems = 15
  , cfgMaxFileBytes = 1024 * 1024
  , cfgMaxFiles = Nothing
  , cfgScanMode = ScanAll
  , cfgInputMode = CrawlFilesystem
  , cfgOutputMode = OutputReport
  , cfgHaskellify = False
  , cfgFailOnHits = False
  , cfgDebug = False
  }

usage :: String
usage = unlines
  [ "OpenClaw spider deduper"
  , ""
  , "Usage: runghc spider_dedupe.hs [options] [root]"
  , ""
  , "Options:"
  , "  --workers N           parallel workers (default 8)"
  , "  --ngrams N            char n-gram size (default 5)"
  , "  --min-occurrences N   minimum count to report (default 2)"
  , "  --max-items N         max rows per section (default 15)"
  , "  --max-file-bytes N    skip files larger than N bytes (default 1048576)"
  , "  --max-files N         stop after discovering N files"
  , "  --haskell-only        only scan Haskell-like files (*.hs, *.lhs, *.hsc, *.cabal, ...)"
  , "  --haskellify          apply Haskell-aware normalization before dedupe analysis"
  , "  --stdin-paths         read newline-delimited paths from stdin instead of crawling"
  , "  --mode MODE           report|summary|files|lines|ngrams|chars|notes"
  , "  --fail-on-hits        exit non-zero when duplicates are found"
  , "  --debug               emit command-trace logs to stderr"
  , "  --help                show this text"
  , "  Emoji aliases:        λ=--haskellify  📥=--stdin-paths  🧾=summary  📁=files  📏=lines  🧬=ngrams  🔤=chars  📝=notes  🐛=--debug"
  , ""
  , "Linux philosophy mode: use --stdin-paths plus --mode files|lines|ngrams|chars"
  , "to compose with find, rg, git ls-files, or PowerShell pipelines."
  ]

parseArgs :: [String] -> Either String ParseAction
parseArgs = go defaultConfig Nothing
  where
    go _ _ ("--help":_) = Right Help
    go cfg mRoot [] = Right (Run cfg { cfgRoot = fromMaybe (cfgRoot cfg) mRoot })
    go cfg mRoot ("--workers":n:rest) = parseInt "workers" n >>= \v -> go cfg { cfgWorkers = v } mRoot rest
    go cfg mRoot ("--ngrams":n:rest) = parseInt "ngrams" n >>= \v -> go cfg { cfgNgramSize = v } mRoot rest
    go cfg mRoot ("--min-occurrences":n:rest) = parseInt "min-occurrences" n >>= \v -> go cfg { cfgMinOccurrences = v } mRoot rest
    go cfg mRoot ("--max-items":n:rest) = parseInt "max-items" n >>= \v -> go cfg { cfgMaxItems = v } mRoot rest
    go cfg mRoot ("--max-file-bytes":n:rest) = parseInteger "max-file-bytes" n >>= \v -> go cfg { cfgMaxFileBytes = v } mRoot rest
    go cfg mRoot ("--max-files":n:rest) = parseInt "max-files" n >>= \v -> go cfg { cfgMaxFiles = Just v } mRoot rest
    go cfg mRoot ("--mode":raw:rest) = parseOutputMode raw >>= \v -> go cfg { cfgOutputMode = v } mRoot rest
    go cfg mRoot ("--haskell-only":rest) = go cfg { cfgScanMode = ScanHaskellOnly } mRoot rest
    go cfg mRoot ("--haskellify":rest) = go cfg { cfgHaskellify = True } mRoot rest
    go cfg mRoot ("λ":rest) = go cfg { cfgHaskellify = True } mRoot rest
    go cfg mRoot ("--stdin-paths":rest) = go cfg { cfgInputMode = ReadPathsFromStdin } mRoot rest
    go cfg mRoot ("📥":rest) = go cfg { cfgInputMode = ReadPathsFromStdin } mRoot rest
    go cfg mRoot ("--fail-on-hits":rest) = go cfg { cfgFailOnHits = True } mRoot rest
    go cfg mRoot ("--debug":rest) = go cfg { cfgDebug = True } mRoot rest
    go cfg mRoot ("🐛":rest) = go cfg { cfgDebug = True } mRoot rest
    go cfg mRoot ("🧾":rest) = go cfg { cfgOutputMode = OutputSummary } mRoot rest
    go cfg mRoot ("📁":rest) = go cfg { cfgOutputMode = OutputFiles } mRoot rest
    go cfg mRoot ("📏":rest) = go cfg { cfgOutputMode = OutputLines } mRoot rest
    go cfg mRoot ("🧬":rest) = go cfg { cfgOutputMode = OutputNgrams } mRoot rest
    go cfg mRoot ("🔤":rest) = go cfg { cfgOutputMode = OutputChars } mRoot rest
    go cfg mRoot ("📝":rest) = go cfg { cfgOutputMode = OutputNotes } mRoot rest
    go cfg Nothing (arg:rest)
      | take 2 arg == "--" = Left ("Unknown option: " ++ arg ++ "\n\n" ++ usage)
      | otherwise = go cfg (Just arg) rest
    go _ (Just _) (arg:_) = Left ("Unexpected extra argument: " ++ arg ++ "\n\n" ++ usage)

    parseInt label raw =
      case readMaybe raw of
        Just n | n > 0 -> Right n
        _ -> Left ("Expected a positive integer for --" ++ label ++ ", got: " ++ raw)

    parseInteger label raw =
      case readMaybe raw of
        Just n | n > 0 -> Right n
        _ -> Left ("Expected a positive integer for --" ++ label ++ ", got: " ++ raw)

parseOutputMode :: String -> Either String OutputMode
parseOutputMode raw =
  case raw of
    "🧾" -> Right OutputSummary
    "📁" -> Right OutputFiles
    "📏" -> Right OutputLines
    "🧬" -> Right OutputNgrams
    "🔤" -> Right OutputChars
    "📝" -> Right OutputNotes
    _ -> case map toLower raw of
      "report" -> Right OutputReport
      "summary" -> Right OutputSummary
      "files" -> Right OutputFiles
      "lines" -> Right OutputLines
      "ngrams" -> Right OutputNgrams
      "chars" -> Right OutputChars
      "notes" -> Right OutputNotes
      _ -> Left ("Unknown --mode value: " ++ raw ++ "\n\n" ++ usage)

main :: IO ()
main = do
  args <- getArgs
  action <- either die pure (parseArgs args)
  case action of
    Help -> putStr usage
    Run cfg -> runProgram (buildProgram cfg)

liftCommand :: Command a -> Program a
liftCommand command = StepP command PureP

whenProgram :: Bool -> Program () -> Program ()
whenProgram condition action
  | condition = action
  | otherwise = pure ()

runProgram :: Program a -> IO a
runProgram (PureP value) = pure value
runProgram (StepP command next) = interpretCommand command >>= runProgram . next

interpretCommand :: Command a -> IO a
interpretCommand command =
  case command of
    DebugLog message -> hPutStrLn stderr ("[debug] " ++ message)
    GatherPaths cfg -> gatherInputPaths cfg
    AnalyzePaths cfg discovered selected -> do
      reports <- processFilesParallel cfg selected
      let aggregate = foldl' accumulate emptyAggregate reports
      pure
        ScanResult
          { srConfig = cfg
          , srDiscovered = discovered
          , srSelected = selected
          , srReports = reports
          , srAggregate = aggregate
          }
    RenderResult mode result -> renderOutput mode result
    EnforceHitPolicy result -> when (hasHits (srConfig result) (srAggregate result)) exitFailure

buildProgram :: Config -> Program ()
buildProgram cfg = do
  whenProgram (cfgDebug cfg) (liftCommand (DebugLog ("config=" ++ show cfg)))
  discovered <- liftCommand (GatherPaths cfg)
  let selected = limitPaths cfg discovered
  whenProgram (cfgDebug cfg) (liftCommand (DebugLog ("discovered=" ++ show (length discovered) ++ " selected=" ++ show (length selected))))
  result <- liftCommand (AnalyzePaths cfg discovered selected)
  whenProgram (cfgDebug cfg) (liftCommand (DebugLog (scanDebugSummary result)))
  liftCommand (RenderResult (cfgOutputMode cfg) result)
  whenProgram (cfgFailOnHits cfg) (liftCommand (EnforceHitPolicy result))

scanDebugSummary :: ScanResult -> String
scanDebugSummary result =
  L.intercalate
    " "
    [ "processed=" ++ show (agTotalFiles agg)
    , "text=" ++ show (agTextFiles agg)
    , "binary=" ++ show (agBinaryFiles agg)
    , "skipped=" ++ show (agSkippedFiles agg)
    , "failed=" ++ show (agFailedFiles agg)
    , "file-groups=" ++ show (length (duplicateFileGroups cfg agg))
    , "line-hits=" ++ show (length (duplicateTextItems cfg (agLineStats agg)))
    , "ngram-hits=" ++ show (length (duplicateTextItems cfg (agNgramStats agg)))
    ]
  where
    cfg = srConfig result
    agg = srAggregate result

limitPaths :: Config -> [FilePath] -> [FilePath]
limitPaths cfg = maybe id takeMaybe (cfgMaxFiles cfg)
  where
    takeMaybe n xs = take n xs

gatherInputPaths :: Config -> IO [FilePath]
gatherInputPaths cfg =
  case cfgInputMode cfg of
    CrawlFilesystem -> collectFiles cfg (cfgRoot cfg)
    ReadPathsFromStdin -> readPathsFromStdin cfg

readPathsFromStdin :: Config -> IO [FilePath]
readPathsFromStdin cfg = do
  input <- TIO.getContents
  pure
    . uniquePreserve
    . filter (shouldIncludePath cfg)
    . map T.unpack
    . filter (not . T.null)
    . map T.strip
    $ T.lines input

uniquePreserve :: Ord a => [a] -> [a]
uniquePreserve = go S.empty
  where
    go _ [] = []
    go seen (x:xs)
      | S.member x seen = go seen xs
      | otherwise = x : go (S.insert x seen) xs

collectFiles :: Config -> FilePath -> IO [FilePath]
collectFiles cfg root = do
  isDir <- safeBool False (doesDirectoryExist root)
  isFile <- safeBool False (doesFileExist root)
  if isFile
    then pure [root | shouldIncludePath cfg root]
    else if isDir
      then go root
      else pure []
  where
    go path = do
      isLink <- safeBool False (pathIsSymbolicLink path)
      if isLink
        then pure []
        else do
          names <- safeListDirectory path
          nested <- forM (L.sort names) $ \name -> do
            let full = path </> name
            fullIsDir <- safeBool False (doesDirectoryExist full)
            fullIsFile <- safeBool False (doesFileExist full)
            if fullIsDir
              then go full
              else if fullIsFile && shouldIncludePath cfg full
                then pure [full]
                else pure []
          pure (concat nested)

shouldIncludePath :: Config -> FilePath -> Bool
shouldIncludePath cfg path =
  case cfgScanMode cfg of
    ScanAll -> True
    ScanHaskellOnly -> isHaskellLikePath path

isHaskellLikePath :: FilePath -> Bool
isHaskellLikePath path =
  any (`L.isSuffixOf` lowerPath) suffixes || fileName `elem` exactNames
  where
    lowerPath = map toLower path
    fileName = map toLower (takeFileName path)
    suffixes =
      [ ".hs"
      , ".lhs"
      , ".hsc"
      , ".chs"
      , ".hs-boot"
      , ".cabal"
      , ".x"
      , ".y"
      ]
    exactNames =
      [ "package.yaml"
      , "stack.yaml"
      , "cabal.project"
      , "cabal.project.local"
      ]

safeListDirectory :: FilePath -> IO [FilePath]
safeListDirectory path = do
  result <- try (listDirectory path) :: IO (Either IOException [FilePath])
  pure (either (const []) id result)

safeBool :: Bool -> IO Bool -> IO Bool
safeBool fallback action = do
  result <- try action :: IO (Either IOException Bool)
  pure (either (const fallback) id result)

processFilesParallel :: Config -> [FilePath] -> IO [FileReport]
processFilesParallel cfg files = do
  sem <- newQSem (cfgWorkers cfg)
  vars <- forM files $ \path -> do
    waitQSem sem
    resultVar <- newEmptyMVar
    _ <- forkIO $ do
      report <- processFile cfg path
      putMVar resultVar report
      signalQSem sem
    pure resultVar
  mapM takeMVar vars

processFile :: Config -> FilePath -> IO FileReport
processFile cfg path = do
  sizeResult <- try (getFileSize path) :: IO (Either IOException Integer)
  case sizeResult of
    Left err -> pure (emptyReport path Failed False (Just (show err)))
    Right size
      | size > cfgMaxFileBytes cfg -> pure (FileReport path size Nothing Skipped False M.empty M.empty M.empty (Just "skipped because file exceeds --max-file-bytes"))
      | otherwise -> do
          bytesResult <- try (BS.readFile path) :: IO (Either IOException BS.ByteString)
          case bytesResult of
            Left err -> pure (FileReport path size Nothing Failed False M.empty M.empty M.empty (Just (show err)))
            Right bytes -> do
              let digest = fnv1a64 bytes
                  useHaskellMode = cfgHaskellify cfg || isHaskellLikePath path
              if isLikelyBinary bytes
                then pure (FileReport path size (Just digest) Binaryish useHaskellMode M.empty M.empty M.empty (Just "binary or null-byte heavy"))
                else case TE.decodeUtf8' bytes of
                  Left _ -> pure (FileReport path size (Just digest) Binaryish useHaskellMode M.empty M.empty M.empty (Just "non-UTF8 text skipped"))
                  Right txt -> do
                    let normalizer = chooseNormalizer useHaskellMode
                        normalizedDoc = normalizeDocument normalizer txt
                        lineCounts = countLinesWith normalizer txt
                        charCounts = countChars normalizedDoc
                        ngramCounts = countNgrams (cfgNgramSize cfg) normalizedDoc
                    pure (FileReport path size (Just digest) Textual useHaskellMode lineCounts charCounts ngramCounts Nothing)

emptyReport :: FilePath -> FileKind -> Bool -> Maybe String -> FileReport
emptyReport path kind usedHaskellMode note = FileReport path 0 Nothing kind usedHaskellMode M.empty M.empty M.empty note

chooseNormalizer :: Bool -> (T.Text -> T.Text)
chooseNormalizer useHaskellMode
  | useHaskellMode = normalizeHaskellLine
  | otherwise = normalizeLine

normalizeDocument :: (T.Text -> T.Text) -> T.Text -> T.Text
normalizeDocument normalizer =
  T.unwords
    . filter (not . T.null)
    . map normalizer
    . T.lines

fnv1a64 :: BS.ByteString -> Word64
fnv1a64 = BS.foldl' step 14695981039346656037
  where
    step acc byte = (acc `xor` fromIntegral byte) * 1099511628211

isLikelyBinary :: BS.ByteString -> Bool
isLikelyBinary bytes = BS.any (== 0) (BS.take 4096 bytes)

normalizeLine :: T.Text -> T.Text
normalizeLine = T.unwords . T.words . T.toCaseFold

normalizeHaskellLine :: T.Text -> T.Text
normalizeHaskellLine = T.unwords . T.words . T.pack . goNormal . T.unpack
  where
    goNormal [] = []
    goNormal ('-':'-':_) = []
    goNormal ('"':xs) = " str " ++ goString False xs
    goNormal ('\'':xs) = " chr " ++ goChar False xs
    goNormal (x:xs)
      | isSpace x = ' ' : goNormal xs
      | isDigit x = '0' : goNormal xs
      | isAlphaNum x || x `elem` ("_'" :: String) = toLower x : goNormal xs
      | isHaskellOperatorChar x = x : goNormal xs
      | otherwise = ' ' : goNormal xs

    goString _ [] = []
    goString escaped (x:xs)
      | escaped = goString False xs
      | x == '\\' = goString True xs
      | x == '"' = ' ' : goNormal xs
      | otherwise = goString False xs

    goChar _ [] = []
    goChar escaped (x:xs)
      | escaped = goChar False xs
      | x == '\\' = goChar True xs
      | x == '\'' = ' ' : goNormal xs
      | otherwise = goChar False xs

isHaskellOperatorChar :: Char -> Bool
isHaskellOperatorChar ch = ch `elem` (":!#$%&*+./<=>?@\\^|-~" :: String)

countLinesWith :: (T.Text -> T.Text) -> T.Text -> M.Map T.Text Int
countLinesWith normalizer txt =
  M.fromListWith (+)
    [ (normalized, 1)
    | line <- T.lines txt
    , let normalized = normalizer line
    , not (T.null normalized)
    ]

countChars :: T.Text -> M.Map Char Int
countChars txt =
  M.fromListWith (+)
    [ (ch, 1)
    | ch <- T.unpack txt
    , not (isSpace ch)
    ]

countNgrams :: Int -> T.Text -> M.Map T.Text Int
countNgrams n txt =
  M.fromListWith (+)
    [ (gram, 1)
    | gram <- charNgrams n txt
    ]

charNgrams :: Int -> T.Text -> [T.Text]
charNgrams n txt
  | n <= 0 = []
  | otherwise = go compact
  where
    compact = filter (not . isSpace) (T.unpack txt)
    go xs =
      case takeExact n xs of
        Nothing -> []
        Just chunk -> T.pack chunk : go (drop 1 xs)

    takeExact k xs =
      let chunk = take k xs
       in if length chunk == k then Just chunk else Nothing

emptyAggregate :: Aggregate
emptyAggregate = Aggregate 0 0 0 0 0 0 0 M.empty M.empty M.empty M.empty []

accumulate :: Aggregate -> FileReport -> Aggregate
accumulate agg report =
  let agg1 =
        agg
          { agTotalFiles = agTotalFiles agg + 1
          , agTextFiles = agTextFiles agg + if frKind report == Textual then 1 else 0
          , agBinaryFiles = agBinaryFiles agg + if frKind report == Binaryish then 1 else 0
          , agSkippedFiles = agSkippedFiles agg + if frKind report == Skipped then 1 else 0
          , agFailedFiles = agFailedFiles agg + if frKind report == Failed then 1 else 0
          , agHaskellFiles = agHaskellFiles agg + if isHaskellLikePath (frPath report) then 1 else 0
          , agHaskellNormalizedFiles = agHaskellNormalizedFiles agg + if frUsedHaskellMode report then 1 else 0
          , agFileGroups = addFileGroup (agFileGroups agg) report
          , agLineStats = mergeTextStats (agLineStats agg) (frLineCounts report)
          , agNgramStats = mergeTextStats (agNgramStats agg) (frNgramCounts report)
          , agCharStats = mergeCharStats (agCharStats agg) (frCharCounts report)
          }
   in case frNote report of
        Nothing -> agg1
        Just note -> agg1 { agNotes = agNotes agg1 ++ [(frPath report, note)] }

addFileGroup :: M.Map (Integer, Word64) [FilePath] -> FileReport -> M.Map (Integer, Word64) [FilePath]
addFileGroup groups report =
  case frHash report of
    Nothing -> groups
    Just digest -> M.insertWith (++) (frSize report, digest) [frPath report] groups

mergeTextStats :: M.Map T.Text (Int, Int) -> M.Map T.Text Int -> M.Map T.Text (Int, Int)
mergeTextStats stats perFile = M.foldlWithKey' step stats perFile
  where
    step acc key count = M.insertWith combine key (count, 1) acc
    combine (newCount, newFiles) (oldCount, oldFiles) = (newCount + oldCount, newFiles + oldFiles)

mergeCharStats :: M.Map Char Int -> M.Map Char Int -> M.Map Char Int
mergeCharStats = M.unionWith (+)

renderOutput :: OutputMode -> ScanResult -> IO ()
renderOutput mode result =
  case mode of
    OutputReport -> renderReport result
    OutputSummary -> renderSummaryPlain result
    OutputFiles -> renderDuplicateFilesPlain result
    OutputLines -> renderTextStatsPlain "line" result (agLineStats agg)
    OutputNgrams -> renderTextStatsPlain "ngram" result (agNgramStats agg)
    OutputChars -> renderCharStatsPlain result (agCharStats agg)
    OutputNotes -> renderNotesPlain result
  where
    agg = srAggregate result

inputRootLabel :: Config -> String
inputRootLabel cfg =
  case cfgInputMode cfg of
    CrawlFilesystem -> cfgRoot cfg
    ReadPathsFromStdin -> "<stdin-paths>"

renderReport :: ScanResult -> IO ()
renderReport result = do
  let cfg = srConfig result
      agg = srAggregate result
  putStrLn "OpenClaw spider deduper"
  putStrLn $ "root:             " ++ inputRootLabel cfg
  putStrLn $ "input mode:       " ++ show (cfgInputMode cfg)
  putStrLn $ "scan mode:        " ++ show (cfgScanMode cfg)
  putStrLn $ "output mode:      " ++ show (cfgOutputMode cfg)
  putStrLn $ "haskellify:       " ++ show (cfgHaskellify cfg)
  putStrLn $ "debug:            " ++ show (cfgDebug cfg)
  putStrLn $ "discovered files: " ++ show (length (srDiscovered result))
  putStrLn $ "processed files:  " ++ show (agTotalFiles agg)
  putStrLn $ "text files:       " ++ show (agTextFiles agg)
  putStrLn $ "binary files:     " ++ show (agBinaryFiles agg)
  putStrLn $ "skipped files:    " ++ show (agSkippedFiles agg)
  putStrLn $ "failed files:     " ++ show (agFailedFiles agg)
  putStrLn $ "haskell files:    " ++ show (agHaskellFiles agg)
  putStrLn $ "haskellified:     " ++ show (agHaskellNormalizedFiles agg)
  putStrLn $ "workers:          " ++ show (cfgWorkers cfg)
  putStrLn $ "ngram size:       " ++ show (cfgNgramSize cfg)
  putStrLn $ "max file bytes:   " ++ show (cfgMaxFileBytes cfg)
  case cfgMaxFiles cfg of
    Nothing -> pure ()
    Just limit -> putStrLn $ "max files:        " ++ show limit ++ " (truncated run)"
  when (length (srSelected result) < length (srDiscovered result)) $ putStrLn "note: file discovery was truncated by --max-files"

  putStrLn ""
  putStrLn "== probable duplicate files =="
  renderDuplicateFilesHuman result

  putStrLn ""
  putStrLn "== duplicate lines =="
  renderTextStatsHuman result (agLineStats agg)

  putStrLn ""
  putStrLn "== duplicate char ngrams =="
  renderTextStatsHuman result (agNgramStats agg)

  putStrLn ""
  putStrLn "== char histogram =="
  renderCharStatsHuman result (agCharStats agg)

  putStrLn ""
  putStrLn "== notes =="
  renderNotesHuman result

renderSummaryPlain :: ScanResult -> IO ()
renderSummaryPlain result = do
  let cfg = srConfig result
      agg = srAggregate result
  putSummary "root" (inputRootLabel cfg)
  putSummary "input_mode" (show (cfgInputMode cfg))
  putSummary "scan_mode" (show (cfgScanMode cfg))
  putSummary "output_mode" (show (cfgOutputMode cfg))
  putSummary "haskellify" (show (cfgHaskellify cfg))
  putSummary "debug" (show (cfgDebug cfg))
  putSummary "discovered_files" (show (length (srDiscovered result)))
  putSummary "processed_files" (show (agTotalFiles agg))
  putSummary "text_files" (show (agTextFiles agg))
  putSummary "binary_files" (show (agBinaryFiles agg))
  putSummary "skipped_files" (show (agSkippedFiles agg))
  putSummary "failed_files" (show (agFailedFiles agg))
  putSummary "haskell_files" (show (agHaskellFiles agg))
  putSummary "haskellified_files" (show (agHaskellNormalizedFiles agg))
  putSummary "workers" (show (cfgWorkers cfg))
  putSummary "ngram_size" (show (cfgNgramSize cfg))
  putSummary "max_file_bytes" (show (cfgMaxFileBytes cfg))
  putSummary "truncated" (show (length (srSelected result) < length (srDiscovered result)))
  where
    putSummary key value = putStrLn (L.intercalate "\t" ["summary", key, escapeField value])

renderDuplicateFilesHuman :: ScanResult -> IO ()
renderDuplicateFilesHuman result = do
  let groups = duplicateFileGroups (srConfig result) (srAggregate result)
  if null groups
    then putStrLn "none"
    else forM_ groups $ \((sizeBytes, digest), paths) -> do
      putStrLn $ "- count=" ++ show (length paths) ++ " size=" ++ show sizeBytes ++ " hash=0x" ++ showHex digest ""
      forM_ paths $ \path -> putStrLn ("  * " ++ path)

renderDuplicateFilesPlain :: ScanResult -> IO ()
renderDuplicateFilesPlain result =
  forM_ (duplicateFileGroups (srConfig result) (srAggregate result)) $ \((sizeBytes, digest), paths) ->
    forM_ paths $ \path ->
      putStrLn (L.intercalate "\t" ["file-group", show (length paths), show sizeBytes, showHex digest "", escapeField path])

duplicateFileGroups :: Config -> Aggregate -> [((Integer, Word64), [FilePath])]
duplicateFileGroups cfg agg =
  take (cfgMaxItems cfg)
    . filter ((> 1) . length . snd)
    . L.sortBy compareGroups
    $ M.toList (agFileGroups agg)
  where
    compareGroups ((sizeA, _), pathsA) ((sizeB, _), pathsB) = compare (length pathsB, sizeB) (length pathsA, sizeA)

renderTextStatsHuman :: ScanResult -> M.Map T.Text (Int, Int) -> IO ()
renderTextStatsHuman result stats = do
  let items = duplicateTextItems (srConfig result) stats
  if null items
    then putStrLn "none"
    else forM_ items $ \(snippet, (totalCount, fileCount)) ->
      putStrLn ("- total=" ++ show totalCount ++ " files=" ++ show fileCount ++ " text=" ++ show (truncateText 80 snippet))

renderTextStatsPlain :: String -> ScanResult -> M.Map T.Text (Int, Int) -> IO ()
renderTextStatsPlain label result stats =
  forM_ (duplicateTextItems (srConfig result) stats) $ \(snippet, (totalCount, fileCount)) ->
    putStrLn (L.intercalate "\t" [label, show totalCount, show fileCount, escapeField (T.unpack snippet)])

duplicateTextItems :: Config -> M.Map T.Text (Int, Int) -> [(T.Text, (Int, Int))]
duplicateTextItems cfg stats =
  take (cfgMaxItems cfg)
    . filter (\(_, (totalCount, _)) -> totalCount >= cfgMinOccurrences cfg)
    . L.sortBy compareStats
    $ M.toList stats
  where
    compareStats (_, (totalA, filesA)) (_, (totalB, filesB)) = compare (totalB, filesB) (totalA, filesA)

renderCharStatsHuman :: ScanResult -> M.Map Char Int -> IO ()
renderCharStatsHuman result stats = do
  let items = charItems (srConfig result) stats
  if null items
    then putStrLn "none"
    else forM_ items $ \(ch, count) -> putStrLn ("- count=" ++ show count ++ " char=" ++ formatChar ch)

renderCharStatsPlain :: ScanResult -> M.Map Char Int -> IO ()
renderCharStatsPlain result stats =
  forM_ (charItems (srConfig result) stats) $ \(ch, count) ->
    putStrLn (L.intercalate "\t" ["char", show count, formatCodePoint ch, escapeField [ch]])

charItems :: Config -> M.Map Char Int -> [(Char, Int)]
charItems cfg stats = take (cfgMaxItems cfg) . L.sortBy compareChars $ M.toList stats
  where
    compareChars (_, countA) (_, countB) = compare countB countA

renderNotesHuman :: ScanResult -> IO ()
renderNotesHuman result =
  let cfg = srConfig result
      notes = agNotes (srAggregate result)
   in if null notes
        then putStrLn "none"
        else forM_ (take (cfgMaxItems cfg) notes) $ \(path, note) -> putStrLn ("- " ++ path ++ " :: " ++ note)

renderNotesPlain :: ScanResult -> IO ()
renderNotesPlain result =
  let cfg = srConfig result
      notes = agNotes (srAggregate result)
   in forM_ (take (cfgMaxItems cfg) notes) $ \(path, note) ->
        putStrLn (L.intercalate "\t" ["note", escapeField path, escapeField note])

hasHits :: Config -> Aggregate -> Bool
hasHits cfg agg =
  not (null (duplicateFileGroups cfg agg))
    || not (null (duplicateTextItems cfg (agLineStats agg)))
    || not (null (duplicateTextItems cfg (agNgramStats agg)))

truncateText :: Int -> T.Text -> T.Text
truncateText n txt
  | T.length txt <= n = txt
  | n <= 3 = T.take n txt
  | otherwise = T.take (n - 3) txt <> "..."

formatChar :: Char -> String
formatChar ch = show [ch] ++ " (" ++ formatCodePoint ch ++ ")"

formatCodePoint :: Char -> String
formatCodePoint ch = "U+" ++ padded
  where
    raw = showHex (ord ch) ""
    padded = replicate (max 0 (4 - length raw)) '0' ++ raw

escapeField :: String -> String
escapeField = map escapeChar
  where
    escapeChar '\t' = ' '
    escapeChar '\n' = ' '
    escapeChar '\r' = ' '
    escapeChar ch = ch
