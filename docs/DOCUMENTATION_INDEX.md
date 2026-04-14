# Merkin Documentation Index

This file is the top-level map for Merkin documentation.

Active scope and de-scoped tracks: `docs/ROADMAP_SCOPE.md`.

## 1) Start here by intent

### I just want a simple tree-sealing flow (lazy mode)

Use:

1. `hash/` for deterministic content hashes
2. `tree/` to ingest hash ids as leaves/routes
3. `tree::seal` to freeze an epoch root

Read first:

- `docs/LIBRARY_API_GUIDE.md` (section: **Lazy tree usage path**)
- `tree/tree.mbt`
- `tree/node.mbt`

### I need an operator CLI

Use:

- `cmd/main/main.mbt`
- `docs/DAEMON_CLI.md`
- `docs/YATA_MOON_JULES_PIPELINE.md`
- `docs/AI_PROVIDER_ADAPTER_CONTRACT_v0.3.md`

Actions include:

- OCI ingest + storage mode checks
- sparse view and diff workflows
- conversational host workflows
- Yata topology diagnostics (`--action yata-topology`)
- moon compiler bug ingestion into Yata + Jules tasks
- WASM `finger.plan` emission for cross-repo drift coordination (`--action yata-wasm-plan`)
- triad contract emission for Merkin/Mu/lang coordination (`--action yata-triad-contract`)

### I need protocol/spec contracts

Use:

- `docs/MERKIN_SUBSTRATE_SPEC_v0.1.md`
- `docs/AI_SUBSTRATE_FINGERPRINTS_v0.2.md`
- `docs/MU_RUNTIME_SPEC.md`
- `docs/MULSP_SPEC.md`
- `docs/MU-INTERFACE-SPEC.md`
- `docs/MU_GENERALIZED_SOLVE_PROFILE.md`
- `docs/PACTIS_CONVERSATIONAL_API_SPEC.md`
- `docs/PACTIS_CONVERSATIONAL_OPENAPI.yaml`
- `docs/YATA_FRAMEWORK.md`
- `docs/MUYATA_SPEC.md`
- `docs/YATA_COGNITIVE_ENVELOPE_DESIGN.md`
- `docs/AI_PROVIDER_ADAPTER_CONTRACT_v0.3.md`
- `docs/TRIAD_CONTRACT_SPEC.md`

### I need to hand off compiler docs to the Mu language project

Use:

- `docs/MU_LANG_COMPILER_HANDOFF.md`
- `docs/MU_LANG_COMPILER_HANDOFF_MANIFEST.txt`
- `make mu-lang-handoff`

The generated transfer bundle lands at:

- `_build/handoff/mu-lang-compiler-docs/latest/merkin-mu-lang-compiler-docs.tar.gz`

---

## 2) Library package map

- `hash/` — digest primitives and keys
- `bloom/` — probabilistic routing sketches
- `gaussian/` — salience/priority fields
- `tree/` — node graph + sparse projection + diff
- `model/` — artifact/envelope/anchor/work + Yata models
- `store/` — basic in-memory artifact store
- `storage/` — policy, queue, OCI, union store
- `daemon/` — daemon runtime and conversation host
- `triad/` — import-friendly triad contract wrapper for Merkin/Mu/lang sync
- `conformance/` — core and optional profile tests/bench

---

## 3) API surfaces

### Library API (MoonBit imports)

- Most reusable APIs are exposed by package methods in:
  - `tree/*.mbt`
  - `model/*.mbt`
  - `storage/*.mbt`
  - `daemon/*.mbt`

Detailed examples: `docs/LIBRARY_API_GUIDE.md`.

### CLI API

- Entry command: `moon run cmd/main -- daemon --action <action>`
- Full command/flag reference: `docs/DAEMON_CLI.md`

---

## 4) Testing and release docs

- `docs/TESTING_AND_BENCHMARKING.md`
- `docs/FIRST_RELEASE_READINESS.md`
- `docs/YATA_RELEASE_CHECKLIST.md`

---

## 5) Drift Surface

- `finger.plan.wasm` (via `moon run cmd/main -- daemon yata wasm-plan ...`)
- `triad-contract.json` (via `moon run cmd/main -- daemon yata triad-contract ...`)
- `/.well-known/mu-interface.json`
- `/.well-known/procsi-sections.json`
- `/.well-known/interface-drift-policy.md`
- `/.well-known/triad-contract.json`
