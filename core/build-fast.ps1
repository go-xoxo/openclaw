$ErrorActionPreference = 'Stop'
$arguments = @(
  '-fforce-recomp'
  '-O0'
  '-threaded'
  '-package'; 'bytestring'
  '-package'; 'containers'
  '-package'; 'directory'
  '-package'; 'filepath'
  '-package'; 'text'
  'spider_dedupe.hs'
  '-o'; 'spider_dedupe-fast.exe'
)
$elapsed = Measure-Command { & ghc @arguments }
"fast-build-seconds`t{0:N2}" -f $elapsed.TotalSeconds
