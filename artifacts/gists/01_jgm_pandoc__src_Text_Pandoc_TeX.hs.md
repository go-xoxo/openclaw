# jgm/pandoc :: src/Text/Pandoc/TeX.hs

- x: `42550`
- y: `1634`
- z: `42550 + 1634i`
- x prime: `false`
- y prime: `false`
- both prime: `false`
- source: https://github.com/jgm/pandoc/blob/d39ca219e7b8de7fee88dd46a6335c17419fecc1/src/Text/Pandoc/TeX.hs
- local copy: `C:\Users\frits\.codex\memories\openclaw\hasel2\artifacts\downloads\jgm\pandoc\src\Text\Pandoc\TeX.hs`

```hs
{-# LANGUAGE FlexibleInstances #-}
{- |
   Module      : Text.Pandoc.TeX
   Copyright   : Copyright (C) 2017-2024 John MacFarlane
   License     : GNU GPL, version 2 or above
   Maintainer  : John MacFarlane <jgm@berkeley.edu>
   Stability   : alpha
   Portability : portable
Types for TeX tokens and macros.
-}
module Text.Pandoc.TeX ( Tok(..)
                       , TokType(..)
                       , Macro(..)
                       , ArgSpec(..)
                       , ExpansionPoint(..)
                       , MacroScope(..)
                       , SourcePos
                       )
```
