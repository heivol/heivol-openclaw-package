# Changelog

## 0.2.0 — schedules + briefing

**New**
- `skills/briefing/` + `bin/vault-briefing` — forward-looking digest (upcoming via `due`/`remind` frontmatter, open loops from stale work)
- `bin/vault-rollup` — week/month/year-scoped retrospective summary
- `schedules/weekly.sh` — Sun 22:00: weekly rollup + signal compaction + stale proposal flagging
- `schedules/monthly.sh` — 1st of month: monthly rollup + maintenance + vault size
- `schedules/yearly.sh` — opt-in stub: yearly rollup + gated diary archival
- `docs/frontmatter.md` — schema v1 spec
- `migrations/` — versioned update hooks; runs automatically from `update.sh`

**Changed**
- `vault-index` now maintains a `schedules` table (type/status/due/remind) so briefing queries are cheap
- `vault-lint` adds checks for invalid date formats, unknown `type:` values, and overdue items
- `install.sh` registers weekly + monthly cron entries alongside daily
- `config.yaml.example` gains `retention.diary_archive` and comments on existing retention keys

**Migration**
- Auto-runs `vault-index --rebuild` once on 0.1.x → 0.2.0 to populate the schedules table
- Informational count of files missing `schema:`/`type:` frontmatter — no files modified

## 0.1.0 — initial release

- Knowledge base: `diary`, `ingest`, `search`, `lint` skills
- Bins: `vault-search`, `vault-index`, `vault-categorize`, `vault-ingest-transcripts`, `vault-lint`, `meta-analyze`, `openclaw-doctor`, `llm` wrapper
- Meta harness: session-signal hook + daily analyzer + pattern proposals
- Overlay install/update model (`package/` + `user/` → `runtime/`)
- Generic agent adapter + adapter contract documentation
- Vault template with diary / entities / sources / meta layout
