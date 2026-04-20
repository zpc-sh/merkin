# Graph View & SPARQL (Read‑Only) Spec

Status: Draft • Mode: Design/Brainstorm • Alignment: SEMANTIC_ALIGNMENT.md

## Goals
- Provide a read‑only graph surface for semantic queries
- Materialize RDF triples on demand from JSON‑LD + SQL provenance
- Keep JSON‑LD the primary contract; SPARQL is optional for power users

## Graph View Endpoints

### Graph Slice (by entity)
`GET /api/v1/graph/entities/{id}`
- Query params: `format=turtle|jsonld` (default jsonld)
- Returns JSON‑LD or Turtle for the entity and its immediate neighborhood

### Graph Query (predefined slices)
`GET /api/v1/graph/slices` with `slice=impacted-repos&org_token=v7`
- Supported slices:
  - `impacted-repos`: repos whose EffectiveTokenSet derives from token set `{org, version}`
  - `components-by-policy`: components validated against a rule
  - `provenance-trail`: generation activities for an entity

### SPARQL (optional)
`POST /api/v1/graph/sparql`
- Body: SPARQL query
- Limits: read‑only, time‑boxed, result size capped

## Security & Limits
- Require `read:graph` scope
- Rate‑limit SPARQL and slices separately
- Return 422 for unsupported features in SPARQL profile

## Implementation Plan (pragmatic)
1) JSON‑LD neighborhood builder using our contexts and IDs
2) Materialize triples in memory for the response (JLD framing → quads)
3) Predefined slices implemented via SQL and projected to JSON‑LD
4) Optional SPARQL endpoint using a light, embedded engine or a service adapter

