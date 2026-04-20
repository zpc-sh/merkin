# Yata Test Suites

## Current Suite Layout

- `model/yata_test.mbt`
  - lifecycle semantics
  - dependency/readiness behavior
  - graph topology and detachment analysis
- `model/yata_protocol_test.mbt`
  - `.plan` wire emission/parsing roundtrips
  - strict parser diagnostics for report metadata
  - git snapshot projection checks
- `model/yata_addressing_test.mbt`
  - `cog://`, `substrate://`, `cas://` parsing and canonicalization
  - strict query validation
  - context-relative address projection

## Fast Commands

- Full model verification:
  - `moon test model -v`
- Yata-focused verification:
  - `make test-yata`
- SAT/SMT offloaded proof attempt:
  - `make prove-offloaded`

## SAT/SMT Offload Marker

Packfile manifests can carry explicit solve-offload annotations:

- `solve_kind=smt`
- `sat_smt_offloaded=true`
- `solve_report_offloaded_to=<provider>`

`ContainerManifest::mark_sat_smt_offloaded(...)` sets these fields for export/import/merge transport.

## Proof Track (MoonBit Theorem Provers)

Planned next steps to move from strong tests to formal proofs:

1. Add `model/yata_proof.mbtp` with core predicates:
   - wire roundtrip stability
   - entry-count consistency
   - address canonicalization idempotence
2. Lift parser/address helpers to contract-bearing APIs (`proof_require` / `proof_ensure`) where invariants are stable.
3. Keep executable tests as regression guards while gradually replacing trusted assumptions with prover-backed lemmas.
