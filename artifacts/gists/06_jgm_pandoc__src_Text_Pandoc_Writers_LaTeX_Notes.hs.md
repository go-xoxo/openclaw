# jgm/pandoc :: src/Text/Pandoc/Writers/LaTeX/Notes.hs

- x: `42550`
- y: `1016`
- z: `42550 + 1016i`
- x prime: `false`
- y prime: `false`
- both prime: `false`
- source: https://github.com/jgm/pandoc/blob/d39ca219e7b8de7fee88dd46a6335c17419fecc1/src/Text/Pandoc/Writers/LaTeX/Notes.hs

```hs
{-# LANGUAGE LambdaCase        #-}
{-# LANGUAGE OverloadedStrings #-}
{- |
   Module      : Text.Pandoc.Writers.LaTeX.Notes
   Copyright   : Copyright (C) 2006-2024 John MacFarlane
   License     : GNU GPL, version 2 or above
   Maintainer  : John MacFarlane <jgm@berkeley.edu>
   Stability   : alpha
   Portability : portable
Output tables as LaTeX.
-}
module Text.Pandoc.Writers.LaTeX.Notes
  ( notesToLaTeX
  ) where
import Data.List (intersperse)
import Text.DocLayout ( Doc, braces, empty, text, vcat, ($$))
import Data.Text (Text)
notesToLaTeX :: [Doc Text] -> Doc Text
```
