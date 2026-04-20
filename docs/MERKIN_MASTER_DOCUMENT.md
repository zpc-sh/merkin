# Merkin Master Document (Current-State Reference)

This document is the cohesive "what Merkin does now" reference for contributors, operators, and integrators.

Date baseline: `2026-04-18`.

## 1) What Merkin Is

Merkin is a MoonBit substrate centered on:

- deterministic content hashing
- sparse/sealed Merkin tree indexing
- policy-gated replication/storage behavior
- daemon-facing operational APIs and CLI
- Yata graph semantics and drift artifacts
- AI provenance/attestation envelopes (APP + procsi)

## 2) Current Scope (Active vs De-scoped)

Active implementation scope (from `docs/ROADMAP_SCOPE.md`):

- deterministic hashing and tree sealing
- storage/policy/daemon integration
- Yata protocol/addressing and regression coverage
- compiler-diagnostics -> Yata/Jules swap-in pipeline

De-scoped from active implementation:

- Merkle-style expansion beyond current tree sealing behavior
- FSM-based cognitive compiler orchestration
- distributed planner implementation roadmap

## 3) Surface Map (What Exists Today)

## 3.1 Library packages

- `hash/`: deterministic hash identities (`Hash::of_bytes`, `Hash::semantic`)
- `bloom/`: bloom sketch (`add`, `maybe_contains`, `merge`, `rebuild`)
- `tree/`: Merkin tree ingest, sparse projection, sealing, diff
- `model/`: envelopes, anchors, session identity, Yata graph/protocol
- `store/`: in-memory stores for artifacts/envelopes/anchors
- `storage/`: replication policy, idempotency ledger, queue, OCI adapters, app envelope file store
- `daemon/`: daemon node modes, OCI ingest behavior, sparse/diff routing, conversation host
- `triad/`: typed wrapper for triad contract and ABI/drift checks
- `api/`: wasm-friendly surface for bloom/tree/finger.plan/triad contract generation

## 3.2 CLI surfaces

CLI is split into three practical surfaces:

- `ratio` (repo/root principal)
- `genius` (AI inhabitation principal)
- `daemon` (operational runtime and diagnostics)

### Ratio commands

- `ratio init`
- `ratio loci new|ls|graph`
- `ratio app put|inspect|emit-pr1|parse-pr1`
- `ratio status`
- `ratio pack`

### Genius commands

- `genius enter`
- `genius sign`
- `genius trail`
- `genius where`
- `genius residue`

Default behavior: procsi attestation is required unless `--bootstrap-genius` is used.

### Daemon commands

Categorical form:

`moon run cmd/main -- daemon <category> <command> [flags]`

Categories:

- `oci`: `capabilities`, `put`
- `tree`: `sparse`, `diff`
- `conv`: `turn`, `replay`, `embed`, `embed-purge`
- `yata`: `topology`, `wasm-plan`, `triad-contract`
- `cognitive`: bridge-only command emitters (`compile`, `distributed`, `measure`)
- `adapter`: bridge-only command emitter (`validate`)

Legacy `--action` form is still supported.

## 3.3 WASM/API surface

`api/api.mbt` and `wasm_entry/entry.mbt` expose:

- bloom add/check/serialize/popcount
- tree ingest/sparse/seal/epoch/node_count
- drift wire and commitment (`plan_finger_wasm`, `plan_drift_commitment`)
- triad contract and ABI status (`triad_contract_wasm`, `triad_abi_status`)
- reset/hash helpers

## 4) Implemented vs Scaffolded Reality

Implemented and usable now:

- hash/bloom/tree core primitives
- tree sparse and diff semantics
- daemon receiver/proxy/passthrough/hybrid OCI-mode behavior
- replication policy + idempotency + queue state checks
- conversation turn/replay + embedding metadata timeline/purge
- Yata topology diagnostics
- `finger.plan.wasm` wire and drift commitment generation
- `finger.plan.wasm` boundary posture signaling (`boundary_*`, `boundary_status`)
- triad contract JSON with branch-byte ghost audit (`U+200B`, `U+200C`, `U+FEFF`)
- APP envelope file-store + `.pr1` emit/parse flow

Present but intentionally bridge-only:

- `daemon cognitive *`
- `daemon adapter validate`

These currently emit `bridge_command=...` and do not execute the external tool directly.

Scaffolded placeholders (not fully wired):

- filesystem scans for some Ratio/Genius views (`loci ls`, `where`, `trail`, `residue`, `status`)
- `ratio pack` serializer/output paths (prints intended flow)
- composition primitives rollout (`consume|union|atop|subtraction`) as next-version contract work

## 5) Security/Integrity Semantics in Current Code

- Procsi/APP attestation path is enforced for `genius` commands unless bootstrap mode is requested.
- Triad contract generation includes branch ghost-byte audit and `void_detected` semantics for disguised `main`.
- Idempotency ledger and queue stats feed replication policy dispatch checks.

## 6) Data and Artifact Surfaces

Repository/runtime artifacts include:

- `.merkin/store/...` for local store conventions
- app envelope store at `--store/app` (default `.merkin/store/app`)
- drift/contract artifacts via daemon Yata actions and helper scripts:
  - `tools/yata-wasm-plan-drift-sync.sh`
  - `tools/yata-triad-contract-sync.sh`
- `.well-known/*` contract and drift policy files as public machine surface

## 7) Testing and Release Gates

Current verification surfaces:

- package tests across `hash`, `bloom`, `tree`, `model`, `store`, `storage`, `daemon`, `gaussian`, `conformance`
- conformance profile tests and conformance benchmarks

Primary commands:

```bash
moon test
moon bench -p zpc/merkin/conformance
moon bench
```

See also:

- `docs/TESTING_AND_BENCHMARKING.md`
- `docs/FIRST_RELEASE_READINESS.md`
- `docs/YATA_RELEASE_CHECKLIST.md`

## 8) Recommended Read Order

1. `docs/MERKIN_USER_MANUAL.md`
2. `docs/MERKIN_PACK_STANDARD_v0.1.md`
3. `docs/GIT_GHOST_HARDENING_RUNBOOK.md`
4. `docs/RATIO_BOUNDARY_SHIM_SPEC_v0.1.md`
5. `docs/MERKIN_COMPOSITION_PRIMITIVES_v0.1.md`
6. `docs/MERKIN_API_REFERENCE_v0.1.md`
7. `docs/LIBRARY_API_GUIDE.md`
8. `docs/DAEMON_CLI.md`
9. `docs/YATA_FRAMEWORK.md`
10. `docs/MERKIN_SUBSTRATE_SPEC_v0.1.md`
11. `docs/MU_RUNTIME_SPEC.md`

## 9) Source-of-Truth Policy

When docs conflict, trust in this order:

1. implementation (`cmd/main/*.mbt`, `daemon/*.mbt`, `api/*.mbt`, `storage/*.mbt`)
2. this master document
3. specialized spec docs
4. historical/de-scoped docs
