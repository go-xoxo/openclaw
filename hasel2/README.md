# xoxo-go/daswerk

`xoxo-go/daswerk` is the local name of this polyglot adapter pack.
`Hasel 2.0` remains the engine underneath.

The stack stays small and direct:

- UTF-8 and emoji aware text handling
- Haskell and GHC first
- local corpus sampling from GitHub
- Codex-built adapters across languages
- blink, x/y, z = x + yi, gists, manifests

## Example

Input:

```text
Hasel λ🐿 2.0
```

Output shape:

```text
input	Hasel λ🐿 2.0
everything	*Hasel λ🐿 2.0*
regex	.*Hasel λ🐿 2\.0.*
ascii_printable	Hasel ?? 2.0
contains_non_ascii	true
tokens	hasel,λ🐿,2.0
codepoints	U+0048,U+0061,U+0073,U+0065,U+006C,U+0020,U+03BB,U+1F43F,U+0020,U+0032,U+002E,U+0030
```

## Run

```powershell
runghc .\haskell\Main.hs "Hasel λ🐿 2.0"
bun run .\typescript\main.ts "Hasel λ🐿 2.0"
python .\python\main.py "Hasel λ🐿 2.0"
cargo run --quiet --manifest-path .\rust\Cargo.toml -- "Hasel λ🐿 2.0"
go run .\go\main.go "Hasel λ🐿 2.0"
```

## PureScript

A PureScript scaffold is included under `purescript/`, but it is not verified here because `purs` is not currently available on PATH.
