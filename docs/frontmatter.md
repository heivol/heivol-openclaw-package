# Frontmatter Schema v1

Every markdown file in the vault may carry YAML frontmatter. Fields below are the ones the package reads. Tenants are free to add their own — the package ignores unknown fields.

## Common fields

| Field | Type | Notes |
|---|---|---|
| `schema` | integer | Always `1` at this version. Migrations bump this. |
| `type` | enum | `diary` · `note` · `entity` · `source` · `proposal` · `meta-analysis` · `briefing` |
| `tags` | list\[string\] | Auto-managed by `vault-categorize`; hand-edits preserved and merged. |
| `status` | enum | `active` · `in-progress` · `done` · `cancelled` — optional. |

## Forward-looking fields

| Field | Type | Notes |
|---|---|---|
| `due` | date (`YYYY-MM-DD`) | Something expected to be done by this date. Surfaces in `vault-briefing` when `today <= due`. Once `status: done`, the briefing drops it. |
| `remind` | date (`YYYY-MM-DD`) | Surface this note on that date. Visible for 7 days after, then hidden (unless `status: done` sooner). |

## Per-type fields

**`type: diary`**

```yaml
---
schema: 1
type: diary
date: YYYY-MM-DD
tags: []
---
```

`date` is required. One file per day.

**`type: source`**

```yaml
---
schema: 1
type: source
source_type: article | transcript | document | meeting | email | other
source_url: <optional>
ingested: YYYY-MM-DD
entities: [name1, name2]
tags: []
---
```

`entities` is the cascade target — each name should correspond to an entity page.

**`type: proposal`** (written by `meta-analyze`)

```yaml
---
schema: 1
type: proposal
date: YYYY-MM-DD
status: open | accepted | rejected
---
```

**`type: meta-analysis`** (written by `meta-analyze`)

```yaml
---
schema: 1
type: meta-analysis
date: YYYY-MM-DD
---
```

## Examples

A note with both a due date and a reminder:

```yaml
---
schema: 1
type: note
status: in-progress
due: 2026-04-25
remind: 2026-04-22
tags: [work, decision]
---
```

A diary entry with entities linked inline:

```yaml
---
schema: 1
type: diary
date: 2026-04-20
tags: [work]
---

## 14:32

Caught up with [[entities/oliver]] about the [[entities/q2-budget]] review.
```

## What NOT to put in frontmatter

- Long prose — belongs in the body
- Sensitive data — frontmatter is indexed and surfaced in search results
- Binary/encoded data — keep it human-readable

## Migration

When `schema` bumps, `update.sh` runs the corresponding script in `migrations/`. The migration is responsible for rewriting existing files in place or, when safer, leaving them alone and relying on backward-compatible reads.
