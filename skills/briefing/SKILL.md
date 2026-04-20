---
name: briefing
description: Forward-looking digest of what's on the user's plate — scheduled items (via `due`/`remind` frontmatter) plus unfinished past work (stale in-progress notes, overdue items, open proposals, orphaned sources). Use when the user asks for a look-ahead, a status check, or wants to pick up where they left off. Triggers on 'what's upcoming', 'brief me', 'catch me up', 'what's on my plate', 'what should I pick up', 'what's due', 'open loops', 'status check', 'what's next'.
---

# Briefing

Invoke `$OPENCLAW_ROOT/runtime/bin/vault-briefing` and present the output to the user.

## Invocation

```bash
vault-briefing                # stdout, default 7-day horizon
vault-briefing --horizon 30   # month-ahead view
vault-briefing --stale-days 7 # tighter "not moving" threshold
```

## How to present

1. Run `vault-briefing` and read the markdown output.
2. Write one sentence of human summary at the top (e.g. "3 things due this week, 2 stale proposals").
3. Show the full briefing verbatim below the summary.
4. If the user follows up with a specific item, route to `search` skill or read the file directly.

## Two sections explained

**Upcoming (forward)** — items with `due` or `remind` frontmatter dates in the horizon. This is the genuine look-ahead.

**Open loops (past, unfinished)** — four sub-categories:
- Stale in-progress notes (status=in-progress, not modified recently)
- Overdue (due date passed, not marked done)
- Open proposals from the meta-analyzer
- Sources ingested but no entity page links to them yet

## When to use

- User asks for a status check or look-ahead
- Start of a session where the user seems to need re-orientation
- Before planning work — catch unfinished items first

## When NOT to use

- User asks "what did I do last week" → that's `vault-rollup --week`, not briefing
- User wants a semantic search → that's `search` skill
- User wants to capture something new → that's `diary` skill

## Offering to write

If the user wants the briefing saved to the vault (e.g. for sharing or later reference), run with `--write`:

```bash
vault-briefing --write
```

Writes to `$OPENCLAW_VAULT/briefings/YYYY-MM-DD.md`.
