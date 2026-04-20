# Pactis spec_api Survival Map for Locus↔Locus Adjoin v0.1

Date: `2026-04-19`

## Purpose

Assess how much of legacy `tmp/pactis/spec_api` survives in the current Merkin/Mu/lang direction, and define required boundary contracts for adjoined loci.

## Spiritual Survival Verdict

High survival (~75-85%) at concept level.

What survived strongly:
- conversation as the primary coordination medium
- typed messages over raw repo/file coupling
- idempotent append semantics
- checkpoint/replay thinking
- structured exports for tool interoperability
- workspace/tenant boundary posture

What changed:
- hub-centric HTTP spec negotiation becomes locus↔locus contract exchange
- status workflow language (`proposed/accepted/...`) shifts toward Yata/FSM states/events
- flat request/message model must become graph-aware and route-aware (`.plan`, `finger.plan.wasm`, triad contract)

## Legacy → Current Mapping

### 1) SpecRequest (legacy)
Now maps to:
- Yata work family + contract hole set (`program` track)
- optional conversation thread object (Pactis/Saba stub)

### 2) SpecMessage types (`comment/question/proposal/decision`)
Now maps to:
- typed event classes over `.play` and/or conversation turn artifacts
- Yata candidate/refinement/witness lifecycle material

### 3) Status flow (`proposed -> accepted -> ...`)
Now maps to:
- FSM transitions (Mu-owned execution states)
- Yata hole progression (`Open -> Converging -> Sealed -> Resolved|Abandoned`)

### 4) JSON-LD export bundle
Now maps to:
- `.plan` + `finger.plan.wasm` compact drift disclosure
- optional JSON-LD projection as compatibility envelope

### 5) Checkpoints/restore
Now maps to:
- checkpointed thread replay (Pactis conversational stub)
- deterministic plan lineage and triad seal references

### 6) Method registry extension
Now maps to:
- Muyata routing plane + capability/handler profile
- not method-as-HTTP first; method-as-route + verification class

## Structural Shift (Not Flat 2D)

Old model:
- request-centric, hub-mediated message timeline

Current model:
- adjoined loci graph where `mu`, `merkin`, and `lang` are structurally coupled planes
- exchange surfaces are pass-through contracts, not ticket objects
- a document/signal can traverse the adjoined structure without re-authoring per project

This matches your "not flat 2d" requirement: coordination is topological and compositional, not just queue-like.

## Required Interface Levels for Adjoin

To be "at the right level" across `mu + merkin + lang`, each project needs a stable boundary at three layers.

### A. Disclosure boundary (Merkin-owned)
- canonical compact drift surface: `finger.plan.wasm`
- optional compatibility mirror(s): `.well-known/*`
- deterministic canonicalization rules

### B. Routing boundary (Mu-owned)
- FSM event/state contract for execution and verification
- route kinds for local/delegate/verify/synthesize
- strict no-command-from-payload invariant

### C. Semantic profile boundary (Lang/Muyata-owned)
- profile fields (`overlay`, `mode`, `intent`, `handler`, `capability_class`)
- work family typing (`Observation`, `Compilation`, `Delegation`, `Resolution`, `Audit`, ...)
- translation contract across overlays/loci

## Minimum Adjoin Contract Set (v0)

1. `merkin.yata.plan` wire remains canonical machine exchange shape.
2. `finger.plan.wasm` remains canonical compact drift disclosure.
3. Triad contract seals pinned heads + ABI + branch hygiene (`merkin`, `mu`, `lang`).
4. Story/news uplink remains one-way bounded context (no downward command channel).
5. Mu FSM remains sole owner of runtime transition execution.

## What from spec_api should be preserved explicitly

Preserve:
- typed message/event discipline
- idempotency key semantics
- attachment/pointer references (but pointer-first, blob-last)
- replay and auditability expectations

Recast:
- request/status nouns into Yata/FSM lifecycle language
- hub API centrality into locus federation topology
- OpenAPI-first stance into wire-first + optional API adapters

## Composition Primitives (Locus↔Locus)

Recommended for next version language:
- `consume`: locus consumes another locus projection/profile
- `union`: two loci adjoin into shared contract plane
- `atop`: hierarchical parent/child loci with bounded inheritance
- `subtract`: emit meaningful difference (time delta or comparative diff)

Each primitive should produce a typed, replay-safe contract artifact rather than imperative instructions.

## Risk If Unaddressed

- semantic drift between conversation API vocabulary and Yata/FSM vocabulary
- accidental reintroduction of hub-centric coupling
- ambiguous ownership of execution (payload-driven vs FSM-driven)

## Immediate Next Contract Work

1. Define `locus.adjoin.contract.v0` (graph relation + primitive + invariants).
2. Define `mu.route.contract.v0` (FSM-consumable route envelope from Yata/Muyata).
3. Define `lang.profile.contract.v0` (Muyata profile projection with strict field bounds).
4. Add `spec_api_compat` adapter doc: old `requests/messages/status` to new event/hole mapping.

