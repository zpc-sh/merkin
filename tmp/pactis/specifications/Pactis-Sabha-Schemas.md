# Pactis-Sabha-Schemas: Canonical Object Contracts

- Status: Draft
- Last Updated: 2026-04-02
- Owners: Pactis Core, Avici Working Group
- Related: Pactis-CCV2.md, Pactis-Sabha-Operations.md

## Summary

This document defines canonical schema contracts for the Sabha profile.
Shapes below are JSON-schema-like and intentionally implementation-neutral.

## 1) Identifiers

```json
{
  "TreeId": "t_...",
  "NodeId": "n_...",
  "RegionId": "r_...",
  "BranchId": "b_...",
  "FoldId": "f_...",
  "NucleantId": "u_...",
  "CrystalId": "c_...",
  "ArchiveId": "a_...",
  "SessionId": "s_...",
  "AgentId": "ag_...",
  "MoveId": "mv_...",
  "CommitmentHash": "h_..."
}
```

## 2) Canonical Core Types

### SymbolForm

```json
{
  "SymbolForm": {
    "kind": "rpd_ir | proof_term | ast | graph | custom",
    "version": "string",
    "payload": "object|string|bytes",
    "refs": ["NodeId|BranchId|RegionId|NucleantId|CrystalId"]
  }
}
```

### Provenance

```json
{
  "Provenance": {
    "created_at": "iso8601",
    "created_by": "AgentId | system",
    "sources": ["NodeId|BranchId|RegionId|ExternalRef"],
    "lineage": {
      "parent_commitments": ["CommitmentHash"],
      "fork_origin": "NodeId|null",
      "fold_origins": ["FoldId"]
    },
    "notes": "string?"
  }
}
```

### Commitment

```json
{
  "Commitment": {
    "hash": "CommitmentHash",
    "algo": "blake3|sha256|custom",
    "covers": ["NodeId|NucleantId|CrystalId|FoldId|ArchiveId"],
    "metadata": {
      "size": 0,
      "hash_of_hashes": "string?"
    }
  }
}
```

## 3) Substrate Objects

### Tree

```json
{
  "Tree": {
    "id": "TreeId",
    "root": "NodeId",
    "status": "live|archived|restarted",
    "provenance": "Provenance"
  }
}
```

### Node

```json
{
  "Node": {
    "id": "NodeId",
    "tree_id": "TreeId",
    "parent": "NodeId|null",
    "children": ["NodeId"],
    "symbol": "SymbolForm",
    "claims": ["ClaimId or inline claim objects"],
    "constraints": ["ConstraintId or inline constraint objects"],
    "status": "active|folded|unfolded|pruned|archived|disputed",
    "commitment": "CommitmentHash",
    "provenance": "Provenance",
    "overlays": {
      "text": "string?",
      "svg": "string?",
      "html": "string?"
    }
  }
}
```

### Region

```json
{
  "Region": {
    "id": "RegionId",
    "tree_id": "TreeId",
    "frontier": ["NodeId"],
    "active_claims": ["ClaimId"],
    "tensions": ["TensionId"],
    "metrics": {
      "mass": 0.0,
      "entropy": 0.0,
      "pressure": 0.0,
      "attention_profile": {
        "heads": 0,
        "agents": ["AgentId"],
        "budget": 0.0
      }
    },
    "status": "live|collapse_ready|overloaded|dormant|archived",
    "provenance": "Provenance"
  }
}
```

### Branch

```json
{
  "Branch": {
    "id": "BranchId",
    "tree_id": "TreeId",
    "origin": "NodeId",
    "path": ["NodeId"],
    "metrics": {
      "mass": 0.0,
      "entropy": 0.0,
      "pressure": 0.0
    },
    "status": "active|prunable|crystallized|folded|archived",
    "provenance": "Provenance"
  }
}
```

### FoldHandle

```json
{
  "FoldHandle": {
    "id": "FoldId",
    "tree_id": "TreeId",
    "mode": "fold_back|fold_in|fold_over|fold_down",
    "source": ["NodeId|BranchId|CrystalId|NucleantId"],
    "target": "NodeId|RegionId",
    "unfoldable": true,
    "commitment": "CommitmentHash",
    "provenance": "Provenance"
  }
}
```

### Archive

```json
{
  "Archive": {
    "id": "ArchiveId",
    "created_at": "iso8601",
    "trees": ["TreeId"],
    "nucleants": ["NucleantId"],
    "crystals": ["CrystalId"],
    "commitments": ["CommitmentHash"],
    "policy": {
      "reason": "threshold|manual",
      "threshold_snapshot": {}
    },
    "provenance": "Provenance"
  }
}
```

## 4) Crystallization Objects

### SemanticNucleant

```json
{
  "SemanticNucleant": {
    "id": "NucleantId",
    "symbol": "SymbolForm",
    "cleartext": "string",
    "embedding": {
      "vector_ref": "string?",
      "model": "string",
      "dims": 0
    },
    "claims": ["ClaimId"],
    "proof_residue": ["ProofRef"],
    "source": ["BranchId|NodeId|RegionId"],
    "commitment": "CommitmentHash",
    "provenance": "Provenance",
    "replay": {
      "L0": "one paragraph",
      "L1": "key claims",
      "L2": "event trace",
      "L3": "graph ref",
      "L4": "key excerpts",
      "L5": "full transcript refs"
    }
  }
}
```

Invariant: if `embedding` exists, `cleartext` MUST exist.

### Crystal

```json
{
  "Crystal": {
    "id": "CrystalId",
    "nucleants": ["NucleantId"],
    "structure": "SymbolForm",
    "claims": ["ClaimId"],
    "proofs": ["ProofRef"],
    "commitment": "CommitmentHash",
    "provenance": "Provenance",
    "replay": {
      "L0": "string",
      "L1": "string",
      "L2": "string",
      "L3": "string",
      "L4": "string",
      "L5": "string"
    }
  }
}
```

## 5) Hall and Session Objects

### Agent

```json
{
  "Agent": {
    "id": "AgentId",
    "name": "string",
    "provider": "openai|anthropic|google|local|human",
    "capabilities": {
      "fork": true,
      "fold": true,
      "unfold": true,
      "overlay": true
    },
    "style": {
      "verbosity": "low|med|high",
      "risk": "low|med|high"
    },
    "constraints": {
      "safety": "default|loose|strict",
      "tools": []
    }
  }
}
```

### Session

```json
{
  "Session": {
    "id": "SessionId",
    "title": "string",
    "created_at": "iso8601",
    "tree_id": "TreeId",
    "participants": ["AgentId"],
    "mode": "hangout|seminar|heat",
    "prompt_seed": "SymbolForm|string",
    "policies": {
      "minimal": true,
      "allow_forks": true,
      "require_nucleant_on_return": true,
      "max_live_complexity": {
        "branch": 0,
        "entropy": 0.0,
        "pressure": 0.0
      }
    },
    "status": "live|ended|archived"
  }
}
```

### Move

```json
{
  "Move": {
    "id": "MoveId",
    "session_id": "SessionId",
    "actor": "AgentId",
    "timestamp": "iso8601",
    "type": "assert|challenge|clarify|concede|reframe|fork|fold|unfold|collapse|crystallize|prune|archive|rehydrate",
    "target": "NodeId|RegionId|BranchId|FoldId|null",
    "payload": "SymbolForm|object",
    "dialect": {
      "id": "string?",
      "version": "string?",
      "token": "string?"
    },
    "result_refs": ["NodeId|BranchId|FoldId|NucleantId|CrystalId|ArchiveId|TreeId"],
    "provenance": "Provenance"
  }
}
```

## 6) Global Invariants

1. Every committed object MUST reference a commitment hash.
2. Every move-derived object MUST preserve provenance lineage.
3. Overlay fields MUST NOT be treated as canonical truth inputs.
4. Fold operations MUST preserve unfold selectors when `unfoldable=true`.
5. Archive objects MUST include policy snapshot for reproducibility.
