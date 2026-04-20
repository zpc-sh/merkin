# Pactis-PQI: Pactis Query Interface

- Status: Draft
- Last Updated: 2025-09-26
- Owners: Pactis Core
- Related: Pactis-PRI.md, Pactis-API.md, Pactis-GRI.md, Pactis-TVI.md
- Notice: Pactis™ is an open specification by Pactis and is not affiliated with any other entity using similar names. ™ indicates an unregistered trademark claim.

## Summary

Query interface for Pactis semantic resources using an "implicit PARQL" model: JSON-LD graphs projected to queryable forms with stable filtering, sorting, pagination, and projection semantics aligned with Ash.Query.

## Abstract

PQI defines how clients express queries over Pactis resources without inventing a new language surface. Queries map to resource schemas and capabilities, compiling to the underlying data layer. Results are serializable as JSON-LD using the Pactis context (`https://pactis.dev/vocab#`).

## Content Types

- Requests: `application/json` for query envelopes; when embedding JSON-LD terms, include `@context` or rely on server defaults.
- Responses: `application/ld+json` for resource collections and items.

## Query Envelope (Illustrative)

```json
{
  "resource": "SpecRequest",
  "filter": {
    "status": {"in": ["accepted", "in_progress"]},
    "workspace_id": "ws-123",
    "inserted_at": {"gte": "2025-09-01T00:00:00Z"}
  },
  "sort": [{"field": "inserted_at", "direction": "desc"}],
  "select": ["id", "title", "status", "inserted_at"],
  "page": {"after": null, "limit": 50}
}
```

## Operators

- Equality/inequality: `eq`, `ne`
- Set: `in`, `nin`
- Range: `lt`, `lte`, `gt`, `gte`, `between`
- Text: `ilike`, `contains`
- Boolean: `is_true`, `is_false`
- Nested: dot-paths for relationships where supported

## Examples

List requests by tag and status
```http
POST /api/v1/query
Content-Type: application/json
Accept: application/ld+json

{ "resource": "SpecRequest", "filter": {"metadata.tags": {"contains": "security"}, "status": "accepted"} }
```

Response (truncated)
```json
{
  "@context": {"pactis": "https://pactis.dev/vocab#"},
  "@type": "pactis:Collection",
  "pactis:items": [
    {"@type": "pactis:SpecRequest", "@id": "pactis:spec/feature-user-authentication", "pactis:title": "Add OAuth2"}
  ],
  "pactis:pageInfo": {"hasNextPage": true, "endCursor": "opaque"}
}
```

## Security Considerations

- Enforce tenant scoping and per-resource authorization on all queries.
- Rate-limit and bound `limit` to prevent exhaustive scans; support pagination only.
- Redact sensitive fields by default and require explicit scopes for privileged projections.

## Conformance

- Support a stable baseline of operators and deterministic sort semantics (tie-break on primary key).
- Return `application/ld+json` with Pactis context and typed items.
- Implement cursor-based pagination; document maximum page size and default ordering.

