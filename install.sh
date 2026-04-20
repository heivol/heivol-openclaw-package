#!/usr/bin/env bash
# heivol-openclaw-package installer
#
# Sets up:
#   ~/.openclaw/{user,runtime,cache}/
#   $OPENCLAW_VAULT (default ~/vault) scaffolded from vault-template/
#   Runtime merge: package/ + user/ → runtime/
#   Agent adapter wires runtime/ into the host harness
#   Daily cron registered
#
# Safe to re-run.

set -euo pipefail

PACKAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${OPENCLAW_ROOT:-$HOME/.openclaw}"
USER_DIR="$ROOT/user"
RUNTIME_DIR="$ROOT/runtime"
CACHE_DIR="$ROOT/cache"
VAULT="${OPENCLAW_VAULT:-$HOME/vault}"
DRY_RUN=0
AGENT_TYPE="${OPENCLAW_AGENT:-generic}"

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --agent=*) AGENT_TYPE="${arg#--agent=}" ;;
    --vault=*) VAULT="${arg#--vault=}" ;;
    -h|--help)
      cat <<EOF
Usage: install.sh [--dry-run] [--agent=<name>] [--vault=<path>]

Environment:
  OPENCLAW_ROOT     Root of the install (default: ~/.openclaw)
  OPENCLAW_VAULT    Vault location (default: ~/vault)
  OPENCLAW_AGENT    Host harness adapter (default: generic)
EOF
      exit 0
      ;;
  esac
done

log() { printf '\033[1;34m[install]\033[0m %s\n' "$*"; }
run() { if [ "$DRY_RUN" = 1 ]; then echo "+ $*"; else eval "$@"; fi; }

log "package:  $PACKAGE_DIR"
log "root:     $ROOT"
log "vault:    $VAULT"
log "adapter:  $AGENT_TYPE"

# 1. Directory scaffolding
log "scaffolding $ROOT"
run "mkdir -p '$USER_DIR' '$RUNTIME_DIR' '$CACHE_DIR'"
run "mkdir -p '$USER_DIR'/skills '$USER_DIR'/hooks '$USER_DIR'/schedules"

# 2. Seed user config once
if [ ! -f "$USER_DIR/config.yaml" ]; then
  log "seeding user/config.yaml"
  run "cp '$PACKAGE_DIR/config.yaml.example' '$USER_DIR/config.yaml'"
fi

# 3. Vault scaffold (only if missing — never overwrite)
if [ ! -d "$VAULT" ]; then
  log "scaffolding vault at $VAULT"
  run "mkdir -p '$VAULT'"
  run "cp -R '$PACKAGE_DIR/vault-template/.' '$VAULT/'"
else
  log "vault exists at $VAULT (skipping scaffold)"
fi

# 4. Runtime merge (user wins on overlap)
log "merging runtime"
run "rm -rf '$RUNTIME_DIR'"
run "mkdir -p '$RUNTIME_DIR'"
for sub in skills hooks schedules bin; do
  run "mkdir -p '$RUNTIME_DIR/$sub'"
  if [ -d "$PACKAGE_DIR/$sub" ]; then
    run "cp -R '$PACKAGE_DIR/$sub/.' '$RUNTIME_DIR/$sub/' 2>/dev/null || true"
  fi
  if [ -d "$USER_DIR/$sub" ]; then
    run "cp -R '$USER_DIR/$sub/.' '$RUNTIME_DIR/$sub/' 2>/dev/null || true"
  fi
done

# 5. Agent adapter
ADAPTER="$PACKAGE_DIR/adapters/install-for-$AGENT_TYPE.sh"
if [ -x "$ADAPTER" ]; then
  log "running adapter: $AGENT_TYPE"
  run "OPENCLAW_ROOT='$ROOT' OPENCLAW_VAULT='$VAULT' '$ADAPTER'"
else
  log "no adapter for '$AGENT_TYPE' (looked for $ADAPTER); skipping"
fi

# 6. Python deps (best-effort)
if command -v pip3 >/dev/null 2>&1; then
  log "installing Python dependencies"
  run "pip3 install --user -q -r '$PACKAGE_DIR/requirements.txt' || true"
fi

# 7. Cron entries
if command -v crontab >/dev/null 2>&1; then
  register_cron() {
    local mark="$1"
    local line="$2"
    if crontab -l 2>/dev/null | grep -Fq "$mark"; then
      log "$mark already registered"
    else
      log "registering: $mark"
      run "(crontab -l 2>/dev/null; echo '$line') | crontab -"
    fi
  }

  register_cron "# heivol-openclaw-package daily" \
    "5 3 * * *  $RUNTIME_DIR/schedules/daily.sh   >> $ROOT/daily.log   2>&1 # heivol-openclaw-package daily"
  register_cron "# heivol-openclaw-package weekly" \
    "0 22 * * 0 $RUNTIME_DIR/schedules/weekly.sh  >> $ROOT/weekly.log  2>&1 # heivol-openclaw-package weekly"
  register_cron "# heivol-openclaw-package monthly" \
    "35 3 1 * * $RUNTIME_DIR/schedules/monthly.sh >> $ROOT/monthly.log 2>&1 # heivol-openclaw-package monthly"
  # Yearly is intentionally not registered — opt-in per tenant.
fi

log "done. Run: $PACKAGE_DIR/bin/openclaw-doctor"
