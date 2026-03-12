# jgm/pandoc :: src/Text/Pandoc/Readers/Typst/Parsing.hs

- x: `42550`
- y: `1973`
- z: `42550 + 1973i`
- x prime: `false`
- y prime: `true`
- both prime: `false`
- source: https://github.com/jgm/pandoc/blob/d39ca219e7b8de7fee88dd46a6335c17419fecc1/src/Text/Pandoc/Readers/Typst/Parsing.hs

```hs
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedLists #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
module Text.Pandoc.Readers.Typst.Parsing
  ( P,
    PState(..),
    defaultPState,
    pTok,
    pWithContents,
    ignored,
    getField,
    chunks,
  )
where
import Control.Monad (MonadPlus)
import Control.Monad.Reader (lift)
import qualified Data.Foldable as F
```
