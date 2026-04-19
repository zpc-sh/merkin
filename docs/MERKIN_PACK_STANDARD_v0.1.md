# Merkin Pack Standard v0.1 (Current Design + Implementation State)

This document defines the current pack direction and separates implemented behavior from planned behavior.

Date baseline: `2026-04-18`.

## 1) Short Answer

- Merkin is **WASM-first** for machine drift exchange (`finger.plan.wasm` wire semantics).
- Repository pack/export via `ratio pack` is designed as `wasm|blob`, but serializer/build output is still scaffolded.
- Current repo config convention advertises `pack_format = "oci+wasm"` in bootstrap output.

## 2) Pack Types

## 2.1 Drift Pack (Implemented)

Primary machine drift surface:

- `finger.plan.wasm` compact plan wire (`api.plan_finger_wasm`)
- deterministic drift commitment (`api.plan_drift_commitment`)
- compact boundary posture lines (`boundary_mode`, `boundary_ghost_*`, `boundary_status`)

Used by:

- `daemon yata wasm-plan`
- triad coordination and compatibility checks

## 2.2 Triad Contract Pack (Implemented)

Structured JSON contract emitted by:

- `daemon yata triad-contract`
- `api.triad_contract_wasm`
- `triad.emit_contract`

Carries:

- drift commitment and finger plan hash
- repo pins (`merkin`, `mu`, `lang`)
- byte-level branch ghost audit (`U+200B`, `U+200C`, `U+FEFF`)
- wasm ABI expected/provided/missing status

## 2.3 Locus Tree Pack (Designed, Not Fully Wired)

Command surface exists:

- `ratio pack <locus> --format wasm|blob`

Current state:

- command prints intended execution plan
- serializer injection/output plumbing is pending

Design intent:

- `--format wasm`: portable wasm component containing sparse tree state + query exports
- `--format blob`: raw serialized tree state in OCI-addressed blob form

## 3) Canonical Position (v0.1)

For current cross-repo interoperability, treat these as canonical:

1. `finger.plan.wasm` drift wire
2. triad contract JSON

Treat `ratio pack` outputs as non-final until serializer wiring lands.

## 4) Compatibility Notes

- Consumers that need stable machine sync should bind to drift/triad surfaces now.
- Consumers needing full tree snapshot transport should treat `ratio pack` as roadmap/stub surface for the moment.

## 5) Security and Integrity Requirements

- Branch refs and pins should be treated as raw bytes during triad generation.
- Hidden-byte ghosts (`U+200B`, `U+200C`, `U+FEFF`) must fail byte-clean assumptions for sync trust.
- Any workflow that sees `main` with ghost bytes should not trust branch identity without canonical byte audit.

## 6) Related Sources

- `api/api.mbt`
- `cmd/main/main.mbt`
- `cmd/main/cli_commands.mbt`
- `docs/TRIAD_CONTRACT_SPEC.md`
- `docs/MU_RUNTIME_SPEC.md`
