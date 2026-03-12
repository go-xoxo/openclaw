module Main where

import Data.Char (isAscii, isPrint, ord, toLower, toUpper)
import Data.List (intercalate)
import Numeric (showHex)
import System.Environment (getArgs, lookupEnv)
import System.IO (hSetEncoding, stderr, stdout, utf8)

main :: IO ()
main = do
  hSetEncoding stdout utf8
  hSetEncoding stderr utf8
  args <- getArgs
  envInput <- lookupEnv "HASEL_INPUT"
  let input = resolveInput envInput args
  emitReport input

defaultInput :: String
defaultInput = "Hasel λ🐿 2.0"

resolveInput :: Maybe String -> [String] -> String
resolveInput (Just value) _ = value
resolveInput Nothing [] = defaultInput
resolveInput Nothing xs = unwords xs

emitReport :: String -> IO ()
emitReport input = do
  emit "input" input
  emit "everything" ("*" ++ input ++ "*")
  emit "regex" (".*" ++ regexEscape input ++ ".*")
  emit "ascii_printable" (map asciiPrintable input)
  emit "contains_non_ascii" (boolString (any (not . isAscii) input))
  emit "tokens" (intercalate "," (words (map toLower input)))
  emit "codepoints" (intercalate "," (map formatCodePoint input))

emit :: String -> String -> IO ()
emit key value = putStrLn (key ++ "\t" ++ value)

boolString :: Bool -> String
boolString True = "true"
boolString False = "false"

asciiPrintable :: Char -> Char
asciiPrintable ch
  | ch == ' ' = ' '
  | isAscii ch && isPrint ch = ch
  | otherwise = '?'

regexEscape :: String -> String
regexEscape = concatMap escape
  where
    escape ch
      | ch `elem` regexMeta = ['\\', ch]
      | otherwise = [ch]
    regexMeta = "\\.^$|?*+()[]{}"

formatCodePoint :: Char -> String
formatCodePoint ch = "U+" ++ pad4 (map toUpper (showHex (ord ch) ""))

pad4 :: String -> String
pad4 raw = replicate (max 0 (4 - length raw)) '0' ++ raw
