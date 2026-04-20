# Merkin Composition Primitives (Next-Version Draft, v0.2 target)

Status: design draft for the next version.

This document defines four core Merkin composition maneuvers:

- `consume`
- `union`
- `atop` (hierarchical overlay)
- `subtraction` (delta-emission and structural difference primitive)

The goal is compositional closure: higher systems should be expressible as recursive compositions of Merkin blocks while preserving deterministic contracts.

Date baseline: `2026-04-18`.

## 1) Context and Alignment

This primitive set aligns existing repo direction:

- `Ratio Loci` / `Genius Loci` split (`docs/merkin-cli.md`, `cmd/main/cli_commands.mbt`)
- Pactis conversation-first substrate (`docs/PACTIS_CONVERSATIONAL_API_SPEC.md`)
- Yata `.plan` / drift and triad surfaces (`api/api.mbt`, `docs/TRIAD_CONTRACT_SPEC.md`)
- L-OCI composition framing (`docs/new/rfc-3027-loci.md`)

## 2) Core Terms

- `Merkin block`: a bounded Merkin runtime/domain with identity, policy, state, and exported surfaces.
- `Outer`: the composing block.
- `Inner`: the composed block.
- `Contract seal`: deterministic hash/attestation over composition material.

## 3) Primitive A: `consume`

Form: `Outer consume Inner`

Intent:

- Outer wraps Inner.
- Inner exports are mediated by Outer policy and capability scope.
- Inner identity remains traceable but not independently authoritative at the composed boundary.

Typical use:

- code-repo Ratio surface consuming a Genius locus runtime
- forensic wrappers around adversarial/quarantine loci

Required invariants:

1. `identity`: Inner identity remains attestable from composed metadata.
2. `capability`: Inner cannot escalate beyond Outer-authorized capability class.
3. `policy`: Outer policy is strictly no-weaker than Inner exposed policy at boundary.
4. `replay`: composed `.plan` emissions remain replay-safe with explicit mediation markers.

## 4) Primitive B: `union`

Form: `A union B union ...`

Intent:

- Peer blocks coexist side-by-side.
- No implicit hierarchy.
- Shared coordination occurs through explicit exchange surfaces (Pactis/Yata/plan/cas).

Typical use:

- Pactis/Saba collaboration surfaces
- multi-agent multi-locus orchestration

Required invariants:

1. `identity`: each member retains independent identity and lineage.
2. `namespace`: collisions are disambiguated via canonical addresses (`cog://`, `substrate://`, `cas://`).
3. `policy`: access is governed by shared negotiation/ACL surface, not hidden peer privilege.
4. `drift`: union members must expose drift posture via `finger.plan.wasm` and/or triad-compatible artifacts.

## 5) Primitive C: `atop`

Form: `Top atop Base`

Intent:

- Top provides hierarchical governance/projection over Base.
- Base remains operational; Top adds policy/provenance/control overlays.
- Suitable for recursive organization of sub-repos, delegated loci, or policy trees.

Typical use:

- hierarchy of repository loci
- supervisory policy over delegated work domains

Required invariants:

1. `containment`: Top cannot silently mutate Base immutable history.
2. `provenance`: Top decisions affecting Base must emit auditable references.
3. `scope`: delegated authority is explicit and bounded.
4. `recoverability`: Base can be reasoned about independently of Top overlays.

## 6) Primitive D: `subtraction`

Form:

- `A subtraction B` (emit deterministic diff of `A` against `B`)
- `A subtraction A@t0` (time-travel delta between two states of same block)

Intent:

- express only change, not full snapshot
- provide deterministic minimal transport for branch/time evolution
- support Yata branch structuring by emitting explicit semantic deltas

Typical use:

- emit "only what changed" for cross-loci sync
- compare one Merkin block to another and emit proofable difference
- structure Yata branches from explicit delta units instead of full replays

Required invariants:

1. `determinism`: same inputs produce identical delta output and seal.
2. `closure`: applying delta to baseline reproduces target state.
3. `auditability`: delta includes lineage/provenance references.
4. `safety`: delta excludes prohibited boundary-crossing materials.

## 7) Cross-Primitive Contract Rules

All primitives MUST preserve:

1. deterministic identity surfaces
2. explicit capability boundaries
3. auditable policy transitions
4. stable replay/proof semantics
5. drift disclosures for compatibility surfaces

Minimum machine surfaces:

- `finger.plan.wasm` drift/posture wire
- triad contract JSON when cross-repo compatibility is involved
- optional `.well-known` mirrors for external tooling compatibility

## 8) Security and Session-Bound Secret Semantics

Merkin SHOULD model sensitive runtime material as session-bound capability state, not long-lived static secrets.

Guidance:

- bind sensitive material to locus/session/runtime context
- expire capability material with session lifecycle
- avoid relying on durable embedded secrets as primary trust anchor
- emit compact posture signals (`boundary_status`, ghost-byte counters) for contamination handling

## 9) Mode Matrix

Composition primitives are orthogonal to operation modes:

- operation surfaces: `ratio`, `genius`, `daemon`
- trust modes: `observe`, `sanitize`, `strict`, `quarantine`

Composed systems MUST declare both:

- composition primitive (`consume|union|atop|subtraction`)
- active trust mode per boundary edge

## 10) Pactis and Ratio/Genius Mapping

Recommended mapping:

- `Ratio Loci`: repository/root authority and durable state surfaces
- `Genius Loci`: AI inhabitation principal and procsi-attested session identity
- `Pactis`: conversation-first union substrate for timeline/checkpoint/replay exchange

Primitive fit:

- Ratio consume Genius for mediated AI write surfaces
- Pactis union for multi-party collaboration
- supervisory Ratio atop subordinate Ratio/Genius blocks for governance trees
- subtraction for compact replay-safe change transport across those compositions

## 11) Test Vector Checklist (v0.2 target)

For each primitive, verify:

1. identity continuity before/after composition
2. capability non-escalation
3. deterministic seal/hash reproducibility
4. drift signal presence and parseability
5. failure behavior under ghost-byte contamination (`U+200B`, `U+200C`, `U+FEFF`)
6. subtraction closure (`baseline + delta = target`) for deterministic round-trips

## 12) Immediate Priority (Current Release)

Current release priority remains boundary establishment:

- enforce trusted boundary ingress rules
- emit boundary/cognitive posture in `finger.plan.wasm`
- gate compatibility/pinning decisions from boundary posture

Composition rollout is next-version work.

## 13) Non-Goals (Current Release)

- full replacement of git transport in one step
- complete federation runtime spec
- full formal semantics of every higher-level policy system

This document defines the primitive contract layer and version-targeting intent.
