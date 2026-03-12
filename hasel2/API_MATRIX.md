# GitHub API Matrix

Local scope: `openclaw` / `hasel2`
Transport: `gh api`
Auth: existing `gh` login
Status: local only, no publish step

## Hard constraint

`git -C C:\Users\frits\.codex\memories\openclaw rev-parse --show-toplevel` resolves to `C:/Users/frits`.
That means `openclaw` is inside a much larger Git working tree.
A blind `git push` or `git pull` here would act on the home-repo scale, not just `openclaw`.

## REST v3 via `gh api`

- repo metadata: `repos/{owner}/{repo}`
- contents: `repos/{owner}/{repo}/contents/{path}`
- git trees: `repos/{owner}/{repo}/git/trees/{sha}?recursive=1`
- blobs: `repos/{owner}/{repo}/git/blobs/{sha}`
- commits: `repos/{owner}/{repo}/commits`
- branches: `repos/{owner}/{repo}/branches`
- releases: `repos/{owner}/{repo}/releases`
- issues: `repos/{owner}/{repo}/issues`
- pull requests: `repos/{owner}/{repo}/pulls`
- actions runs: `repos/{owner}/{repo}/actions/runs`
- workflows: `repos/{owner}/{repo}/actions/workflows`
- code search: `search/code?q=...`
- repo search: `search/repositories?q=...`
- users/orgs: `users/{user}`, `orgs/{org}`
- gists: `gists`, `gists/{gist_id}`

## GraphQL v4 via `gh api graphql`

Useful for:
- batched repository metadata
- pagination over viewer repositories
- releases / discussions / PR summaries
- shape-controlled responses

## CLI features around the API

- pagination: `--paginate`
- JSON query: `--jq`
- Go templates: `--template`
- request body: `--input file.json`
- typed fields: `-F key=value`
- raw fields: `-f key=value`
- caching: `--cache 1h`
- previews: `--preview name`
- verbose transport: `--verbose`

## Gist path

- create: `gh gist create file.md`
- secret gist: `gh gist create --private file.md`
- raw REST: `gh api gists -F 'files[name.md][content]=@file.md'`

## Safe local uses already demonstrated here

- GitHub repo search for Haskell repositories
- code search for small Haskell files
- tree walk on large Haskell repos
- contents fetch to local `artifacts/downloads`
- local gist-like markdown cards under `artifacts/gists`

## Recommended next steps

1. Keep all GitHub traffic read-only until `openclaw` has its own repo root.
2. Use repo-tree traversal instead of heavy `search/code` when scraping big Haskell repos.
3. Run publish checks against `openclaw/public` before any real upload.
