# Design Tokens API Spec (Org → Repo → Component)

Status: Draft • Audience: Backend/Frontend/Integrations • Mode: Design/Brainstorm

## Goals
- Make org hubs authoritative for design token sets
- Allow repos to derive EffectiveTokenSet with controlled overrides
- Bind token/version provenance to component releases
- Keep JSON‑LD as the primary contract; RDF/SPARQL compatible (see SEMANTIC_ALIGNMENT.md)

## Endpoints

### Create/Update Org Token Set
`POST /api/v1/orgs/{org_id}/design-tokens`
`Content-Type: application/ld+json`

Request (JSON‑LD, using pactis.context.jsonld):
```
{
  "@context": "https://pactis.dev/jsonld/pactis.context.jsonld",
  "@id": "pactis:token-sets/{org_id}/v{n}",
  "@type": "pactis:TokenSet",
  "version": "v7",
  "tokens": { ... },
  "metadata": {
    "orgId": "{org_id}",
    "prov:generatedAtTime": "2025-09-19T12:00:00Z"
  }
}
```

Response 201 Created:
```
{
  "id": "pactis:token-sets/{org_id}/v7",
  "version": "v7",
  "hash": "sha256:...",
  "created_at": "...",
  "conflicts": []
}
```

Notes
- Version is client or server assigned (policy); server enforces monotonicity
- Server validates token scopes and schema

### Get Org Token Set (Pinned)
`GET /api/v1/orgs/{org_id}/design-tokens/{version}`
`Accept: application/ld+json`

Response: JSON‑LD TokenSet with `@id`, `version`, `tokens`, `metadata`.

### Get Repo Effective Token Set
`GET /api/v1/repos/{owner}/{repo}/effective-design-tokens`
`Accept: application/ld+json`

Response:
```
{
  "@context": "https://pactis.dev/jsonld/pactis.context.jsonld",
  "@id": "pactis:effective-token-sets/{owner}/{repo}/{org_version}+{override_hash}",
  "@type": "pactis:EffectiveTokenSet",
  "derivedFrom": {
    "org": "pactis:token-sets/{org_id}/v7",
    "repoOverrides": "sha256:..."
  },
  "tokens": { ... },
  "hash": "sha256:...",
  "computedAt": "..."
}
```

Notes
- Computation is Org TokenSet ∪ Allowed Repo Overrides
- Includes provenance pointers

### Propose Repo Overrides
`POST /api/v1/repos/{owner}/{repo}/design-tokens`
`Content-Type: application/ld+json`

Request (subset/scoped):
```
{
  "@context": "https://pactis.dev/jsonld/pactis.context.jsonld",
  "@type": "pactis:TokenSet",
  "tokens": {
    "spacing": { "base": { "value": "1.25rem" } }
  }
}
```

Response 200 OK:
```
{
  "status": "applied|rejected|conflict",
  "effective": "pactis:effective-token-sets/{owner}/{repo}/{org_version}+{override_hash}",
  "messages": ["override within constraints"],
  "conflicts": []
}
```

Notes
- Server enforces scope constraints (locked/overridable)
- Violations return `status=conflict` with details

## Component Binding

On publish, components record:
- `designTokenSet`: `@id` of the EffectiveTokenSet
- `validatedAgainst`: list of `pactis:PolicyRule` IDs with result
- `provenance`: `prov:*` (activity id, generatedAtTime)

## Policy Rules (Sketch)

Schema (JSON):
```
{
  "id": "pactis:policy/color-contrast",
  "type": "rule",
  "severity": "error|warning",
  "params": {"minContrast": 4.5}
}
```

Validation pipeline:
1) Compute EffectiveTokenSet
2) Run rule checks → produce Validation records
3) Attach results to component JSON‑LD export

## Errors
- 409 Conflict: scope violation or incompatible overrides
- 422 Unprocessable Entity: malformed JSON‑LD or invalid schema
- 403 Forbidden: insufficient permissions (org vs repo)

## Security
- Org token endpoints require org‑scope `write:design-tokens`
- Repo overrides require repo `write:design-tokens` with scope checks
- EffectiveTokenSet GET requires `read:design-tokens`
