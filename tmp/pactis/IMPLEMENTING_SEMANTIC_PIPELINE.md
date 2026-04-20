# Implementing the Pactis Semantic Pipeline

Status: Draft • Target: Teams integrating design tokens + component validation • Scope: JSON‑LD + Ash + Graph

## Overview
- JSON‑LD is the primary contract for components, token sets, validations, provenance
- Ash resources are the source of truth: we persist and derive from the DB
- Graph view is materialized from JSON‑LD slices and SQL; SPARQL is optional

## Key Resources
- TokenSet (org) → `Pactis.DesignTokens.TokenSet` (table: `design_token_sets`)
- EffectiveTokenSet (repo) → `Pactis.DesignTokens.EffectiveTokenSet` (table: `effective_token_sets`)
- ProvenanceEvent → `Pactis.Semantics.ProvenanceEvent` (table: `provenance_events`)
- ComponentValidation → `Pactis.Semantics.ComponentValidation` (table: `component_validations`)

## Endpoints
- Create/Update TokenSet (org): `POST /api/v1/orgs/:org_id/design-tokens`
- Get TokenSet (pinned): `GET /api/v1/orgs/:org_id/design-tokens/:version`
- Get EffectiveTokenSet (repo): `GET /api/v1/repos/:owner/:repo/effective-design-tokens`
- Propose Repo Overrides: `POST /api/v1/repos/:owner/:repo/design-tokens`

<!-- @spec-include path="docs/specifications/Pactis-DAI.md" section="Endpoints" -->
<!-- content is auto-generated; do not edit below this line -->
<!-- @end-spec-include -->

Auth/Scopes
- Reads: `read:design-tokens`
- Writes: `write:design-tokens`

## JSON‑LD Context
- Context served at `/jsonld/pactis.context.jsonld` (from `priv/jsonld`)
- Examples under `docs/jsonld/examples/`

## Effective Token Resolution
- Implemented in `Pactis.DesignTokens.EffectiveResolver`
- Supports scopes: locked, overridable, hint
- Enforces overridable constraints: min/max/step for dimensions

## Provenance
- Record events via `Pactis.Provenance.record/2` (logs + telemetry + SQL)
- Include `prov:*` in JSON‑LD exports for traceability

## Background Jobs
- `Pactis.DesignTokens.EffectiveTokenRecomputeJob` (Oban)
  - Triggered when org TokenSet changes; recompute EffectiveTokenSet for dependent repos

## CI/Dogfooding
- Mix alias: `mix semantic.check`
  - `pactis.jsonld.validate --dir priv/jsonld`
  - `pactis.jsonld.verify`
- CI alias: `mix ci` (creates DB, migrates, tests, semantic.check)

## Integration Steps for Other Teams
1) Define org TokenSet JSON‑LD (scopes, constraints) and POST to org endpoint
2) Allow repos to propose overrides (scoped) and fetch EffectiveTokenSet
3) Validate components on publish against EffectiveTokenSet and store Validation records
4) Export component JSON‑LD with `designTokenSet`, `validatedAgainst`, and `provenance`
5) Subscribe to webhooks or poll for updates; use graph slices/SPARQL if needed

## References
- SEMANTIC_ALIGNMENT.md
- DESIGN_LANGUAGE_HUB_INTEGRATION.md
- SPEC_DESIGN_TOKENS_API.md
- SPEC_GRAPH_VIEW.md
- docs/jsonld/examples/*

## Docs Sync Markers
- Sections can be auto-synced from specs using markers:
  - `<!-- @spec-include path="docs/specifications/Pactis-DAI.md" section="Endpoints" -->`
  - `<!-- @end-spec-include -->`
- Do not edit content between these markers; run `mix pactis.docs.sync` to refresh.
- CI checks for drift via the docs-sync workflow on pull requests touching `docs/**`.
