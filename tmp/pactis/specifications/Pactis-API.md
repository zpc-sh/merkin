# Pactis-API: Artifact Publication Interface

- Status: Draft
- Last Updated: 2025-09-26
- Owners: Pactis Core
- Related: Pactis-PRI.md, Pactis-GRI.md, Pactis-VFS.md
- Notice: Pactis™ is an open specification by Pactis and is not affiliated with any other entity using similar names. ™ indicates an unregistered trademark claim.

## Purpose
Enroll sources, request generation, and fetch artifacts and pointers without mandating storage or transport coupling.

## Scope
- Enroll source; request generation by GeneratorDescriptor; retrieve ArtifactPointer and artifacts.

## API Sketch
- POST /enroll: register source with context policy.
- POST /generate: inputs + generator_version → ArtifactPointer.
- GET /artifacts/{pointer}: fetch immutable artifact (CAS semantics).

## Security Considerations
- Authentication
  - Browser: AshAuthentication session under `/auth`
  - API: Bearer auth via AshAuthentication API tokens (`cdfm_…`), with scopes
  - Scopes example: `read:components`, `write:components`, `admin`
- Authorization
  - Repository/source ownership checks
  - Workspace/org membership checks for org‑scoped endpoints
- Operational controls
  - Idempotency keys on generation
  - Rate‑limit generation endpoints (X‑RateLimit headers)
  - Validate JSON‑LD contexts; reject unknown/stale contexts per policy

## Rate Limits

All API endpoints may be subject to rate limiting. Responses include standard headers:

```
X-RateLimit-Limit: 120           # total requests allowed in window
X-RateLimit-Remaining: 42        # remaining requests in current window
X-RateLimit-Reset: 1732579200    # UNIX timestamp when window resets
```

On limit exceed (`429 Too Many Requests`), responses include:

```
Retry-After: 60
X-RateLimit-Limit: 120
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1732579200
```

Implementers SHOULD back off and retry after the indicated interval.

## Invitations (Org Management)
- `GET /api/v1/orgs/{org_id}/invitations` — list
- `GET /api/v1/orgs/{org_id}/invitations/{id}` — show
- `POST /api/v1/orgs/{org_id}/invitations` — create (email, role, message, expires_at)
- `DELETE /api/v1/orgs/{org_id}/invitations/{id}` — revoke
- `POST /api/v1/orgs/{org_id}/invitations/{id}/resend` — resend invitation
- `GET /auth/invitations/accept?token=...` — accept page
- `POST /auth/invitations/accept` — accept action (requires session auth)

## Conformance
- Idempotency keys; determinism checks; pointer immutability.
