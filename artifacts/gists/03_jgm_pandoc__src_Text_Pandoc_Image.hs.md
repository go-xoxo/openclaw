# jgm/pandoc :: src/Text/Pandoc/Image.hs

- x: `42550`
- y: `1329`
- z: `42550 + 1329i`
- x prime: `false`
- y prime: `false`
- both prime: `false`
- source: https://github.com/jgm/pandoc/blob/d39ca219e7b8de7fee88dd46a6335c17419fecc1/src/Text/Pandoc/Image.hs
- local copy: `C:\Users\frits\.codex\memories\openclaw\hasel2\artifacts\downloads\jgm\pandoc\src\Text\Pandoc\Image.hs`

```hs
{-# LANGUAGE OverloadedStrings, ScopedTypeVariables, CPP #-}
{- |
Module      : Text.Pandoc.Image
Copyright   : Copyright (C) 2020-2024 John MacFarlane
License     : GNU GPL, version 2 or above
Maintainer  : John MacFarlane <jgm@berkeley.edu>
Stability   : alpha
Portability : portable
Functions for converting images.
-}
module Text.Pandoc.Image ( svgToPng ) where
import Text.Pandoc.Process (pipeProcess)
import qualified Data.ByteString.Lazy as L
import System.Exit
import Data.Text (Text)
import Text.Pandoc.Shared (tshow)
import qualified Control.Exception as E
import Control.Monad.IO.Class (MonadIO(liftIO))
```
