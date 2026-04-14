# Merkin Substrate v0.1 Spec
**Status:** build-now  
**Primary languages:** MoonBit (core/perf), Mu (policy/config/contracts/scripts)

---

## 0. Terms and invariants

### 0.1 Triad compatibility
- **Akash** = append-only MMR of hashes; no query beyond “does hash exist / proof”; timeless (sequence only).
- **Arbit** = infrastructure-applied metadata envelope (hashing, DAG updates, behavioral fingerprint extraction) invisible to AI.
- **Temporash** = composed query pattern combining temporal constraints + semantic constraints + existence proofs.

### 0.2 Self-supporting test (must hold)
- Semantic header is independently meaningful.
- Content hash is independently verifiable.
- Optional semantic hash verifies content+meaning.
- No AI behavior must change because this exists (stigmergy allowed).

### 0.3 Time model
- Core substrate ordering is **sequence and causality**, not wall-clock.
- Wall-clock time is an **external imprint** via Tempora/Temporash; stored as metadata and may be resolved lazily.

---

## 1. Canonical objects

### 1.1 Artifact (content-addressed bytes)
Represents immutable bytes (or chunk-addressed bytes).

**Fields**
- `content_hash: Hash` — hash of bytes (**blake3** for v0)
- `size_bytes: u64`
- `mime: String?`
- `payload_ref: PayloadRef` — pointer to storage backend (local, s3, ipfs, etc.)
- `chunking: Chunking?` — optional (chunk size, chunk hashes)

**Invariant**
- `content_hash = H(payload_bytes)` always.

---

### 1.2 Envelope (metadata + semantics + execution promises)
Infrastructure-applied record that attaches “meaning, policy, and state” to an Artifact.

**Fields**
- `envelope_id: Hash` — content-addressed id of this envelope record
- `artifact_hash: Hash` — references Artifact
- `semantic_header: [Symbol]` — raw ordered symbols only  
  - length = 8 → `arbyte_grin`  
  - length ≠ 8 → `chain_coda`
- `header_encoding: enum{arbyte_grin, chain_coda}`
- `semantic_hash: Hash?` — optional (see 2.2 Option C)
- `policy_ids: [Hash]` — references policy/config objects
- `lens_ids: [Hash]` — references isomorphic views (“lenses”)
- `states: EnvelopeState`
- `anchors: AnchorRefs` — references to Tempora/Akash anchoring records
- `provenance: Provenance` — optional (source ids, toolchain ids, node ids)
- `work_refs: [WorkRef]` — optional pointers to computed properties/results

**EnvelopeState**
- `freshness: enum{FRESH, DIRTY, DEFERRED, SEALED}`
- `semantic_committed: bool` (true if `semantic_hash` present and verified)

**Invariant**
- Envelope is immutable once `SEALED` (new metadata = new envelope).

---

### 1.3 Anchor (existence proof + optional time imprint)
Represents an anchoring action (Akash proof and/or Tempora imprint). Anchoring is allowed to be lazy.

**Fields**
- `anchor_id: Hash`
- `subject_hash: Hash` — usually `semantic_hash` preferred, else `content_hash` fallback
- `anchor_state: enum{UNANCHORED, PENDING, ANCHORED, FAILED}`
- `akash_leaf_index: u64?`
- `akash_root_hash: Hash?`
- `mmr_proof_ref: ProofRef?`
- `temporash_ref: TimeRef?` — external time imprint (optional/lazy)
- `anchored_at: RFC3339?` — may be null until resolved
- `replication_vector: [ReplicaRef]` — sharding/replication info

---

## 2. Canonical IDs and hashing rules

### 2.1 Hash primitives
- `Hash = <alg>:<bytes>` (e.g., `blake3:...`)
- Canonical serialization for hashing MUST be stable and language-agnostic (**CBOR recommended**).

### 2.2 Semantic hash (Option C dual hash)
v0 standard: **Option C supported**, optional on hot path, encouraged by stigmergy.

- `content_hash = H(artifact_bytes)`
- `semantic_hash = H(content_hash || canonical(semantic_header))`

Rules:
- If `semantic_hash` exists, it is the preferred `subject_hash` for anchoring and routing.
- If missing, fall back to `content_hash` without breaking verification.

### 2.3 Policy/Lens/Transform IDs
All are content-addressed.

- `policy_id = H(canonical(policy_doc))`
- `transform_id = H(transform_name || impl_hash || model_id || params_hash || io_schema_hash)`
- `lens_id = H(canonical(lens_topology || policy_id || seed_roots || routing_params))`

---

## 3. Merkin Tree (living substrate index + execution router)

### 3.1 Merkin Node Header (core fields)
Each node stores:

- `node_id: Hash` (content-addressed header id)
- `children: [NodeRef]`
- `routing_sketch: BloomSketch` (machine pruning)
- `salience_field: GaussianField` (anti-thrash scheduling)
- `mass: u64` (size proxy)
- `heat: u64` (activity proxy)
- `lazy_state: enum{FRESH, DIRTY, DEFERRED, SEALED}`
- `envelope_refs: [EnvelopeRef]` (pointers to envelopes under this node)
- `work_queue_refs: [WorkPromiseRef]` (optional, see 4)

### 3.2 BloomSketch
Used for membership-ish routing (“maybe contains token/object/feature”).

- Implementation: Bloom or Counting Bloom.
- Update semantics:
  - Hot path may be approximate / deferred.
  - On sealing, rebuild exact from children (recommended).

### 3.3 GaussianField
Represents “confidence/salience with uncertainty” for scheduling.

- `mu: f32` (expected relevance / priority)
- `sigma: f32` (uncertainty / volatility)

Scheduling rule (policy-driven): expensive work should require `mu - k*sigma >= threshold`.

### 3.4 Node state transitions
- Inserts mark path `DIRTY`.
- Background consolidation may set `FRESH`.
- Explicit deferral sets `DEFERRED`.
- Sealing sets `SEALED` and freezes.

---

## 4. Self-executing substrate: computed vs computing properties

### 4.1 WorkPromise
A node/envelope may carry “promises” for derived artifacts (object extraction, embeddings, transcripts, etc.).

**Fields**
- `promise_id: Hash`
- `input_hash: Hash` (usually Artifact hash or Envelope id)
- `transform_id: Hash`
- `policy_id: Hash`
- `state: enum{ABSENT, PROMISED, RUNNING, STALE, FRESH, FAILED}`
- `result_hash: Hash?` (Artifact hash for result)
- `result_envelope_id: Hash?`
- `cost_hint: u32?`

### 4.2 Work sharing rule (network)
Before executing a transform, implementation SHOULD:
1) consult local cache index
2) consult network `finger` capability/cache (if enabled by policy)
3) only then compute and publish result

---

## 5. APIs (service boundaries)

### 5.1 Akash API (hash-in, proof-out)
Minimum:
- `POST /akash/append {leaf_hash, metadata?} -> {leaf_index, root_hash}`
- `GET /akash/root -> {root_hash}`
- `GET /akash/proof/{leaf_hash} -> proof`
- `GET /akash/verify/{leaf_hash} -> {exists: bool}`

### 5.2 Merkin Store API (artifacts + envelopes)
- `PUT /artifact` (bytes upload) -> `{content_hash}`
- `POST /envelope` -> `{envelope_id}`
- `GET /envelope/{id}`
- `GET /artifact/{hash}` (optional if you keep content private elsewhere)

### 5.3 Merkin Tree API (routing + sealing)
- `POST /merkin/ingest {envelope_id, routing_tokens...} -> {hot_root}`
- `POST /merkin/seal {hot_root} -> {sealed_root, epoch_id}`
- `GET /merkin/node/{node_id}`

### 5.4 Temporash/Tempora integration
- `POST /tempora/anchor {subject_hash} -> {time_ref}` (async ok)
- Anchor resolution can be lazy: `anchored_at` may fill later.

### 5.5 Finger + AI disclosure + Gopher
- `GET /finger.plan` (canonical plan file; not pollable)
- `GET /finger.plan.wasm` (canonical compact drift/disclosure surface for cross-repo coordination)
- `GET /.well-known/finger.plan` (legacy transitional mirror/alias)
- `finger.plan` is a track-backed, timestamp-agnostic `.plan` artifact generated from Yata graph state (program track).
- `finger.plan` SHOULD be the preferred layered disclosure surface for repository/runtime posture.
- `finger.plan.wasm` SHOULD be the preferred machine sync payload for multi-repo drift coordination.
- `finger.plan` SHOULD carry compact `solve_report_*`, `procsi_report_*`, and `capability_report_*` fields when those layers are present.
- `finger.plan` MUST NOT inline raw APP payloads, raw AI substrate fingerprints, or full ticket bodies; those stay in procsi sections, APP stores, and runtime-specific artifacts.
- `.well-known` manifests may mirror or summarize this information for interface drift detection, but they are transitional exports rather than the native source of truth.
- `GET /aicheck` (machine-readable, ethical AI inventory endpoint)
- `GET /ai` (canonical version of `/aicheck`, may content-negotiate HTML/JSON)
- `gopher://…` (AI-first text presentation; stable symbol-native rendering)

---

## 6. Background jobs (required for “lazy everywhere”)

### 6.1 Consolidation worker
- rebuild node Bloom sketches if drift too high
- update Gaussian fields from access patterns
- mark nodes `FRESH` when consistent

### 6.2 Anchoring worker
- batches `subject_hash` to Akash (append-only)
- optionally sends Tempora requests
- updates `Anchor.anchor_state` to `ANCHORED` and fills proof/time fields as available

### 6.3 Semantic commitment worker (stigmergic)
- opportunistically computes `semantic_hash` for envelopes missing it (Option C)
- policy can demand it for publish/audit lanes

---

## 7. MoonBit vs Mu responsibilities

### 7.1 MoonBit (core/performance)
Implement in MoonBit:
- Hashing + canonical serialization
- Bloom/Counting Bloom operations
- Gaussian field update primitives
- Merkin node store + mutation logic (DIRTY propagation, sealing)
- Akash client / proof verify
- Envelope validation (including semantic hash check)

### 7.2 Mu (policy/config/contracts)
Implement in Mu:
- policy docs + compilation to canonical form
- lens topology specs (what partitions, publish lanes, lifecycle)
- scheduling policies (k, thresholds, cost hints)
- publish policies (what must be anchored/committed before activation)
- conversation/negotiation protocols (merge-like compliance thresholds)
- gopher presentation templates and transformations

---

## 8. Minimal v0 deliverables (Codex checklist)

### 8.1 Data model + storage
- Artifact store (content hash)
- Envelope store (semantic header field + state machine)
- Anchor store (subject hash + Akash pointers + lazy time fields)
- Merkin node store (header fields in 3.1)

### 8.2 Core flows
1) **Artifact ingest**: bytes → content_hash  
2) **Envelope attach**: semantic_header → envelope_id (header encoding discriminated by length)  
3) **Hot tree ingest**: envelope_id routed; path marked DIRTY  
4) **Seal epoch**: freeze; rebuild sketches; optionally compute semantic_hash; produce epoch root  
5) **Anchor**: append semantic_hash (or content_hash fallback) to Akash MMR; optionally Tempora imprint  

### 8.3 Verification
- verify `content_hash` against bytes
- verify `semantic_hash` if present (Option C)
- verify existence via Akash proof-out

---

## 9. Explicit philosophy constraints
- No component is allowed to require “AI must provide timestamps.” Temporal anchoring is infra-side.
- Semantic vocabulary is not fixed; convergence is emergent.
- Finger plan files are not APIs; enforce “Talk-to-the-Hand” rate limit semantics.

---

## Appendix A — Canonical semantic header rules (normative)
- Stored as raw symbol list; derived metrics computed at query time.
- Encoding discrimination:  
  - `len == 8` → `arbyte_grin`  
  - else → `chain_coda`
