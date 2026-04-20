# Locus Crossing Passport v0.1

Date: `2026-04-19`

## Purpose

Define the minimum contract required for an intelligence to cross from one locus into another and perform work safely.

Boundary is treated as a governed membrane, not a hard wall.

## Contract Identity

- `kind`: `merkin.locus.crossing.passport`
- `version`: `v0.1`
- `track`: `program`

## Core Rule

Crossing is allowed when shape and authority are valid.

- strict on shape and trust envelope
- flexible on artifact intent (specs/designs/plans/patches/signals)

## Passport Fields (Minimum 6)

1. `who`
- actor identity and attestation
- fields: `overlay`, `family`, `session_surface`, `fingerprint_commitment`, `actor_seal`

2. `what`
- artifact class entering target locus
- enum: `spec|plan|design|patch|signal|report|bundle`

3. `why`
- crossing intent
- enum: `observe|propose|implement|verify|synthesize|audit`

4. `where`
- source and target locus references + allowed target surfaces
- required: `source_locus`, `target_locus`, `allowed_surfaces[]`

5. `how_far`
- capability budget and boundary policy mode
- required: `capability_class`, `budget_class`, `boundary_mode`

6. `trace`
- replay/provenance references
- required: `context_ref`, `lineage_ref`, `passport_seal`

## Normalized Wire (`passport.v0`)

```json
{
  "kind": "merkin.locus.crossing.passport",
  "version": "v0.1",
  "passport_id": "pass-20260419-001",
  "who": {
    "overlay": "codex",
    "family": "openai",
    "session_surface": "codex",
    "fingerprint_commitment": "blake3:fprint-opaque",
    "actor_seal": "blake3:actor"
  },
  "what": {
    "artifact_type": "plan",
    "artifact_ref": "merkin.yata.plan#hole-902"
  },
  "why": {
    "intent": "implement",
    "note": "cross-locus compiler handoff"
  },
  "where": {
    "source_locus": "genius://merkin/main",
    "target_locus": "genius://mu/compiler",
    "allowed_surfaces": ["contract", "runtime", "federation"]
  },
  "how_far": {
    "capability_class": "patch+verify",
    "budget_class": "bounded-medium",
    "boundary_mode": "sanitize"
  },
  "trace": {
    "context_ref": "finger.plan.wasm#node-22",
    "lineage_ref": "triad-contract#v0.1",
    "passport_seal": "blake3:passport"
  }
}
```

## Semantic Router/Firewall (Recommended)

A semantic router/firewall SHOULD evaluate every crossing request before target execution.

### Router inputs

- crossing passport (`passport.v0`)
- target locus policy profile
- boundary walker findings/posture
- capability ticket status

### Router actions

- `allow`: crossing permitted as declared
- `narrow`: reduce surfaces/capability and continue
- `sandbox`: redirect to constrained execution lane
- `quarantine`: hold artifact for review
- `deny`: reject crossing

### Router invariants

- router decisions must be emitted as replayable artifacts
- no hidden implicit escalations
- policy narrowing is allowed; policy widening is not

## Coupling to Adjoin Contract

This passport pairs with `LOCUS_ADJOIN_CONTRACT_v0.1.md`.

- adjoin defines topology/composition expression
- passport defines active crossing authority for a specific action

Expected mapping:
- `union`: passport required for write-class operations
- `consume`: passport required for inner-surface access
- `atop`: passport required for proxy governance actions
- `subtract`: passport required when diff includes cross-locus material
- `yata_union`: passport required when typed void is being materialized

## Validation Rules

A passport MUST include all six sections (`who/what/why/where/how_far/trace`).

Additional rules:
- `allowed_surfaces` must be non-empty
- `boundary_mode` must be one of `observe|sanitize|strict|quarantine`
- `artifact_type=patch` requires `intent` in `implement|verify`
- `intent=implement` requires capability class allowing writes
- all seals must be non-empty

## Error Codes (v0.1)

- `BAD_KIND`
- `BAD_VERSION`
- `MISSING_SECTION`
- `INVALID_ARTIFACT_TYPE`
- `INVALID_INTENT`
- `EMPTY_ALLOWED_SURFACES`
- `INVALID_BOUNDARY_MODE`
- `CAPABILITY_INTENT_MISMATCH`
- `MISSING_SEAL`
- `ROUTER_DENY`

## Operational Notes

- passports are short-lived and scope-bound
- reuse across unrelated loci SHOULD be denied
- all crossing outcomes SHOULD append to contract/replay surfaces

