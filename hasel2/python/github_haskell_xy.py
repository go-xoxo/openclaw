from __future__ import annotations

import argparse
import base64
import html
import json
import math
import subprocess
import sys
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterable
from urllib.parse import quote, urlencode


@dataclass
class Repo:
    full_name: str
    stars: int
    default_branch: str
    html_url: str


@dataclass
class Sample:
    x: int
    y: int
    repo: str
    path: str
    ext: str
    sha: str
    html_url: str
    download_path: str
    preview: str
    x_prime: bool
    y_prime: bool
    both_prime: bool
    z: str
    gist_path: str = ""


def gh_json(endpoint: str) -> object:
    completed = subprocess.run(
        ["gh", "api", endpoint],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
    )
    if completed.returncode != 0:
        message = completed.stderr.strip() or completed.stdout.strip() or "gh api failed"
        raise RuntimeError(f"{endpoint}: {message}")
    return json.loads(completed.stdout)


def query_endpoint(base: str, params: dict[str, object]) -> str:
    return f"{base}?{urlencode(params)}"


def is_prime(value: int) -> bool:
    if value < 2:
        return False
    if value in (2, 3):
        return True
    if value % 2 == 0 or value % 3 == 0:
        return False
    limit = math.isqrt(value)
    factor = 5
    while factor <= limit:
        if value % factor == 0 or value % (factor + 2) == 0:
            return False
        factor += 6
    return True


def search_repositories(query: str, limit: int) -> list[Repo]:
    payload = gh_json(
        query_endpoint(
            "search/repositories",
            {
                "q": query,
                "sort": "stars",
                "order": "desc",
                "per_page": max(1, min(limit, 100)),
            },
        )
    )
    items = payload.get("items", [])
    return [
        Repo(
            full_name=item["full_name"],
            stars=int(item["stargazers_count"]),
            default_branch=item.get("default_branch", "HEAD"),
            html_url=item["html_url"],
        )
        for item in items
    ]


def normalize_extensions(raw: str) -> list[str]:
    return [segment.strip().lstrip(".").lower() for segment in raw.split(",") if segment.strip()]


def extension_for_path(path: str) -> str:
    name = Path(path).name.lower()
    if name.endswith(".cabal"):
        return "cabal"
    if name.endswith(".package.yaml"):
        return "package.yaml"
    suffix = Path(path).suffix.lower().lstrip(".")
    return suffix


def matches_extension(path: str, allowed: set[str]) -> bool:
    ext = extension_for_path(path)
    return ext in allowed


def search_code(repo: Repo, ext: str, min_bytes: int, max_bytes: int, per_page: int, extra_query: str) -> list[dict[str, object]]:
    terms = [f"repo:{repo.full_name}", f"extension:{ext}", f"size:<{max_bytes}"]
    if min_bytes > 0:
        terms.append(f"size:>{min_bytes}")
    if extra_query:
        terms.append(extra_query)
    payload = gh_json(
        query_endpoint(
            "search/code",
            {
                "q": " ".join(terms),
                "per_page": max(1, min(per_page, 100)),
            },
        )
    )
    return payload.get("items", [])


def list_tree_matches(repo: Repo, extensions: set[str], min_bytes: int, max_bytes: int, per_repo: int) -> list[dict[str, object]]:
    payload = gh_json(f"repos/{repo.full_name}/git/trees/{quote(repo.default_branch, safe='')}?recursive=1")
    if not isinstance(payload, dict):
        raise RuntimeError(f"unexpected tree payload for {repo.full_name}")
    candidates: list[dict[str, object]] = []
    for item in payload.get("tree", []):
        if item.get("type") != "blob":
            continue
        path = item.get("path")
        size = item.get("size")
        sha = item.get("sha")
        if not isinstance(path, str) or not isinstance(size, int) or not isinstance(sha, str):
            continue
        if size > max_bytes or size < min_bytes:
            continue
        if not matches_extension(path, extensions):
            continue
        candidates.append(
            {
                "path": path,
                "sha": sha,
                "size": size,
                "html_url": f"https://github.com/{repo.full_name}/blob/{repo.default_branch}/{path}",
            }
        )
    candidates.sort(key=lambda item: int(item["size"]), reverse=True)
    return candidates[:per_repo]


def fetch_contents(repo_full_name: str, path: str) -> dict[str, object]:
    encoded_path = quote(path, safe="/")
    payload = gh_json(f"repos/{repo_full_name}/contents/{encoded_path}")
    if not isinstance(payload, dict):
        raise RuntimeError(f"unexpected contents payload for {repo_full_name}:{path}")
    return payload


def decode_content(payload: dict[str, object]) -> bytes:
    content = payload.get("content", "")
    encoding = payload.get("encoding")
    if isinstance(content, str) and encoding == "base64":
        return base64.b64decode(content)
    return b""


def text_preview(content_bytes: bytes, limit: int = 18) -> str:
    if not content_bytes:
        return ""
    text = content_bytes.decode("utf-8", errors="replace")
    lines = [line.rstrip("\n") for line in text.splitlines() if line.strip()]
    return "\n".join(lines[:limit])


def slugify(value: str) -> str:
    safe = []
    for char in value:
        if char.isalnum() or char in ("-", "_", "."):
            safe.append(char)
        else:
            safe.append("_")
    return "".join(safe)


def write_xy(samples: Iterable[Sample], destination: Path) -> None:
    lines = ["x\ty"]
    lines.extend(f"{sample.x}\t{sample.y}" for sample in samples)
    destination.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_complex(samples: Iterable[Sample], destination: Path) -> None:
    lines = ["z\tx\ty"]
    lines.extend(f"{sample.z}\t{sample.x}\t{sample.y}" for sample in samples)
    destination.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_manifest(samples: Iterable[Sample], destination: Path) -> None:
    payload = [asdict(sample) for sample in samples]
    destination.write_text(json.dumps(payload, indent=2), encoding="utf-8")


def write_markdown(samples: Iterable[Sample], destination: Path, query: str, max_bytes: int, scan_mode: str) -> None:
    lines = [
        "# GitHub Haskell XY",
        "",
        f"- query: `{query}`",
        f"- scan mode: `{scan_mode}`",
        f"- y-axis: file size in bytes, hard-capped at `{max_bytes}`",
        "- x-axis: repository stars",
        "- complex form: `z = x + yi`",
        "",
        "| x | y | x prime | y prime | repo | path | link | gist |",
        "|---:|---:|:---:|:---:|---|---|---|---|",
    ]
    for sample in samples:
        gist_link = f"[local]({Path(sample.gist_path).name})" if sample.gist_path else ""
        lines.append(
            f"| {sample.x} | {sample.y} | {'yes' if sample.x_prime else 'no'} | {'yes' if sample.y_prime else 'no'} | `{sample.repo}` | `{sample.path}` | [view]({sample.html_url}) | {gist_link} |"
        )
    destination.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_gists(samples: list[Sample], gist_root: Path) -> None:
    gist_root.mkdir(parents=True, exist_ok=True)
    index_lines = [
        "# Local Gists",
        "",
        "Generated from live GitHub API samples. These are local markdown cards, not published gists.",
        "",
    ]
    for index, sample in enumerate(samples, start=1):
        name = f"{index:02d}_{slugify(sample.repo)}__{slugify(sample.path)}.md"
        destination = gist_root / name
        preview_block = sample.preview or "(no local preview downloaded)"
        body = [
            "---",
            f"title: \"{sample.repo} :: {sample.path}\"",
            f"repo: \"{sample.repo}\"",
            f"path: \"{sample.path}\"",
            "project: \"Hasel 2.0\"",
            f"x: {sample.x}",
            f"y: {sample.y}",
            f"z: \"{sample.z}\"",
            f"x_prime: {'true' if sample.x_prime else 'false'}",
            f"y_prime: {'true' if sample.y_prime else 'false'}",
            f"both_prime: {'true' if sample.both_prime else 'false'}",
            f"source: \"{sample.html_url}\"",
            "---",
            "",
            f"# {sample.repo} :: {sample.path}",
            "",
        ]
        if sample.download_path:
            body.append(f"- local copy: `{sample.download_path}`")
        body.extend([
            "",
            "```hs",
            preview_block,
            "```",
            "",
        ])
        destination.write_text("\n".join(body), encoding="utf-8")
        sample.gist_path = str(destination)
        index_lines.append(f"- [{sample.repo} :: {sample.path}]({name})")
    (gist_root / "index.md").write_text("\n".join(index_lines) + "\n", encoding="utf-8")


def write_blink_html(samples: list[Sample], destination: Path, query: str) -> None:
    if not samples:
        destination.write_text("<html><body><p>no samples</p></body></html>\n", encoding="utf-8")
        return
    max_x = max(sample.x for sample in samples)
    max_y = max(sample.y for sample in samples)
    points = []
    for sample in samples:
        left = 4 + round((sample.x / max_x) * 92, 2)
        bottom = 4 + round((sample.y / max_y) * 88, 2)
        prime_class = "prime" if sample.both_prime else "mixed"
        title = html.escape(f"{sample.repo} :: {sample.path} :: ({sample.x}, {sample.y})")
        label = html.escape(f"{sample.x}+{sample.y}i")
        points.append(
            f'<a class="point {prime_class}" style="left:{left}%;bottom:{bottom}%;" href="{html.escape(sample.html_url)}" title="{title}"><span>{label}</span></a>'
        )
    doc = f"""<!doctype html>
<html lang=\"en\">
<head>
<meta charset=\"utf-8\">
<title>GitHub Haskell XY Blink</title>
<style>
:root {{
  --bg: #0d1117;
  --grid: #213042;
  --ink: #d8f3dc;
  --prime: #80ed99;
  --mixed: #ffd166;
  --axis: #8ecae6;
}}
body {{
  margin: 0;
  min-height: 100vh;
  background:
    radial-gradient(circle at top, rgba(128, 237, 153, 0.15), transparent 40%),
    linear-gradient(180deg, #071018 0%, var(--bg) 100%);
  color: var(--ink);
  font-family: Consolas, \"Courier New\", monospace;
}}
main {{
  max-width: 1200px;
  margin: 0 auto;
  padding: 24px;
}}
.plot {{
  position: relative;
  height: 72vh;
  border: 1px solid var(--grid);
  background-image:
    linear-gradient(var(--grid) 1px, transparent 1px),
    linear-gradient(90deg, var(--grid) 1px, transparent 1px);
  background-size: 10% 10%;
  overflow: hidden;
}}
.axis {{
  position: absolute;
  color: var(--axis);
  font-size: 14px;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}}
.axis.x {{ bottom: 8px; right: 12px; }}
.axis.y {{ top: 12px; left: 12px; }}
.point {{
  position: absolute;
  width: 14px;
  height: 14px;
  border-radius: 999px;
  transform: translate(-50%, 50%);
  animation: blink 1.1s steps(2, start) infinite;
  box-shadow: 0 0 18px currentColor;
}}
.point span {{
  position: absolute;
  top: -22px;
  left: 12px;
  white-space: nowrap;
  font-size: 11px;
  color: var(--ink);
}}
.point.prime {{ color: var(--prime); background: var(--prime); }}
.point.mixed {{ color: var(--mixed); background: var(--mixed); }}
@keyframes blink {{
  50% {{ opacity: 0.18; transform: translate(-50%, 50%) scale(0.7); }}
}}
</style>
</head>
<body>
<main>
<h1>GitHub Haskell XY Blink</h1>
<p>query: <code>{html.escape(query)}</code></p>
<p>x = repo stars, y = file bytes, green = both prime, yellow = mixed.</p>
<div class=\"plot\">
<div class=\"axis y\">y bytes</div>
<div class=\"axis x\">x stars</div>
{''.join(points)}
</div>
</main>
</body>
</html>
"""
    destination.write_text(doc, encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Sample Haskell-adjacent files from GitHub and project them into x/y coordinates."
    )
    parser.add_argument("--repo-query", default="language:Haskell stars:>500")
    parser.add_argument("--extra-code-query", default="")
    parser.add_argument("--repo-limit", type=int, default=5)
    parser.add_argument("--file-limit", type=int, default=16)
    parser.add_argument("--per-query", type=int, default=12)
    parser.add_argument("--max-bytes", type=int, default=4096)
    parser.add_argument("--min-bytes", type=int, default=0)
    parser.add_argument("--download-limit", type=int, default=8)
    parser.add_argument("--extensions", default="hs,lhs,hsc,cabal")
    parser.add_argument("--scan-mode", choices=("search", "tree"), default="search")
    parser.add_argument("--output-dir", default=str(Path(__file__).resolve().parents[1] / "artifacts"))
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    download_root = output_dir / "downloads"
    download_root.mkdir(parents=True, exist_ok=True)
    gist_root = output_dir / "gists"

    repos = search_repositories(args.repo_query, args.repo_limit)
    extensions = normalize_extensions(args.extensions)
    extension_set = set(extensions)
    seen: set[tuple[str, str]] = set()
    samples: list[Sample] = []
    downloads = 0

    for repo in repos:
        if len(samples) >= args.file_limit:
            break
        try:
            if args.scan_mode == "tree":
                matches = list_tree_matches(repo, extension_set, args.min_bytes, args.max_bytes, args.per_query)
            else:
                matches = []
                for ext in extensions:
                    matches.extend(search_code(repo, ext, args.min_bytes, args.max_bytes, args.per_query, args.extra_code_query))
        except RuntimeError as error:
            print(f"skip repo {repo.full_name}: {error}", file=sys.stderr)
            continue
        if args.scan_mode == "search":
            matches.sort(key=lambda item: int(item.get("size", 0)), reverse=True)
        for item in matches:
            path = item.get("path")
            sha = item.get("sha")
            if not isinstance(path, str) or not isinstance(sha, str):
                continue
            key = (repo.full_name, path)
            if key in seen:
                continue
            seen.add(key)
            try:
                payload = fetch_contents(repo.full_name, path)
            except RuntimeError as error:
                print(f"skip contents {repo.full_name}:{path}: {error}", file=sys.stderr)
                continue
            size = payload.get("size")
            if not isinstance(size, int) or size > args.max_bytes or size < args.min_bytes:
                continue
            content_bytes = decode_content(payload)
            preview = text_preview(content_bytes)
            download_path = ""
            if downloads < args.download_limit and content_bytes:
                destination = download_root / repo.full_name / path
                destination.parent.mkdir(parents=True, exist_ok=True)
                destination.write_bytes(content_bytes)
                download_path = str(destination)
                downloads += 1
            x_prime = is_prime(repo.stars)
            y_prime = is_prime(size)
            samples.append(
                Sample(
                    x=repo.stars,
                    y=size,
                    repo=repo.full_name,
                    path=path,
                    ext=extension_for_path(path),
                    sha=sha,
                    html_url=item.get("html_url", f"https://github.com/{repo.full_name}/blob/{repo.default_branch}/{path}"),
                    download_path=download_path,
                    preview=preview,
                    x_prime=x_prime,
                    y_prime=y_prime,
                    both_prime=x_prime and y_prime,
                    z=f"{repo.stars} + {size}i",
                )
            )
            if len(samples) >= args.file_limit:
                break

    write_gists(samples, gist_root)

    xy_path = output_dir / "github_haskell_xy.tsv"
    complex_path = output_dir / "github_haskell_complex.tsv"
    json_path = output_dir / "github_haskell_samples.json"
    md_path = output_dir / "github_haskell_samples.md"
    html_path = output_dir / "github_haskell_blink.html"

    write_xy(samples, xy_path)
    write_complex(samples, complex_path)
    write_manifest(samples, json_path)
    write_markdown(samples, md_path, args.repo_query, args.max_bytes, args.scan_mode)
    write_blink_html(samples, html_path, args.repo_query)

    print(f"samples\t{len(samples)}")
    print(f"xy\t{xy_path}")
    print(f"complex\t{complex_path}")
    print(f"json\t{json_path}")
    print(f"markdown\t{md_path}")
    print(f"html\t{html_path}")
    print(f"gists\t{gist_root}")
    for sample in samples:
        print(f"{sample.x}\t{sample.y}\t{'P' if sample.x_prime else '-'}\t{'P' if sample.y_prime else '-'}")
    return 0 if samples else 1


if __name__ == "__main__":
    raise SystemExit(main())
