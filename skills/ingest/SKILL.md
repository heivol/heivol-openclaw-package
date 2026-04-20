---
name: ingest
description: Ingest a source (URL, document, pasted text, transcript) into the vault with cascading entity updates. Unlike diary (one-off capture), ingest processes a larger source into a summary, then cascades updates to entity pages — one source touches multiple files so context compounds. Triggers on 'ingest', 'process this', 'add this to the vault', 'incorporate this', 'absorb this', 'catalog this', 'ingest this article'.
---

# Ingest

Turn a source into a summary note plus cascading updates to the entities the source mentions.

## Steps

1. **Read the source.** URL → fetch + extract text. File → read. Pasted text → use as-is.
2. **Classify** the source type: `article`, `transcript`, `document`, `meeting`, `email`, `other`.
3. **Write a summary** at `$OPENCLAW_VAULT/sources/YYYY-MM-DD-<slug>.md` with frontmatter:

   ```yaml
   ---
   source_type: article
   source_url: <original url if any>
   ingested: YYYY-MM-DD
   schema: 1
   entities: [name1, name2]
   tags: []
   ---
   ```

   Body: 3–6 bullet points of key findings, then a `## Full Notes` section with the distilled content.

4. **Extract entities** — named people, projects, companies, products, concepts. For each, either update the existing page at `$OPENCLAW_VAULT/entities/<name>.md` (add a bullet to the "References" section with a link back to the source) or create a new stub:

   ```markdown
   # <Name>

   <one-line description>

   ## References
   - [[sources/YYYY-MM-DD-<slug>]] — <why this source mentions the entity>
   ```

5. **Link bidirectionally** — add `[[entities/<name>]]` wiki-links in the source note wherever the name appears, and list the entities in the source's `entities:` frontmatter.

6. **Categorize** the source via `$OPENCLAW_ROOT/runtime/bin/vault-categorize`.

7. **Index** the new/updated files via `vault-index --file <path>` for each.

## Principle

One source touches ≥3 pages (the source note plus at least 2 entity pages). That's the compounding effect — the next session reading any of those entities sees this source. Skipping the cascade defeats the ingest vs. diary distinction.

## What NOT to do

- Don't skip entity extraction because "the source is short" — a one-paragraph mention of a new library is still worth a stub.
- Don't overwrite existing entity pages — append to References only.
- Don't fabricate URLs or attribute quotes the source didn't contain.
