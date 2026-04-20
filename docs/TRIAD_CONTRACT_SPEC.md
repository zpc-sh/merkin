# Triad Contract Spec (`v0.1`)

This document defines the machine contract that groups the three synchronized repos:

- `merkin` (store + drift surface)
- `mu` (execution/computation facility)
- `lang` (`mulsp` / `muyata` runtime wrappers)

The contract is emitted as JSON by:

```bash
moon run cmd/main -- daemon yata triad-contract ...
```

Automation helper:

```bash
make triad-contract-sync
```

Import-friendly MoonBit package:

- `zpc/merkin/triad`

Generated artifact:

- `_build/yata/triad/latest/triad-contract.json`

Compatibility mirror:

- `/.well-known/triad-contract.json`

## 1. Purpose

The triad contract pins repo state and drift posture in one record:

1. sparse-tree drift commitment rooted in `finger.plan.wasm`
2. pinned heads for Merkin/Mu/lang
3. byte-level branch hygiene (`U+200B`, `U+200C`, `U+FEFF`)
4. required Merkin wasm ABI exports for Mu/lang integration
5. deterministic contract seal

## 2. Canonical shape

Top-level fields:

- `kind`: `merkin.triad.contract`
- `version`: schema version (current: `v0.1`)
- `generated_at_utc`: RFC3339 emission time
- `ratio_loci`: contract family marker (`git-replacement`)
- `drift`: sparse drift/finger fields
- `repos`: `merkin`, `mu`, `lang` head + branch audit
- `refs_byte_clean`: true if no ghost bytes detected in pinned refs/branches
- `abi`: expected/provided/missing wasm exports + status
- `compatibility`: required surfaces and pinned minimum heads
- `seal`: deterministic hash over normalized contract material

## 3. Branch ghost-byte rules

Each repo includes:

- `branch_raw`
- `branch`
- `branch_raw_hex`
- `branch_byte_clean`
- `void_detected`
- `ghost.u200b`, `ghost.u200c`, `ghost.ufeff`

`void_detected` is `true` when a ghosted raw branch canonicalizes to `main`.

## 4. ABI requirements

Required Merkin wasm exports in `v0.1`:

- `plan_finger_wasm`
- `plan_drift_commitment`
- `triad_contract_wasm`

`abi.status`:

- `ok`: all required exports present
- `missing`: one or more required exports absent

## 5. Drift policy

Any change to:

- `finger.plan.wasm` emission semantics
- required wasm ABI exports
- branch hygiene handling
- compatibility version rules

must update triad contract generation and `.well-known` mirror policy in the same change.
