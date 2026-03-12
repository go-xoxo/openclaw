[Console]::InputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$OutputEncoding = [System.Text.UTF8Encoding]::new()
$env:HASEL_INPUT = "Hasel λ🐿 2.0"

Write-Host "== haskell =="
runghc .\haskell\Main.hs
Write-Host ""
Write-Host "== typescript =="
bun run .\typescript\main.ts
Write-Host ""
Write-Host "== python =="
python .\python\main.py
Write-Host ""
Write-Host "== rust =="
cargo run --quiet --manifest-path .\rust\Cargo.toml
Write-Host ""
Write-Host "== go =="
go run .\go\main.go
