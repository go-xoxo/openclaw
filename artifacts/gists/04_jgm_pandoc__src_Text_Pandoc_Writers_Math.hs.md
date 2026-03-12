# jgm/pandoc :: src/Text/Pandoc/Writers/Math.hs

- x: `42550`
- y: `1839`
- z: `42550 + 1839i`
- x prime: `false`
- y prime: `false`
- both prime: `false`
- source: https://github.com/jgm/pandoc/blob/d39ca219e7b8de7fee88dd46a6335c17419fecc1/src/Text/Pandoc/Writers/Math.hs
- local copy: `C:\Users\frits\.codex\memories\openclaw\hasel2\artifacts\downloads\jgm\pandoc\src\Text\Pandoc\Writers\Math.hs`

```hs
{-# LANGUAGE OverloadedStrings #-}
module Text.Pandoc.Writers.Math
  ( texMathToInlines
  , convertMath
  , defaultMathJaxURL
  , defaultKaTeXURL
  )
where
import qualified Data.Text as T
import Text.Pandoc.Class.PandocMonad
import Text.Pandoc.Definition
import Text.Pandoc.Logging
import Text.TeXMath (DisplayType (..), Exp, readTeX, writePandoc)
import Text.Pandoc.Options (defaultMathJaxURL, defaultKaTeXURL)
-- | Converts a raw TeX math formula to a list of 'Pandoc' inlines.
-- Defaults to raw formula between @$@ or @$$@ characters if entire formula
-- can't be converted.
texMathToInlines :: PandocMonad m
```
