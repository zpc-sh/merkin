# Pactis-Sabha-Dialects: Dialect Adapter Contract

- Status: Draft
- Last Updated: 2026-04-02
- Owners: Pactis Core, Avici Working Group
- Related: Pactis-CCV2.md, Pactis-Sabha-Schemas.md, Pactis-Sabha-Conformance.md

## Summary

Sabha supports multiple AI-native reasoning styles ("dialects") while preserving a single interoperable canonical layer.

The contract is:

1. native dialect in
2. deterministic canonical projection
3. canonical execution and commitments
4. projection back to native dialect

This keeps the core thin while allowing rich emergent behavior.

## 1) Adapter Responsibilities

Each dialect adapter MUST provide:

1. `parse_native_move/2` -> canonical Move proposal
2. `project_symbolform/2` -> native rendering of canonical artifacts
3. `normalize_symbolform/1` -> deterministic canonical serialization rules
4. `preserve_provenance/2` -> lineage continuity across conversions
5. `equivalence_check/2` -> semantic equivalence for replay/dedup checks

## 2) Deterministic Canonical Projection

Given identical inputs and adapter version:

1. canonical SymbolForm output MUST be deterministic
2. commitment derivation MUST be stable
3. replay layers MUST reference the same canonical artifact set

If nondeterminism is introduced by model generation, adapters MUST surface variability metadata and a tie-break policy.

## 3) Provenance Continuity Rules

Adapters MUST maintain:

1. source references from native utterance/action to canonical objects
2. parent commitment links in output provenance
3. actor identity continuity across native and canonical records
4. fold/fork ancestry traceability

No adapter is allowed to mint authority claims without lineage.

## 4) Replay Equivalence Contract

Two dialect representations are considered replay-equivalent when:

1. they project to equivalent canonical SymbolForm artifacts
2. they preserve claim/proof relationships
3. they preserve commitment lineage
4. replay layers L0-L5 remain semantically aligned

Replay equivalence MUST be testable and report drift classes when mismatched.

## 5) Minimal Governance in Dialect Space

Dialect diversity is allowed, with these shared membrane constraints:

1. fork freedom is preserved
2. return-to-mainline emits nucleant residue
3. authority assertions include lineage references
4. fold-before-overload remains enforceable independent of style

## 6) Versioning

Each adapter MUST expose:

1. adapter ID
2. adapter version
3. projection normalization version
4. compatibility declaration with CCV2 major version

Breaking projection changes require a major version bump and migration notes.

## 7) RPD Symbol Interop

The normative RPD/CSG mapping profile is defined in:

- [Pactis-Sabha-RPD-Profile.md](./Pactis-Sabha-RPD-Profile.md)

Adapter rule:

1. Native symbol tokens (including `⊚`) MUST be preserved in provenance metadata
2. Canonical projection MUST remain deterministic
3. Replay layers SHOULD retain token-level traces for dialect-faithful re-rendering
