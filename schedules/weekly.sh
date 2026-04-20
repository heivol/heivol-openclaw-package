#!/usr/bin/env bash
# Weekly job — runs Sunday 22:00 (registered by install.sh).
#
# 1. vault-rollup --week          weekly narrative + aggregate
# 2. Retention: compact raw signal JSONLs older than N days into
#    meta/signals-compact/<iso-week>.jsonl, then delete the raw ones.
# 3. Flag open proposals older than 14 days in the rollup.

set -uo pipefail

ROOT="${OPENCLAW_ROOT:-$HOME/.openclaw}"
VAULT="${OPENCLAW_VAULT:-$HOME/vault}"
BIN="$ROOT/runtime/bin"

log() { printf '\033[1;34m[weekly]\033[0m %s\n' "$*"; }
run() { log "→ $*"; "$@" || log "  (exit $? — continuing)"; }

log "start"

[ -x "$BIN/vault-rollup" ] && run "$BIN/vault-rollup" --week

# Retention: compact raw signals older than retention.signals_raw_days (default 30)
python3 - <<'PY'
import datetime as dt
import json
import os
import re
from collections import defaultdict
from pathlib import Path

try:
    import yaml
except ImportError:
    yaml = None

VAULT = Path(os.environ.get("OPENCLAW_VAULT", Path.home() / "vault")).expanduser()
ROOT = Path(os.environ.get("OPENCLAW_ROOT", Path.home() / ".openclaw")).expanduser()
CFG = ROOT / "user" / "config.yaml"

retain_days = 30
if yaml and CFG.exists():
    try:
        data = yaml.safe_load(CFG.read_text()) or {}
        retain_days = int((data.get("retention") or {}).get("signals_raw_days", 30))
    except Exception:
        pass

raw_dir = VAULT / "meta" / "signals"
compact_dir = VAULT / "meta" / "signals-compact"
compact_dir.mkdir(parents=True, exist_ok=True)

cutoff = dt.date.today() - dt.timedelta(days=retain_days)
compacted_by_week: dict[str, list[dict]] = defaultdict(list)
to_delete: list[Path] = []

if not raw_dir.exists():
    print("no signals/ dir, skipping")
    raise SystemExit(0)

for f in sorted(raw_dir.glob("*.jsonl")):
    try:
        day = dt.date.fromisoformat(f.stem)
    except ValueError:
        continue
    if day >= cutoff:
        continue
    sessions = 0; errors = 0; corrections = 0; duration = 0
    for line in f.read_text(errors="ignore").splitlines():
        try:
            obj = json.loads(line)
        except json.JSONDecodeError:
            continue
        sessions += 1
        errors += obj.get("errors", 0) or 0
        corrections += obj.get("corrections", 0) or 0
        duration += obj.get("duration_s", 0) or 0
    iso = day.isocalendar()
    week = f"{iso.year}-W{iso.week:02d}"
    compacted_by_week[week].append({
        "date": day.isoformat(),
        "sessions": sessions,
        "errors": errors,
        "corrections": corrections,
        "duration_s_total": duration,
    })
    to_delete.append(f)

for week, records in compacted_by_week.items():
    out = compact_dir / f"{week}.jsonl"
    existing = out.read_text(errors="ignore").splitlines() if out.exists() else []
    seen_dates = set()
    merged = []
    for line in existing:
        try:
            obj = json.loads(line)
            seen_dates.add(obj.get("date"))
            merged.append(obj)
        except json.JSONDecodeError:
            continue
    for r in records:
        if r["date"] not in seen_dates:
            merged.append(r)
    merged.sort(key=lambda x: x.get("date", ""))
    out.write_text("\n".join(json.dumps(r) for r in merged) + "\n", encoding="utf-8")

for f in to_delete:
    f.unlink()

print(f"compacted: {len(to_delete)} raw file(s) → {len(compacted_by_week)} week bucket(s)")
PY

# Flag stale open proposals (>14d) by appending a note to the week's rollup
python3 - <<'PY'
import datetime as dt
import os
import re
from pathlib import Path

VAULT = Path(os.environ.get("OPENCLAW_VAULT", Path.home() / "vault")).expanduser()
props = VAULT / "meta" / "proposals"
if not props.exists():
    raise SystemExit(0)

cutoff = dt.date.today() - dt.timedelta(days=14)
stale = []
for f in sorted(props.glob("*.md")):
    try:
        d = dt.date.fromisoformat(f.stem[:10])
    except ValueError:
        d = dt.date.fromtimestamp(f.stat().st_mtime)
    if d > cutoff:
        continue
    text = f.read_text(errors="ignore")
    m = re.search(r"^status:\s*(\S+)", text, re.MULTILINE)
    status = m.group(1) if m else "open"
    if status == "open":
        stale.append((d, f.stem))

if not stale:
    raise SystemExit(0)

iso = dt.date.today().isocalendar()
slug = f"{iso.year}-W{iso.week:02d}"
rollup = VAULT / "meta" / "rollups" / f"{slug}.md"
if not rollup.exists():
    raise SystemExit(0)

with rollup.open("a", encoding="utf-8") as f:
    f.write("\n## Stale proposals\n\n")
    for d, name in sorted(stale):
        f.write(f"- `{d.isoformat()}` {name} — open for {(dt.date.today() - d).days} days\n")
print(f"flagged {len(stale)} stale proposal(s)")
PY

log "done"
