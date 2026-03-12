# jgm/pandoc :: src/Text/Pandoc/ImageSize.hs

- x: `42550`
- y: `23298`
- z: `42550 + 23298i`
- x prime: `false`
- y prime: `false`
- both prime: `false`
- source: https://github.com/jgm/pandoc/blob/d39ca219e7b8de7fee88dd46a6335c17419fecc1/src/Text/Pandoc/ImageSize.hs
- local copy: `C:\Users\frits\.codex\memories\openclaw\hasel2\artifacts\downloads\jgm\pandoc\src\Text\Pandoc\ImageSize.hs`

```hs
{-# LANGUAGE OverloadedStrings, ScopedTypeVariables #-}
{-# LANGUAGE ViewPatterns      #-}
{-# OPTIONS_GHC -fno-warn-type-defaults #-}
{- |
Module      : Text.Pandoc.ImageSize
Copyright   : Copyright (C) 2011-2024 John MacFarlane
License     : GNU GPL, version 2 or above
Maintainer  : John MacFarlane <jgm@berkeley.edu>
Stability   : alpha
Portability : portable
Functions for determining the size of a PNG, JPEG, or GIF image.
-}
module Text.Pandoc.ImageSize ( ImageType(..)
                             , ImageSize(..)
                             , imageType
                             , imageSize
                             , sizeInPixels
                             , sizeInPoints
```
