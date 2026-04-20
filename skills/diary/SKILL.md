---
name: diary
description: Capture a note into the vault's daily diary file. Triggers on 'note', 'jot', 'log this', 'remember this', 'capture this', 'save thought', 'write down', 'diary', or any explicit ask to record something for later. Use for fleeting thoughts, meeting notes, decisions, things to remember — anything that belongs in a personal narrative log.
---

# Diary

Append a timestamped entry to the current day's diary file in the tenant's vault. Auto-tag the entry after writing.

## Where it writes

```
$OPENCLAW_VAULT/diary/YYYY-MM-DD.md
```

If the file doesn't exist, create it with this frontmatter:

```yaml
---
date: YYYY-MM-DD
type: diary
schema: 1
---
```

## Entry format

Each entry is a `## HH:MM` heading followed by the content. Keep the user's wording — don't paraphrase. If the user supplies a short fragment, write it as-is; if they supply a long block, preserve structure.

```markdown
## 14:32

The user's content here, verbatim or near-verbatim.
```

## After writing

1. Run `$OPENCLAW_ROOT/runtime/bin/vault-categorize "$OPENCLAW_VAULT/diary/YYYY-MM-DD.md"` — this appends tags to the frontmatter based on today's entries.
2. Run `$OPENCLAW_ROOT/runtime/bin/vault-index --file "$OPENCLAW_VAULT/diary/YYYY-MM-DD.md"` to refresh the embedding index for search.

## Linking

When the entry mentions a named person, project, or topic, wrap it in `[[wiki-links]]`. The ingest skill maintains the entity pages those links resolve to — no need to create stubs here.

## What NOT to do

- Don't summarize — a diary is a capture tool, not a digest tool.
- Don't ask "which diary file?" — it's always today's date.
- Don't rewrite existing entries in the file.
- Don't add commentary about what was captured. Just capture it.
