#!/usr/bin/env bash
# Generic adapter — drops a pointer file so the tenant can wire the runtime
# into whatever harness they use. Does nothing harness-specific.
#
# To support a new harness, copy this file to install-for-<name>.sh and
# have it symlink $OPENCLAW_ROOT/runtime/{skills,hooks} into the harness's
# config directory. See docs/adapters.md.

set -euo pipefail

ROOT="${OPENCLAW_ROOT:-$HOME/.openclaw}"
VAULT="${OPENCLAW_VAULT:-$HOME/vault}"

cat > "$ROOT/INTEGRATION.md" <<EOF
# Integration

The generic adapter is a no-op. To wire the runtime into your host harness,
point it at these paths:

- Skills:     $ROOT/runtime/skills
- Hooks:      $ROOT/runtime/hooks
- Schedules:  $ROOT/runtime/schedules
- Vault:      $VAULT

Typically you'll either:

1. Symlink the runtime subdirs into the harness's config dir, or
2. Configure the harness to read from these paths directly.

For the session-end signal hook, set these env vars before invoking
$ROOT/runtime/hooks/log-signal.sh at session end:

  OPENCLAW_SESSION_ID
  OPENCLAW_SESSION_DURATION
  OPENCLAW_SESSION_TOOLS       (JSON object)
  OPENCLAW_SESSION_SKILLS      (JSON array)
  OPENCLAW_SESSION_ERRORS
  OPENCLAW_SESSION_CORRECTIONS

See docs/adapters.md to contribute a native adapter for your harness.
EOF

echo "[adapter:generic] wrote $ROOT/INTEGRATION.md"
