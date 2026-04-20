# Locus Adjoin Contract v0.1

Date: `2026-04-19`

## Purpose

Define a composable machine contract for locus-to-locus composition.

Canonical operations:
- `union`
- `consume`
- `atop`
- `subtract`
- `yata_union` (locus + yata locus; typed locus that is void)

## Contract Identity

- `kind`: `merkin.locus.adjoin.contract`
- `version`: `v0.1`
- `track`: `program`
- `ratio_loci`: required authority marker

## Core Objects

### LocusRef

```json
{
  "locus_id": "genius://merkin/alpha",
  "surface_ref": "finger.plan.wasm#alpha",
  "profile_ref": "surface.plan#alpha",
  "seal": "blake3:..."
}
```

### YataLocusRef (typed void)

```json
{
  "kind": "merkin.yata.locus",
  "yata_plan_ref": "merkin.yata.plan#hole-123",
  "expected_type": "Observation|Compilation|Delegation|Resolution|Audit|Synthesis",
  "void_typed": true,
  "min_confidence": 70,
  "seal": "blake3:..."
}
```

`void_typed=true` means the locus is intentionally unfilled but strongly typed by Yata contract.

## Recursive Expression Model

Any composition is an expression tree.

```json
{
  "op": "union|consume|atop|subtract|yata_union",
  "left": { "expr": "..." },
  "right": { "expr": "..." },
  "meta": {}
}
```

Leaf form:

```json
{ "locus": { "...LocusRef" } }
```

or

```json
{ "yata_locus": { "...YataLocusRef" } }
```

This makes all operations composable and nestable in any direction.

## Operation Semantics

### 1) `union`

Form: `A union B`

- peer composition
- no implicit hierarchy
- shared exchange through explicit contract surfaces

Required invariants:
- identity preserved for both sides
- namespace conflicts resolved explicitly
- no hidden privilege inheritance

### 2) `consume`

Form: `A consume B`

- A wraps B
- B exports are mediated by A policy/capability scope

Required invariants:
- B remains attestable
- B cannot escalate beyond A boundary
- mediation must be visible in projection output

### 3) `atop`

Form: `A atop B`

- A is governance/proxy layer over B
- B remains independently recoverable

Required invariants:
- no silent Base mutation
- provenance required for top-driven decisions
- delegation scope explicit and bounded

### 4) `subtract`

Form: `A subtract B`

- deterministic pattern difference or time delta
- emits minimal replay-safe change artifact

Required invariants:
- determinism (`same inputs -> same diff seal`)
- closure (`B + diff = A` for applicable mode)
- no prohibited raw payload leakage

### 5) `yata_union`

Form: `L yata_union Y`

Where:
- `L` is concrete locus
- `Y` is typed-void Yata locus

Intent:
- adjoin an explicit typed gap to a concrete locus
- let FSM/runtime fill from typed contract without forcing immediate materialization

Required invariants:
- typed void must declare `expected_type` and `min_confidence`
- no execution command in Y payload
- transitions from void -> resolved must emit provenance witness
- unresolved typed void remains first-class state, not error

## Normalized Wire (`adjoin.v0`)

```json
{
  "kind": "merkin.locus.adjoin.contract",
  "version": "v0.1",
  "contract_id": "adjoin-20260419-001",
  "ratio_loci": "ratio://merkin/root",
  "expr": {
    "op": "union",
    "left": {
      "expr": {
        "op": "consume",
        "left": { "locus": { "locus_id": "genius://repo/root", "seal": "blake3:aaa" } },
        "right": { "locus": { "locus_id": "genius://repo/agent", "seal": "blake3:bbb" } },
        "meta": { "policy_mode": "sanitize" }
      }
    },
    "right": {
      "expr": {
        "op": "yata_union",
        "left": { "locus": { "locus_id": "genius://repo/root", "seal": "blake3:aaa" } },
        "right": {
          "yata_locus": {
            "kind": "merkin.yata.locus",
            "yata_plan_ref": "merkin.yata.plan#hole-attn-14",
            "expected_type": "Observation",
            "void_typed": true,
            "min_confidence": 72,
            "seal": "blake3:ccc"
          }
        },
        "meta": { "route_hint": "mu-fsm-observe" }
      }
    },
    "meta": { "federation": "pactis" }
  },
  "required_surfaces": [
    "finger.plan.wasm",
    "merkin.yata.plan",
    "triad-contract"
  ],
  "boundary_mode": "sanitize",
  "seal": "blake3:final"
}
```

## Validation Rules

A valid contract MUST:
- use known `op`
- have exactly one leaf type (`locus` or `yata_locus`) per leaf node
- include `seal` for all leaf references and top-level contract
- include `ratio_loci`
- remain acyclic by expression identity

Additional rules:
- if `op=yata_union`, right leaf MUST be `yata_locus` with `void_typed=true`
- if `op=subtract`, `meta.diff_mode` SHOULD be one of `pattern|temporal|structural`
- all contracts MUST declare `boundary_mode` (`observe|sanitize|strict|quarantine`)

## Composability Guarantees

1. Closure: output of any operation is a locus expression node and can be input to any operation.
2. Deterministic sealing: same normalized expression and leaves produce same top-level seal.
3. Replay safety: contracts carry references, not imperative execution scripts.
4. Boundary safety: boundary mode applies per edge and to the full expression.

## Error Codes (v0.1)

- `BAD_KIND`
- `BAD_VERSION`
- `UNKNOWN_OP`
- `MISSING_RATIO_LOCI`
- `BAD_LEAF_SHAPE`
- `MISSING_SEAL`
- `CYCLE_DETECTED`
- `INVALID_YATA_UNION_RIGHT`
- `INVALID_VOID_TYPED`
- `UNSAFE_BOUNDARY_MODE`

## Immediate Integration Points

- Merkin: parse/validate expression and emit canonical seal
- Mu: consume `yata_union` typed void lanes as FSM work units
- Lang: route by `meta.route_hint` and capability class
- Pactis: treat contract as federation edge artifact, not ticket metadata

