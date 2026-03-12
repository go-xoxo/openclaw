# jgm/pandoc :: src/Text/Pandoc/Readers/Docx/Util.hs

- x: `42550`
- y: `1924`
- z: `42550 + 1924i`
- x prime: `false`
- y prime: `false`
- both prime: `false`
- source: https://github.com/jgm/pandoc/blob/d39ca219e7b8de7fee88dd46a6335c17419fecc1/src/Text/Pandoc/Readers/Docx/Util.hs

```hs
{-# LANGUAGE OverloadedStrings #-}
{- |
   Module      : Text.Pandoc.Readers.Docx.Util
   Copyright   : © 2014-2020 Jesse Rosenthal <jrosenthal@jhu.edu>,
                   2014-2024 John MacFarlane <jgm@berkeley.edu>,
                   2015 Nikolay Yakimov <root@livid.pp.ru>
   License     : GNU GPL, version 2 or above
   Maintainer  : Jesse Rosenthal <jrosenthal@jhu.edu>
   Stability   : alpha
   Portability : portable
Docx reader utility functions.
-}
module Text.Pandoc.Readers.Docx.Util (
                                        NameSpaces
                                      , elemName
                                      , isElem
                                      , elemToNameSpaces
                                      , findChildByName
```
