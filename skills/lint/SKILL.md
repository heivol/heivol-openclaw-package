---
name: lint
description: Vault health check. Finds orphan notes, broken wiki-links, stale content, and missing frontmatter. Read-only by default — reports findings. Pass --fix to apply safe auto-fixes. Triggers on 'lint vault', 'vault health', 'check vault', 'find orphans', 'vault maintenance', 'vault cleanup'.
---

# Lint

Inspect vault integrity. Runs as part of the daily job; can be invoked manually any time.

## Invocation

```bash
$OPENCLAW_ROOT/runtime/bin/vault-lint                  # report only
$OPENCLAW_ROOT/runtime/bin/vault-lint --fix            # apply safe auto-fixes
$OPENCLAW_ROOT/runtime/bin/vault-lint --report <path>  # write report to a file
```

## Checks

- **Orphan notes** — markdown files nothing links to
- **Broken wiki-links** — `[[foo]]` where `foo.md` doesn't exist
- **Missing frontmatter** — notes without `schema:` and `type:` fields
- **Stale notes** — frontmatter says `status: in-progress` but file hasn't been modified in N days
- **Index drift** — MEMORY.md entries pointing at missing files
- **Duplicate entities** — two entity pages with near-identical titles (edit-distance)

## Auto-fixable (`--fix`)

- Add missing frontmatter with defaults
- Remove dangling MEMORY.md entries (after confirming file is actually missing)
- Flag (but do not delete) orphan files — deletion is manual only

## When to invoke manually

- User asks about vault health explicitly
- Before a big reorganization
- After a mass ingest — new broken links often appear

## What NOT to do

- Don't auto-delete files under any flag — orphans may be intentional.
- Don't modify note bodies; only frontmatter.
