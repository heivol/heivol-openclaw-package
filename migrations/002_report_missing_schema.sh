#!/usr/bin/env bash
# Migration 002 — applies on 0.1.x → 0.2.0
#
# Informational only. Counts notes that do not declare a `schema:` or `type:`
# frontmatter field. Does NOT modify any files — schema defaults never
# invent missing metadata on content the tenant wrote themselves.

set -euo pipefail

FROM="${OPENCLAW_FROM:-0.0.0}"
TO="${OPENCLAW_TO:-0.0.0}"
case "$TO" in
  0.2.*|0.3.*|1.*) ;;
  *) exit 0 ;;
esac
case "$FROM" in
  0.1.*) ;;
  *) exit 0 ;;
esac

VAULT="${OPENCLAW_VAULT:-$HOME/vault}"
[ -d "$VAULT" ] || exit 0

python3 - <<'PY'
import os
from pathlib import Path

VAULT = Path(os.environ.get("OPENCLAW_VAULT", Path.home() / "vault")).expanduser()

total = 0
missing_schema = 0
missing_type = 0
for root, dirs, files in os.walk(VAULT):
    if ".git" in root or ".obsidian" in root:
        continue
    for name in files:
        if not name.endswith(".md"):
            continue
        total += 1
        p = Path(root) / name
        try:
            head = p.read_text(encoding="utf-8", errors="ignore")[:800]
        except OSError:
            continue
        if not head.startswith("---\n"):
            missing_schema += 1
            missing_type += 1
            continue
        fm_end = head.find("\n---", 4)
        fm = head[4:fm_end] if fm_end != -1 else ""
        if "schema:" not in fm:
            missing_schema += 1
        if "type:" not in fm:
            missing_type += 1

print(f"[002] vault has {total} markdown file(s)")
print(f"[002]   missing `schema:` frontmatter: {missing_schema}")
print(f"[002]   missing `type:` frontmatter:   {missing_type}")
if missing_schema or missing_type:
    print("[002] no files modified. New writes will include the fields; back-filling is optional.")
PY
