# mu Runtime, Solve, and Procsi Specification (v0.4-draft)

This document is the canonical mu-facing specification for Merkin integration.

It consolidates the prior mu interface and generalized solve material into one primary contract and adds a formal procsi binary section specification for wasm artifacts.

Audience:

- mu runtime implementers
- FSM/control-plane implementers
- Merkin integrators who need the execution boundary, not just the substrate boundary

Companion code/doc references:

- `docs/MERKIN_SUBSTRATE_SPEC_v0.1.md`
- `docs/AI_SUBSTRATE_FINGERPRINTS_v0.2.md`
- `docs/MULSP_SPEC.md`
- `docs/MUYATA_SPEC.md`
- `docs/YATA_PLAN_SPEC.md`
- `docs/YATA_COGNITIVE_ENVELOPE_DESIGN.md`
- `docs/AI_PROVIDER_ADAPTER_CONTRACT_v0.3.md`
- `model/work_promise.mbt`
- `model/solve.mbt`

---

## 0. Design stance

Merkin should not be deeply involved in computing or compiling.

The intended split is:

- Merkin: structure, addressing, roots, envelopes, routing, Yata gaps, replay transport
- mu: execution, compilation, policy, config, memoization, solve dispatch, proof and artifact production
- FSM control plane: handle resolution, callback routing, pubsub, status transitions, external provider coordination

In other words:

- Merkin names and stores the problem
- mu performs or brokers the work
- FSMs resolve handles and move work across queues and subscriptions

This keeps Merkin small and keeps runtime behavior where it belongs.

---

## 1. Boundary contract

### 1.1 Merkin responsibilities

Merkin is responsible for:

- content addressing and stable hashing
- envelopes and policy references
- anchors and routing indexes
- `WorkPromise` identity for derived work
- Yata graph semantics and `.plan` transport

Merkin is not the compute runtime.

### 1.2 mu responsibilities

mu is responsible for:

- deterministic execution
- compilation and transform execution
- policy/config interpretation
- local and offloaded solve execution
- trace emission
- memoization and result publication
- proof generation and verification when enabled

mu may store state, execute code, and compute over its own artifacts.

### 1.3 FSM responsibilities

FSMs form the active control plane over mu solve units.

FSMs should own:

- handle creation and resolution
- queue transitions
- pubsub channel routing
- callback delivery
- provider submission and polling
- verification gating
- reopen, retry, and failure transitions

Merkin may observe and persist summaries of these flows, but the FSMs are the active machinery.

---

## 2. Core mu runtime interface

### 2.1 Core execution

A conformant mu runtime MUST provide:

- deterministic `apply_op`
- deterministic `run_program`
- lifecycle init/checkpoint/restore
- capability reporting
- trace mode control and draining
- incremental cache read/write

Core determinism rule:

- same `(initial_root, program_hash, config_hash)` must produce the same consensus-relevant result

External nondeterminism:

- must not affect consensus state transitions
- may appear in diagnostics only

### 2.2 Incremental execution

mu SHOULD expose:

- cache lookup by opaque Merkin-provided key
- commit of resolved results
- idempotent incremental resolution for same key and dependencies

Merkin owns key derivation. mu treats keys as opaque.

### 2.3 Tracing

mu MUST support:

- `None`
- `Summary`
- `Full`

Trace events SHOULD expose:

- operation id
- operation key
- input hash
- output hash
- logical time
- optional wall-clock diagnostics

### 2.4 Capability gating

Merkin and FSM layers MUST gate optional calls by mu capability reporting.

Core capability families:

- incremental execution
- tracing
- deterministic replay
- batch execution
- proof support
- solve/offload support
- semantic/embedding support
- cave materialization support

---

## 3. Generalized solve profile

### 3.1 Why generalized solve exists

mu should not have one orchestration model for embeddings, another for compile repair, another for SAT/SMT, and another for outsourcing.

Instead, all of these should be solve units.

Examples:

- embeddings
- compiler repair
- semantic extraction
- compression
- proof generation
- SAT/SMT formulation or execution
- outsourced coding work

### 3.2 Standard expectation surface

Every solve unit should have, at minimum:

- `offloaded_to`
- `status`
- `handler`

Recommended standard fields:

- `solve_id`
- `solve_kind`
- `offloaded_to`
- `status`
- `handler`
- `result_ref`
- `witness_ref`
- `detail`

### 3.3 Solve mode

Generalized solve reuses the same three execution modes already used by incremental embedding work:

- `Accumulate`
- `Offload`
- `Execute`

Meaning:

- `Accumulate`: queue only
- `Offload`: queue and dispatch to another handler or backend
- `Execute`: run in the current runtime boundary

### 3.4 Solve status

Canonical solve status vocabulary:

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

### 3.5 Solve handler

`handler` names the concrete execution surface.

Examples:

- `mu.local.compile`
- `mu.local.z3`
- `mu.local.compressor`
- `provider.codex`
- `provider.chatgpt`
- `provider.jules-cli`

### 3.6 Solve kind

Recommended initial kinds:

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

These are semantic classes, not implementation classes.

### 3.7 Relationship to `WorkPromise`

`WorkPromise` remains the stable Merkin substrate identity for deferred derived work.

Generalized solve sits above it as the richer operational layer.

Recommended mapping:

- `promise_id` -> `solve_id`
- `transform_id` -> solve transform family identity
- `policy_id` -> policy/config shaper of solve posture
- `result_hash` and `result_envelope_id` -> solve materialization anchors

Merkin keeps the identity.
mu and FSMs keep the active lifecycle.

### 3.8 Policy-emitted solve traits

Policy should emit traits over solve units instead of hard-coding routing into each producer.

Execution traits:

- `deterministic`
- `replayable`
- `idempotent`
- `ephemeral`
- `requires_verification`
- `requires_proof`

Routing traits:

- `may_offload`
- `preferred_surface`
- `preferred_tier`
- `preferred_lane`
- `fallback_handler`
- `max_parallelism`

Cognitive traits:

- `ambiguity`
- `decomposition_pressure`
- `symbolic_density`
- `context_span`
- `write_scope`
- `expected_artifact_shape`

Safety traits:

- `allow_network`
- `allow_mutation`
- `allow_external_tooling`
- `requires_human_review`
- `purge_after_turns`

---

## 4. FSM handle and pubsub model

### 4.1 Principle

FSMs should resolve handles and pubsub, not Merkin.

Merkin may store a reference to a handle or a compact solve summary, but handle resolution is runtime work.

### 4.2 Solve handle

A solve handle is the active control-plane locator for a solve unit.

Conceptual fields:

- `handle_id`
- `solve_id`
- `handler`
- `owner_fsm`
- `status_channel`
- `result_channel`
- `control_channel`
- `callback_uri`

### 4.3 Pubsub channels

Recommended channel families:

- `mu.solve.status`
- `mu.solve.result`
- `mu.solve.control`
- `mu.solve.verify`
- `mu.solve.retry`

Recommended partition keys:

- `solve_id`
- `handle_id`
- `policy_id`
- `locus`

### 4.4 FSM lane ownership

Recommended ownership split:

- `ObserverFSM`: ingest and normalize events
- `ContractFSM`: shape Yata contract and solve traits
- `DelegateFSM`: create/resolve handles and dispatch
- `ResolveFSM`: consume status and result channels
- `VerifyFSM`: run policy/compile/test/proof checks
- `EmbedFSM`: specialized solve family for embeddings
- `LookaheadFSM`: pre-shape likely future solve units

### 4.5 Callback semantics

Callbacks should be carried by solve handles and consumed by FSMs.

Callback fields SHOULD include:

- `target`
- `channel`
- `uri`
- `on_state`
- `idempotency_key`

This lets the runtime react to solver/provider output without reparsing natural language.

---

## 5. Procsi identity and cognitive envelope

### 5.1 Purpose

`procsi` is the mu-side execution identity and compile-context envelope carried with a wasm artifact.

Its job is to answer:

- what locus/project this artifact belongs to
- what tier or execution persona shaped it
- what semantic context it was compiled against
- which cognitive identity is being projected by the runtime

### 5.2 Relationship to cognitive envelopes

Merkin-level cognitive envelopes should remain lightweight and transport-oriented.

`procsi` is different:

- it is mu-side runtime identity
- it is compile-context identity
- it is wasm-carried execution metadata

So:

- Merkin may store summaries
- `.plan` may carry compact reports
- `procsi` is the heavier runtime identity capsule

### 5.3 AI identity stance

The complicated part is AI identity.

Recommended split:

- Merkin `.plan` and Yata metadata carry compact cognitive summaries
- `procsi` carries the runtime identity and context binding needed by mu/FSMs

For now, the minimally required identity is:

- locus
- project
- tier
- context hash

Future extensions may add:

- overlay
- family
- mode
- policy hash
- transform id
- module/build hash

### 5.4 AI substrate fingerprint v2

For `Genius Loci`, raw `tier/session` strings are not a sufficient identity contract.

Recommended direction:

- define a raw `AiSubstrateFingerprintV2`
- derive a stable `fingerprint_commitment`
- protect the raw fingerprint with `APP`
- carry only the commitment plus APP envelope in human-visible procsi carriers

Recommended raw fingerprint fields:

- `family`
- `surface`
- `overlay`
- `mode`
- `context_hash`
- optional `policy_hash`
- `capability_hash`
- `substrate_hash`
- `issuer`

Recommended APP carrier fields:

- `protocol`
- `audience`
- `ciphertext_ref`
- `ciphertext_hash`
- `masked_commitment`

This lets FSMs and mu verify an AI identity binding without forcing the full substrate fingerprint into human-facing text or binary inspection surfaces.

### 5.5 Genius procsi attestation

The runtime-facing contract for `Genius Loci` SHOULD be a compact attestation containing:

- optional `locus`
- `project`
- `ratio_loci`
- `session_surface`
- `fingerprint_commitment`
- APP envelope metadata

This is the preferred identity contract for `merkin genius ...` commands and future mu/FSM handle gating.

---

## 6. Formal wasm binary section specification

### 6.1 Section convention

mu procsi metadata is carried in wasm custom sections.

Conventions:

- custom section id is `0x00`
- section name is UTF-8
- integer fields are little-endian
- strings are UTF-8 bytes without terminating NUL

v0 sections defined here:

- `.mks` for mutable Merkin solve/runtime state cursor
- `.prc` for procsi compile/runtime identity envelope
- `.pr1` for APP-masked Genius procsi attestation

### 6.2 `.mks` section

Section id:

- `0x00`

Section name:

- `.mks`

Magic:

- `0x4D 0x4B 0x53 0x54`
- ASCII: `MKST`

Binary layout:

```text
[4]  magic      : bytes          "MKST"
[4]  cursor     : u32 LE         remaining runs
[4]  total      : u32 LE         original run count
[4]  n_items    : u32 LE         number of items

repeat n_items times:
  [4]  type_len : u32 LE
  [*]  type     : utf8
  [4]  arg_len  : u32 LE
  [*]  arg      : utf8
```

Semantics:

- `cursor` is the remaining execution cursor
- `total` is the original run budget or count
- each item is a pending or declared work item
- `type` identifies the item kind such as `merge_pr`, `answer_jules`, `repair`, `smt`
- `arg` names the target or principal argument

Recommended constraints:

- `cursor <= total`
- `type_len` and `arg_len` MUST exactly match byte lengths
- item order MUST be preserved

Recommended interpretation:

- `.mks` is operational state, not sealed identity
- if mutated, the containing artifact SHOULD be treated as a new content-addressed state

### 6.3 `.prc` section

Section id:

- `0x00`

Section name:

- `.prc`

Magic:

- `0x50 0x52 0x43 0x53`
- ASCII: `PRCS`

Binary layout:

```text
[4]  magic        : bytes          "PRCS"
[4]  locus_len    : u32 LE
[*]  locus        : utf8
[4]  project_len  : u32 LE
[*]  project      : utf8
[4]  tier_len     : u32 LE
[*]  tier         : utf8
[32] context_hash : bytes
```

Semantics:

- `locus` is the mu/merkin execution locus
- `project` is the project identity
- `tier` is the runtime execution tier or persona
- `context_hash` is the semantic compile-time context binding

`context_hash` SHOULD be the canonical semantic-context digest used by the mu compiler pipeline.

### 6.4 `.pr1` section

Section id:

- `0x00`

Section name:

- `.pr1`

Magic:

- `0x50 0x52 0x43 0x31`
- ASCII: `PRC1`

Binary layout:

```text
[4]  magic               : bytes          "PRC1"
[4]  locus_len           : u32 LE
[*]  locus               : utf8           optional; empty means unattached
[4]  project_len         : u32 LE
[*]  project             : utf8
[4]  ratio_loci_len      : u32 LE
[*]  ratio_loci          : utf8
[4]  session_surface_len : u32 LE
[*]  session_surface     : utf8
[32] fingerprint_commitment : bytes
[4]  app_protocol_len    : u32 LE
[*]  app_protocol        : utf8
[4]  app_audience_len    : u32 LE
[*]  app_audience        : utf8
[4]  app_ref_len         : u32 LE
[*]  app_ref             : utf8
[32] app_payload_hash    : bytes
[32] context_hash        : bytes
[32] policy_hash         : bytes
```

Semantics:

- `.pr1` is the preferred attested procsi carrier for `Genius Loci`
- raw AI substrate fingerprint material SHOULD NOT be embedded directly here
- `fingerprint_commitment` binds the APP-protected identity payload
- `app_*` fields locate and verify the APP-protected body
- `ratio_loci` binds the AI principal to the repository principal
- empty `locus` is valid for unattached or roaming Genius identity

### 6.5 Validation rules

For both sections:

- magic MUST match exactly
- length-prefixed strings MUST be valid UTF-8
- truncated payloads MUST fail validation
- trailing bytes SHOULD fail strict readers

For `.prc`:

- `locus`, `project`, and `tier` MUST be non-empty

For `.pr1`:

- `project`, `ratio_loci`, and `session_surface` MUST be non-empty
- `app_protocol`, `app_audience`, and `app_ref` MUST be non-empty
- `fingerprint_commitment`, `app_payload_hash`, `context_hash`, and `policy_hash` MUST be 32 bytes

For `.mks`:

- `n_items` MUST match the actual decoded count

### 6.6 Extension policy

Because v0 does not include an explicit version field, compatibility is defined by:

- section name
- magic
- exact field order

Future revisions SHOULD do one of:

1. add a new section name such as `.mks1` / `.prc1`
2. change magic and publish a new strict layout
3. introduce a trailing extension block only after a versioned transition

Do not silently repurpose existing v0 bytes.

### 6.7 Recommended v1 direction

When versioning is introduced, the first additional fields SHOULD be:

For `.mks`:

- `status`
- `handler`
- `offloaded_to`
- optional `result_ref`
- optional `witness_ref`

For `.prc`:

- `policy_hash`
- `transform_id`
- `overlay`
- `family`
- `mode`

That direction is now formalized more explicitly by `.pr1`, which is preferred for AI-attested `Genius Loci` runtime identity without changing Merkin’s role.

---

## 7. Interaction with `.plan`

`.plan` should remain compact.

Recommended split:

- `.plan` carries compact solve summary such as `solve_report_*`
- `.mks` carries operational solve cursor/work-item state
- `.prc` carries legacy sealed compile/runtime identity
- `.pr1` carries attested Genius procsi identity when AI identity must remain APP-masked

This prevents `.plan` from becoming the full runtime state dump.

---

## 8. Interaction with Yata

Yata remains the typed semantic frontier.

Generalized solve and procsi do not replace Yata.

Recommended mapping:

- Yata defines the gap
- mu/FSMs create solve units against that gap
- `.mks` and handles track active runtime posture
- `.prc` or `.pr1` bind execution identity and compile context
- `.plan` carries replay-safe summaries back into Merkin transport

One Yata hole may produce many solve units over time.

That is expected.

---

## 9. Interface Drift Surface (`finger.plan.wasm` first)

This repo SHOULD use `finger.plan.wasm` (compact `.plan` wire emitted from sparse Merkin tree posture) as the canonical machine drift surface.

Preferred layering:

- `finger.plan.wasm` exposes compact AI-facing posture + cross-repo drift commitment
- `.well-known` remains a compatibility mirror for existing external tooling
- `.pr1`, APP stores, and capability stores retain deeper runtime/auth material

Canonical producer surfaces:

- wasm export: `plan_finger_wasm(tokens_csv, peer_refs_csv)`
- daemon CLI: `moon run cmd/main -- daemon yata wasm-plan ...`

Compatibility mirrors:

- `/.well-known/mu-interface.json`
- `/.well-known/procsi-sections.json`
- `/.well-known/interface-drift-policy.md`

Required rule:

- any change to canonical mu contract, solve surface, procsi section layout, or drift policy MUST update the emitted `finger.plan.wasm` surface and any maintained `.well-known` mirrors in the same change

---

## 10. Compatibility policy

- additive fields and additive manifests are preferred
- do not silently repurpose binary bytes
- do not silently repurpose solve status names
- do not move active FSM concerns into Merkin substrate types unless strictly necessary

The default rule is:

- Merkin persists
- mu executes
- FSMs coordinate

---

## 11. Supersession note

This document is the canonical mu spec for this repo.

The following docs are now companion or historical decomposition docs:

- `docs/MU-INTERFACE-SPEC.md`
- `docs/MU_GENERALIZED_SOLVE_PROFILE.md`

They may remain useful for narrower discussion, but this document should be treated as the cohesive source of truth.
