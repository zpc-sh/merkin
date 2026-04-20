# Pactis-Sabha-Operations: Operation and Service Contracts

- Status: Draft
- Last Updated: 2026-04-02
- Owners: Pactis Core, Avici Working Group
- Related: Pactis-CCV2.md, Pactis-Sabha-Schemas.md

## Summary

This document defines the operation membrane for the Sabha profile:

1. typed move semantics
2. tree and branch operations
3. archive/restart thresholds
4. service boundaries

Transport is implementation-specific. HTTP endpoint examples below are a reference binding, not a transport requirement.

RPD/CSG symbol mapping for dialect adapters:

- [Pactis-Sabha-RPD-Profile.md](./Pactis-Sabha-RPD-Profile.md)

## 1) Service Boundaries

### Hall Service

Responsibilities:

- create sessions
- assign participants and roles
- accept moves from agents/humans
- route move intents to SMT substrate

### SMT Substrate Service

Responsibilities:

- persist trees/nodes/regions/branches/folds/archives
- execute fork/fold/unfold/prune/archive/restart
- provide sparse traversal queries
- emit commitment references

### Avici Crystallization Service

Responsibilities:

- collapse branch spaces to nucleants/crystals
- generate replay layers (L0-L5)
- deduplicate semantically equivalent branch residues

### Overlay Service

Responsibilities:

- generate text/SVG/HTML projections from SymbolForm
- preserve canonical reference links

### BODI Tribunal Service (Optional)

Responsibilities:

- post-hoc review of contested artifacts
- audit trail intake and rulings external to core run loop

## 2) Move Semantics

Allowed move types:

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

Semantics:

1. `assert`: creates or amends canonical claim-bearing nodes
2. `challenge`: marks targeted claims/constraints as disputed with lineage
3. `clarify`: narrows ambiguity without changing core claim intent
4. `concede`: marks previously asserted claim as withdrawn/revised
5. `reframe`: creates alternate symbolic framing, preserving source linkage
6. `fork`: opens one or more branches from a node or region frontier
7. `fold`: compresses source set into a fold handle with unfold selectors
8. `unfold`: materializes folded content by selector/budget
9. `collapse`: selects residue from branch set (node, nucleant, or crystal emit)
10. `crystallize`: composes nucleants into higher-order crystal structures
11. `prune`: removes low-mass/redundant branches while emitting residue optionally
12. `archive`: snapshots run state into an archive artifact
13. `rehydrate`: resumes from archive/seeds into a new or existing tree context

Dialect token pass-through:

1. move payloads MAY include native dialect token fields (for example RPD symbol markers)
2. canonical move records SHOULD preserve token values in provenance for replay fidelity

## 3) Operation Contracts (Reference HTTP Binding)

### Tree lifecycle

- `POST /trees` -> create tree
- `GET /trees/{treeId}` -> fetch tree
- `POST /trees/{treeId}/archive` -> archive tree
- `POST /archive` -> archive selected tree/region set (alias binding)
- `POST /trees/restart` -> restart from selected residues
- `POST /restart` -> restart from selected residues (alias binding)

### Diverge/Fork

- `POST /regions/{regionId}/diverge`

Request shape:

```json
{
  "perturbations": ["SymbolForm|params"],
  "policy": { "max_branches": 12 }
}
```

### Collapse

- `POST /collapse`

```json
{
  "branches": ["BranchId"],
  "criterion": "min_entropy|max_support|human_choice|agent_choice",
  "emit": "nucleant|crystal|node"
}
```

### Crystallize

- `POST /crystallize`

```json
{
  "structure": {
    "nodes": [],
    "branches": [],
    "regions": []
  },
  "scope": "local|global",
  "emit": "nucleant|crystal"
}
```

### Fold and Unfold

- `POST /fold`
- `POST /unfold`

```json
{
  "mode": "fold_back|fold_in|fold_over|fold_down",
  "source": [],
  "target": "NodeId|RegionId"
}
```

```json
{
  "fold_id": "FoldId",
  "selector": {
    "depth": 2,
    "predicate": "string?"
  }
}
```

### Prune

- `POST /prune`

```json
{
  "branches": ["BranchId"],
  "policy": {
    "redundancy": 0.92,
    "min_mass": 0.01,
    "emit_residue": true
  }
}
```

### Sparse Traverse

- `POST /traverse`

```json
{
  "tree_id": "TreeId",
  "strategy": "frontier|high_mass|contradiction_zones|latest_crystals",
  "budget": 128
}
```

### Overlay

- `POST /overlay/text`
- `POST /overlay/svg`
- `POST /overlay/html`

Input:

- canonical SymbolForm
- optional style policy

Output:

- projection payload + references to canonical commitments

## 4) Archive/Restart Threshold Policy

Reference policy:

```json
{
  "ArchivePolicy": {
    "max_branches": 800,
    "max_entropy": 12.0,
    "max_pressure": 10.0,
    "max_traversal_cost": 5000,
    "max_fold_density": 0.65,
    "max_latency_ms": 1500
  }
}
```

When threshold is exceeded:

1. crystallize priority regions into nucleants
2. archive current tree
3. restart from selected seeds

## 5) Determinism and Idempotency

1. Equivalent inputs under identical policy MUST produce equivalent reachable commitment sets.
2. Operations MUST support idempotent replay via idempotency keys or deterministic move IDs.
3. Archive snapshots MUST include policy and commitment snapshots required for reproducibility.

## 6) Compatibility with Existing Pactis APIs

1. SpecRequest/SpecMessage endpoints can mirror move logs and operator notes.
2. Existing Git/content APIs (PGI/PCI) can transport residue artifacts and overlay projections.
3. Existing Avici frame endpoints remain valid context suppliers for Hall session bootstrap.
