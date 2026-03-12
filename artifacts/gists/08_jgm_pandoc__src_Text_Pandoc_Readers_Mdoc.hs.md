---
title: "jgm/pandoc :: src/Text/Pandoc/Readers/Mdoc.hs"
repo: "jgm/pandoc"
path: "src/Text/Pandoc/Readers/Mdoc.hs"
project: "Hasel 2.0"
x: 42550
y: 47611
z: "42550 + 47611i"
x_prime: false
y_prime: false
both_prime: false
source: "https://github.com/jgm/pandoc/blob/main/src/Text/Pandoc/Readers/Mdoc.hs"
---

# jgm/pandoc :: src/Text/Pandoc/Readers/Mdoc.hs


```hs
{-# LANGUAGE CPP  #-}
{-# LANGUAGE FlexibleContexts  #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE ViewPatterns #-}
{- |
   Module      : Text.Pandoc.Readers.Mdoc
   Copyright   : © 2024 Evan Silberman
   License     : GNU GPL, version 2 or above
   Maintainer  : Evan Silberman <evan@jklol.net>
   Stability   : WIP
   Portability : portable
Conversion of mdoc to 'Pandoc' document.
-}
module Text.Pandoc.Readers.Mdoc (readMdoc) where
import Data.Char (isAsciiLower, toUpper)
import Data.Default (Default)
import Data.Either (fromRight)
```
