# Customization

Everything under `~/.openclaw/user/` is yours. The installer never writes there after the initial seed, and the updater never touches it.

## Overriding a skill

To change the diary skill's prompt:

```bash
mkdir -p ~/.openclaw/user/skills/diary
cp ~/.openclaw/package/skills/diary/SKILL.md ~/.openclaw/user/skills/diary/SKILL.md
# edit ~/.openclaw/user/skills/diary/SKILL.md
~/.openclaw/package/update.sh
```

The merged runtime now serves your version.

## Adding a new skill

```bash
mkdir -p ~/.openclaw/user/skills/my-skill
cat > ~/.openclaw/user/skills/my-skill/SKILL.md <<'EOF'
---
name: my-skill
description: ...
---
...
EOF
~/.openclaw/package/install.sh
```

The runtime picks it up; the host harness loads it via the adapter.

## Overriding a bin

Same pattern — put your override in `~/.openclaw/user/bin/`. The runtime merge prefers your version.

## config.yaml

`~/.openclaw/user/config.yaml` is yours to edit. Set:

- `vault_path` — where the vault lives (default `~/vault`)
- `llm_cmd` — the command used for LLM features (empty disables them)
- `agent_type` — which adapter in `adapters/` gets run at install
- `embedding_model` — change the sentence-transformer model
- `retention.*` — how long to keep raw signals vs. compacted ones
- `categories` — the closed tag vocabulary for `vault-categorize`

## Lockable files

A file matching `*.openclaw-lock` next to the real file marks that path as "do not re-merge". Useful if you've customized something and don't want future updates to clobber it even if you later delete your `user/` version.

Example:

```bash
touch ~/.openclaw/runtime/skills/diary/SKILL.md.openclaw-lock
```

`update.sh` will skip the merge for that path.

## Disabling a component

To remove a skill entirely without forking:

```bash
mkdir -p ~/.openclaw/user/skills/diary
touch ~/.openclaw/user/skills/diary/.disabled
~/.openclaw/package/install.sh
```

(Adapters respect the `.disabled` marker — see `adapters/`.)

## Running without the cron

If you prefer to run the daily job manually or via a different scheduler, remove the crontab entry and invoke `~/.openclaw/runtime/schedules/daily.sh` on your own cadence.
