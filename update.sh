#!/usr/bin/env bash
# heivol-openclaw-package updater
#
# Fast-forwards the package repo and re-runs the install to rebuild runtime/.
# User files in ~/.openclaw/user/ are never touched.

set -euo pipefail

PACKAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log() { printf '\033[1;34m[update]\033[0m %s\n' "$*"; }

log "fetching upstream"
git -C "$PACKAGE_DIR" fetch --quiet origin

OLD_VERSION="$(cat "$PACKAGE_DIR/VERSION" 2>/dev/null || echo "0.0.0")"
log "updating (was $OLD_VERSION)"
git -C "$PACKAGE_DIR" pull --ff-only --quiet
NEW_VERSION="$(cat "$PACKAGE_DIR/VERSION" 2>/dev/null || echo "0.0.0")"

if [ "$OLD_VERSION" != "$NEW_VERSION" ]; then
  log "version $OLD_VERSION → $NEW_VERSION"
  MIG_DIR="$PACKAGE_DIR/migrations"
  if [ -d "$MIG_DIR" ]; then
    for mig in "$MIG_DIR"/*.sh; do
      [ -f "$mig" ] || continue
      log "migration: $(basename "$mig")"
      OPENCLAW_FROM="$OLD_VERSION" OPENCLAW_TO="$NEW_VERSION" bash "$mig"
    done
  fi
fi

log "re-running install"
"$PACKAGE_DIR/install.sh" "$@"

log "done."
