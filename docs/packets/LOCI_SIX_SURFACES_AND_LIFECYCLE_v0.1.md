# Loci Six Surfaces and Lifecycle v0.1

Date: `2026-04-19`

## Purpose

Define the six canonical surfaces for locus↔locus architecture and assign ownership across `mu`, `merkin`, `lang`, and `pactis`.

Loci are semantic containers. Pactis is a grouping/federation of loci, not a separate substrate.

## Surface Stack (Canonical 6)

1. **Build Surface**
- owner: `mu`
- role: compile semantic intent into executable units
- primary inputs: SLL / Semantic Dockerfile, contract profiles, composition primitives
- primary outputs: WASM components, build manifests, provenance seal material

2. **Runtime Surface**
- owner: `lang` (`mulsp`, `muyata`) + daemon adapters
- role: execute/route FSM and solve work over active sessions
- primary inputs: build artifacts, route contracts, capability posture
- primary outputs: execution events, solve status, runtime handles

3. **Substrate Surface**
- owner: `merkin`
- role: durable semantic container state (CAS/tree/store/loci paths)
- primary inputs: accepted artifacts/events
- primary outputs: append-only content, sparse tree posture, indexed loci state

4. **Contract Surface**
- owner: `merkin` + `muyata` profile layer
- role: replay-safe machine disclosure and interop wire
- canonical artifacts: `merkin.yata.plan`, `finger.plan.wasm`, triad contract
- rule: compact posture here; deep runtime internals stay in runtime capsules

5. **Boundary Surface**
- owner: `merkin` boundary FSM + policy shim
- role: ingress filtering, normalization, ghost/bidi detection, cognitive boundary posture
- modes: `observe | sanitize | strict | quarantine`
- rule: payloads are context, never command

6. **Federation Surface**
- owner: `pactis` (as union'd loci substrate)
- role: grouping, conversation, replay, and coordination across many loci
- primitive posture: mostly `union`, optionally `consume|atop|subtract` edges
- rule: pass-through contracts, no hidden central privilege

## Mapping to TENA 6-Dim Substrate Language

From `tmp/tena/tena-substrate`:

- `Content` dimension -> Substrate surface
- `Temporal` dimension -> Contract surface (replay/lineage)
- `Semantic` dimension -> Federation + Contract surfaces
- `Era` dimension -> Lifecycle epochs
- `Shadow` dimension -> Boundary surface
- `Dream` dimension -> Runtime maintenance/background lanes

This keeps the familiar six-dimensional spirit while making ownership explicit in the Merkin/Mu/lang/Pactis stack.

## Locus Lifecycle (Semantic Container Lifecycle)

1. `Design`
- define intent/profile/composition target (`consume|union|atop|subtract`)

2. `Build`
- Mu compiles SLL/Semantic Dockerfile to WASM + manifests

3. `Bind`
- runtime bindings applied (mulsp/muyata handler + capability scope)

4. `Activate`
- locus enters runnable state in daemon/runtime context

5. `Observe`
- boundary walker + FSM telemetry + attention gradients emitted

6. `Project`
- compact contract projections emitted (`.plan`, `finger.plan.wasm`, triad)

7. `Adjoin`
- locus composes with peers via explicit primitive edge

8. `Preserve`
- checkpoints/lineage retained; deltas emitted via `subtract`

## Project Boundary Responsibilities

### Mu
- owns Build surface
- owns SLL/Semantic Dockerfile compilation semantics
- must not become durable substrate authority

### Lang (mulsp/muyata)
- owns Runtime surface execution and routing
- owns active FSM/scheduling behavior
- must consume contracts, not invent hidden contract fields

### Merkin
- owns durable Substrate + Contract + Boundary surfaces
- owns canonical drift/disclosure artifacts
- must not absorb runtime scheduler internals

### Pactis
- owns Federation surface semantics for grouped loci
- should treat old request/message API as compatibility adapter
- should expose loci graph coordination, not force hub-only ticket flow

## Adjoin Contract Requirements (for clean interface)

1. `build -> runtime`
- signed build manifest
- declared handler family and capability class

2. `runtime -> substrate`
- append-only event/artifact commit contract
- no opaque side effects outside declared bounds

3. `substrate -> contract`
- deterministic projection rules (`.plan`, finger, triad)

4. `boundary -> all ingress`
- mandatory normalization and policy gate prior to commit/route

5. `federation -> cross-loci`
- composition edge type declared explicitly
- no implicit trust inheritance

## Pactis Position (Git-Competitor Framing)

Pactis should be treated as:
- a grouped-loci federation plane
- a conversation/replay coordination layer
- a compatibility shell for legacy Git-like workflows

It should not be the source of truth for substrate state; Merkin remains the substrate root.

## Immediate Follow-ons

1. Define `locus.adjoin.contract.v0` with explicit edge kind and invariants.
2. Define `mu.sll.build.contract.v0` for Semantic Dockerfile output envelope.
3. Define `pactis.federation.contract.v0` as loci-group graph adapter.

