#!/usr/bin/env bash
# Session-end signal logger.
#
# Appends one JSONL line per session to $OPENCLAW_VAULT/meta/signals/YYYY-MM-DD.jsonl.
# Consumed by bin/meta-analyze.
#
# METADATA ONLY — never log message content. This hook is part of a public
# package; every field here is safe for a daily aggregation report.
#
# Inputs (env, best-effort — missing values are omitted from the JSON):
#   OPENCLAW_SESSION_ID        opaque session id
#   OPENCLAW_SESSION_DURATION  seconds (integer)
#   OPENCLAW_SESSION_TOOLS     JSON object: {"Read": 12, "Bash": 3, ...}
#   OPENCLAW_SESSION_SKILLS    JSON array: ["diary", "search"]
#   OPENCLAW_SESSION_ERRORS    integer: failed tool calls
#   OPENCLAW_SESSION_CORRECTIONS integer: user corrections detected
#
# Adapters are responsible for populating these env vars from whatever
# telemetry the host harness exposes — see adapters/.

set -euo pipefail

VAULT="${OPENCLAW_VAULT:-$HOME/vault}"
DAY="$(date +%Y-%m-%d)"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
OUT_DIR="$VAULT/meta/signals"
OUT_FILE="$OUT_DIR/$DAY.jsonl"

mkdir -p "$OUT_DIR"

# Build JSON without a jq dependency.
python3 - <<PY >> "$OUT_FILE"
import json, os

def maybe_json(s):
    try:
        return json.loads(s) if s else None
    except json.JSONDecodeError:
        return None

def maybe_int(s):
    try:
        return int(s) if s else None
    except ValueError:
        return None

record = {
    "ts": "$TS",
    "event": "session_end",
    "session_id": os.environ.get("OPENCLAW_SESSION_ID") or None,
    "duration_s": maybe_int(os.environ.get("OPENCLAW_SESSION_DURATION", "")),
    "tools": maybe_json(os.environ.get("OPENCLAW_SESSION_TOOLS", "")),
    "skills": maybe_json(os.environ.get("OPENCLAW_SESSION_SKILLS", "")),
    "errors": maybe_int(os.environ.get("OPENCLAW_SESSION_ERRORS", "")) or 0,
    "corrections": maybe_int(os.environ.get("OPENCLAW_SESSION_CORRECTIONS", "")) or 0,
}
record = {k: v for k, v in record.items() if v is not None}
print(json.dumps(record, ensure_ascii=False))
PY
