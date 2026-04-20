#!/usr/bin/env bash
# Daily job — runs once per day via cron (registered by install.sh).
#
# Order matters:
#   1. vault-index      keep the search index fresh before anything reads it
#   2. vault-ingest-transcripts  fold new agent sessions into the diary
#   3. vault-lint       vault health; write findings to meta/analysis/
#   4. meta-analyze     aggregate signals; emit proposals

set -uo pipefail

ROOT="${OPENCLAW_ROOT:-$HOME/.openclaw}"
VAULT="${OPENCLAW_VAULT:-$HOME/vault}"
BIN="$ROOT/runtime/bin"
DAY="$(date +%Y-%m-%d)"

log() { printf '\033[1;34m[daily %s]\033[0m %s\n' "$DAY" "$*"; }
run() { log "→ $*"; "$@" || log "  (exit $? — continuing)"; }

log "start"

[ -x "$BIN/vault-index" ]                && run "$BIN/vault-index"
[ -x "$BIN/vault-ingest-transcripts" ]   && run "$BIN/vault-ingest-transcripts"
[ -x "$BIN/vault-lint" ]                 && run "$BIN/vault-lint" --report "$VAULT/meta/analysis/$DAY-lint.md"
[ -x "$BIN/meta-analyze" ]               && run "$BIN/meta-analyze"

log "done"
