# Concepts

## Why this exists

Most agent setups lose everything between sessions. This package gives a tenant:

- A **local, searchable narrative** — a diary plus ingested sources, indexed by semantic search.
- A **reflection loop** — a daily job that watches how the harness is being used and proposes improvements when friction recurs.

The package is deliberately minimal: four skills, a handful of bins, one cron entry. Every piece is optional; the tenant can unplug any one of them and the rest still works.

## Overlay model

```
~/.openclaw/
├── package/   ← this repo, read-only
├── user/      ← tenant customizations, persisted
├── runtime/   ← merged view (user wins on conflict)
└── cache/     ← embedding models, indexes, state
```

The install / update scripts rebuild `runtime/` from scratch on every run by copying `package/*` and then overlaying `user/*` on top. The merge is file-level: if `user/skills/diary/SKILL.md` exists, it wins over the package version.

Why this pattern:

- Upstream updates rewrite `package/` cleanly without ever touching `user/`.
- A tenant can override any single file without forking the whole repo.
- Rolling back is `rm -rf runtime && install.sh`.

## Knowledge base

Two capture paths feed the same vault:

- **Diary** — small, live entries. Triggered by the user in conversation.
- **Ingest** — larger sources (articles, transcripts, meetings) with cascading entity updates.

Both routes:

1. Write a markdown file with YAML frontmatter.
2. Call `vault-categorize` → LLM tags the note against a closed vocabulary.
3. Call `vault-index --file` → embedding refresh for search **and** schedules-table refresh (extracts `type`/`status`/`due`/`remind` for cheap briefing queries).

Search (`vault-search`) is semantic, runs fully local (sqlite-vec + a small sentence-transformer), and is always the first place the harness looks before fresh research or grep.

**Briefing** (`vault-briefing` + `skills/briefing/`) is the forward-looking view:

- **Upcoming** — notes whose `due` or `remind` date is within the horizon, pulled from the schedules table
- **Open loops** — stale in-progress notes, overdue items, open proposals, orphaned sources

Triggered on demand via the briefing skill (`"what's upcoming"`, `"brief me"`). Not on a schedule — context drives when it runs.

**Rollups** (`vault-rollup`) are the retrospective view at week/month/year scope, written by the weekly/monthly/yearly schedules.

## Meta harness

The reflection loop has four pieces:

1. **Signal hook** (session end) — appends a JSONL metadata line to `vault/meta/signals/`. Metadata only — no message content, no user input. Safe for a public, multi-tenant package.
2. **Daily analyzer** — reads the last day of signals, writes a summary to `vault/meta/analysis/YYYY-MM-DD.md`, optionally with an LLM-written narrative.
3. **Pattern detector** — if the same issue appears on ≥3 days, drops a stub proposal into `vault/meta/proposals/` for the tenant to review.
4. **Lint** — orthogonal vault-health check that also runs daily.

Proposals are never auto-applied. The system observes and suggests; the tenant decides.

## Privacy boundary

The only calls that leave the tenant's machine are to the configured `llm_cmd`, and only for:

- **Categorization** — note body → tag list
- **Transcript summarization** — full session text → bullet summary
- **Meta-analysis narrative** — aggregated metadata → 2–3 sentences

If `llm_cmd` is empty, everything above is skipped. Search still works; the diary still captures; signals still log. The package degrades to "vault + static analysis" cleanly.

No telemetry, no phone-home, no analytics.

## Delivery contract

The repo is read-only from the tenant's point of view. They pull updates via `update.sh`; they customize via `~/.openclaw/user/`. Breaking changes bump `VERSION` and ship a migration script in `migrations/`.
