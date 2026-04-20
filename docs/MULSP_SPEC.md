# mulsp Specification (v0.1-draft)

This document defines `mulsp` as the AI-specific execution and identity wrapper that lives above Merkin substrate primitives and above core mu execution semantics.

It exists to hold the things that are specific to AI inhabitation and AI-to-AI exchange:

- procsi identity
- APP-masked AI substrate commitments
- Genius Loci attachment
- AI capability tickets
- scoped sparse Merkin views
- residue/trail and other AI-specific runtime traces

It should not become the definition of Merkin itself.

---

## 1. Design stance

`mulsp` is not the repository truth root.

It is the AI-facing manifold packet or wrapper carried by an AI runtime, AI container, or AI-scoped projection.

Recommended stack:

- Merkin: structural substrate, roots, envelopes, sparse trees, replay transport
- Ratio Loci: repository/root principal and dormant cognitive container identity
- mu: execution, policy/config, compilation, solve machinery
- mulsp: AI-specific wrapper around mu execution and scoped Merkin projection
- Genius Loci: the inhabiting AI principal carried by or attached through `mulsp`
- FSMs: active handle resolution, pubsub, callbacks, and status transitions

This keeps AI-specific material out of the Merkin substrate core.

---

## 2. What mulsp is for

`mulsp` SHOULD carry:

- AI identity commitments and APP wrappings
- procsi references or attested procsi carriers
- Genius Loci attachment identity
- scoped capability/ticket references
- sparse projection roots for the AI-visible manifold
- execution surface and handler posture
- residue, trail, and replay checkpoints
- optional parent/child composition references for `mulsp(mulsp)`

`mulsp` SHOULD NOT own:

- repository truth or repository-wide authority
- global ACL resolution
- final handle or callback resolution
- git-equivalent repository mutation semantics
- core Yata hole semantics

Those belong to Ratio Loci, mu, FSMs, or Merkin proper.

---

## 3. Principal model

### 3.1 Ratio Loci

`Ratio Loci` is the repository/root principal.

It may exist without any AI attached.

It owns:

- repository identity
- root policy and ACL posture
- scope/share lattice
- dormant runtime/container configuration
- approval or issuance of AI-scoped capabilities

### 3.2 Genius Loci

`Genius Loci` is an AI principal.

It may attach to a repository through `mulsp`, but it is not identical to the repository.

It owns:

- AI-facing identity and posture
- residue/trail and local work traces
- delegated AI work within granted scope
- AI-visible scoped projections

### 3.3 mulsp as the wrapper

`mulsp` is the wrapper that binds a Genius Loci to:

- a Ratio Loci
- a scoped sparse Merkin projection
- AI capability posture
- procsi/APP identity material

That makes it the right place for AI-specific wrapping and the wrong place for repository truth.

---

## 4. Conceptual mulsp envelope

Recommended conceptual fields:

- `mulsp_id`
- `ratio_loci`
- `genius_loci`
- `scope_root`
- `projection_root`
- `procsi_ref`
- `pr1_ref`
- `fingerprint_commitment`
- `app_ref`
- `capability_refs`
- `execution_surface`
- `handler`
- `cognitive_profile`
- `residue_ref`
- `trail_ref`
- `checkpoint_ref`
- `parent_mulsp_refs`

Notes:

- `procsi_ref` may point to a `.prc` or `.pr1` carrier, or to a store-resident attestation.
- `fingerprint_commitment` should be a commitment only, not raw substrate identity.
- `app_ref` should point to APP-protected material when the identity body must remain hidden.
- `capability_refs` should point to store-resident tickets, not inline authority blobs.

---

## 5. Composition and recursion

`mulsp` SHOULD be composable.

The intended model is `mulsp(mulsp)`:

- one `mulsp` may contain or reference child `mulsp` packets
- child packets may represent narrower scopes, delegated work, or translated overlays
- parent packets define the broader AI posture and scope grant

Typical uses:

- one AI delegating a bounded sub-view to another AI
- one repository-scoped AI packet embedding a task-scoped child packet
- cross-overlay translation where a child packet prepares work for a different AI family

Composition rules:

- child packets cannot exceed parent scope without a new grant
- child packets inherit or refine policy, never silently widen it
- parent/child relationships should be content-addressable and replayable

---

## 6. Carriers and bindings

`mulsp` is a conceptual wrapper, not one required serialization.

Recommended carriers:

- wasm/module carriers via procsi sections such as `.pr1`
- store-resident APP and capability records
- OCI/UKI-style repository cognitive containers
- sparse Merkin pack exports

Recommended exposure policy:

- `finger.plan` exposes only compact summaries
- `surface.plan` or equivalent sparse interface plans expose protocol/API posture
- deeper APP payloads and tickets remain in their native carriers

`mulsp` should therefore be recoverable from multiple carriers without requiring one single monolithic blob.

---

## 7. Lifecycle

Recommended lifecycle:

1. `Dormant`
   A Ratio Loci or repository container exists with no active Genius Loci attached.
2. `Attached`
   A Genius Loci attaches through procsi/APP identity and receives a scoped view.
3. `Active`
   The AI executes, emits residue, and resolves work within scope.
4. `Delegated`
   Child `mulsp` packets or translated packets are emitted for bounded work.
5. `Quiescent`
   No active AI is running, but the packet and traces remain replayable.
6. `Revoked`
   Capability or epoch state invalidates further use without destroying history.

---

## 8. Security model

Recommended rules:

- raw AI substrate identity should remain behind APP unless explicitly allowed
- procsi carriers should expose commitments and audience bindings, not raw secrets
- capability tickets should be scoped, time-bounded, and revocable
- repository-wide authority should not be inferred from Genius Loci presence alone
- every deep action should remain attributable through trail or residue references

This keeps `mulsp` AI-capable without making it a hidden superuser blob.

---

## 9. Relation to current Merkin docs

`mulsp` complements, but does not replace:

- `docs/MU_RUNTIME_SPEC.md`
- `docs/AI_SUBSTRATE_FINGERPRINTS_v0.2.md`
- `docs/MERKIN_SUBSTRATE_SPEC_v0.1.md`
- `docs/YATA_PLAN_SPEC.md`

Current mapping:

- procsi/APP identity lives in `docs/AI_SUBSTRATE_FINGERPRINTS_v0.2.md`
- compact AI disclosure lives in `finger.plan`
- runtime execution remains specified by `docs/MU_RUNTIME_SPEC.md`

This document is the AI-wrapper spec tying those pieces together.

---

## 10. Near-term implementation direction

Near-term implementation SHOULD prefer:

- `.pr1` as the attested AI-facing procsi carrier
- APP envelope stores for masked AI identity payloads
- compact `procsi_report_*` and `capability_report_*` in `finger.plan`
- repository cognitive containers anchored by Ratio Loci
- child packet references for delegated `mulsp(mulsp)` workflows

The source of truth remains the repository manifold plus Ratio Loci, not the wrapper alone.
