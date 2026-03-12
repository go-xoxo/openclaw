---
title: "jgm/pandoc :: src/Text/Pandoc/Readers/Docx/Parse.hs"
repo: "jgm/pandoc"
path: "src/Text/Pandoc/Readers/Docx/Parse.hs"
project: "Hasel 2.0"
x: 42550
y: 58582
z: "42550 + 58582i"
x_prime: false
y_prime: false
both_prime: false
source: "https://github.com/jgm/pandoc/blob/main/src/Text/Pandoc/Readers/Docx/Parse.hs"
---

# jgm/pandoc :: src/Text/Pandoc/Readers/Docx/Parse.hs

- local copy: `C:\Users\frits\.codex\memories\openclaw\hasel2\artifacts\downloads\jgm\pandoc\src\Text\Pandoc\Readers\Docx\Parse.hs`

```hs
{-# LANGUAGE TupleSections     #-}
{-# LANGUAGE LambdaCase        #-}
{-# LANGUAGE OverloadedStrings #-}
{- |
 Module : Text.Pandoc.Readers.Docx.Parse
 Copyright : Copyright (C) 2014-2020 Jesse Rosenthal
                           2019 Nikolay Yakimov <root@livid.pp.ru>
 License : GNU GPL, version 2 or above
 Maintainer : Jesse Rosenthal <jrosenthal@jhu.edu>
 Stability : alpha
 Portability : portable
Conversion of docx archive into Docx haskell type
-}
module Text.Pandoc.Readers.Docx.Parse ( Docx(..)
                                      , Document(..)
                                      , Body(..)
                                      , BodyPart(..)
                                      , TblLook(..)
```
