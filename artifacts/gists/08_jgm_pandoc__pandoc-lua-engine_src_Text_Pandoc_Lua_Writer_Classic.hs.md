# jgm/pandoc :: pandoc-lua-engine/src/Text/Pandoc/Lua/Writer/Classic.hs

- x: `42550`
- y: `8608`
- z: `42550 + 8608i`
- x prime: `false`
- y prime: `false`
- both prime: `false`
- source: https://github.com/jgm/pandoc/blob/d39ca219e7b8de7fee88dd46a6335c17419fecc1/pandoc-lua-engine/src/Text/Pandoc/Lua/Writer/Classic.hs
- local copy: `C:\Users\frits\.codex\memories\openclaw\hasel2\artifacts\downloads\jgm\pandoc\pandoc-lua-engine\src\Text\Pandoc\Lua\Writer\Classic.hs`

```hs
{-# LANGUAGE CPP                 #-}
{-# LANGUAGE FlexibleContexts    #-}
{-# LANGUAGE FlexibleInstances   #-}
{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications    #-}
{- |
   Module      : Text.Pandoc.Lua.Writer.Classic
   Copyright   : Copyright (C) 2012-2024 John MacFarlane
   License     : GNU GPL, version 2 or above
   Maintainer  : John MacFarlane <jgm@berkeley.edu>
   Stability   : alpha
   Portability : portable
Conversion of Pandoc documents using a \"classic\" custom Lua writer.
-}
module Text.Pandoc.Lua.Writer.Classic
  ( runCustom
  ) where
```
