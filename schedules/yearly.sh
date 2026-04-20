#!/usr/bin/env bash
# Yearly job — NOT registered in cron by default.
#
# Enable manually once per tenant:
#   5 4 1 1 * $OPENCLAW_ROOT/runtime/schedules/yearly.sh >> ...
#
# 1. vault-rollup --year                (previous calendar year)
# 2. Diary archival — gated by retention.diary_archive in config.yaml.
#    When true: concatenate diary/YYYY-*.md into diary/archive/YYYY.md
#    and delete the original per-day files.

set -uo pipefail

ROOT="${OPENCLAW_ROOT:-$HOME/.openclaw}"
VAULT="${OPENCLAW_VAULT:-$HOME/vault}"
BIN="$ROOT/runtime/bin"

log() { printf '\033[1;34m[yearly]\033[0m %s\n' "$*"; }
run() { log "→ $*"; "$@" || log "  (exit $? — continuing)"; }

log "start"

[ -x "$BIN/vault-rollup" ] && run "$BIN/vault-rollup" --year

python3 - <<'PY'
import datetime as dt
import os
from pathlib import Path

try:
    import yaml
except ImportError:
    yaml = None

VAULT = Path(os.environ.get("OPENCLAW_VAULT", Path.home() / "vault")).expanduser()
ROOT = Path(os.environ.get("OPENCLAW_ROOT", Path.home() / ".openclaw")).expanduser()
CFG = ROOT / "user" / "config.yaml"

archive_enabled = False
if yaml and CFG.exists():
    try:
        data = yaml.safe_load(CFG.read_text()) or {}
        archive_enabled = bool((data.get("retention") or {}).get("diary_archive", False))
    except Exception:
        pass

if not archive_enabled:
    print("diary archival disabled (retention.diary_archive=false) — skipping")
    raise SystemExit(0)

year = dt.date.today().year - 1
diary = VAULT / "diary"
archive_dir = diary / "archive"
archive_dir.mkdir(parents=True, exist_ok=True)
archive_file = archive_dir / f"{year}.md"

sources = sorted(p for p in diary.glob(f"{year}-*.md") if p.is_file())
if not sources:
    print(f"no diary files for {year}")
    raise SystemExit(0)

parts = [f"# Diary Archive — {year}\n"]
for p in sources:
    parts.append(f"\n## {p.stem}\n")
    parts.append(p.read_text(encoding="utf-8", errors="ignore"))
archive_file.write_text("\n".join(parts), encoding="utf-8")

for p in sources:
    p.unlink()
print(f"archived {len(sources)} diary file(s) → {archive_file.relative_to(VAULT)}")
PY

log "done"
