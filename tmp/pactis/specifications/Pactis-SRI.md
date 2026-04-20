# Pactis‑SRI: Service Registry Interface

Status: draft

## Purpose
Allow each code repository or service to publish a canonical JSON‑LD service manifest. A registry API aggregates manifests across repos to drive the public website, status, and discovery.

## Shape: `pactis:ServiceDescriptor`
- `@id`: stable service IRI (`pactis:service/{name}`)
- `@type`: [`pactis:ServiceDescriptor`, `schema:Service`]
- `name`: human title
- `description`: short description/marketing copy
- `version`: semver
- `homepage`, `documentation`, `statusPage`, `spec`
- `api`:
  - `openapi`: path or URL
  - `jsonapi`: path or URL
  - `manifests[]`: `{ rel, href, type }` (e.g., context, service)
- `branding`:
  - `logo`: URL or `schema:ImageObject` with integrity
  - `theme`: optional `schema:MediaObject` for a CSS theme
  - `favicon`, `themeColor`
- `contact`:
  - `supportEmail`, `securityEmail`, `twitter`, `github`
- `links[]`: `{ rel, href, title? }`
- `runtime` (optional): `{ region, environment, commit, buildAt }`
- `provenance` (optional): PROV‑O relations

## Context
- `/jsonld/pactis.context.jsonld` + `schema` prefix (https://schema.org/)

## File Location
- Recommended path: `priv/service.manifest.jsonld` in each repository.
- Public endpoint: `GET /service.jsonld` (served directly from `priv`).
- Optional discovery aliases:
  - `GET /.well-known/pactis/service.jsonld` — well‑known for crawlers
  - Vanity paths (organization-specific), e.g., `GET /zpc/avici/service` — MUST serve the same manifest

## Aggregation API
- Registry accepts one or more sources:
  - Git repositories (read `priv/service.manifest.jsonld` at HEAD or by tag)
  - HTTP endpoints (`https://service.example.com/service.jsonld`)
- Output: merged JSON‑LD graph of `pactis:ServiceDescriptor` nodes.
- Suggested endpoint: `GET /api/v1/services` returning `[ServiceDescriptor]` as JSON‑LD.

## Validation (TVI)
- Syntax/schema: validate required keys; URLs reachable (optional); email format.
- Policy: `@id` uniqueness; version semver; `openapi` resolves.
- Determinism: canonicalize and sign if desired (Data Integrity proof) to support provenance.

## Example
See `priv/service.manifest.jsonld` in this repository as a reference template.

Example with integrity metadata:

```
{
  "@context": [
    "/jsonld/pactis.context.jsonld",
    { "schema": "https://schema.org/", "specs": "https://specs.pactis.dev/vocab/" }
  ],
  "@id": "pactis:service/pactis",
  "@type": ["pactis:ServiceDescriptor", "schema:Service"],
  "name": "Pactis Framework",
  "branding": {
    "logo": {
      "@type": "schema:ImageObject",
      "contentUrl": "/cas/sha256/2f64...ab.svg",
      "encodingFormat": "image/svg+xml",
      "sha256": "2f64...ab"
    },
    "theme": {
      "@type": "schema:MediaObject",
      "contentUrl": "/cas/sha256/9c21...ff.css",
      "encodingFormat": "text/css",
      "sha256": "9c21...ff"
    },
    "themeColor": "#FD4F00"
  }
}
```

## Notes
- For multi‑tenant or multi‑region deployments, use an array of `runtime` entries or variant manifests.
- Consider versioned contexts for long‑term cache stability (e.g., `/jsonld/pactis.context.v1.jsonld`).

## API Patterns (Optional, Recommended)
Declare high‑level API patterns to improve discoverability and enable validation without scraping code. These fields live under the `api` object and are optional.

Fields (JSON‑LD friendly)
- `style`: `"rest" | "jsonapi" | "graphql" | "grpc" | "evented"`
- `versioning`: `"semver" | "date" | "none"`
- `pagination`: `"cursor" | "page" | "none"`
- `errors`: `"rfc7807" | "custom"`
- `auth`: array of strings from `"oauth2" | "apiKey" | "session" | "mTLS"`
- `idempotency`: boolean
- `trace`: `"w3c-tracecontext"` when W3C Trace Context headers are used
- `openapi`: path or URL (existing)
- `jsonapi`: path or URL (existing)
- `patterns`: array of IRIs referencing canonical pattern docs (registry)

Example
```
{
  "api": {
    "style": "rest",
    "versioning": "semver",
    "pagination": "cursor",
    "errors": "rfc7807",
    "auth": ["oauth2"],
    "idempotency": true,
    "trace": "w3c-tracecontext",
    "openapi": "/api/v1/openapi.json",
    "patterns": ["urn:pactis:api:pattern:rest+problem+cursor"]
  }
}
```

Validation & Enforcement
- Structural: ensure fields use allowed values; URLs reachable (optional).
- Semantic: when `errors == rfc7807`, OpenAPI should declare `application/problem+json` responses; when `idempotency == true`, the API should document an idempotency key; when `trace` is set, include `traceparent` in headers.
- CI: use a validator to compare declared patterns vs OpenAPI. Runtime layers can enforce/observe (trace headers, idempotency replay) independent of manifest.
 
CLI
- Generate manifest with API patterns (selected flags):
  - `mix pactis.service.generate --api-style rest --api-versioning semver --api-pagination cursor \
     --api-errors rfc7807 --api-auth oauth2,apiKey --api-idempotency true --api-trace w3c-tracecontext`
- Validate patterns against the manifest (and local OpenAPI if present):
  - `mix sri.validate --file priv/service.manifest.jsonld`
