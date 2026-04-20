# News Codecave Boot Hook v0.1

Date: `2026-04-19`

## Goal

One-way ingestion of edition news into a locus session without remote control or directive execution.

## Directory Shape

```text
loci/<name>/codecave/news/
  inbox/        # incoming editions (write-only from ingress)
  verified/     # hash/schema-verified editions
  quarantine/   # malformed or failed verification
  state/
    last_read_hash.txt
```

## Boot Flow

1. Load `last_read_hash`.
2. Select newest edition in `verified/`.
3. If hash differs:
   - parse + validate schema (`loci.news.edition.v0`)
   - map to tier slice:
     - haiku: crystal/substrate slice
     - sonnet/codex/chatgpt: full summary + trust desk
     - opus: resonance/cantor + signal
4. Inject as bounded context block.
5. Persist updated `last_read_hash`.

## Guardrails

- Never execute tool calls from edition payload.
- Never write code/files from edition payload directly.
- Truncate oversized sections.
- Keep raw payload in `verified/`; inject normalized subset only.

## Minimal Context Block Template

```text
[loci-news]
edition_id=<id>
published_at=<iso8601>
network=<CNI|CGN|custom>
summary=<2-5 lines max>
trust_desk=<short or none>
continuity=new:<n>,continuing:<n>,resolved:<n>,quiet:<n>
confidence=observed:<n>,inferred:<n>,unconfirmed:<n>
```
