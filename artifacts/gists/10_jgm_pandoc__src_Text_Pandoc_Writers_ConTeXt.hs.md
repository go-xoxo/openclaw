# jgm/pandoc :: src/Text/Pandoc/Writers/ConTeXt.hs

- x: `42550`
- y: `34848`
- z: `42550 + 34848i`
- x prime: `false`
- y prime: `false`
- both prime: `false`
- source: https://github.com/jgm/pandoc/blob/d39ca219e7b8de7fee88dd46a6335c17419fecc1/src/Text/Pandoc/Writers/ConTeXt.hs
- local copy: `C:\Users\frits\.codex\memories\openclaw\hasel2\artifacts\downloads\jgm\pandoc\src\Text\Pandoc\Writers\ConTeXt.hs`

```hs
{-# LANGUAGE LambdaCase          #-}
{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE ViewPatterns        #-}
{- |
   Module      : Text.Pandoc.Writers.ConTeXt
   Copyright   : Copyright (C) 2007-2025 John MacFarlane
   License     : GNU GPL, version 2 or above
   Maintainer  : John MacFarlane <jgm@berkeley.edu>
   Stability   : alpha
   Portability : portable
Conversion of 'Pandoc' format into ConTeXt.
-}
module Text.Pandoc.Writers.ConTeXt ( writeConTeXt ) where
import Control.Monad (liftM, unless)
import Control.Monad.State.Strict
    ( StateT, MonadState(put, get), gets, modify, evalStateT )
import Data.Char (ord, isDigit)
```
