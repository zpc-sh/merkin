# Cognitive Semantic Compiler Distributed Network (v0.3-draft)

> Status: archived/de-scoped. This document is not part of the active implementation roadmap.

This document expands `v0.3` into a distributed compiler network for large-scale, recursive AI-assisted maintenance.

It is designed to keep cognitive compilation feasible when total work includes both:

1. near-instant micro-embedding preparation
2. heavy deferred delegation, resolution, and replay processing

## 1. Design stance

The network has two explicit execution stances:

- `markup` (default): compile and route intent only, no required remote execution side effects
- `active`: consume provider dispatch/status and advance runtime queues

In both stances, artifacts remain deterministic and replayable.

## 2. Why distributed is necessary

At scale, monolithic compilation fails on three dimensions:

- throughput: diagnostics + deferrals + status polling fan out faster than one process can maintain
- latency: micro-embedding context wants sub-second locality while provider resolution can be minutes/hours
- fault isolation: provider outages or queue spikes should degrade one lane, not the full compiler

## 3. Network topology

Separate control-plane and data-plane responsibilities.

### 3.1 Control-plane (deterministic)

- ingest diagnostics and Yata signals
- normalize into `CognitiveSemanticIR`
- produce queue/work assignment contracts
- maintain replay ledger and provenance envelope

### 3.2 Data-plane (elastic)

- execute lane workers over deterministic assignments
- run provider adapters (Jules now, multi-provider later)
- run verify/resolve gates
- run embed/lookahead workers with strict policy budgets

## 4. Worker roles (FSM-aligned)

Every role maps directly to one or more FSM edges:

- `observer-gateway`: source ingestion and normalization
- `contractor`: contract shaping and confidence bounds
- `scheduler`: deterministic shard/lane assignment
- `delegate-router`: provider dispatch control
- `resolve-poller`: status ingestion and closure transitions
- `embed-hot`: micro-embedding generation and eviction
- `lookahead-warm`: probable next-zone preparation

## 5. Queue lanes

A lane is a network-level specialization of a worklist queue.

- `prepare` -> `contract-prep`
- `delegate` -> `delegate-control`
- `poll` -> `resolve-poll`
- `verify` -> `resolve-verify`
- `repair` -> `repair-loop`

Lane separation enables independent scaling and backpressure.

## 6. Deterministic sharding contract

Given `hole_id`, shard assignment is deterministic:

1. compute stable hash over `hole_id`
2. assign `index = hash % shard_count`
3. route to `shard-(index+1)`

Properties:

- no coordinator lock required for routing decisions
- replay produces identical placement
- safe handoff across processes and regions

## 7. Replica policy

`v0.3` default policy:

- base replica factor: `2`
- elevated replica factor for `repair` and `verify`: `base + 1`

Rationale:

- repair/verify are high-value correctness paths and benefit from extra redundancy
- prepare/poll lanes usually optimize for cost and do not require higher replication by default

## 8. Embedding strategy split

### 8.1 Hot micro-embeddings

- generated adjacent to active routes
- small token budgets
- short TTL and aggressive purge
- intended for immediate compiler/agent decisions

### 8.2 Deferred semantic batches

- larger contextual procedures can run asynchronously
- may include symbol-neighborhood snapshots and prior hole history
- emitted as references, not always inline payloads

Policy baseline:

- embeddings are ephemeral unless explicitly promoted by policy
- all embedding emissions must be traceable to `hole_id` and queue transition

## 9. Callback and deferral contract

Distributed operation requires callback metadata to be first-class.

Each task should carry:

- `deferral.deferred`
- `deferral.strategy`
- `resolution.on_state`
- `resolution.callback.target/channel/uri`

This allows external resolution routers to update hole state without parsing natural-language prompts.

## 10. Consistency and replay

### 10.1 Event discipline

Prefer append-only event streams over mutable in-place state.

### 10.2 Idempotency keys

Use `hole_id` and dispatch/session ids as idempotency keys for:

- provider submit
- status ingest
- closure transitions

### 10.3 Replay safety

- same input diagnostics + same plan metadata => same IR + same shard/lane assignments
- unknown fields are tolerated by readers unless explicitly required

## 11. Fault model

Handle faults at lane granularity.

- provider outage: isolate to `delegate-control` + `resolve-poll`
- embedding pressure: throttle `embed-hot` first before contract/resolve lanes
- ghost-branch provenance anomalies: mark and continue with canonical branch fields

`v0.3` already carries byte-level branch hygiene fields to reduce provenance ambiguity.

## 12. Backpressure policy

Key control variable: `max_inflight_per_shard`.

When shard saturation exceeds threshold:

1. slow `delegate-control` enqueue
2. continue `prepare` with lowered embedding budgets
3. prioritize `repair` and `verify` lanes
4. optionally spill low-priority work to deferred batch windows

## 13. Multi-provider trajectory

Provider integration is intentionally adapter-based.

Current:

- Jules CLI (`jules-cli`)
- Jules MCP wrapper mode (`jules-mcp` via BYO command)
- dry-run mode

Near-term:

- additional adapters can expose same submit/status contracts
- scheduler stays provider-agnostic; provider selected per lane/task policy
- shared adapter envelope is documented in `docs/AI_PROVIDER_ADAPTER_CONTRACT_v0.3.md`

## 14. Recursive operation model

The network is recursive by construction:

1. compile diagnostics into holes/contracts
2. dispatch selected work
3. ingest status/patch outcomes
4. run compile + verify
5. recompile into next-round IR/worklist

This loop continues until no unresolved error groups remain or policy halts.

## 15. Capacity planning heuristics (`v0.3` draft)

Use these as initial heuristics, not hard guarantees:

- shard count: `max(8, ceil(open_holes / 50))`
- base worker pools:
  - prepare-contract: `2`
  - delegate-router: `1` in markup, `2` in active
  - resolve-poller: `1` in markup, `3` in active
  - embed-hot: `2`
- increase shards when `max_shard_load / max_inflight_per_shard > 0.8`

## 16. Implementation in this repo

### 16.1 Compiler emitter

- `tools/cognitive-semantic-compile-v0_3.sh`
- emits IR/worklist/registry + mode-aware summaries

### 16.2 Distributed planner

- `tools/cognitive-distributed-plan-v0_3.sh`
- consumes compiler summary/IR/worklist and emits:
  - `cognitive_distributed_manifest.v0_3.json`
  - `cognitive_distributed_assignments.v0_3.ndjson`
  - `cognitive_distributed_queue_plan.v0_3.ndjson`
  - `cognitive_distributed_capacity.v0_3.json`

### 16.3 Offload + additive measurements

- `tools/cognitive-offload-measure-v0_3.sh`
- emits typed-hole additive metrics and offload estimates from compiler summaries

Example:

```bash
tools/cognitive-semantic-compile-v0_3.sh \
  --skip-pipeline \
  --mode markup \
  --pipeline-out-dir _build/yata/moon-build/latest \
  --out-dir _build/cognitive/v0.3/markup-check

tools/cognitive-distributed-plan-v0_3.sh \
  --compiler-out-dir _build/cognitive/v0.3/markup-check \
  --shards 12 \
  --replicas 2 \
  --max-inflight-per-shard 32
```

Single-command variant:

```bash
tools/cognitive-semantic-compile-v0_3.sh \
  --skip-pipeline \
  --mode markup \
  --pipeline-out-dir _build/yata/moon-build/latest \
  --out-dir _build/cognitive/v0.3/markup-check \
  --emit-distributed \
  --distributed-shards 12 \
  --distributed-replicas 2 \
  --distributed-max-inflight-per-shard 32
```

## 17. Rollout phases

1. Phase A: markup-only distributed planning with replay checks.
2. Phase B: active delegate/poll lanes with strict throttles.
3. Phase C: verify/repair promotion and confidence-gated auto-resolve.
4. Phase D: adaptive lookahead + policy-driven multi-provider routing.

## 18. Open questions

- Should lookahead scoring remain heuristic or use a learned model in `v0.4`?
- Should embedding promotion to durable storage be per-lane or per-project policy?
- How should economic budgets (token/cost/time) be represented in IR contracts?
