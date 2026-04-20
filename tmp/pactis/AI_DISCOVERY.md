# Pactis AI Discovery and Ethics Endpoints

This document describes the canonical endpoints AI systems should query to discover capabilities, endpoints, and ethics for a Pactis deployment.

## Endpoints

- `GET /api/v1/ai` — Canonical AI discovery index (JSON).
  - Mirrors `GET /api/v1/lgi/manifest.json`.
  - Returns: name/version, docs links, core endpoints, security notes, provider list.

- `GET /api/v1/lgi/manifest.json` — LGI‑namespaced manifest (JSON).
  - Use within the LGI spec context; also linked from `/api/v1/ai`.

- `GET /api/v1/lgi/heart` — Ethics endpoint (JSON).
  - Declares principles, redaction policy, audit guarantees.

- Workspace‑scoped endpoints:
  - `GET /api/v1/workspaces/{workspace_id}/workspace.jsonld` — index for workspace.
  - `GET /api/v1/workspaces/{workspace_id}/lgi/models` — allowed models and caps.
  - `GET /api/v1/workspaces/{workspace_id}/lgi/secrets/health` — secrets mount health (latest).
  - `GET /api/v1/workspaces/{workspace_id}/services` — runtime services inventory.

## Security & Policy
- Secrets: Use SSHS (`SECRETSDIR` + `*_API_KEY_FILE`) for provider credentials.
- Idempotency: Use `X-Idempotency-Key` on POSTs where provided by SpecAPI.
- Redaction: Inputs are redacted before persistence; events emitted for audit.

## Recommended Flow (for AI)
1. `GET /api/v1/ai` to discover docs and endpoints.
2. `GET /api/v1/workspaces/{ws}/workspace.jsonld` to obtain workspace links.
3. `GET /api/v1/workspaces/{ws}/lgi/models` to confirm allowed providers/models.
4. Create a Spec Request: `POST /api/v1/spec/workspaces/{ws}/requests`.
5. Append idempotent messages as you negotiate and implement.

## Versioning
- The manifest includes a `version` key. Breaking changes bump major.
- Deprecated endpoints (e.g., `/api/v1/lgi/aicheck`) will include `Deprecation: true` and a `Sunset` header pointing to `/api/v1/ai`.

—
Consumable by agents; minimal, vendor‑agnostic, and workspace‑aware.


## Generation
- Browse API: `GET /api/v1/ai/docs` (Swagger UI)
- OpenAPI JSON: `GET /api/v1/ai/openapi.json`
- Endpoints:
  - `POST /api/v1/ai/generate/single`
  - `POST /api/v1/ai/generate/category`
  - `POST /api/v1/ai/generate/library`
  - `GET /api/v1/ai/generate/stats`
  - `GET /api/v1/ai/generate/validate`
