# Interface Drift Policy

`finger.plan.wasm` is the primary machine drift surface.
This directory is the compatibility mirror for external tooling that still reads `.well-known`.

## Required updates

Update the emitted `finger.plan.wasm` surface (and relevant `.well-known` mirror file) in the same change when any of the following change:

- canonical mu interface ownership or execution boundary
- generalized solve surface
- procsi binary section layout
- genius procsi attestation or APP-masked fingerprint contract
- compatibility or versioning rules
- triad contract pinning (Merkin/Mu/lang heads) or required wasm ABI exports
- byte-level branch hygiene rules (`U+200B`, `U+200C`, `U+FEFF`)
- boundary shim filtering rules or boundary posture signaling fields in `finger.plan.wasm`

## Review heuristic

If code or docs affecting mu, solve, procsi, APP-masked fingerprinting, handler resolution, or callback/pubsub semantics changed but no `finger.plan.wasm` or mirror update is present, reviewers should assume interface drift may have gone untracked.

## Canonical files

- `mu-interface.json`
- `procsi-sections.json`
- `triad-contract.json`
- `sat-smt-offload.json`
- `boundary-shim.json`

These mirror files are intentionally small so they remain easy to diff.
