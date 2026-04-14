# Merkin Documentation Index

This file is the top-level map for Merkin documentation.

## 1) Start here by intent

### I just want a simple Merkle-tree-like flow (lazy mode)

Use:

1. `hash/` for deterministic content hashes
2. `tree/` to ingest hash ids as leaves/routes
3. `tree::seal` to freeze an epoch root

Read first:

- `docs/LIBRARY_API_GUIDE.md` (section: **Lazy Merkle-like usage path**)
- `tree/tree.mbt`
- `tree/node.mbt`

### I need an operator CLI

Use:

- `cmd/main/main.mbt`
- `docs/DAEMON_CLI.md`
- `docs/YATA_MOON_JULES_PIPELINE.md`
- `docs/AI_PROVIDER_ADAPTER_CONTRACT_v0.3.md`
- `docs/COGNITIVE_SEMANTIC_COMPILER_v0.3.md`
- `docs/COGNITIVE_SEMANTIC_COMPILER_DISTRIBUTED_v0.3.md`

Actions include:

- OCI ingest + storage mode checks
- sparse view and diff workflows
- conversational host workflows
- Yata topology diagnostics (`--action yata-topology`)
- moon compiler bug ingestion into Yata + Jules tasks
- cognitive semantic compiler (`v0.3`) IR/FSM emission
- offload and typed-hole additive measurement emission

### I need protocol/spec contracts

Use:

- `docs/MERKIN_SUBSTRATE_SPEC_v0.1.md`
- `docs/MU-INTERFACE-SPEC.md`
- `docs/PACTIS_CONVERSATIONAL_API_SPEC.md`
- `docs/PACTIS_CONVERSATIONAL_OPENAPI.yaml`
- `docs/YATA_FRAMEWORK.md`
- `docs/AI_PROVIDER_ADAPTER_CONTRACT_v0.3.md`
- `docs/COGNITIVE_SEMANTIC_COMPILER_v0.3.md`
- `docs/COGNITIVE_SEMANTIC_COMPILER_DISTRIBUTED_v0.3.md`

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
