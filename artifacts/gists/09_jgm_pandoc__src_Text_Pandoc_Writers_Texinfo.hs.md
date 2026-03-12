# jgm/pandoc :: src/Text/Pandoc/Writers/Texinfo.hs

- x: `42550`
- y: `20272`
- z: `42550 + 20272i`
- x prime: `false`
- y prime: `false`
- both prime: `false`
- source: https://github.com/jgm/pandoc/blob/d39ca219e7b8de7fee88dd46a6335c17419fecc1/src/Text/Pandoc/Writers/Texinfo.hs
- local copy: `C:\Users\frits\.codex\memories\openclaw\hasel2\artifacts\downloads\jgm\pandoc\src\Text\Pandoc\Writers\Texinfo.hs`

```hs
{-# LANGUAGE OverloadedStrings #-}
{- |
   Module      : Text.Pandoc.Writers.Texinfo
   Copyright   : Copyright (C) 2008-2024 John MacFarlane
                               2012 Peter Wang
   License     : GNU GPL, version 2 or above
   Maintainer  : John MacFarlane <jgm@berkeley.edu>
   Stability   : alpha
   Portability : portable
Conversion of 'Pandoc' format into Texinfo.
-}
module Text.Pandoc.Writers.Texinfo ( writeTexinfo ) where
import Control.Monad (zipWithM, unless)
import Control.Monad.Except (throwError)
import Control.Monad.State.Strict
    ( StateT, MonadState(get), gets, modify, evalStateT )
import Data.Char (chr, ord, isAlphaNum)
import Data.List (maximumBy, transpose)
```
