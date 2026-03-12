{-# LANGUAGE OverloadedStrings #-}
module Main where

import Control.Monad (forM_, unless, when)
import Data.Char (isSpace)
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import qualified Data.Text.Encoding as TE
import qualified Data.ByteString as BS
import System.Directory (createDirectoryIfMissing, doesFileExist)
import System.Environment (getArgs)
import System.Exit (die)
import System.FilePath (takeFileName, (</>))
import System.IO (hSetEncoding, stderr, stdout, utf8)

data InputMode = InputArgs | InputStdin
  deriving (Eq, Show)

data Config = Config
  { cfgInputMode :: InputMode
  , cfgOutDir :: Maybe FilePath
  , cfgEmitHeaders :: Bool
  , cfgPaths :: [FilePath]
  }
  deriving (Eq, Show)

defaultConfig :: Config
defaultConfig = Config
  { cfgInputMode = InputArgs
  , cfgOutDir = Nothing
  , cfgEmitHeaders = False
  , cfgPaths = []
  }

usage :: String
usage = unlines
  [ "haskell_compactify"
  , ""
  , "Usage: haskell_compactify [--stdin-paths] [--out-dir DIR] [--emit-headers] [paths...]"
  , ""
  , "Examples:"
  , "  haskell_compactify spider_dedupe.hs"
  , "  rg --files -g '*.hs' . | haskell_compactify --stdin-paths --out-dir compacted"
  , ""
  , "The tool removes comments, collapses whitespace, preserves pragmas, and keeps"
  , "string and char literals intact."
  ]

parseArgs :: [String] -> Either String Config
parseArgs = go defaultConfig
  where
    go cfg []
      | cfgInputMode cfg == InputArgs && null (cfgPaths cfg) = Left usage
      | otherwise = Right cfg
    go cfg ("--help":_) = Left usage
    go cfg ("--stdin-paths":rest) = go cfg { cfgInputMode = InputStdin } rest
    go cfg ("--emit-headers":rest) = go cfg { cfgEmitHeaders = True } rest
    go cfg ("--out-dir":dir:rest) = go cfg { cfgOutDir = Just dir } rest
    go cfg (arg:rest)
      | take 2 arg == "--" = Left ("Unknown option: " ++ arg ++ "\n\n" ++ usage)
      | otherwise = go cfg { cfgPaths = cfgPaths cfg ++ [arg] } rest

main :: IO ()
main = do
  hSetEncoding stdout utf8
  hSetEncoding stderr utf8
  cfg <- either die pure . parseArgs =<< getArgs
  paths <- gatherPaths cfg
  unless (null paths) $ do
    files <- filterMExisting paths
    renderAll cfg files

filterMExisting :: [FilePath] -> IO [FilePath]
filterMExisting = go []
  where
    go acc [] = pure (reverse acc)
    go acc (path:rest) = do
      exists <- doesFileExist path
      if exists
        then go (path : acc) rest
        else go acc rest

gatherPaths :: Config -> IO [FilePath]
gatherPaths cfg =
  case cfgInputMode cfg of
    InputArgs -> pure (cfgPaths cfg)
    InputStdin -> do
      raw <- TIO.getContents
      pure
        [ T.unpack (T.strip line)
        | line <- T.lines raw
        , not (T.null (T.strip line))
        ]

renderAll :: Config -> [FilePath] -> IO ()
renderAll cfg paths =
  case cfgOutDir cfg of
    Just outDir -> do
      createDirectoryIfMissing True outDir
      forM_ paths $ \path -> do
        compacted <- compactFile path
        let target = outDir </> sanitizePath path
        TIO.writeFile target compacted
    Nothing ->
      case paths of
        [single] -> compactFile single >>= TIO.putStr
        _ -> forM_ paths $ \path -> do
          when (cfgEmitHeaders cfg) $ TIO.putStrLn (T.pack ("-- FILE: " ++ path))
          compactFile path >>= TIO.putStrLn

compactFile :: FilePath -> IO T.Text
compactFile path = do
  bytes <- BS.readFile path
  txt <- either (const (die ("UTF-8 decode failed: " ++ path))) pure (TE.decodeUtf8' bytes)
  pure (T.pack (trimSpaces (compactify (T.unpack txt))))

sanitizePath :: FilePath -> FilePath
sanitizePath path = map sanitizeChar path ++ ".compact.hs"
  where
    sanitizeChar ch
      | ch == '/' = '_'
      | ch == '\\' = '_'
      | ch == ':' = '_'
      | otherwise = ch

data Mode = Normal | StringLit Bool | CharLit Bool | LineComment | BlockComment Int | Pragma Int
  deriving (Eq, Show)

compactify :: String -> String
compactify = reverse . go Normal False []
  where
    go _ pending acc [] = finish pending acc
    go Normal pending acc ('{':'-':'#':xs) = go (Pragma 1) False (prepend "#-{" (emitSpace pending acc)) xs
    go Normal pending acc ('{':'-':xs) = go (BlockComment 1) True acc xs
    go Normal pending acc ('-':'-':x:xs)
      | startsLineComment x = go LineComment True acc (x:xs)
    go Normal pending acc ['-','-'] = go LineComment True acc []
    go Normal _ acc (c:xs)
      | isSpace c = go Normal True acc xs
    go Normal pending acc ('"':xs) = go (StringLit False) False ('"' : emitSpace pending acc) xs
    go Normal pending acc ('\'':xs) = go (CharLit False) False ('\'' : emitSpace pending acc) xs
    go Normal pending acc (c:xs) = go Normal False (c : emitSpace pending acc) xs

    go (StringLit escaped) pending acc [] = finish pending acc
    go (StringLit escaped) pending acc (c:xs)
      | escaped = go (StringLit False) pending (c : acc) xs
      | c == '\\' = go (StringLit True) pending (c : acc) xs
      | c == '"' = go Normal pending (c : acc) xs
      | otherwise = go (StringLit False) pending (c : acc) xs

    go (CharLit escaped) pending acc [] = finish pending acc
    go (CharLit escaped) pending acc (c:xs)
      | escaped = go (CharLit False) pending (c : acc) xs
      | c == '\\' = go (CharLit True) pending (c : acc) xs
      | c == '\'' = go Normal pending (c : acc) xs
      | otherwise = go (CharLit False) pending (c : acc) xs

    go LineComment pending acc [] = finish pending acc
    go LineComment _ acc (c:xs)
      | c == '\n' = go Normal True acc xs
      | otherwise = go LineComment True acc xs

    go (BlockComment depth) pending acc [] = finish pending acc
    go (BlockComment depth) pending acc ('{':'-':'#':xs) = go (BlockComment depth) pending acc ('{':'-':xs)
    go (BlockComment depth) pending acc ('{':'-':xs) = go (BlockComment (depth + 1)) pending acc xs
    go (BlockComment 1) pending acc ('-':'}':xs) = go Normal True acc xs
    go (BlockComment depth) pending acc ('-':'}':xs) = go (BlockComment (depth - 1)) pending acc xs
    go (BlockComment depth) pending acc (_:xs) = go (BlockComment depth) pending acc xs

    go (Pragma depth) pending acc [] = finish pending acc
    go (Pragma depth) pending acc ('{':'-':'#':xs) = go (Pragma (depth + 1)) pending (prepend "#-{" (emitSpace pending acc)) xs
    go (Pragma 1) pending acc ('#':'-':'}':xs) = go Normal True (prepend "}-#" acc) xs
    go (Pragma depth) pending acc ('#':'-':'}':xs) = go (Pragma (depth - 1)) pending (prepend "}-#" acc) xs
    go (Pragma depth) pending acc (c:xs) = go (Pragma depth) pending (c : emitSpace pending acc) xs

    emitSpace True acc =
      case acc of
        [] -> []
        (' ' : _) -> acc
        _ -> ' ' : acc
    emitSpace False acc = acc

    finish pending acc = reverseTrim (emitSpace pending acc)

    prepend = foldr (:)

startsLineComment :: Char -> Bool
startsLineComment next = not (isHaskellSymbol next)

isHaskellSymbol :: Char -> Bool
isHaskellSymbol ch = ch `elem` (":!#$%&*+./<=>?@\\^|-~" :: String)

trimSpaces :: String -> String
trimSpaces = T.unpack . T.strip . T.pack

reverseTrim :: String -> String
reverseTrim = dropWhile isSpace
