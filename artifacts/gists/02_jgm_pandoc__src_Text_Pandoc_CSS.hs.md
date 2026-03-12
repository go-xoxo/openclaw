# jgm/pandoc :: src/Text/Pandoc/CSS.hs

- x: `42550`
- y: `1781`
- z: `42550 + 1781i`
- x prime: `false`
- y prime: `false`
- both prime: `false`
- source: https://github.com/jgm/pandoc/blob/d39ca219e7b8de7fee88dd46a6335c17419fecc1/src/Text/Pandoc/CSS.hs
- local copy: `C:\Users\frits\.codex\memories\openclaw\hasel2\artifacts\downloads\jgm\pandoc\src\Text\Pandoc\CSS.hs`

```hs
{- |
Module      : Text.Pandoc.CSS
Copyright   : © 2006-2024 John MacFarlane <jgm@berkeley.edu>,
                2015-2016 Mauro Bieg,
                2015      Ophir Lifshitz <hangfromthefloor@gmail.com>
License     : GNU GPL, version 2 or above
Maintainer  : John MacFarlane <jgm@berkeley@edu>
Stability   : alpha
Portability : portable
Tools for working with CSS.
-}
module Text.Pandoc.CSS
  ( cssAttributes
  , pickStyleAttrProps
  , pickStylesToKVs
  )
where
import Data.Either (fromRight)
```
