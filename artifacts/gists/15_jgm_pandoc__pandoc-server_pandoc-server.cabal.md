# jgm/pandoc :: pandoc-server/pandoc-server.cabal

- x: `42550`
- y: `2653`
- z: `42550 + 2653i`
- x prime: `false`
- y prime: `false`
- both prime: `false`
- source: https://github.com/jgm/pandoc/blob/d39ca219e7b8de7fee88dd46a6335c17419fecc1/pandoc-server/pandoc-server.cabal

```hs
cabal-version:   2.4
name:            pandoc-server
version:         0.1.2
build-type:      Simple
license:         GPL-2.0-or-later
license-file:    COPYING.md
copyright:       (c) 2006-2024 John MacFarlane
author:          John MacFarlane <jgm@berkeley.edu>
maintainer:      John MacFarlane <jgm@berkeley.edu>
bug-reports:     https://github.com/jgm/pandoc/issues
stability:       alpha
homepage:        https://pandoc.org
category:        Text
tested-with:     GHC == 8.6.5, GHC == 8.8.4, GHC == 8.10.7, GHC == 9.0.2,
                 GHC == 9.2.5, GHC == 9.4.4
synopsis:        Pandoc document conversion as an HTTP servant-server
description:     Pandoc-server provides pandoc's document conversion functions
                 in an HTTP server.
```
