# Pactis‑RSI: Repository Service Interface (Pattern)

- Status: Draft
- Last Updated: 2025-09-27
- Related: Pactis‑SDI (Service Self‑Description), Pactis‑KEI (Knowledge Engine), Pactis‑LGI (Language Gateway Interface)

## Summary
Repository‑scoped APIs expose resources and capabilities under a fully qualified repository name `:owner/:repo`. RSI standardizes the route grammar, discovery, JSON‑LD descriptors, and conventions (idempotency, error model, trace) so clients and agents can interact with any repository the same way across services (code, storage, registries).

## Route Grammar
- Base: `/api/v1/repos/:owner/:repo`
- Subresources (examples):
  - Contents: `/api/v1/repos/:owner/:repo/contents/*path`
  - SDI Descriptor: `/api/v1/repos/:owner/:repo/service.jsonld` (from Pactis‑SDI)
  - RSI Descriptor (this spec): `/api/v1/repos/:owner/:repo/manifest.jsonld`
  - Storage/OCI (service‑specific): `/api/v1/repos/:owner/:repo/blobs/:digest`, `/tags`, `/refs`, `/search`
- Transfers: `POST /api/v1/repos/:owner/:repo/transfer` (owner → user/org)
 - Transfers (dry‑run): `GET /api/v1/repos/:owner/:repo/transfer/dry-run?target_owner_type=organization|user&target_org_id=...|target_user_id=...`
 - Listings:
   - Org repos: `GET /api/v1/orgs/:org/repos`
   - User repos: `GET /api/v1/users/:user/repos`

## Discovery
- Entry points:
  - Repo descriptor (RSI): `GET /api/v1/repos/:owner/:repo/manifest.jsonld`
  - Service descriptor (SDI): `GET /api/v1/repos/:owner/:repo/service.jsonld`
- Workspace index (optional): `GET /api/v1/workspaces/:workspace_id/workspace.jsonld` links to repo‑scoped APIs that are available in that workspace.

## JSON‑LD Vocabulary
- `pactis:RepositoryDescriptor` (extends `schema:Dataset`)
- Fields (suggested):
  - `@id`: `pactis:repos/:owner/:repo`
  - `schema:name`: repository name or full name
  - `pactis:owner`: owner id/slug
  - `pactis:defaultBranch`: string (optional)
  - `pactis:capabilities`: ["oci.registry", "cas", "objects", "graph", "ai.memory"] (service‑specific)
  - `links`: list of `{rel, href, type?}`
  - `policy`: retention, immutability, size caps, encryption (service‑specific)
  - `provenance`: signatures/attestations, `prov:wasDerivedFrom`

## Example — manifest.jsonld
```
{
  "@context": {
    "pactis": "https://pactis.dev/vocab#",
    "schema": "https://schema.org/",
    "prov": "http://www.w3.org/ns/prov#"
  },
  "@type": ["pactis:RepositoryDescriptor", "schema:Dataset"],
  "@id": "pactis:repos/org/repo",
  "schema:name": "org/repo",
  "pactis:owner": "org",
  "pactis:defaultBranch": "main",
  "links": [
    {"rel": "contents", "href": "/api/v1/repos/org/repo/contents"},
    {"rel": "service", "href": "/api/v1/repos/org/repo/service.jsonld", "type": "application/ld+json"},
    {"rel": "workspace", "href": "/api/v1/workspaces/ws_id/workspace.jsonld", "type": "application/ld+json"}
  ]
}
```

## OCI/CAS Example — Kyozo RepositoryDescriptor
```
{
  "@context": {
    "pactis": "https://pactis.dev/vocab#",
    "schema": "https://schema.org/",
    "oci": "https://opencontainers.org/vocab#",
    "prov": "http://www.w3.org/ns/prov#"
  },
  "@type": ["pactis:RepositoryDescriptor", "schema:Dataset"],
  "@id": "pactis:repos/acme/memory",
  "schema:name": "acme/memory",
  "pactis:owner": "acme",
  "pactis:capabilities": ["oci.registry", "cas", "ai.memory"],
  "links": [
    {"rel": "oci-index", "href": "/api/v1/repos/acme/memory/index.json", "type": "application/vnd.oci.image.index.v1+json"},
    {"rel": "tags", "href": "/api/v1/repos/acme/memory/tags"},
    {"rel": "blobs", "href": "/api/v1/repos/acme/memory/blobs"},
    {"rel": "cas", "href": "/api/v1/repos/acme/memory/cas"},
    {"rel": "service", "href": "/api/v1/repos/acme/memory/service.jsonld", "type": "application/ld+json"}
  ],
  "policy": {
    "retentionDays": 30,
    "immutableTags": ["release-*"],
    "maxObjectSizeMB": 200,
    "encryption": "server-side"
  },
  "provenance": {
    "signatures": [{"type": "cosign", "subject": "index.json@sha256:..."}],
    "attestations": [{"type": "slsa", "predicateType": "slsaprovenance"}]
  }
}
```

## Conventions
- Idempotency: `Idempotency-Key` on POST/PUT/PATCH/DELETE (24h window)
- Error model: `{error:{code,message,type,details?,event_ids?}}` (aligns with LGI)
- Trace: W3C `traceparent`, `tracestate`; echo correlation ids in responses
- Streaming (optional): SSE/WS for large transfers or watch flows

## Ownership & Transfers
- Canonical owner: Each repository has exactly one owner — either an Organization or a User (never both).
- Representation:
  - Path: `:owner/:repo` where `:owner` resolves to an org or user namespace.
  - JSON‑LD: include `pactis:owner` (string id/slug); additional details can be linked via RSI/SDI as needed.
- Invariants:
  - Membership churn must not affect org‑owned repositories; repos remain with the org when members leave.
  - Prevent orphaning: disallow states with both `owner_id` and `owner_org_id` set or both unset.
  - Enforce explicit transfers; do not implicitly reassign on user/org deletion.
- Transfer API (recommended):
  - `POST /api/v1/repos/:owner/:repo/transfer` with body:
    ```json
    { "target_owner_type": "organization" | "user", "target_org_id": "..." | "target_user_id": "..." }
    ```
  - Semantics: validates permissions and collisions; on success updates canonical owner and recomputes derived identifiers (e.g., `full_name`, clone URLs).
  - Dry‑run: `GET /api/v1/repos/:owner/:repo/transfer/dry-run` — computes proposed identifiers, returns 200 on success or 409 with `code: full_name_conflict` if path exists.
  - Example (dry‑run):
    - Request: `GET /api/v1/repos/acme/myrepo/transfer/dry-run?target_owner_type=organization&target_org_id=ORG_UUID`
    - 200 Response
      ```json
      {
        "status": "ok",
        "proposed_full_name": "org-1234abcd/myrepo",
        "proposed_clone_url_http": "https://pactis.dev/org-1234abcd/myrepo.git",
        "proposed_clone_url_ssh": "git@pactis.dev:org-1234abcd/myrepo.git"
      }
      ```
    - 409 Response
      ```json
      {
        "error": "conflict",
        "code": "full_name_conflict",
        "details": ["proposed full_name already exists"],
        "proposed_full_name": "org-1234abcd/myrepo"
      }
      ```
- Deletion safeguards:
  - On user delete: require transfer/archive of user‑owned repos (409 until resolved).
  - On org delete: require transfer/archive of org‑owned repos; never cascade‑delete by default.
  - Optional archive policy is acceptable if well‑documented and reversible.

## Interop — Kyozo Store (OCI/CAS)
- Expose an RSI descriptor that links OCI index/refs and CAS endpoints
- Add capabilities: `oci.registry`, `cas`
- Provide media types and artifact types under `oci:{ index, manifests, artifactTypes }`

## Guidance
- Keep replicas consistent: repo descriptor stays thin; link to SDI (what) and workspace (where/now)
- Avoid duplication across descriptors; prefer linking (`prov:wasDerivedFrom`)
- Maintain stable routes and link relations for client portability
