module Main where

import Prelude

import Data.Array (intercalate)
import Data.Char (toLower)
import Data.CodePoint.Unicode (isPrint)
import Data.Maybe (fromMaybe)
import Data.String (Pattern(..), Replacement(..), joinWith, split)
import Data.String.CodePoints as CP
import Effect (Effect)
import Effect.Console (log)
import Node.Process (argv)

defaultInput :: String
defaultInput = "Hasel λ🐿 2.0"

main :: Effect Unit
main = do
  args <- argv
  let input = fromMaybe defaultInput (joinArgs (drop 2 args))
  emit "input" input
  emit "everything" ("*" <> input <> "*")
  emit "regex" (".*" <> regexEscape input <> ".*")
  emit "ascii_printable" (asciiPrintable input)
  emit "contains_non_ascii" (if containsNonAscii input then "true" else "false")
  emit "tokens" (joinWith "," (map toLower <$> split (Pattern " ") input))
  emit "codepoints" (joinWith "," (map formatCodePoint (CP.toCodePointArray input)))

emit :: String -> String -> Effect Unit
emit key value = log (key <> "\t" <> value)

joinArgs :: Array String -> Maybe String
joinArgs xs = if null xs then Nothing else Just (joinWith " " xs)

containsNonAscii :: String -> Boolean
containsNonAscii = any (_ > 0x7F) <<< map CP.codePointToInt <<< CP.toCodePointArray

asciiPrintable :: String -> String
asciiPrintable = CP.fromCodePointArray <<< map replace <<< CP.toCodePointArray
  where
  replace cp =
    let n = CP.codePointToInt cp
    in if n == 32 || (n >= 33 && n <= 126 && isPrint cp) then cp else CP.codePointFromChar '?'

regexEscape :: String -> String
regexEscape = CP.foldMap escape <<< CP.toCodePointArray
  where
  meta = CP.toCodePointArray "\\.^$|?*+()[]{}"
  escape cp = if cp `elem` meta then "\\" <> CP.singleton cp else CP.singleton cp

formatCodePoint :: CP.CodePoint -> String
formatCodePoint cp = "U+" <> show (CP.codePointToInt cp)
