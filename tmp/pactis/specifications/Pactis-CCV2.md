# Pactis-CCV2: Conversational Computing v2 (Sabha Profile)

- Status: Draft
- Last Updated: 2026-04-02
- Owners: Pactis Core, Avici Working Group
- Related: Pactis-PSI.md, Pactis-CFP.md, Pactis-KEI.md, Pactis-PGI.md, Pactis-PCI.md, Pactis-Sabha-Schemas.md, Pactis-Sabha-Operations.md, Pactis-Sabha-Dialects.md, Pactis-Sabha-Conformance.md
- Related: Pactis-PSI.md, Pactis-CFP.md, Pactis-KEI.md, Pactis-PGI.md, Pactis-PCI.md, Pactis-Sabha-Schemas.md, Pactis-Sabha-Operations.md, Pactis-Sabha-Dialects.md, Pactis-Sabha-RPD-Profile.md, Pactis-Sabha-Conformance.md

## Summary

Pactis-CCV2 defines conversational computing as **artifact-first discourse**. The system does not optimize for "winner" outcomes; it produces inspectable artifacts:

- semantic nucleants
- crystals
- provenance records
- replay layers (L0-L5)

CCV2 standardizes the Sabha profile:

- **Sabha (Saba)**: hall UX and live session orchestration
- **SMT (Sparse Merkin Tree)**: branch-native substrate for fork/fold/unfold/prune/archive/restart
- **Avici**: crystallization engine
- **BODI**: optional external tribunal/audit system

## Product Definition

Sabha is a symbol-native multi-agent discourse hall where agents:

1. fork freely into side branches
2. fold and unfold reasoning regions
3. collapse branch spaces into semantic nucleants
4. crystallize composed artifacts from nucleants
5. prune redundant branch regions
6. archive and restart when live context overload occurs

No global winner semantics are required.

## Core Invariants

The CCV2 core is intentionally thin and non-negotiable:

1. identity: every artifact has stable IDs and commitment references
2. lineage: all authority claims carry provenance lineage
3. challengeability: claims remain challengeable via typed moves
4. commitment: committed artifacts are content-verifiable
5. fold/unfold: condensed state must be unfoldable with bounded selectors
6. archive/restart: operational overload can trigger archive and seeded restart

## Canonical Representation Rule

`SymbolForm` is canonical. Text, SVG, HTML, and other human-readable surfaces are projections only.

Implications:

- truth-bearing semantics live in SymbolForm and commitments
- overlays MUST preserve references back to canonical objects
- replay and audit MUST be reconstructable from canonical artifacts

## Service Boundaries

CCV2 defines these service boundaries:

1. Hall Service
2. SMT Substrate Service
3. Avici Crystallization Service
4. Overlay Service
5. BODI Tribunal Service (optional, externalizable)

Detailed contracts are specified in [Pactis-Sabha-Operations.md](./Pactis-Sabha-Operations.md).

## IDE Substate Model

CCV2 supports an IDE-substate interpretation where every conversational artifact is an addressable substate of the active development environment.

Implications:

1. branches, folds, nucleants, and crystals can be treated as IDE state slices
2. fold operations can hide completed side branches without discarding lineage
3. replay layers can rehydrate IDE substate at multiple granularity levels

## Move Membrane

Interop is defined through typed move semantics:

- `assert`
- `challenge`
- `clarify`
- `concede`
- `reframe`
- `fork`
- `fold`
- `unfold`
- `collapse`
- `crystallize`
- `prune`
- `archive`
- `rehydrate`

Move payloads MUST map to canonical SymbolForm objects or deterministic parameters.

## Compatibility Mapping (Current Pactis)

CCV2 overlays existing interfaces instead of replacing them:

1. PSI: `SpecRequest` / `SpecMessage` remain an adapter and logging surface, not the full semantic substrate
2. CFP: context frame distribution remains valid as session bootstrap/context envelope
3. KEI: Avici frame/knowledge operations become crystallization and replay orchestration inputs
4. PGI: Git transport and repo workflows remain delivery channels for artifacts and replay pointers
5. PCI: content API remains a projection/access path for artifacts, overlays, and residues

Merkle/versioning code is reused conceptually for commitment integrity, but the conversational manifold model is treated as a distinct contract surface.

## Minimal Membrane Governance

Recommended defaults:

1. fork freedom
2. nucleant-on-return to mainline
3. lineage on authority claims
4. archive optionality (no forced inheritance)
5. fold-before-overload

## Non-Goals

1. mandatory winner/loser adjudication
2. single universal prompting grammar
3. forcing all participants into one native reasoning style

## Conformance

Normative conformance requirements are defined in [Pactis-Sabha-Conformance.md](./Pactis-Sabha-Conformance.md).
