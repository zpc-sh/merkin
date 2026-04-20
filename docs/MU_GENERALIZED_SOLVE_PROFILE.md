# mu Generalized Solve Profile (v0.1-draft)

Canonical replacement:

- `docs/MU_RUNTIME_SPEC.md`

This document proposes a generalized `solve` construct for mu and Merkin.

Code sketch companion:

- `model/solve.mbt`

The intent is to lift a wide range of work into one standard shape instead of creating separate orchestration contracts for each domain.

Examples that should fit under the same umbrella:

- embedding creation
- compiler work
- compression and semantic extraction
- SAT/SMT solving
- outsourced code repair
- proof generation
- translation or synthesis passes

This is designed to fit Merkin's existing architecture:

- Yata remains the typed gap layer
- the cognitive compiler remains the coordinator
- mu remains the execution, memoization, policy, and offload facility

## 1. Recommendation

Treat "solving" as a first-class generalized construct in mu.

That means:

- a solve unit is the standard execution/offload object
- domain-specific tasks become parameterizations of the same construct
- policy emits traits over solve units
- routing, offload, replay, and status all operate on one shared contract

This extends the same pattern already present in the embedding profile, where work can be accumulated, offloaded, or executed, but generalizes it beyond embeddings.

## 2. Why this fits the current repo

The repo already has three pieces that want to snap together:

1. `WorkPromise` is already a generic identity for deferred derived work, keyed by `input_hash`, `transform_id`, and `policy_id`.
2. The mu interface already models one offload-capable domain in a general way through embedding jobs and `Accumulate | Offload | Execute`.
3. The cognitive compiler already separates contract shaping from delegation, polling, verification, and replay.

So the missing layer is not "another special job type."

The missing layer is a single generalized solve profile that all these workflows can share.

## 3. Core concept

A `solve` is any deterministic or policy-bounded attempt to transform an input view into:

- a result artifact
- a proof or witness
- a status transition
- or a compact negative result such as `unsat`, `infeasible`, or `blocked`

The generalized construct should not care whether the underlying engine is:

- local mu code
- a compiler worker
- a compression engine
- a SAT/SMT solver
- a coding agent
- an external provider

Those are handler choices, not type-system boundaries.

## 4. Standard expectation

Your minimal standard is exactly the right instinct.

Every solve unit should have a stable expectation surface including:

- `offloaded_to`
- `status`
- `handler`

Recommended expanded minimum:

- `solve_id`
- `solve_kind`
- `offloaded_to`
- `status`
- `handler`
- `result_ref`
- `witness_ref`
- `detail`

Interpretation:

- `solve_id`: stable identity for this solve attempt or contract
- `solve_kind`: what sort of solving this is
- `offloaded_to`: local runtime, tier, provider, queue lane, or external backend
- `status`: current lifecycle position
- `handler`: concrete runtime or adapter that is expected to act
- `result_ref`: optional artifact/result address
- `witness_ref`: optional proof/log/trace/reference
- `detail`: human-readable short explanation

## 5. Proposed generalized data model

### 5.1 Solve kinds

Recommended initial `solve_kind` values:

- `embed`
- `compile`
- `compress`
- `extract`
- `repair`
- `verify`
- `prove`
- `smt`
- `search`
- `translate`
- `synthesize`

These are routing hints, not separate subsystems.

### 5.2 Solve modes

Reuse the same three-mode shape already present in mu's embedding profile:

- `Accumulate`
- `Offload`
- `Execute`

Meaning:

- `Accumulate`: materialize intent and queue it, but do not dispatch
- `Offload`: queue and dispatch to selected handler/provider
- `Execute`: run immediately in the current runtime boundary

This is one of the strongest reasons to unify the model: the embedding profile already proved the mode vocabulary.

### 5.3 Solve status

Recommended status set:

- `Absent`
- `Promised`
- `Queued`
- `Running`
- `Blocked`
- `RateLimited`
- `Stale`
- `Materialized`
- `Verified`
- `Failed`
- `Purged`

Notes:

- `Materialized` means a result exists, not necessarily that it passed downstream checks.
- `Verified` means policy/verification gates accepted the result.
- `Purged` is useful for ephemeral solve products such as short-lived embeddings or transient search artifacts.

This lines up naturally with existing `WorkPromiseState` while giving the compiler and runtime a richer shared vocabulary.

### 5.4 Solve handler

`handler` should name the actual execution surface.

Examples:

- `mu.local.embed`
- `mu.local.compile`
- `mu.local.z3`
- `mu.local.compressor`
- `provider.codex`
- `provider.chatgpt`
- `provider.jules-cli`
- `provider.jules-mcp`

The important thing is that `handler` is concrete while `solve_kind` is semantic.

## 6. Proposed interface shape for mu

This is the generalized shape I would aim for conceptually:

```rust
enum SolveMode { Accumulate, Offload, Execute }

enum SolveStatus {
    Absent,
    Promised,
    Queued,
    Running,
    Blocked,
    RateLimited,
    Stale,
    Materialized,
    Verified,
    Failed,
    Purged,
}

struct SolveTraits {
    deterministic: bool,
    replayable: bool,
    idempotent: bool,
    ephemeral: bool,
    requires_verification: bool,
    requires_proof: bool,
    may_offload: bool,
    may_parallelize: bool,
    bounded_write_scope: bool,
}

struct SolveTicket {
    solve_id: [u8; 32],
    solve_kind: String,
    offloaded_to: String,
    status: SolveStatus,
    handler: String,
    result_ref: Option<[u8; 32]>,
    witness_ref: Option<[u8; 32]>,
    detail: Option<String>,
}

trait GeneralizedSolve<K, Payload> {
    fn submit_solve(
        &mut self,
        key: K,
        payload: Payload,
        mode: SolveMode,
        traits: SolveTraits,
    ) -> Result<SolveTicket, MuError>;

    fn poll_solve(&self, solve_id: [u8; 32]) -> Option<SolveTicket>;
    fn flush_solves(&mut self, limit: usize) -> Result<Vec<SolveTicket>, MuError>;
    fn cancel_solve(&mut self, solve_id: [u8; 32]) -> Result<SolveTicket, MuError>;
}
```

This should be understood as a profile direction, not a lockstep codegen requirement.

## 7. Relationship to `WorkPromise`

`WorkPromise` is already nearly the right substrate identity.

Recommended interpretation:

- `promise_id` becomes the stable parent identity of a solve contract
- `transform_id` identifies the solve transform family
- `policy_id` identifies the routing/config policy that shaped this solve
- `result_hash` and `result_envelope_id` remain the completion anchors

What is missing today is not identity.

What is missing is the richer solve lifecycle surface around that identity.

So I would not replace `WorkPromise`.
I would treat generalized solve as the operational/profile layer above it.

## 8. Policy-emitted traits

This is the most important part for your compiler story.

Some characteristics should not be hand-coded into every solve producer. They should be emitted by policy as traits.

Recommended trait families:

### 8.1 Execution traits

- `deterministic`
- `replayable`
- `idempotent`
- `ephemeral`
- `requires_verification`
- `requires_proof`

### 8.2 Routing traits

- `may_offload`
- `preferred_surface`
- `preferred_tier`
- `preferred_lane`
- `fallback_handler`
- `max_parallelism`

### 8.3 Cognitive traits

- `ambiguity`
- `decomposition_pressure`
- `symbolic_density`
- `context_span`
- `write_scope`
- `expected_artifact_shape`

### 8.4 Safety traits

- `allow_network`
- `allow_mutation`
- `allow_external_tooling`
- `requires_human_review`
- `purge_after_turns`

These are exactly the sorts of things the cognitive compiler should compute or attach, while mu/policy decides what they imply operationally.

## 9. ChatGPT/Codex and other handlers

Under this design, ChatGPT and Codex are just handlers or execution surfaces, not special-case top-level task categories.

That gives you a clean split:

- `solve_kind` says what kind of problem it is
- policy traits say what kind of cognition or execution it wants
- `handler` says who or what is actually acting on it

Examples:

### 9.1 Small compiler bug

- `solve_kind=repair`
- `preferred_surface=codex`
- `bounded_write_scope=true`
- `requires_verification=true`
- `handler=provider.codex`

### 9.2 SAT/SMT formulation

- `solve_kind=smt`
- `preferred_surface=chatgpt`
- `symbolic_density=high`
- `expected_artifact_shape=query`
- `handler=provider.chatgpt`

### 9.3 SAT/SMT execution

- `solve_kind=smt`
- `preferred_surface=mu-local`
- `deterministic=true`
- `requires_proof=false`
- `handler=mu.local.z3`

### 9.4 Semantic compression

- `solve_kind=compress`
- `preferred_surface=mu-local`
- `ephemeral=false`
- `requires_verification=true`
- `handler=mu.local.compressor`

So the generalized solve model gives you one envelope for all of these while still allowing routing differences.

## 10. Cognitive compiler integration

The cognitive compiler currently coordinates:

- observe
- contract
- delegate
- resolve
- embed
- lookahead

Generalized solve suggests a refinement:

- `embed` becomes one specialized solve family
- `delegate` becomes submission/routing of solve units
- `resolve` becomes polling, verification, and closure of solve units

This keeps the FSM model intact while reducing bespoke job types.

Recommended compiler responsibilities:

1. derive or lower a `solve_kind`
2. emit solve traits from diagnostics/context/policy
3. choose `mode`
4. choose handler or leave it to policy
5. attach callback and replay metadata
6. materialize `WorkPromise` + solve ticket linkage

## 11. Yata integration

Yata remains the semantic frontier.

The solve construct is what attempts to fill that frontier.

Recommended mapping:

- `YataHole.contract.expected_type` identifies the semantic target
- the compiler lowers one or more solve units against that hole
- solve outcomes produce candidates, witnesses, artifacts, or failure states
- resolution of the hole remains separate from the solve lifecycle

This matters because a hole may outlive many solve attempts.

One hole:

- may spawn multiple solve units
- may switch handlers over time
- may accumulate residues and failed attempts
- may still remain open even after several materialized but rejected outputs

That is exactly why solve should be generalized but still not be the same thing as the hole.

## 12. `.plan` and transport

Short term, I would not add a giant new wire format immediately.

Instead:

- keep `.plan` as the compact replay/handoff surface
- add solve summaries as optional report metadata
- keep detailed solve records artifact-local or task-local

Recommended future compact fields:

- `solve_report=1`
- `solve_report_kind=<text>`
- `solve_report_status=<text>`
- `solve_report_handler=<text>`
- `solve_report_offloaded_to=<text>`
- `solve_report_count=<uint>`

This mirrors what embedding reports already do well: compact transport summary, detailed local metadata elsewhere.

## 13. mu policy/config role

Since mu handles policy, config, and compiling, policy should be the layer that decides:

- whether a solve kind is permitted
- whether it may offload
- what handler class is eligible
- what tier/surface is preferred
- what verification gate is required
- what replay and purge requirements apply

In other words:

- Merkin names and routes the problem
- the cognitive compiler shapes the solve unit
- mu policy decides the operational posture
- the handler executes

## 14. Standard routing examples

### 14.1 Compiler maintenance

- parse diagnostics into Yata holes
- lower `repair` solve units
- prefer `provider.codex` when write scope is bounded
- require `verify` follow-up solve unit

### 14.2 SAT/SMT workflow

- lower `smt` formulation solve unit
- materialize query artifact
- execute solver as `mu.local.z3`
- lower interpretation solve unit if result requires explanation or next-step synthesis

### 14.3 Compression or semantic extraction

- lower `compress` or `extract` solve unit
- execute locally by default
- emit result artifact and optional witness

### 14.4 Outsourcing

- any solve kind with `may_offload=true` may use `Offload`
- `offloaded_to` records the selected provider/lane
- `handler` records the concrete execution surface
- replay remains stable because the contract and policy identities remain local

## 15. Migration path

### Phase 1

Treat this as a conceptual unification only:

- embeddings are solve units by convention
- compiler tasks are solve units by convention
- SAT/SMT and compression adopt the same naming and status fields in task-local metadata

### Phase 2

Add a mu generalized solve profile alongside existing embedding APIs.

At this stage, embeddings can become one specialization of generalized solve without breaking compatibility.

### Phase 3

Unify:

- embedding incremental jobs
- provider adapter tasks
- compiler offload records
- `WorkPromise`-backed derived work

under one common solve contract.

## 16. Bottom line

The right abstraction is not "offload coding differently from solving."

The right abstraction is:

- everything is a solve unit
- policy emits traits over solve units
- handlers differ
- Yata holes remain the semantic target
- mu owns execution/offload/config semantics

That gives you one standard expectation surface:

- `offloaded_to`
- `status`
- `handler`

while still allowing compile, embedding, compression, SAT/SMT, and outsourced coding to behave differently through policy and traits rather than through incompatible orchestration models.
