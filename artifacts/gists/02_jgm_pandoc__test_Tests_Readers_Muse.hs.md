---
title: "jgm/pandoc :: test/Tests/Readers/Muse.hs"
repo: "jgm/pandoc"
path: "test/Tests/Readers/Muse.hs"
project: "Hasel 2.0"
x: 42550
y: 59162
z: "42550 + 59162i"
x_prime: false
y_prime: false
both_prime: false
source: "https://github.com/jgm/pandoc/blob/main/test/Tests/Readers/Muse.hs"
---

# jgm/pandoc :: test/Tests/Readers/Muse.hs

- local copy: `C:\Users\frits\.codex\memories\openclaw\hasel2\artifacts\downloads\jgm\pandoc\test\Tests\Readers\Muse.hs`

```hs
{-# LANGUAGE OverloadedStrings #-}
{- |
   Module      : Tests.Readers.Muse
   Copyright   : © 2017-2020 Alexander Krotov
   License     : GNU GPL, version 2 or above
   Maintainer  : Alexander Krotov <ilabdsf@gmail.com>
   Stability   : alpha
   Portability : portable
Tests for the Muse reader.
-}
module Tests.Readers.Muse (tests) where
import Data.List (intersperse)
import Data.Text (Text)
import qualified Data.Text as T
import Test.Tasty
import Test.Tasty.HUnit (HasCallStack)
import Tests.Helpers
import Text.Pandoc
```
