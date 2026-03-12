---
title: "jgm/pandoc :: src/Text/Pandoc/Readers/LaTeX.hs"
repo: "jgm/pandoc"
path: "src/Text/Pandoc/Readers/LaTeX.hs"
project: "Hasel 2.0"
x: 42550
y: 53237
z: "42550 + 53237i"
x_prime: false
y_prime: false
both_prime: false
source: "https://github.com/jgm/pandoc/blob/main/src/Text/Pandoc/Readers/LaTeX.hs"
---

# jgm/pandoc :: src/Text/Pandoc/Readers/LaTeX.hs

- local copy: `C:\Users\frits\.codex\memories\openclaw\hasel2\artifacts\downloads\jgm\pandoc\src\Text\Pandoc\Readers\LaTeX.hs`

```hs
{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE PatternGuards         #-}
{-# LANGUAGE ScopedTypeVariables   #-}
{-# LANGUAGE ViewPatterns          #-}
{- |
   Module      : Text.Pandoc.Readers.LaTeX
   Copyright   : Copyright (C) 2006-2024 John MacFarlane
   License     : GNU GPL, version 2 or above
   Maintainer  : John MacFarlane <jgm@berkeley.edu>
   Stability   : alpha
   Portability : portable
Conversion of LaTeX to 'Pandoc' document.
-}
module Text.Pandoc.Readers.LaTeX ( readLaTeX,
                                   applyMacros,
                                   rawLaTeXInline,
                                   rawLaTeXBlock,
                                   inlineCommand
```
