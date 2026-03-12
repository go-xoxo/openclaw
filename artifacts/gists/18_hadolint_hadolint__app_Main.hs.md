# hadolint/hadolint :: app/Main.hs

- x: `11994`
- y: `2774`
- z: `11994 + 2774i`
- x prime: `false`
- y prime: `false`
- both prime: `false`
- source: https://github.com/hadolint/hadolint/blob/0d4f787e3f8211457c4423febc24680a313c43d0/app/Main.hs

```hs
module Main where
import Control.Monad (when)
import Data.Default
import Hadolint (OutputFormat (..), printResults, DLSeverity (..))
import Hadolint.Config
import Prettyprinter
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Sequence as Seq
import qualified Hadolint
import qualified Hadolint.Rule as Rule
import Options.Applicative
  ( execParser,
    fullDesc,
    header,
    helper,
    info,
    progDesc
  )
```
