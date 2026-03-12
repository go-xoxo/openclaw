---
title: "jgm/pandoc :: src/Text/Pandoc/Writers/Powerpoint/Presentation.hs"
repo: "jgm/pandoc"
path: "src/Text/Pandoc/Writers/Powerpoint/Presentation.hs"
project: "Hasel 2.0"
x: 42550
y: 50341
z: "42550 + 50341i"
x_prime: false
y_prime: true
both_prime: false
source: "https://github.com/jgm/pandoc/blob/main/src/Text/Pandoc/Writers/Powerpoint/Presentation.hs"
---

# jgm/pandoc :: src/Text/Pandoc/Writers/Powerpoint/Presentation.hs


```hs
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE LambdaCase                 #-}
{-# LANGUAGE MultiWayIf                 #-}
{-# LANGUAGE OverloadedStrings          #-}
{-# LANGUAGE PatternGuards              #-}
{-# LANGUAGE ViewPatterns               #-}
{- |
   Module      : Text.Pandoc.Writers.Powerpoint.Presentation
   Copyright   : Copyright (C) 2017-2020 Jesse Rosenthal
   License     : GNU GPL, version 2 or above
   Maintainer  : Jesse Rosenthal <jrosenthal@jhu.edu>
   Stability   : alpha
   Portability : portable
Definition of Presentation datatype, modeling a MS Powerpoint (pptx)
document, and functions for converting a Pandoc document to
Presentation.
-}
module Text.Pandoc.Writers.Powerpoint.Presentation ( documentToPresentation
```
