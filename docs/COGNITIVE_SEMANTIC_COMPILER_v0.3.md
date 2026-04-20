# Cognitive Semantic Compiler (v0.3-draft)

> Status: archived/de-scoped. This document is not part of the active implementation roadmap.

This document defines a `v0.3` cognitive semantic compiler for Merkin.

The goal is to stay ahead of active AI work by compiling runtime signals (compiler diagnostics, Yata state, delegation status, provenance, embeddings) into a deterministic semantic control plane.

## 1. Core idea

Treat the compiler as a **coordinator of finite state machines (FSMs)** walking the Merkin tree and Yata graph.

Each FSM has one role:

1. observe
2. contract
3. delegate
4. resolve
5. embed
6. lookahead

Together they form a closed loop:

`observe -> contract -> delegate -> resolve -> embed -> lookahead -> observe`

## 2. Why Merkin-native

- Merkin tree provides route-local context (path neighborhood + sparse/diff shape).
- Yata provides typed gaps and replay-safe ids (`hole_id`).
- `.plan` provides deterministic, timestamp-light exchange.
- Git envelope provides branch/head provenance where needed.

The compiler does not replace Yata; it compiles work into Yata and consumes Yata outcomes.

## 3. FSM roles

### 3.1 `ObserverFSM`

Purpose:
- ingest raw signals (compiler diagnostics, policy alerts, replay anomalies)
- normalize into semantic events

States:
- `Idle`
- `Observed`
- `Rejected` (malformed or unsafe input)

### 3.2 `ContractFSM`

Purpose:
- convert events into typed Yata contracts and confidence bounds
- attach deferral + callback contract metadata

States:
- `Unbounded`
- `BoundedImmediate`
- `BoundedDeferred`

### 3.3 `DelegateFSM`

Purpose:
- route bounded holes to agent providers (`jules-cli`, `jules-mcp`, future API providers)
- persist dispatch identity and handoff envelope

States:
- `Queued`
- `Dispatched`
- `RateLimited`
- `ProviderError`

### 3.4 `ResolveFSM`

Purpose:
- consume provider status and patch outcomes
- verify with compile/tests/policy gates
- seal/resolve/reopen hole

States:
- `Awaiting`
- `Verified`
- `Resolved`
- `Failed`
- `Reopened`

### 3.5 `EmbedFSM`

Purpose:
- generate micro-embeddings around active hole context
- keep them ephemeral and policy-bounded

States:
- `Staged`
- `Materialized`
- `Purged`

### 3.6 `LookaheadFSM`

Purpose:
- predict likely next failure/fix zones
- precompute local semantic context for upcoming agent operations

States:
- `Projected`
- `Warm`
- `Invalidated`

## 4. Compiler IR (`CognitiveSemanticIR v0.3`)

Canonical record shape:

```json
{
  "kind": "merkin.cognitive.ir.entry",
  "version": "0.3",
  "track": "program",
  "hole_id": "sha256:...",
  "anchor": "model/x.mbt:12:3",
  "diagnostic": { "...": "..." },
  "fsm": {
    "observer": { "role": "observe", "state": "Observed" },
    "contract": { "role": "contract", "state": "BoundedDeferred", "conf_floor": 70 },
    "delegate": { "role": "delegate", "state": "Dispatched", "provider": "jules-cli" },
    "resolve": { "role": "resolve", "state": "Awaiting" },
    "embed": { "role": "embed", "state": "Staged" },
    "lookahead": { "role": "lookahead", "state": "Projected" }
  },
  "callbacks": { "...": "..." },
  "deferral": { "...": "..." },
  "git": { "...": "..." },
  "merkin": {
    "route": ["model", "x.mbt"],
    "probabilistic": true
  }
}
```

## 5. Compilation passes

1. **Signal ingest**: parse diagnostics and produce normalized events.
2. **Yata lowering**: map events to holes/contracts + metadata envelopes.
3. **Delegation planning**: assign provider, callback contract, and dispatch queue.
4. **Resolution ingestion**: poll status, ingest patches/results, classify outcomes.
5. **Micro-embedding**: attach short-lived local context vectors.
6. **Lookahead projection**: pre-warm adjacent routes/symbol neighborhoods.
7. **Replay emit**: produce `.plan` + IR + FSM worklist.

## 6. Safety and policy bounds

- Deferral must be explicit (`deferral.deferred=true|false`).
- Callback channel/target must be explicit and auditable.
- Embeddings are ephemeral by default and must be purgeable.
- Branch/provenance data must include byte-level hygiene signals (ghost-byte detection).
- Provider failures must be representable as first-class FSM states, not silent retries.

## 7. Current `v0.3` implementation status in this repo

Implemented now:

- Moon diagnostics -> Yata holes + `.plan` + callback contracts.
- Provider-agnostic delegation hooks (`jules-cli`, `jules-mcp` wrapper mode, dry-run).
- Recursive round runner for delegate/poll/recompile loops.
- Prototype cognitive IR + FSM worklist emitter in `tools/cognitive-semantic-compile-v0_3.sh`.
- Optional one-shot distributed emission from the compiler via `--emit-distributed`.
- Distributed planning emitter in `tools/cognitive-distributed-plan-v0_3.sh` (manifest, shard assignments, queue plan, capacity model).

Not yet implemented:

- Native MoonBit runtime for compiler passes (current prototype is shell + jq).
- Learned lookahead ranking model (currently heuristic/procedural).
- Persistent embedding store with turn-bound purge ledger.

## 8. Versioning policy (`v0.3`)

- `v0.3.x`: additive fields only for IR/worklist.
- No semantic repurposing of existing FSM state names.
- Unknown fields should be ignored by readers; unknown required fields must fail strict readers.

## 9. Execution modes (`v0.3`)

The prototype compiler supports two explicit modes:

- `markup` (default): annotation/preparation only.
  - `delegate.state=Prepared`
  - `delegate.execution_enabled=false`
  - worklist queue is `prepare`
  - no dispatch-promotion from submit results
- `active`: provider-aware execution state.
  - promotes task files with `.dispatch` metadata when submit results exist
  - `delegate.state` and `resolve.state` may reflect provider status
  - worklist queue typically advances to `delegate` or `poll`

This keeps markup-first dogfooding safe while still allowing an execution-capable path when explicitly enabled.

## 10. Distributed expansion

For the full distributed compiler-network design and rollout model, see:

- `docs/COGNITIVE_SEMANTIC_COMPILER_DISTRIBUTED_v0.3.md`
- `docs/AI_PROVIDER_ADAPTER_CONTRACT_v0.3.md` (provider-neutral submit/status/cancel contract)
