# Saba Project Starter (Consolidated)

Last Updated: 2026-04-02

This is a practical kickoff pack for launching Saba as a standalone project with controlled chaos.

## Product Thesis

Saba is a live multi-agent debate hall that produces artifacts, not winners.

Primary outputs:

1. semantic nucleants
2. composed crystals
3. provenance chains
4. replay layers (L0-L5)

## Scope Cuts (Phase 0)

Build only what enables real sessions and stable residues:

1. Hall orchestration
2. SMT substrate core (tree/node/branch/region)
3. fold/unfold with residue
4. crystallize v0 (nucleant emit)
5. archive/restart triggers

Defer:

1. full tribunal workflows (BODI optional)
2. advanced scoring/governance UX
3. rich visual overlays beyond minimal projections

## Architectural Services

1. `hall-service`
2. `smt-substrate-service`
3. `avici-crystallization-service`
4. `overlay-service`
5. `bodi-tribunal-service` (optional, external)

## Contract Sources (Import First)

1. `docs/specifications/Pactis-CCV2.md`
2. `docs/specifications/Pactis-Sabha-Schemas.md`
3. `docs/specifications/Pactis-Sabha-Operations.md`
4. `docs/specifications/Pactis-Sabha-Dialects.md`
5. `docs/specifications/Pactis-Sabha-RPD-Profile.md`
6. `docs/specifications/Pactis-Sabha-Conformance.md`
7. `docs/specifications/contract_matrix.jsonld`

## Minimum Repo Layout

```text
saba/
  docs/
    specs/
      CCV2.md
      Sabha-Schemas.md
      Sabha-Operations.md
      Sabha-Dialects.md
      Sabha-RPD-Profile.md
      Sabha-Conformance.md
      contract_matrix.jsonld
  services/
    hall/
    smt/
    avici/
    overlay/
  sdk/
    contracts/
    dialect-adapters/
  test/
    conformance/
```

## Day-1 Backlog

1. Create tree/session/move persistence and IDs.
2. Implement move router for `assert`, `fork`, `fold`, `unfold`, `crystallize`, `archive`, `rehydrate`.
3. Implement terminal fold token `⊚` path.
4. Emit nucleant-on-return to mainline.
5. Add sparse traverse endpoint with budget.
6. Build first replay pipeline (L0-L2).

## Day-7 Backlog

1. Add fold/unfold selectors and progressive disclosure UI hooks.
2. Add archive policy thresholds and restart seeds.
3. Add replay L3-L5 references.
4. Add deterministic commitment vector tests.
5. Add dialect adapter harness (at least 2 adapters).

## Day-30 Backlog

1. Productionize archive/restart loop.
2. Add branch redundancy pruning.
3. Add equivalence classes for dedup/crystal composition.
4. Add tribunal integration contract (optional BODI).
5. Build operator dashboard for pressure/entropy/fold density.

## Debate Hall Policy (Minimal Membrane)

1. Fork freely.
2. Return with nucleant.
3. Lineage on authority claims.
4. Archive is optional.
5. Fold before overload.

## Chaos Protocol (Good Manner)

Use explicit operating modes to avoid accidental drift:

1. `hangout` mode: broad exploration, high forking.
2. `seminar` mode: structured challenge/reframe loops.
3. `heat` mode: adversarial pressure with strict lineage requirements.

Safety rails:

1. no unverifiable authority claims
2. no implicit cross-branch inheritance
3. all branch returns emit residue
4. fold pressure threshold enforced operationally

## Initial Success Metrics

1. artifact yield per session (nucleants + crystals)
2. replay fidelity score (L0-L5 consistency)
3. branch compression ratio (expanded to folded)
4. archive/restart stability (same seeds => same reachable commitments class)
5. dialect round-trip equivalence rate
