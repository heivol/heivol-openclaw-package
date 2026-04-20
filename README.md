# heivol-openclaw-package

A public, read-only base layer for personal-AI assistants. Drops in two capabilities:

1. **Knowledge base** — an Obsidian-compatible vault with a diary, auto-categorized ingestion, and local semantic search.
2. **Meta harness** — a daily job that logs session signals, analyzes them for self-improvement proposals, and lints the vault for drift.

Designed to be consumed by [OpenClaw](https://heivol.com) instances or any personal-agent setup that wants a persistent knowledge layer and a reflection loop — without coupling to a specific LLM or harness.

## Why

Most agent setups lose everything between sessions. This package gives a tenant:

- A local, searchable narrative of what they've done, decided, and discussed
- Automatic categorization and entity extraction as content flows in
- A reflection loop that notices friction in the harness itself and proposes fixes

All local. No cloud store. The only outbound calls happen when the tenant configures an LLM command for categorization.

## Install

```bash
git clone --depth=1 https://github.com/heivol/heivol-openclaw-package.git ~/.openclaw/package
~/.openclaw/package/install.sh
```

The installer:

1. Creates `~/.openclaw/{user,runtime,cache}/`
2. Scaffolds a vault at `$OPENCLAW_VAULT` (default `~/vault/`) from `vault-template/`
3. Merges `package/` + `user/` into `runtime/` (user wins)
4. Runs the agent adapter to wire `runtime/` into the host harness
5. Registers the daily cron

## Update

```bash
~/.openclaw/package/update.sh
```

Fast-forwards `package/`, re-runs the merge. Files in `user/` are never touched. Any file marked with `.openclaw-lock` is skipped even if unchanged upstream.

## Architecture

```
~/.openclaw/
├── package/   ← this repo, read-only
├── user/      ← tenant customizations, persisted
├── runtime/   ← merged view consumed by the host harness
└── cache/     ← embedding models, indexes
```

See [docs/concepts.md](docs/concepts.md) for the overlay model, [docs/customization.md](docs/customization.md) for how to override, and [docs/adapters.md](docs/adapters.md) for supporting a new host harness.

## Components

| Path | Purpose |
|---|---|
| `skills/diary/` | Capture notes into `vault/diary/YYYY-MM-DD.md` with auto-tagging |
| `skills/ingest/` | Turn a source into summary + entity pages with cascading links |
| `skills/search/` | Semantic search wrapper over the vault |
| `skills/lint/` | Vault health checks (orphans, broken links, stale content) |
| `skills/briefing/` | Forward-looking digest: upcoming + open loops |
| `bin/vault-search` | CLI: sqlite-vec + local embedding search |
| `bin/vault-index` | CLI: incremental embedding index + schedules table |
| `bin/vault-categorize` | CLI: classify a note into a tag vocabulary via LLM |
| `bin/vault-ingest-transcripts` | CLI: fold agent session transcripts into the diary |
| `bin/vault-briefing` | CLI: upcoming (`due`/`remind`) + open loops |
| `bin/vault-rollup` | CLI: week/month/year-scoped summary writer |
| `bin/meta-analyze` | CLI: read recent signals, write analysis + proposals |
| `bin/vault-lint` | CLI: vault health; `--fix` applies safe fixes |
| `bin/openclaw-doctor` | CLI: checks the install is healthy |
| `hooks/log-signal.sh` | Session-end hook; appends metadata JSONL |
| `schedules/daily.sh` | Daily: index + lint + meta-analyze + transcript ingest |
| `schedules/weekly.sh` | Sun 22:00: weekly rollup + signal compaction + stale proposals |
| `schedules/monthly.sh` | 1st of month: monthly rollup + maintenance + vault size |
| `schedules/yearly.sh` | Stub (opt-in): yearly rollup + optional diary archival |
| `vault-template/` | Initial vault scaffolding |

## Frontmatter

Package-aware frontmatter fields — see [docs/frontmatter.md](docs/frontmatter.md):

```yaml
---
schema: 1
type: diary | note | entity | source | proposal | meta-analysis | briefing | rollup
status: active | in-progress | done | cancelled
due: YYYY-MM-DD            # briefing surfaces when today ≤ due
remind: YYYY-MM-DD          # briefing surfaces around this date
tags: []
---
```

## Configuration

`~/.openclaw/user/config.yaml` (copy from `config.yaml.example`):

```yaml
vault_path: ~/vault
llm_cmd: ""            # e.g. "heivol-modelproxy prompt"; empty disables LLM features
agent_type: generic    # selects adapter in adapters/
retention:
  signals_raw_days: 30
  signals_compact_days: 365
```

## Privacy

- Diary content never leaves the host
- Session signals contain metadata only (tool names, durations, error codes) — never message content
- LLM calls happen only when `llm_cmd` is set, and only for categorization + meta-analysis
- No telemetry, no phone-home

## License

MIT. See [LICENSE](LICENSE).
