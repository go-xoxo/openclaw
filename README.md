# openclaw/public

This is the public-style export of the local `openclaw` workspace.
It is assembled for sharing, reading and cloning, but it is still local on disk.
Nothing was pushed to a public remote by this step.

## Included

- `core/`: main Haskell tools and build files
- `hasel2/`: the polyglot adapter pack
- `artifacts/`: GitHub-derived Haskell samples, x/y tables, local gists and downloads
- `xoxo-go/`: the `xoxo-go/daswerk` text layer
- `MANIFEST.tsv`: file inventory plus binary references

## Main entry points

- `hasel2/README.md`
- `hasel2/ADAPTERS.yaml`
- `hasel2/BIO.md`
- `hasel2/EICHHOERNCHEN-OS.yaml`
- `xoxo-go/daswerk.md`
- `artifacts/github_haskell_samples.md`
- `artifacts/gists/index.md`
- `artifacts/github_haskell_blink.html`

## Notes

- UTF-8, emoji, Hasel, Haskell, GHC and Codex naming are preserved.
- Large executables are listed in `MANIFEST.tsv` as references instead of being duplicated.
- This export is prepared "for all", but publication is still a separate action.
