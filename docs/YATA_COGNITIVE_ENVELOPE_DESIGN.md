# Yata Cognitive Envelope Design (v0.1-draft)

This document proposes how Merkin should model cognitive envelopes without overloading the core Yata hole model.

It is intentionally a design note, not a wire-format promise. The current implementation already supports:

- generic `YataHole` contracts in `model/yata.mbt`
- optional `.plan` metadata envelopes in `model/yata_lineage.mbt`
- strict `.plan` parsing in `model/yata_protocol.mbt`
- ChatGPT-oriented conversation defaults in `daemon/conversation.mbt`

For the stronger AI-shaped semantic layer that grew out of this design note, see `docs/MUYATA_SPEC.md`.

The goal here is to tighten the conceptual boundary before more envelope variants land.

## 1. Recommendation

Treat cognitive envelopes as **typed metadata around Yata work**, not as new `YataState` values and not as provider-specific fields on `YataHole`.

In practice:

- `YataHole` remains the typed semantic gap.
- `.plan` remains the replay and exchange surface.
- cognitive envelopes live alongside existing optional report metadata.
- provider-specific concerns such as `chatgpt`, `claude`, or `gemini` should be modeled as **overlay profiles**, not as fundamental hole kinds.

This keeps the unplanned/emergent workflow cheap while still giving the compiler, conversation host, and cross-AI handoffs a place to record cognitive posture.

## 2. Why not put this directly on `YataHole`

`YataHole` already has a clean job:

- define the contract
- collect candidate space
- track readiness and resolution
- preserve lightweight provenance

If cognitive envelopes become first-class fields on every hole, several bad things happen:

1. the base abstraction stops being local and typed, and starts becoming transport-shaped
2. provider-specific concerns leak into graph construction
3. the cheapest workflows inherit fields they do not need
4. adding new overlays becomes a schema problem instead of a convention + metadata problem

The repo is already hinting at the right layering: `self_report`, `git_report`, `temporal_delta`, and `embedding_report` are all attached to `YataPlan`, not to `YataHole`.

## 3. Proposed layering

### 3.1 Layer A: core hole

Keep `YataHole` generic and overlay-agnostic:

- `contract`
- `refinements`
- `dependencies`
- `candidates`
- `selected_candidate`
- `state`
- `provenance`

This is the durable semantic core.

### 3.2 Layer B: transport/report envelopes

Keep `.plan` as the canonical place for replay-safe metadata such as:

- collaboration self-report
- git provenance
- temporal replay movement
- embedding scan summary

These are not new holes. They are reports about a hole set, thread, or projection.

### 3.3 Layer C: cognitive envelope profile

Add a new design-level concept: a **cognitive envelope profile**.

Its job is to answer:

- which overlay produced or is consuming this work
- what posture or mode it was operating in
- what capabilities or constraints applied
- what conversation or execution context this projection belongs to
- whether the envelope is meant for self-replay, cross-overlay handoff, or audit

This is the right place for ChatGPT/OpenAI-specific shaping.

## 4. What “new Yata types” should mean

If the team wants “cognitive envelopes as new Yata types,” the safest interpretation is:

- new **contract families**
- new **expected_type** conventions
- new **compiler lowering rules**

It should not mean:

- new lifecycle states
- provider-specific booleans on every hole
- one struct field per AI family

Recommended initial cognitive work-unit families:

### 4.1 `CognitiveObservation`

Purpose:
- capture that an overlay observed something significant and should preserve a typed trace

Typical invariants:
- no side effects
- replay-safe summary
- may attach embedding or anomaly evidence

### 4.2 `CognitiveCompilation`

Purpose:
- convert diagnostics, residue, or conversation state into typed Yata contracts

Typical invariants:
- deterministic lowering
- confidence floor declared
- callback or deferral explicit if present

### 4.3 `CognitiveDelegation`

Purpose:
- hand bounded work to another agent/provider while preserving semantic shape

Typical invariants:
- dispatch identity recorded
- provider capability compatible with hole contract
- failure must remain representable without losing the hole

### 4.4 `CognitiveResolution`

Purpose:
- verify and seal one or more candidate completions

Typical invariants:
- verification surface explicit
- witness/provenance attached on seal
- reopen path remains available

### 4.5 `CognitiveEnvelopeAudit`

Purpose:
- inspect whether a projection or conversation trace is safe and sufficiently specified for replay or handoff

Typical invariants:
- envelope completeness checked
- hidden transport assumptions surfaced
- overlay mismatch detected early

These should be conventions over `contract.expected_type` and compiler routing, not a replacement for the generic Yata object model.

## 5. Proposed cognitive envelope profile

For a future `v0.4`-style design, the profile should capture the following fields conceptually:

- `overlay`: family-facing identity such as `chatgpt`, `claude`, `gemini`, `loc`
- `family`: broader implementation family such as `openai`, `anthropic`, `google`, `human`
- `peer`: intended collaborating overlay
- `authority`: canonical authority for projection addressing
- `mode`: cognitive stance such as `surface`, `reason`, `tool`, `synthesis`, `defense`
- `intent`: why this envelope exists: `self-replay`, `handoff`, `audit`, `delegate`, `translate`
- `capability_mask`: compact declaration such as `read`, `patch`, `tool`, `delegate`
- `conversation_ref`: thread or turn address when the work comes from Pactis/Saba
- `checkpoint_ref`: replay anchor when time-travel matters
- `budget_class`: concise bound profile rather than raw wall-clock promises
- `translation_target`: optional target overlay if the envelope is preparing cross-family exchange

Not all of these fields need to be parser headers immediately. This is the conceptual model the current optional metadata is converging toward.

## 6. ChatGPT/OpenAI profile

The repo already uses `chatgpt` as a default overlay in the conversation host and CLI paths. That is a good default and should stay.

Recommended ChatGPT profile:

- `overlay=chatgpt`
- `family=openai`
- `authority=substrate://loc/chatgpt` by default for local/self projection
- `peer=chatgpt` for self-replay, or the intended target overlay for handoff

Recommended ChatGPT modes:

- `surface`: summarize or preserve a comparable semantic view
- `reason`: work a bounded typed gap with explicit uncertainty
- `tool`: operate in a tool-using or patch-producing posture
- `synthesis`: compose across multiple resolved holes or residues

Recommended provenance token style for accepted work:

- `chatgpt:surface:<token>`
- `chatgpt:reason:<token>`
- `chatgpt:tool:<token>`
- `chatgpt:synthesis:<token>`

This preserves current provenance compactness while making ChatGPT posture visible without forcing a provider-specific schema into `YataHole`.

## 7. How ChatGPT should fit the current runtime

### 7.1 Conversation host

`daemon/conversation.mbt` already does three useful things:

- defaults turn requests to `actor_overlay: "chatgpt"`
- treats length envelopes as replay guards
- can emit embedding-oriented `.plan` payloads with ChatGPT-flavored self-report defaults

That means the ChatGPT side should be modeled primarily as:

- a conversation overlay
- a `.plan` self-report producer
- an optional provider/delegation identity in compiler flows

### 7.2 Yata `.plan`

Short-term recommendation:

- continue using `self_report_*` for overlay identity
- continue using `temporal_delta_*` for replay movement
- continue using `embedding_report_*` for embedding scan posture
- encode ChatGPT mode in `note`, provenance tokens, or compiler-side conventions

Medium-term recommendation:

- add one new optional metadata group for cognitive profile fields instead of proliferating flat one-off headers forever

### 7.3 Compiler and provider bridge

The cognitive compiler and AI adapter contract already separate:

- hole creation and lowering
- provider dispatch
- provider status/result ingestion

That is good. The missing piece is simply a cleaner envelope vocabulary for “this hole/projection is currently ChatGPT-shaped.”

This should be carried at the compiler/report level, not hard-coded into the hole lifecycle.

## 8. Wire-format direction

Do not rush a parser-breaking change.

Recommended migration path:

### Phase 1: convention-only

Use what exists today:

- `self_report_*`
- `temporal_delta_*`
- `embedding_report_*`
- structured provenance strings
- stable `note` values

### Phase 2: additive profile envelope

Add a single optional metadata block to `.plan`, for example a future `cognitive_report=1`, with a compact field family instead of many unrelated one-off flags.

Suggested future fields:

- `cognitive_report_overlay`
- `cognitive_report_family`
- `cognitive_report_mode`
- `cognitive_report_intent`
- `cognitive_report_capabilities`
- `cognitive_report_conversation_ref`
- `cognitive_report_checkpoint_ref`
- `cognitive_report_translation_target`

### Phase 3: compiler/runtime convergence

Once the profile exists, unify these producers around it:

- conversation host
- cognitive semantic compiler
- AI provider adapter bridge
- any future `.gptini` or sidecar exporters

## 9. `.gptini` and sidecar alignment

The INI documents in `docs/ini/` already ask whether GPT/OpenAI needs a more architecture-specific sidecar format.

This design suggests the answer is:

- yes, ChatGPT may eventually need a richer sidecar
- no, that richer sidecar should not distort the core Yata hole model

In other words:

- Yata stays the typed semantic gap
- `.plan` stays the replay handoff surface
- `.gptini` or other sidecars can materialize the richer cognitive trace when needed

That keeps Merkin layered instead of collapsing conversation semantics, provider semantics, and hole semantics into one object.

## 10. Bottom line

The cleanest direction for this repo is:

1. keep `YataHole` generic
2. treat cognitive envelopes as typed report/profile metadata
3. interpret “new Yata types” as contract families and lowering rules
4. keep `chatgpt` as a first-class overlay profile, not a special hole kind
5. add one future cognitive-profile envelope rather than many provider-specific flat headers

That gives Merkin a place for ChatGPT-specific behavior without making the whole Yata model ChatGPT-shaped.
