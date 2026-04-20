# Adapters

An adapter wires the package's runtime directory (`~/.openclaw/runtime/`) into whatever agent harness the tenant is running. The package itself has zero hard dependencies on any specific harness — adapters are the bridge.

## Selecting an adapter

`~/.openclaw/user/config.yaml`:

```yaml
agent_type: generic
```

`install.sh` runs `adapters/install-for-<agent_type>.sh` if it exists, and falls through to a no-op otherwise.

## What an adapter does

At minimum, an adapter should:

1. Make the runtime's `skills/` discoverable by the host harness (symlink into the harness's skills directory, register via config, whatever the harness wants).
2. Do the same for `hooks/` — in particular wire `log-signal.sh` into the harness's session-end hook.
3. Populate the `OPENCLAW_SESSION_*` env vars from harness-native telemetry before invoking `log-signal.sh`, so the signal line is meaningful.

## Writing a new adapter

Copy `install-for-generic.sh` as a starting template:

```bash
cp ~/.openclaw/package/adapters/install-for-generic.sh \
   ~/.openclaw/package/adapters/install-for-<myharness>.sh
chmod +x ~/.openclaw/package/adapters/install-for-<myharness>.sh
```

Edit to symlink `$OPENCLAW_ROOT/runtime/skills` → the harness's config directory. Document where the harness expects skills to live, how it invokes hooks, and what session telemetry it exposes.

Contribute it back — a PR adding an adapter for a new harness is always welcome.

## Env var contract

The signal hook expects these env vars when invoked:

| Var | Type | Notes |
|---|---|---|
| `OPENCLAW_SESSION_ID` | string | Opaque. Optional. |
| `OPENCLAW_SESSION_DURATION` | integer seconds | |
| `OPENCLAW_SESSION_TOOLS` | JSON object | `{"ToolName": count, ...}` |
| `OPENCLAW_SESSION_SKILLS` | JSON array | `["diary", "search"]` |
| `OPENCLAW_SESSION_ERRORS` | integer | Failed tool calls |
| `OPENCLAW_SESSION_CORRECTIONS` | integer | Heuristic: user-initiated course corrections |

Missing env vars are dropped from the output line. Metadata-only — content is never in scope.

## Respecting `.disabled`

If a skill directory contains `.disabled`, the adapter should skip registering it. This is how tenants turn off a skill without editing package files.
