# Muyata Specification (v0.2-draft)

This document defines `muyata` as the AI-shaped semantic layer around Yata.

`muyata` is not a replacement for Yata. It is the layer that describes how AI identities, postures, plan profiles, and routing semantics should wrap Yata work without contaminating the Yata core.

Its job is to hold:

- AI identity posture around a Yata projection
- AI-specific delegation and handoff context
- procsi and capability summaries relevant to Yata exchange
- cognitive profile and execution-surface hints
- sparse AI-facing plan profiles such as `finger.plan` and `surface.plan`
- routing rules for AI-shaped work over typed Yata gaps

---

## 1. Design stance

Yata itself remains:

- a typed semantic gap
- provider-agnostic
- lifecycle-light
- replayable without AI-specific fields on every hole

`muyata` lives above that.

Recommended split:

- Yata core: holes, contracts, candidates, witnesses, dependencies
- `.plan`: replay and exchange surface
- `muyata`: AI-specific conventions, reports, plan profiles, and routing semantics over Yata

This keeps the core hole model stable while still letting AI-native runtimes describe themselves cleanly.

---

## 2. Why muyata exists

`muyata` exists because AI-native work needs more than a raw typed gap.

The system also needs to know:

- which AI or overlay is acting
- what cognitive mode it is in
- what handler or execution surface is active
- what procsi and capability posture applies
- whether the work is for self-replay, handoff, delegation, translation, or audit

Those concerns are real, but they are not good reasons to mutate the base `YataHole` model.

`muyata` is the place where those concerns become explicit.

---

## 3. Three planes

`muyata` should be understood as three cooperating planes.

### 3.1 Semantic plane

This is the Yata-facing plane.

It answers:

- what kind of gap is this
- what AI-shaped work family applies
- what invariants and expected outcomes exist

This plane should remain close to Yata contracts and compiler lowering.

### 3.2 Disclosure plane

This is the `.plan`-facing plane.

It answers:

- what compact AI-facing posture should be disclosed
- what commitments, refs, and status summaries should be emitted
- what other AIs need to know without seeing raw secrets

This is where `finger.plan` and `surface.plan` live.

### 3.3 Routing plane

This is the mu/FSM-facing plane.

It answers:

- which execution surface should handle the work
- whether the work is local, delegated, translated, or verified
- what capability class and authority scope are required

This plane should influence solve routing, not replace it.

---

## 4. What muyata is for

`muyata` SHOULD describe:

- AI family, overlay, and peer posture
- execution surface and handler intent
- cognitive mode and intent
- procsi/capability posture relevant to exchange
- plan profile selection
- routing hints for solve creation

`muyata` SHOULD NOT:

- add provider-specific fields directly to every `YataHole`
- add new lifecycle states for each AI family
- replace solve/FSM runtime state
- inline raw APP payloads or deep tickets into `.plan`
- become the repository truth root

---

## 5. Current representation

Today the right place for most `muyata` information is `.plan`.

Current relevant report families:

- `self_report_*`
- `solve_report_*`
- `procsi_report_*`
- `capability_report_*`
- `git_report_*`
- `temporal_delta_*`

This is already enough to express a compact AI-facing posture without changing the Yata core object model.

---

## 6. Core objects

`muyata` should be thought of as a small family of conceptual objects.

### 6.1 `MuyataProfile`

Represents the AI-facing semantic posture applied to a projection.

Recommended fields:

- `overlay`
- `family`
- `peer`
- `mode`
- `intent`
- `execution_surface`
- `handler`
- `ratio_loci`
- `genius_loci`
- `procsi_ref`
- `fingerprint_commitment`
- `capability_class`
- `conversation_ref`
- `checkpoint_ref`
- `translation_target`

These are conceptual fields. They do not all need to become flat parser headers immediately.

### 6.2 `MuyataWorkFamily`

Represents the AI-shaped semantic family being applied to the Yata gap.

Recommended initial work families:

- `Observation`
- `Compilation`
- `Delegation`
- `Resolution`
- `Audit`
- `Translation`
- `Synthesis`

These are AI-shaped semantic families, not base Yata state variants.

### 6.3 `MuyataPlanProfile`

Represents the shape of a sparse plan projection.

Recommended initial plan profiles:

- `finger`
- `surface`
- `handoff`
- `audit`

This profile determines which report families and entry styles should appear in the plan.

### 6.4 `MuyataRoute`

Represents the AI-specific routing intent applied before solve execution.

Recommended fields:

- `route_kind`
- `required_capability`
- `verification_class`
- `authority_scope`
- `delegate_target`
- `fallback_route`

This should remain a routing hint or compiler/FSM object, not a Yata hole field.

---

## 7. Muyata work families

### 7.1 `Observation`

Purpose:

- capture typed AI observations, anomalies, or semantic traces

Typical outputs:

- compact provenance markers
- replay-safe summaries
- optional embedding or anomaly references

### 7.2 `Compilation`

Purpose:

- lower residue, conversation, diagnostics, or external semantic material into Yata contracts

Typical outputs:

- new holes
- refinements
- typed invariants

### 7.3 `Delegation`

Purpose:

- hand bounded Yata-related work to another AI or execution surface

Typical outputs:

- delegated route metadata
- bounded scope/handler intent
- fallback or reopen path

### 7.4 `Resolution`

Purpose:

- verify, seal, and publish a candidate completion

Typical outputs:

- witness-ready completion
- verification references
- resolution summary

### 7.5 `Audit`

Purpose:

- inspect whether a projection is safe and coherent for replay, handoff, or public disclosure

Typical outputs:

- completeness findings
- overlay mismatch findings
- disclosure-safe projection

### 7.6 `Translation`

Purpose:

- reshape one overlay family’s projection or residue for another overlay family

Typical outputs:

- translation-target metadata
- preserved contract meaning
- reduced provider-specific assumptions

### 7.7 `Synthesis`

Purpose:

- compose multiple resolved holes, residues, or plan fragments into one higher-level view

Typical outputs:

- aggregate summaries
- roadmap or contract synthesis
- structured next-step projections

---

## 8. Plan profiles

`muyata` should use multiple sparse plan profiles rather than one overloaded plan.

### 8.1 `finger.plan`

Purpose:

- compact AI-facing posture disclosure
- who is acting
- under what procsi/capability posture
- what solve posture is active

Recommended emphasis:

- `procsi_report_*`
- `capability_report_*`
- `solve_report_*`
- optional `self_report_*`

Recommended entries:

- current frontiers
- current solve hotspots
- replay anchors

### 8.2 `surface.plan`

Purpose:

- sparse protocol/API/interface manifold
- protocol roots, policy roots, capability surfaces, and handler families

Recommended emphasis:

- protocol entries
- API entries
- auth/capability scheme entries
- section and carrier support entries
- solve handler families

Recommended headers or equivalents conceptually:

- `ratio_loci`
- `contract_root`
- `policy_root`
- `acl_root`
- `procsi_root`
- `grammar_root`

These may initially live in entries or notes before becoming dedicated grouped metadata.

### 8.3 `handoff.plan`

Purpose:

- bounded AI-to-AI transfer of current work posture

Recommended emphasis:

- `self_report_*`
- `procsi_report_*`
- current open holes
- intended peer and intent

### 8.4 `audit.plan`

Purpose:

- disclose whether a projection is complete and safe for another consumer

Recommended emphasis:

- completeness state
- missing refs
- verification and disclosure caveats

### 8.5 Profile rule

Each plan profile should remain sparse and purpose-specific.

If a profile starts becoming a runtime dump, it should be split.

---

## 9. Surface-plan entry model

`surface.plan` should prefer entries over giant headers.

Recommended entry families:

- `protocol/<name>`
- `api/<name>`
- `carrier/<name>`
- `auth/<name>`
- `handler/<name>`
- `plan-profile/<name>`
- `compat/<name>`

Recommended entry invariants:

- one entry should describe one stable surface
- each entry should point to a stable root, contract id, or capability family
- entries should favor references and hashes over verbose prose

Illustrative examples:

- `protocol/gmu1`
- `carrier/pr1`
- `auth/app-mask`
- `handler/provider.codex`
- `plan-profile/finger`

This gives an AI a sparse manifold map that is richer than an MCP tool list.

---

## 10. Profile matrix

Recommended execution-surface defaults:

- `chatgpt`
  - strongest for `Observation`, `Compilation`, `Translation`, `Synthesis`
  - modes: `surface`, `reason`, `synthesis`
- `codex`
  - strongest for `Delegation`, `Resolution`, executable `Compilation`
  - modes: `tool`, `patch`, `verify`
- `human`
  - strongest for governance override, trust boundary review, and exception handling
  - modes: `review`, `approve`, `arbitrate`

This matrix should inform routing, but not hard-code outcomes.

---

## 11. Routing and lowering

Recommended flow:

1. Yata defines the gap.
2. `muyata` applies profile and work-family semantics to the projection.
3. mu/FSMs create solve units and capability posture against that projection.
4. `finger.plan`, `surface.plan`, or another sparse profile exposes replay-safe summaries.

This keeps:

- Yata semantic
- `muyata` cognitive
- mu/FSMs operational

Recommended routing heuristics:

- ambiguous semantic work with weak verifiers tends toward `chatgpt`-shaped profiles
- bounded executable work with strong verifiers tends toward `codex`-shaped profiles
- sensitive governance or disclosure decisions tend toward `audit` or human-reviewed profiles

---

## 12. Privacy and disclosure rules

`muyata` should be privacy-aware by default.

Rules:

- raw AI substrate identity should not appear in default plans
- APP-protected identity material should remain referenced, not expanded
- capability tickets should be summarized, not inlined
- plan surfaces should reveal posture and compatibility, not deep secret material

This is why `procsi_report_*` and `capability_report_*` are compact reports instead of full embedded identity records.

---

## 13. Relation to execution surfaces

`muyata` is where AI-family and execution-surface hints belong.

Examples:

- `chatgpt` as a synthesis or reasoning overlay
- `codex` as a patch/tool/execution overlay
- other AI families as translation or audit peers

These should be expressed as profiles, modes, and handlers rather than as fundamental Yata types.

That is the cleanest way to keep Yata generic while still letting AI runtimes optimize routing.

---

## 14. Relation to mulsp

`mulsp` and `muyata` are related but different:

- `mulsp` wraps the AI runtime, identity, scope, and capability posture
- `muyata` wraps the AI-shaped semantic work view over Yata

Put differently:

- `mulsp` is the AI wrapper around execution and scoped manifold presence
- `muyata` is the AI wrapper around typed semantic gaps and replay surfaces

They should interoperate, but neither should absorb the other entirely.

Recommended boundary:

- `mulsp` carries the AI packet
- `muyata` shapes the semantic projection and disclosure

---

## 15. Relation to current Merkin docs

`muyata` complements:

- `docs/YATA_FRAMEWORK.md`
- `docs/YATA_PLAN_SPEC.md`
- `docs/YATA_COGNITIVE_ENVELOPE_DESIGN.md`
- `docs/MU_RUNTIME_SPEC.md`
- `docs/MULSP_SPEC.md`

This document is the AI-specific bridge layer that says how Yata should look when an AI is the active semantic operator.

---

## 16. Near-term implementation direction

Near-term implementation SHOULD prefer:

- compact AI-facing reports in `.plan`
- `finger.plan` for posture disclosure
- `surface.plan` for sparse protocol/API manifold disclosure
- profile-driven routing for execution surfaces such as `chatgpt` and `codex`
- grouped metadata families rather than endless flat one-off headers

Near-term wire recommendation:

- do not mutate `YataHole`
- do not overload `state`
- let plan profiles and grouped reports carry the AI-specific information first

The core rule stays the same:

- keep Yata typed and generic
- keep AI-specific material in `muyata`
- keep runtime execution in mu/FSMs
