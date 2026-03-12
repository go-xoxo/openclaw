# jgm/pandoc :: src/Text/Pandoc/Chunks.hs

- x: `42550`
- y: `15502`
- z: `42550 + 15502i`
- x prime: `false`
- y prime: `false`
- both prime: `false`
- source: https://github.com/jgm/pandoc/blob/d39ca219e7b8de7fee88dd46a6335c17419fecc1/src/Text/Pandoc/Chunks.hs
- local copy: `C:\Users\frits\.codex\memories\openclaw\hasel2\artifacts\downloads\jgm\pandoc\src\Text\Pandoc\Chunks.hs`

```hs
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE DeriveGeneric #-}
{- |
   Module      : Text.Pandoc.Chunks
   Copyright   : Copyright (C) 2022-2024 John MacFarlane
   License     : GNU GPL, version 2 or above
   Maintainer  : John MacFarlane <jgm@berkeley.edu>
   Stability   : alpha
   Portability : portable
Functions and types for splitting a Pandoc into subdocuments,
e.g. for conversion into a set of HTML pages.
-}
module Text.Pandoc.Chunks
```
