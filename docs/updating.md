# Updating

## The command

```bash
~/.openclaw/package/update.sh
```

Does three things:

1. `git pull --ff-only` inside `package/`
2. Runs any migration scripts if `VERSION` changed
3. Re-runs `install.sh` → rebuilds `runtime/` from `package/` + `user/`

## What's safe

- `package/` is always replaced wholesale on update.
- `user/` is never touched.
- `vault/` is never touched (the initial scaffold only happens if the vault didn't exist at install time).
- `cache/` is kept — re-indexing is incremental.

## What can go wrong

- **`git pull --ff-only` fails** — someone committed to `package/` directly. Either stash/revert your local changes or, for a clean slate, `rm -rf ~/.openclaw/package && git clone ... ~/.openclaw/package`.
- **New version adds a required config key** — `openclaw-doctor` will flag it. Copy the new key from `config.yaml.example` into `~/.openclaw/user/config.yaml`.
- **Schema version bumps** — a migration under `migrations/` runs automatically. Check `CHANGELOG.md` for the context.

## Rolling back

Pin a version:

```bash
git -C ~/.openclaw/package checkout v0.1.0
~/.openclaw/package/install.sh
```

## Verifying

```bash
~/.openclaw/package/bin/openclaw-doctor
```

Everything green? You're good.
