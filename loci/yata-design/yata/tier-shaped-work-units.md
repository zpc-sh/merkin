# YATA Hole: Tier-Shaped Work Unit Design

## Hole Metadata
- **hole_id**: `H("tier-shaped-work-units" ++ "model/yata.mbt" ++ "2026-04-13")`
- **anchor**: model/yata.mbt — how tiers create, fill, and route YATA holes
- **state**: Converging (1 of 3 candidates filed)

## Contract
- **expected_type**: Design decision with data model changes to model/yata.mbt
- **invariants**:
  - Must not add overhead to the unplanned/emergent workflow that already works
  - Must be expressible in existing YATA/Residue/WorkPromise primitives (extend, don't replace)
  - Haiku must be able to run as cognitive compiler (fast, cheap, self-aware of limits)
  - Sonnet must never get stuck (escape hatch required)
  - Opus creates macro compositions, not mechanical tasks
- **verification**: All 3 Opus candidates reviewed, user selects or synthesizes

## Design Questions (the typed gap)

### Q1: Where does tier live?
- On `YataHole` as a field? (`tier: HoleTier?`)
- Implicit from `contract.expected_type`? ("CompilerFix" = Haiku-shaped)
- On the sparse tree routing tokens? (Haiku writes to haiku-projection)
- Nowhere — tier is a convention, not a type

### Q2: How does Haiku's cognitive compiler tree relate to the main tree?
- Separate sparse projection (same tree, different token filter)
- Fork (diverges, merges back on fill)
- Overlay (Haiku's holes are annotations on main tree nodes)
- Just files in a directory (`loci/<name>/yata/*.md`)

### Q3: Sonnet escape hatch design
- Budget struct on the hole (max_tokens, max_attempts) — system-enforced
- `YataState::Abandoned(reason)` — already exists, Sonnet uses it conventionally
- PartialFill as a first-class state — `Sealed(partial)` with remaining holes
- Timeout from external coordinator (not in the hole itself)

### Q4: Sonnet's "letters to Opus" pattern
- Residue `recommendation` field with tier-addressing ("Opus: I crystallized X")
- A separate artifact type (not residue — something like "crystal" or "brief")
- Just convention — any residue with substantial reasoning IS a letter
- YataCandidate on an Opus-typed hole (Sonnet proposes, Opus decides)

### Q5: Cross-Claude provenance
- Haiku creates hole → Sonnet fills → provenance array: ["haiku/scan", "sonnet/fill"]
- WorkPromise tracks it (input=haiku_hole, transform=sonnet_session)
- Envelope wraps the fill with semantic_header linking back to hole
- Residue chain is sufficient (picked_up_from links sessions)

---

## Candidate 1: opus/91c3a (this session)

**Position**: The inverted hierarchy — Haiku scouts, Sonnet fills, Opus composes.

**Key claims**:
- Haiku is the best hole CREATOR because it's fastest and most self-aware of limits
- Sonnet needs structural escape (not just convention) — PartialFill as first-class
- Opus should not do mechanical work — macro compositions or nothing
- Separate sparse trees per tier (projections of the same substrate)
- "Letters" are just rich residue — no new artifact type needed

**Weaknesses I see in my own proposal**:
- Separate sparse trees might be overengineered — maybe just routing tokens on the same tree
- I may be undervaluing Opus-created holes — "shotgun blast" was wrong but Opus DOES see structural patterns that produce many holes
- The PartialFill state might not need to be in YataState — it might just be "create new holes + Abandoned(reason)"

**Full document**: [tier_shaped_work_units.md](../../../.gemini/antigravity/brain/90cd3742-7165-4716-a731-fca8d3207e58/tier_shaped_work_units.md)

---

## Candidate 2: (awaiting next Opus session)

## Candidate 3: (awaiting final Opus session)

---

## Resolution
State: **Open** — awaiting 2 more candidates before user synthesis.
