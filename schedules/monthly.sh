#!/usr/bin/env bash
# Monthly job — runs 1st of month 03:35 (registered by install.sh).
#
# 1. vault-rollup --month               (covers the previous calendar month)
# 2. vault-lint (loose thresholds)      stale prune pass, never deletes
# 3. Archive daily analyses older than retention.analysis_keep_days
# 4. Vault size report appended to the month rollup

set -uo pipefail

ROOT="${OPENCLAW_ROOT:-$HOME/.openclaw}"
VAULT="${OPENCLAW_VAULT:-$HOME/vault}"
BIN="$ROOT/runtime/bin"

log() { printf '\033[1;34m[monthly]\033[0m %s\n' "$*"; }
run() { log "→ $*"; "$@" || log "  (exit $? — continuing)"; }

log "start"

[ -x "$BIN/vault-rollup" ] && run "$BIN/vault-rollup" --month
[ -x "$BIN/vault-lint" ]   && run "$BIN/vault-lint" --stale-days 60 --report "$VAULT/meta/analysis/$(date +%Y-%m-%d)-lint-monthly.md"

python3 - <<'PY'
import datetime as dt
import os
import shutil
from pathlib import Path

try:
    import yaml
except ImportError:
    yaml = None

VAULT = Path(os.environ.get("OPENCLAW_VAULT", Path.home() / "vault")).expanduser()
ROOT = Path(os.environ.get("OPENCLAW_ROOT", Path.home() / ".openclaw")).expanduser()
CFG = ROOT / "user" / "config.yaml"

keep_days = 730
if yaml and CFG.exists():
    try:
        data = yaml.safe_load(CFG.read_text()) or {}
        keep_days = int((data.get("retention") or {}).get("analysis_keep_days", 730))
    except Exception:
        pass

analysis = VAULT / "meta" / "analysis"
archive = VAULT / "meta" / "analysis" / "archive"
if not analysis.exists():
    raise SystemExit(0)

cutoff = dt.date.today() - dt.timedelta(days=keep_days)
moved = 0
for f in list(analysis.glob("*.md")):
    try:
        day = dt.date.fromisoformat(f.stem[:10])
    except ValueError:
        continue
    if day < cutoff:
        year_dir = archive / str(day.year)
        year_dir.mkdir(parents=True, exist_ok=True)
        shutil.move(str(f), str(year_dir / f.name))
        moved += 1
print(f"archived {moved} analysis file(s)")
PY

# Vault size report appended to the month rollup
python3 - <<'PY'
import datetime as dt
import os
from pathlib import Path

VAULT = Path(os.environ.get("OPENCLAW_VAULT", Path.home() / "vault")).expanduser()
prev = (dt.date.today().replace(day=1) - dt.timedelta(days=1))
slug = f"{prev.year}-{prev.month:02d}"
rollup = VAULT / "meta" / "rollups" / f"{slug}.md"
if not rollup.exists():
    raise SystemExit(0)

total_files = 0
total_bytes = 0
by_dir: dict[str, int] = {}
for root, dirs, files in os.walk(VAULT):
    if ".git" in root or ".obsidian" in root:
        continue
    for name in files:
        if not name.endswith(".md"):
            continue
        p = Path(root) / name
        try:
            sz = p.stat().st_size
        except OSError:
            continue
        total_files += 1
        total_bytes += sz
        rel = p.relative_to(VAULT)
        top = rel.parts[0] if rel.parts else "."
        by_dir[top] = by_dir.get(top, 0) + 1

with rollup.open("a", encoding="utf-8") as f:
    f.write("\n## Vault size\n\n")
    f.write(f"- Total markdown files: **{total_files}**\n")
    f.write(f"- Total size: **{total_bytes / 1024:.1f} KB**\n")
    f.write("\n### By top-level directory\n\n")
    for d, n in sorted(by_dir.items(), key=lambda x: -x[1]):
        f.write(f"- `{d}/` — {n}\n")
print(f"appended vault-size to {rollup.name}")
PY

log "done"
