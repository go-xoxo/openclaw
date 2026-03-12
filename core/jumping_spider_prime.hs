module Main where

import Data.Bits (shiftR, testBit)
import Data.List (intercalate)
import System.Environment (getArgs)
import System.Exit (die)
import System.IO (hSetEncoding, stderr, stdout, utf8)
import Text.Read (readMaybe)

data Config = Config
  { cfgTarget :: Integer
  , cfgCount :: Int
  }

main :: IO ()
main = do
  hSetEncoding stdout utf8
  hSetEncoding stderr utf8
  args <- getArgs
  cfg <- either die pure (parseArgs args)
  let target = cfgTarget cfg
      count = cfgCount cfg
      below = previousPrimes target count
      above = nextPrimes target count
  putStrLn "Jumping Spider Prime Searcher"
  putStrLn $ "target\t" ++ show target
  putStrLn $ "is_prime\t" ++ boolString (isPrime target)
  putStrLn $ "below\t" ++ csv below
  putStrLn $ "above\t" ++ csv above
  putStrLn "rhythm"
  mapM_ putStrLn (zipRhythm below above)

parseArgs :: [String] -> Either String Config
parseArgs [] = Right (Config 10001 10)
parseArgs [targetRaw] = Config <$> parseInteger "target" targetRaw <*> pure 10
parseArgs [targetRaw, countRaw] = Config <$> parseInteger "target" targetRaw <*> parseCount countRaw
parseArgs _ = Left usage

usage :: String
usage = unlines
  [ "Usage: jumping_spider_prime.hs [target] [count]"
  , ""
  , "Defaults: target=10001 count=10"
  , "Example: runghc jumping_spider_prime.hs 10000000001 8"
  ]

parseInteger :: String -> String -> Either String Integer
parseInteger label raw =
  case readMaybe raw of
    Just value | value >= 0 -> Right value
    _ -> Left ("Expected a non-negative integer for " ++ label ++ ", got: " ++ raw)

parseCount :: String -> Either String Int
parseCount raw =
  case readMaybe raw of
    Just value | value > 0 -> Right value
    _ -> Left ("Expected a positive count, got: " ++ raw)

boolString :: Bool -> String
boolString True = "true"
boolString False = "false"

csv :: Show a => [a] -> String
csv = intercalate "," . map show

zipRhythm :: [Integer] -> [Integer] -> [String]
zipRhythm below above = take (max (length below) (length above) * 2) (go 1 below above)
  where
    go _ [] [] = []
    go ix (b:bs) (a:as) = format ix "down" b : format ix "up" a : go (ix + 1) bs as
    go ix (b:bs) [] = format ix "down" b : go (ix + 1) bs []
    go ix [] (a:as) = format ix "up" a : go (ix + 1) [] as
    format ix side value = show ix ++ "\t" ++ side ++ "\t" ++ show value

previousPrimes :: Integer -> Int -> [Integer]
previousPrimes target count = take count (filter isPrime [target - 1, target - 2 .. 2])

nextPrimes :: Integer -> Int -> [Integer]
nextPrimes target count = take count (filter isPrime [target + 1 ..])

isPrime :: Integer -> Bool
isPrime n
  | n < 2 = False
  | n == 2 = True
  | even n = False
  | otherwise = all (millerRabinPass n) bases64
  where
    bases64 = filter (< n) [2, 325, 9375, 28178, 450775, 9780504, 1795265022]

millerRabinPass :: Integer -> Integer -> Bool
millerRabinPass n a =
  let (s, d) = factorTwos (n - 1)
      x0 = powMod a d n
   in x0 == 1 || x0 == n - 1 || any ((== n - 1) . step x0) [1 .. s - 1]
  where
    step x _ = (x * x) `mod` n

factorTwos :: Integer -> (Int, Integer)
factorTwos = go 0
  where
    go s d
      | even d = go (s + 1) (d `div` 2)
      | otherwise = (s, d)

powMod :: Integer -> Integer -> Integer -> Integer
powMod _ 0 modulus = 1 `mod` modulus
powMod base exponent modulus = go base exponent 1
  where
    go _ 0 acc = acc
    go b e acc
      | testBit e 0 = go b2 (e `shiftR` 1) ((acc * b) `mod` modulus)
      | otherwise = go b2 (e `shiftR` 1) acc
      where
        b2 = (b * b) `mod` modulus
