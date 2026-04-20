# Pactis-Sabha-RPD-Profile: RPD/CSG Symbol Grammar Profile

- Status: Draft
- Last Updated: 2026-04-02
- Owners: Pactis Core, Avici Working Group
- Related: Pactis-CCV2.md, Pactis-Sabha-Schemas.md, Pactis-Sabha-Operations.md, Pactis-Sabha-Dialects.md

## Summary

This document defines the Saba/Sabha RPD grammar profile used by CCV2 dialect adapters.

It aligns with RPD and Crystal State Grammar (CSG) and adds one Saba-native extension token:

- `⊚` (terminal branch fold)

## Canonical State Model

CSG state is represented as:

- `M·C·P·E` (Materialization · Computation · Provenance · Embedding)

### Materialization Axis (M)

- `⊕` expanded
- `⊖` folded
- `⊗` omitted
- `⊘` absent
- `⊙` NOOP stub
- `⊖ₗ` lazy

### Computation Axis (C)

- `∅` static
- `⊛` generating
- `⊜` pending external computation
- `⊝` resolved external computation

### Provenance Axis (P)

- `⊟` pristine
- `⊞` accumulated transformation chain

### Embedding Axis (E)

- `⊠` unembedded
- `⊡` embedded
- `⊞ₑ` stale embedding

## Composite Examples

- `⊕∅⊟⊠` expanded/static/pristine/unembedded
- `⊕∅⊞⊡` expanded/static/accumulated/embedded
- `⊖∅⊞⊠` folded/static/accumulated/unembedded
- `⊙∅⊟⊠` NOOP stub
- `⊖ₗ∅⊟⊠` lazy generator defined

## Transition Semantics (Profile Core)

Materialization:

- `⊙ -> ⊕` NOOP fulfilled
- `⊙ -> ⊖ₗ` NOOP becomes lazy
- `⊖ₗ -> ⊕` lazy materialized
- `⊖ₗ -> ⊖` lazy resolved to pointer
- `⊖ -> ⊕` folded expanded
- `⊕ -> ⊖` expanded folded
- `⊕ -> ⊗` expanded omitted
- `⊗ -> ⊕` omitted included

Computation:

- `∅ -> ⊛` local generation start
- `⊛ -> ∅` local generation complete
- `∅ -> ⊜` sent external
- `⊜ -> ⊝` resolved external
- `⊝ -> ∅` integrated

Provenance:

- `⊟ -> ⊞` first transformation
- `⊞ -> ⊞` additional transformations

Embedding:

- `⊠ -> ⊡` embedding generated
- `⊡ -> ⊞ₑ` embedding stale
- `⊞ₑ -> ⊡` embedding regenerated

## Saba Extension Token

### `⊚` Terminal Fold (Saba extension)

`⊚` marks a branch/region as folded and semantically complete for current discourse intent.

Canonical mapping:

1. Emit `Move.type=fold`
2. Payload:
   - `mode=fold_down`
   - `terminal=true`
   - `target_ref=BranchId|RegionId`
3. Result:
   - create `FoldHandle`
   - set branch/region status to `folded`
   - optionally emit `SemanticNucleant` on return to mainline
4. CSG projection:
   - default `⊖∅⊞⊠` (if provenance exists)
   - fallback `⊖∅⊟⊠` (if pristine)

Interpretation:

- `⊖` alone can mean generic compression.
- `⊚` explicitly means "this side debate is folded and finished for now."

## Move Interop Table

- `⊕ -> ⊖` => `fold`
- `⊖ -> ⊕` => `unfold`
- `⊙ -> ⊕` => `assert` (fulfillment)
- `⊙ -> ⊖ₗ` => `reframe` or `crystallize` (generator-oriented, implementation-specific)
- `∅ -> ⊜ -> ⊝ -> ∅` => `crystallize` / external compute round-trip
- `⊕ -> ⊗` => `prune` with omission reason
- `⊗ -> ⊕` => `rehydrate` or `unfold` (policy-dependent)
- `⊚` => terminal `fold` + optional nucleant-on-return

## Serialization Guidance

1. Store `csg_state` as compact symbol string (for example `⊕∅⊞⊡`).
2. Preserve native token traces (`⊚`, etc.) in move dialect metadata.
3. Keep SymbolForm canonical for truth-bearing semantics.
4. Treat token rendering as dialect projection, not canonical truth.

## Conformance Additions

1. Adapter tests MUST verify deterministic mapping from token strings to canonical moves.
2. Replay tests MUST preserve `⊚` terminal-fold semantics across round-trips.
3. CSG transition validity checks MUST reject invalid combinations.
