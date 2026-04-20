#!/usr/bin/env bash
# Migration 001 — applies on 0.1.x → 0.2.0
#
# v0.2.0 adds a `schedules` table to the index. Rebuild from scratch so the
# new table is populated. Incremental re-indexes after this one are fast
# because mtime-based skipping kicks back in.

set -euo pipefail

FROM="${OPENCLAW_FROM:-0.0.0}"
TO="${OPENCLAW_TO:-0.0.0}"

# Only run going into 0.2.0 from anything older.
case "$TO" in
  0.2.*|0.3.*|1.*) ;;
  *) exit 0 ;;
esac
case "$FROM" in
  0.1.*) ;;
  *) exit 0 ;;
esac

VAULT="${OPENCLAW_VAULT:-$HOME/vault}"
ROOT="${OPENCLAW_ROOT:-$HOME/.openclaw}"
BIN="$ROOT/runtime/bin"

if [ ! -d "$VAULT" ]; then
  echo "[001] no vault yet — skipping"
  exit 0
fi

if [ ! -x "$BIN/vault-index" ]; then
  echo "[001] vault-index not found — will index on next daily run"
  exit 0
fi

echo "[001] rebuilding vault index to populate schedules table"
"$BIN/vault-index" --rebuild
