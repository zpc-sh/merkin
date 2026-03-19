# Imprint Mirage Framework (v0.1)

This file captures the universal idea behind "lifting imprints" from any substrate object
into a fast, surface-only projection.

## Purpose

Imprint mirages are used when we want to:
- move quickly across large structures without full deep reasoning,
- preserve only appearance, topology, and contract-facing metadata,
- keep the system itself safer by minimizing payload exposure.

This is useful for:
- router projections,
- cross-AI handoff surfaces (Claude/Gemini/Opus/etc.),
- defense-oriented replay where timestamps are optional,
- forward/backward traversal where exact runtime truth is intentionally deferred.

## Core abstraction (implemented in `model/imprint.mbt`)

- `Imprint`: universal source record.
  - Has `source`, `kind`, `surface_projection`, `route_projection`,
    `contract_graph`, `horizon`, and `mode`.
  - Always has deterministic `imprint_id`.
  - Can carry optional `parent_imprint` for causal lineage.
- `Mirage`: hollow, portable projection from `Imprint::to_mirage`.
  - Always sets `has_private_payload = false`.
  - Retains `source_imprint` for traceability.

## Security / defense behavior

- Mirages are intentionally "empty by design" at the payload layer.
- They encode only route, contract labels, and visible mode.
- They are suitable for:
  - coarse routing,
  - quick comparisons across routers,
  - trust-gated projection assembly,
  - avoiding unnecessary engagement with contaminated raw substrate.

## Minimal operational mapping

- Lift a live route into a universal surface record:
  - `lift_router_imprint(router_id, route, contract_graph, parent)` -> `Imprint`
- Materialize a safe mirror for sharing:
  - `imprint.to_mirage()` -> `Mirage`
- Use as an input to future "projected form" tooling:
  - one imprint can project many times across horizons.

## Relation to existing cognitive overlays

This abstraction is designed to work with the INI/cognitive overlay model:
- Raw substrate remains in layer 1.
- Semantic representation remains in layer 2.
- Cognition overlays remain in layer 3.
- Mirage layers sit as an additional "fast transfer skin" when only shared appearance is required.

`Mirage` IDs still point back to the originating imprint so later full analysis can be recovered.

