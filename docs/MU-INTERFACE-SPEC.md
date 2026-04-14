# Merkin <-> mu Interface Specification (v0.2)

> Canonical replacement:
> `docs/MU_RUNTIME_SPEC.md` is now the primary cohesive mu specification.
>
> This document defines the executable interface Merkin expects from a mu runtime.
> It replaces legacy N-Merkle wording and is aligned with `MERKIN_SUBSTRATE_SPEC_v0.1.md`.
> **Audience:** mu runtime implementers.
>
> Related design note:
> `docs/MU_GENERALIZED_SOLVE_PROFILE.md` generalizes offload-capable work across embeddings, compile, SAT/SMT, compression, and outsourced solving.

---

## 0. Scope

Merkin is a structural substrate. It manages addressing, roots, envelopes, anchoring metadata, and routing indexes.
mu is the execution facility. It runs programs, memoizes results, emits traces, and optionally generates proofs.

Hard boundary:

```text
Merkin: structure, hashes, roots, envelopes, routing, anchoring references
mu:     execution, memoization, traces, embeddings, optional ZK proofs
```

---

## 1. Normative Language and Conformance Profiles

Terms:
- `MUST`: required for conformance to the named profile.
- `SHOULD`: strongly recommended.
- `MAY`: optional.

A runtime can be conformant to one or more profiles.

### 1.1 Core Profile (required)

A Core-conformant mu runtime MUST implement:
- deterministic `apply_op` and `run_program`
- incremental cache read/write primitives
- trace mode control and trace draining
- capability reporting
- lifecycle init/checkpoint/restore APIs

### 1.2 Optional Profiles

- `Semantic`: embeddings + cosine oracle + semantic header emission
- `Batch`: ordered batch execution
- `Proof`: execution proof generation and verification
- `Offload`: accumulate/offload/execute queue semantics
- `CaveMaterialization`: fixed-size cave + copy-on-write artifact emission

Merkin MUST gate every optional call by `mu.capabilities()`.

---

## 2. Core Execution Interface

### 2.1 `ExecutableFacility<State, Ops>`

```rust
pub trait ExecutableFacility<State, Ops> {
    type Error;
    type Proof;

    fn apply_op(&mut self, state: &mut State, op: Ops) -> Result<(), Self::Error>;
    fn run_program(&mut self, state: &mut State, program: Vec<Ops>) -> Result<(), Self::Error>;

    // Optional: required only when `zk_proving=true`.
    fn prove_execution(&self, state: &State, program: Vec<Ops>) -> Result<Self::Proof, Self::Error>;
    fn verify_execution(
        &self,
        state: &State,
        program: Vec<Ops>,
        proof: &Self::Proof,
    ) -> Result<bool, Self::Error>;
}
```

Core requirements:
- `apply_op` and `run_program` MUST be deterministic over `(initial_root, program_hash, config_hash)`.
- External nondeterminism (time, RNG, network) MUST NOT influence consensus state transitions.
- Deterministic internal memoization/checkpoint writes are allowed.
- If `zk_proving=false`, `prove_execution` and `verify_execution` MUST return `UnsupportedOperation`.

State semantics:
- `State` is a Merkin substrate snapshot containing active roots.
- mu MUST treat input state as immutable and transition through explicit operation application.

---

## 3. Incremental Execution and Memoization

### 3.1 `IncrementalExecution<K, Ops>`

```rust
pub trait IncrementalExecution<K, Ops> {
    type ResolutionResult;

    fn check_resolution_cache(&self, input_key: &K) -> Option<Self::ResolutionResult>;
    fn commit_resolution(&mut self, input_key: K, result: Self::ResolutionResult);
    fn resolve_incremental(&mut self, input_key: K, dependencies: Vec<Ops>) -> Self::ResolutionResult;
}
```

Requirements:
- Merkin owns key derivation. mu MUST treat keys as opaque.
- `resolve_incremental` MUST be idempotent for identical `(input_key, dependencies)`.
- Cache semantics SHOULD be append-only or copy-on-write.

Key generation (Merkin side):
- Baseline: `blake3(concat(dependency_roots))`
- Extended operation key profile (recommended):
  - `blake3(concat(dependency_roots, op_kind, model_id, model_version, params_hash, chunking_hash))`

---

## 4. Tracing Interface

### 4.1 `Traceable`

```rust
pub enum TraceMode { None, Summary, Full }

pub trait Traceable {
    type Event;
    fn set_trace_mode(&mut self, mode: TraceMode);
    fn drain_traces(&mut self) -> Vec<Self::Event>;
}
```

Requirements:
- mu MUST support `None`, `Summary`, and `Full` modes.
- `drain_traces` MUST flush accumulated events since last drain.
- `logical_time` MUST be deterministic and monotonic.
- `wall_clock_ns` MAY be emitted for diagnostics, but MUST be excluded from consensus/proof commitments.

Recommended event fields:

```text
TraceEvent {
    op_id: u64,
    op_name: &str,
    op_key: [u8; 32],
    input_hash: [u8; 32],
    output_hash: [u8; 32],
    logical_time: u64,
    wall_clock_ns: Option<u64>,
    subtree_root: Option<[u8; 32]>,
}
```

---

## 5. Semantic Profile (optional)

This profile is active only when `embedding_generation=true`.

Required APIs:

```text
mu.embed(content: Bytes) -> Vec<f32>
mu.embed_batch(contents: Vec<Bytes>) -> Vec<Vec<f32>>
mu.cosine_similarity(a: &[f32], b: &[f32]) -> f32
mu.emit_semantic_header(context: ExecutionContext) -> Vec<Symbol>
```

Requirements:
- Embedding dimension `d` MUST be fixed per runtime configuration and exposed at startup.
- `embed_batch` MUST be semantically equivalent to mapping `embed`.
- `cosine_similarity` result range MUST be `[0.0, 1.0]`.
- Semantic header discrimination is Merkin-side by length:
  - `len == 8` => `arbyte_grin`
  - else => `chain_coda`

### 5.1 Incremental Embedding Modes (optional)

```rust
enum EmbeddingMode { Accumulate, Offload, Execute }
enum EmbeddingJobStatus { Pending, Running, Materialized, Failed }

struct EmbeddingJobTicket {
    op_key: [u8; 32],
    status: EmbeddingJobStatus,
}

mu.embed_incremental(
    op_key: [u8; 32],
    content: Bytes,
    mode: EmbeddingMode,
) -> Result<EmbeddingJobTicket, MuError>

mu.poll_embedding_job(op_key: [u8; 32]) -> Option<EmbeddingJobTicket>
mu.flush_embedding_jobs(limit: usize) -> Result<Vec<EmbeddingJobTicket>, MuError>
```

Mode semantics:
- `Accumulate`: enqueue only.
- `Offload`: enqueue and dispatch to external backend.
- `Execute`: run locally and commit immediately.

---

## 6. Cave Materialization Profile (optional)

This profile is active only when `fixed_size_caves=true` and `copy_on_write_emission=true`.

Contract:
- Existing `.mu` artifact bytes are immutable.
- Cave regions are fixed-size per artifact instance.
- Overflow MUST emit a new copy-on-write artifact; previous artifact remains valid.

API:

```rust
struct CaveMaterializationResult {
    previous_artifact_root: [u8; 32],
    next_artifact_root: [u8; 32],
    emitted_path: String,
}

mu.materialize_embedding_cave(
    artifact_bytes: &[u8],
    op_keys: Vec<[u8; 32]>,
) -> Result<CaveMaterializationResult, MuError>
```

---

## 7. Proof Profile (optional)

This profile is active only when `zk_proving=true`.

Execution proof contract:
- mu MUST produce a proof proving `S0 --P--> S1`.
- mu MUST verify that proof without replaying full execution.

Proof structure requirements:
- `witness: Vec<u8>`
- `output_root: [u8; 32]`
- `proof_system: ProofSystemId`
- `initial_root: [u8; 32]`
- `program_hash: [u8; 32]`
- `transcript_hash: [u8; 32]`

Verification API (name normalized):

```text
mu.verify_execution(
    initial_state: &State,
    claimed_output_root: [u8; 32],
    proof: &ExecutionProof,
    program: Vec<Ops>,
) -> bool
```

Optional extensions:
- `aggregate_proofs(proofs: Vec<ExecutionProof>) -> ExecutionProof`
- `prove_incremental(cached_proof, delta_ops, delta_state) -> Result<ExecutionProof, ProofError>`

---

## 8. Batch Profile (optional)

Active when `batch_execution=true`.

API:

```text
mu.batch_execute(
    ops: Vec<(InputKey, Vec<Ops>)>
) -> Vec<(InputKey, ResolutionResult)>
```

Requirements:
- mu MAY execute independent items in parallel.
- mu MUST return outputs in input order.
- Duplicate keys in the same batch MUST produce identical results at each duplicate index.

---

## 9. Runtime Lifecycle

Initialization:

```text
mu.initialize(config: MuConfig) -> MuRuntime
```

`MuConfig` SHOULD expose:
- `embedding_dimension: usize`
- `proof_system: ProofSystemId`
- `cache_backend: CacheConfig`
- `trace_mode: TraceMode`
- `parallelism: usize`
- `max_context_vault_bytes: usize`
- `max_embedding_cave_bytes: usize`
- `copy_on_write_artifacts: bool`
- `offload_backend: Option<OffloadBackendConfig>`

Substrate view handoff:

```text
mu.receive_substrate_view(view: SubstrateView)
```

`SubstrateView` fields:
- `content_root: [u8; 32]`
- `semantic_root: [u8; 32]`
- `temporal_root: [u8; 32]`
- `era_root: [u8; 32]`
- `artifact_root: [u8; 32]`
- `block_height: u64`

Checkpoint/restore:

```text
mu.checkpoint() -> Vec<u8>
mu.restore(bytes: &[u8]) -> MuRuntime
```

---

## 10. Error Classification

```rust
enum MuError {
    ExecutionError(String),
    ProofGenerationFailed(String),
    CacheMiss,
    UnsupportedOperation(String),
    SubstrateViewStale,
    ResourceExhausted,
    DeterminismViolation(String),
    CaveCapacityExceeded,
    OffloadUnavailable(String),
    ModelDrift(String),
}
```

Requirements:
- Optional profile calls MUST return `UnsupportedOperation` when disabled.
- Offload failures MUST avoid partial commits.
- Determinism violations MUST be explicit and terminal for the current execution.

---

## 11. Capability Flags

```rust
struct MuCapabilities {
    // Core
    incremental_execution: bool,
    traceable: bool,
    deterministic_replay: bool,

    // Optional profiles
    zk_proving: bool,
    batch_execution: bool,
    embedding_generation: bool,
    embedding_incremental_modes: Vec<EmbeddingMode>,
    semantic_header_emission: bool,
    proof_aggregation: bool,
    incremental_proofs: bool,
    operation_keyed_execution: bool,
    fixed_size_caves: bool,
    copy_on_write_emission: bool,
    hardware_acceleration: Option<AcceleratorKind>,
}

enum AcceleratorKind { Cpu, Gpu(GpuBackend), Fpga }
enum GpuBackend { Cuda, Metal, Vulkan, WebGPU }
```

Merkin MUST degrade gracefully based on this struct.

---

## 12. MVP Implementation Order

1. `apply_op` and `run_program`
2. tracing (`set_trace_mode`, `drain_traces`)
3. cache primitives (`check_resolution_cache`, `commit_resolution`)
4. semantic profile (`embed`, `embed_batch`, `emit_semantic_header`) if semantic dimension is enabled
5. batch execution
6. proof profile (`prove_execution`, `verify_execution`) when `zk_proving` is enabled
7. cave materialization and offload queue modes
8. proof aggregation and incremental proof extensions

---

## 13. Minimum Conformance Tests

Core:
- Determinism test: same inputs produce same output root across two fresh processes.
- Cache test: duplicate key returns cached resolution without re-execution.
- Trace test: `logical_time` monotonic and reproducible for the same program.

Optional profiles:
- Cave overflow test: fixed cave triggers copy-on-write emission.
- Offload parity test: `Offload` output equals `Execute` output for same key/content.
- Proof round-trip test: `prove_execution` then `verify_execution` succeeds on fixtures.
- Batch order test: parallel execution still returns results in input order.

---

## 14. Terminology Migration

Legacy term `N-Merkle` in older docs maps to `Merkin` in this spec.
