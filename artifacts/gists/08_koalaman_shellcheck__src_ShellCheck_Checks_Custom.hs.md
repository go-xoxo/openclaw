# koalaman/shellcheck :: src/ShellCheck/Checks/Custom.hs

- x: `39092`
- y: `533`
- z: `39092 + 533i`
- x prime: `false`
- y prime: `false`
- both prime: `false`
- source: https://github.com/koalaman/shellcheck/blob/cd41f794383b6159757575c9debbf198426b21aa/src/ShellCheck/Checks/Custom.hs

```hs
{-
    This empty file is provided for ease of patching in site specific checks.
    However, there are no guarantees regarding compatibility between versions.
-}
{-# LANGUAGE TemplateHaskell #-}
module ShellCheck.Checks.Custom (checker, ShellCheck.Checks.Custom.runTests) where
import ShellCheck.AnalyzerLib
import Test.QuickCheck
checker :: Parameters -> Checker
checker params = Checker {
    perScript = const $ return (),
    perToken = const $ return ()
  }
prop_CustomTestsWork = True
return []
runTests = $quickCheckAll
```
