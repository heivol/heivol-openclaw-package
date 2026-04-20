---
name: search
description: Search the vault semantically. Use this FIRST before grep/glob for any question about past notes, prior decisions, ingested sources, or "what did I say about X". Triggers on 'search vault', 'find in notes', 'look up', 'what did I note about', 'recall', 'what have I written on', 'what do I know about'.
---

# Search

Semantic search over the vault using the local embedding index. Always try this before falling back to grep — semantic search surfaces related content that keyword match misses.

## Invocation

```bash
$OPENCLAW_ROOT/runtime/bin/vault-search "<query>" [--limit N] [--scope <subdir>]
```

Returns ranked results: score, path, snippet.

## When to use

- User asks a question that past notes may answer
- You're about to do research and want to check what's already known
- User says "what did I decide about X" or "have I written about Y"
- Before ingesting a new source, check if a related one is already indexed

## Tips

- Keep queries natural-language, not keyword — `"why we picked postgres over sqlite"` works better than `"postgres sqlite"`.
- Narrow with `--scope diary` or `--scope entities` when you know where to look.
- If results are thin, fall back to `Grep` on the vault path.

## What NOT to do

- Don't skip this step and go straight to grep — you'll miss semantically-related notes.
- Don't run it for current-session context; search is for persisted vault content, not the conversation.
