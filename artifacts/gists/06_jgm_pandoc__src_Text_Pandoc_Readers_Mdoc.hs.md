# jgm/pandoc :: src/Text/Pandoc/Readers/Mdoc.hs

- x: `42550`
- y: `47611`
- z: `42550 + 47611i`
- x prime: `false`
- y prime: `false`
- both prime: `false`
- source: https://github.com/jgm/pandoc/blob/d39ca219e7b8de7fee88dd46a6335c17419fecc1/src/Text/Pandoc/Readers/Mdoc.hs
- local copy: `C:\Users\frits\.codex\memories\openclaw\hasel2\artifacts\downloads\jgm\pandoc\src\Text\Pandoc\Readers\Mdoc.hs`

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
