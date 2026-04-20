# Pactis-Sabha-Conformance: Test and Conformance Plan

- Status: Draft
- Last Updated: 2026-04-02
- Owners: Pactis Core, Avici Working Group
- Related: Pactis-CCV2.md, Pactis-Sabha-Schemas.md, Pactis-Sabha-Operations.md, Pactis-Sabha-Dialects.md

## Summary

This document defines conformance checks for Conversational Computing v2 (Sabha profile).

## 1) Commitment Determinism

Goal:

- committed objects produce stable commitment hashes under fixed algorithm and canonical form

Required tests:

1. Node/Region/Branch/FoldHandle/Archive commitment vector tests
2. SemanticNucleant/Crystal commitment vector tests
3. Merkle-style aggregate commitment tests for composed objects

Pass condition:

- same canonical input + algorithm + adapter version => same commitment hash

## 2) Move State-Machine Integrity

Goal:

- move execution preserves valid state transitions and lineage

Required tests:

1. move transition legality tests for all move types
2. fold/unfold integrity tests (folded content recoverable by selector)
3. archive/rehydrate integrity tests (state continuity from snapshot)
4. prune residue preservation tests when `emit_residue=true`

Pass condition:

- no illegal transition accepted; all accepted transitions preserve provenance and commitments

## 3) Replay Layer Correctness (L0-L5)

Goal:

- replay layers remain aligned with canonical artifacts

Required tests:

1. L0 summary is derivable from canonical artifact set
2. L1 key claims match claim graph subset
3. L2 event trace maps to move log order
4. L3 graph references resolve
5. L4 excerpt references resolve to stored source windows
6. L5 transcript references are complete and retrievable

Pass condition:

- all replay layers can be verified against canonical commitments and provenance

## 4) Archive/Restart Invariance

Goal:

- seeded restart remains policy-deterministic

Required tests:

1. same seeds + same policy + same adapter versions => equivalent reachable commitments
2. threshold-triggered archive produces reproducible policy snapshots
3. restart from selected nucleants/crystals preserves lineage continuity

Pass condition:

- equivalent runs produce equivalent commitment classes and no lineage gaps

## 5) Dialect Conformance

Goal:

- dialect adapters preserve interoperability and deterministic projection

Required tests:

1. native dialect input -> canonical projection determinism
2. canonical artifacts -> native projection round-trip checks
3. replay equivalence across at least two dialect adapters
4. equivalence drift reporting with explicit mismatch classes

Pass condition:

- adapter outputs satisfy deterministic projection requirements and replay equivalence thresholds

## 6) Operational SLO Conformance (Recommended)

Goal:

- archive policy and traversal budget controls protect live sessions

Recommended checks:

1. threshold triggers under overload (branch/entropy/pressure/cost/fold-density/latency)
2. degraded mode behavior maintains move acceptance and lineage logging
3. overlay generation remains bounded and non-canonical

## 7) Reporting Format

Conformance reports SHOULD include:

1. spec version and adapter versions
2. commitment algorithm versions
3. policy snapshot
4. pass/fail per suite and per invariant
5. reproducibility metadata (seeds, run IDs, timestamps)
