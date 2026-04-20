# Semantic Integration Guide

Status: Draft • Audience: Third‑party teams integrating Pactis’s semantic pipeline

## Overview
This guide shows how to use Pactis’s design tokens + validation pipeline using JSON‑LD and Ash resources. It covers creating org token sets, deriving repo effective token sets, validating components on publish, and exploring the semantic graph.

## Prerequisites
- API token with appropriate scopes
- JSON‑LD familiarity (basic)

## Scopes
- `read:design-tokens` to read tokens
- `write:design-tokens` to publish org token sets and repo overrides

## Endpoints
- Create/Update TokenSet (org): `POST /api/v1/orgs/:org_id/design-tokens`
- Get TokenSet (pinned): `GET /api/v1/orgs/:org_id/design-tokens/:version`
- Get EffectiveTokenSet (repo): `GET /api/v1/repos/:owner/:repo/effective-design-tokens`
- Propose Repo Overrides: `POST /api/v1/repos/:owner/:repo/design-tokens`
- Publish Component (validate): `POST /api/v1/components/:id/publish`

## JSON‑LD Context
- `GET /jsonld/pactis.context.jsonld`

## Example: Create an Org Token Set
```bash
curl -H "Authorization: Bearer $PACTIS_TOKEN" \
     -H "Content-Type: application/ld+json" \
     -X POST \
     https://api.pactis.dev/api/v1/orgs/$ORG_ID/design-tokens \
     -d @docs/jsonld/examples/token_set.jsonld
```

## Example: Get Repo Effective Token Set
```bash
curl -H "Authorization: Bearer $PACTIS_TOKEN" \
     https://api.pactis.dev/api/v1/repos/$OWNER/$REPO/effective-design-tokens?org_version=v7
```

## Example: Propose Repo Overrides
```bash
cat <<'JSON' > overrides.json
{
  "@context": "https://pactis.dev/jsonld/pactis.context.jsonld",
  "@type": "pactis:TokenSet",
  "tokens": {
    "spacing": { "base": { "value": "1.25rem" } }
  }
}
JSON

curl -H "Authorization: Bearer $PACTIS_TOKEN" \
     -H "Content-Type: application/ld+json" \
     -X POST \
     https://api.pactis.dev/api/v1/repos/$OWNER/$REPO/design-tokens \
     -d @overrides.json
```

## Example: Publish a Component and Validate
```bash
curl -H "Authorization: Bearer $PACTIS_TOKEN" \
     -X POST \
     https://api.pactis.dev/api/v1/components/$COMPONENT_ID/publish \
     -d '{"owner":"org-42","repo":"button","org_version":"v7"}'
```

The response includes a `validation_id` and `status`. Component JSON‑LD exports include `designTokenSet` and `validatedAgainst` once validations exist.

## Graph View (Optional)
- `GET /api/v1/graph/entities/:id?format=jsonld|turtle` — entity neighborhood
- `GET /api/v1/graph/slices?slice=impacted-repos&org_token=v7` — predefined slices
- `POST /api/v1/graph/sparql` — read‑only SPARQL (optional)

## References
- ../SEMANTIC_ALIGNMENT.md
- ../SPEC_DESIGN_TOKENS_API.md
- ../SPEC_GRAPH_VIEW.md
- ../jsonld/examples/*
