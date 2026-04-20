# Avici Harvest Flow — Quick Start

- Status: Draft
- Last Updated: 2025-09-20

This flow shows how to expose a service manifest, harvest it into Avici/KEI, and consume frames and search.

## 0) Expose your manifest
- Canonical: `GET /service.jsonld` (served from `priv/service.manifest.jsonld`)
- Aliases:
  - `GET /.well-known/pactis/service.jsonld` (well‑known)
  - `GET /zpc/avici/service` (vanity; 301 → /service.jsonld)

## 1) Configure SRI registry sources (local dev)
```
config :pactis, :sri_registry_sources, [
  "http://localhost:4000/zpc/avici/service"
]
```

## 2) Harvest (optional explicit sources)
POST /api/v1/avici/harvest (requires `write:avici`)

```
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"sources":["http://localhost:4000/zpc/avici/service"]}' \
  http://localhost:4000/api/v1/avici/harvest
```

Response: `{ "status": "enqueued" }`

Alternatively, harvest an SRI registry doc (expands to service manifests):

```
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"sources":["http://localhost:4000/docs/examples/sri_registry.jsonld"]}' \
  http://localhost:4000/api/v1/avici/harvest
```

## 3) List services (harvested)
GET /api/v1/avici/services (requires `read:avici`)

```
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:4000/api/v1/avici/services | jq .
```

## 4) Compact services view for AI
GET /api/v1/avici/services?view=compact (requires `read:avici`)

```
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:4000/api/v1/avici/services?view=compact" | jq .
```

Sample response row:

```
{
  "id": "pactis:service/pactis",
  "name": "Pactis Framework",
  "aiSummary": "Negotiated truth framework...",
  "capabilities": ["openapi"],
  "openapi": "/api/v1/openapi.json",
  "jsonapi": "/api/json",
  "manifests": [{"rel":"service","href":"/service.jsonld","type":"application/ld+json"}]
}
```
```

## 5) Build a Context Frame
GET /api/v1/avici/frame?indirection=3&mode=architect (requires `read:avici`)

```
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:4000/api/v1/avici/frame?indirection=3&mode=architect" | jq .
```

## 6) Naive search
GET /api/v1/avici/search?q=pactis&types=service,pattern,decision&limit=10 (requires `read:avici`)

```
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:4000/api/v1/avici/search?q=pactis&types=service,pattern,decision&limit=10" | jq .
```

## 7) Contribute knowledge (async)
- Upsert Pattern:

```
curl -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"title":"Async Billing Pipeline","description":"Oban workers for SMI","tags":["smi","billing"]}' \
  http://localhost:4000/api/v1/avici/patterns
```

- Upsert Decision:

```
curl -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"title":"Use Oban for jobs","rationale":"reliability/backoff","tags":["jobs","oban"]}' \
  http://localhost:4000/api/v1/avici/decisions
```

Notes
- Scopes: use API tokens with `read:avici` (GET) and `write:avici` (POST) scopes.
- In production, set `config :pactis, :sri_registry_sources, ["https://pactis.sh/zpc/avici/service", ...]`.
