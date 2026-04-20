# Pactis Semantic Alignment (RDF • JSON‑LD • SPARQL)

Status: Design/Brainstorm • Scope: Spec alignment and pragmatic roadmap

## Why this exists

Pactis already uses JSON‑LD as the primary machine contract for components and design token exchange. This document aligns that work with the RDF model and sketches how we expose a SPARQL‑friendly view without forcing a triple store or changing the dev ergonomics.

Short version: JSON‑LD first; RDF‑compatible by design; SPARQL access optional and pragmatic.

## Design decisions

- JSON‑LD remains the primary serialization and API contract
- We adopt stable IRIs (`@id`) and types (`@type`) for all first‑class entities
- We define a small vocabulary for Pactis and reuse established ones where possible
- Provenance is first‑class (W3C PROV‑O)
- SPARQL is an optional surface, backed by a materialized or on‑the‑fly graph

## Namespaces

```
@prefix pactis:  <https://pactis.dev/vocab/> .
@prefix dlh:   <https://pactis.dev/vocab/dlh/> .
@prefix prov:  <http://www.w3.org/ns/prov#> .
@prefix dct:   <http://purl.org/dc/terms/> .
@prefix schema:<https://schema.org/> .
```

## Core classes (RDF types)

- `pactis:Organization`
- `pactis:Repository`
- `pactis:Component`
- `pactis:TokenSet` (org‑scoped authoritative design tokens)
- `pactis:EffectiveTokenSet` (repo‑derived result)
- `pactis:PolicyRule` (design governance rule)
- `pactis:Validation` (validation result for a component release)
- `pactis:Event` (semantic lifecycle events; conflicts/resolutions)

## Core properties

- Linking
  - `pactis:owns` (Organization → Repository)
  - `pactis:containsComponent` (Repository → Component)
  - `pactis:hasTokenSet` (Organization → TokenSet)
  - `pactis:hasEffectiveTokenSet` (Repository → EffectiveTokenSet)
  - `pactis:validatedAgainst` (Component → PolicyRule)
- Versioning / metadata
  - `dct:hasVersion` (TokenSet, Component)
  - `dct:created`, `dct:modified`
  - `prov:wasGeneratedBy`, `prov:generatedAtTime`, `prov:wasDerivedFrom`

## JSON‑LD alignment

Keep JSON‑LD as the source of truth. Always include a context with the prefixes above and emit `@id` values that are dereferenceable or resolvable by ID mapping.

Example (component excerpt):

```json
{
  "@context": {
    "@vocab": "https://pactis.dev/vocab/",
    "prov": "http://www.w3.org/ns/prov#",
    "dct": "http://purl.org/dc/terms/"
  },
  "@id": "pactis:components/abc123",
  "@type": "pactis:Component",
  "name": "Button",
  "version": "2.3.1",
  "designTokenSet": "pactis:token-sets/org-42/v7",
  "validatedAgainst": [
    {"@id": "pactis:policy/color-contrast"},
    {"@id": "pactis:policy/spacing-scale"}
  ],
  "provenance": {
    "prov:wasGeneratedBy": "pactis:build/def456",
    "prov:generatedAtTime": "2025-09-19T12:34:56Z"
  }
}
```

## SPARQL: optional, pragmatic

We do not require a triple store. We provide:

- A “graph view” endpoint that materializes core triples from JSON‑LD/SQL
- JSON‑LD framing and “slice” queries via our APIs for most clients
- Optional SPARQL endpoint (read‑only) for power users and integration testing

### Candidate SPARQL queries

1) Repos impacted by a TokenSet version change

```sparql
PREFIX pactis:  <https://pactis.dev/vocab/>
PREFIX dct:   <http://purl.org/dc/terms/>

SELECT ?repo ?ets
WHERE {
  ?org pactis:hasTokenSet ?ts .
  ?ts dct:hasVersion "v7" .
  ?repo pactis:hasEffectiveTokenSet ?ets .
  ?ets prov:wasDerivedFrom ?ts .
}
```

2) Components built against a given policy rule and token set

```sparql
PREFIX pactis: <https://pactis.dev/vocab/>
SELECT ?component
WHERE {
  ?component a pactis:Component ; pactis:designTokenSet <https://pactis.dev/token-sets/org-42/v7> ; pactis:validatedAgainst <https://pactis.dev/policy/color-contrast> .
}
```

3) Provenance trail for a component

```sparql
PREFIX prov: <http://www.w3.org/ns/prov#>
PREFIX pactis: <https://pactis.dev/vocab/>
SELECT ?activity ?when
WHERE {
  <https://pactis.dev/components/abc123> prov:wasGeneratedBy ?activity .
  ?activity prov:generatedAtTime ?when .
}
ORDER BY DESC(?when)
```

## Validation and shapes (optional)

Use SHACL for basic schema validation of our JSON‑LD graph slices (optional). Keep component and token JSON Schema alongside to serve the majority of clients.

## Content negotiation

- Default responses remain JSON (JSON‑LD)
- We can support `Accept: application/ld+json` and `Accept: text/turtle` for graph consumers
- Graph view endpoints may provide Turtle/JSON‑LD depending on `Accept`

## Roadmap (pragmatic)

1) Stabilize @id patterns and JSON‑LD contexts for all entities
2) Add provenance records to component release + token set updates (in SQL)
3) Expose a read‑only “graph view” route that materializes RDF from SQL/JSON‑LD
4) Add optional SPARQL endpoint (read‑only) backed by materialized view
5) Publish minimal SHACL shapes for Component, TokenSet, EffectiveTokenSet

## Glossary (plain‑English)

- RDF: A graph data model using triples (subject‑predicate‑object)
- JSON‑LD: JSON format that can describe an RDF graph via `@context`
- SPARQL: Query language for RDF graphs
- PROV‑O: W3C provenance ontology (who/what/when/how)

