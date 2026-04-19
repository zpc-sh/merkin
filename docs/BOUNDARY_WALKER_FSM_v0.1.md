# Boundary Walker FSM v0.1

First bottom-up FSM for Merkin boundary establishment and boundary stigmergy emission.

Date baseline: `2026-04-18`.

## 1) Purpose

Walk Merkin boundary-relevant scalars, mark suspicious byte/control patterns, and emit deterministic stigmergy describing:

- what was inspected
- what was normalized/flagged
- boundary posture outcome
- who/what intelligence performed the walk

## 2) Implementation

Code:

- `model/boundary_fsm.mbt`

Tests:

- `model/boundary_fsm_test.mbt`

Core type:

- `BoundaryWalkerFsm`

Core lifecycle:

- `Idle -> Walking -> Marked -> Emitted` (with `Failed` reserved)

## 3) Detection Scope

Current detection marks:

- ghost bytes: `U+200B`, `U+200C`, `U+FEFF`
- bidi controls: `U+202A`, `U+202B`, `U+202C`, `U+202D`, `U+202E`, `U+2066`, `U+2067`, `U+2068`, `U+2069`
- ASCII controls (except `TAB`, `LF`, `CR`)

## 4) Boundary Posture Rules

Status mapping:

- `clean`: no suspicious controls found
- `attention`: ghost bytes present
- `containment`: bidi controls or disallowed ASCII controls present

## 5) Stigmergy Wire

`emit_stigmergy` emits deterministic wire with:

- actor identity (`actor_overlay`)
- boundary domain (`ratio_loci`)
- `boundary_cognitive=1`
- aggregate counters (`boundary_ghost_*`, `boundary_bidi_controls`, etc.)
- per-finding detail lines (field, canonical value, raw hex)
- `material_hash` for deterministic identity

This is designed to feed `.plan`/finger style boundary reporting without exposing raw session authority material.

## 6) Why This Is Bottom-Up

No top-down compiler watcher is required for this FSM:

- it walks concrete boundary surfaces directly
- emits machine-parseable marks
- can be composed into higher FSM lanes later

This preserves bottom-up execution while giving deterministic contract output for higher orchestration.

## 7) Next Integration Steps

1. attach walker to ingress points (`ratio`/`daemon yata` boundary paths)
2. map emitted counters into `finger.plan.wasm` posture lines
3. add policy mode control (`observe|sanitize|strict|quarantine`) to FSM config
4. stream findings into Yata contract-language profile as compiler gate inputs
