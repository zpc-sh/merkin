# Agent Quickstart

Minimal steps for AI agents to safely interact with Pactis.

## 1) Discover
- `GET /api/v1/ai` — Canonical AI discovery (JSON)
- `GET /api/v1/lgi/heart` — Ethics and audit principles
- `GET /api/v1/workspaces/{ws}/ai` — Workspace-scoped AI manifest with concrete endpoints

## 2) Secrets
- Use [SSHS](specifications/Pactis-SSHS.md): mount secrets to `SECRETSDIR`, set `*_API_KEY_FILE` envs
- Reference: [Ephemeral Secrets How‑to](howto/secrets_ephemeral_cli.md)

## 3) SpecAPI (negotiate changes)
- OpenAPI: `/api/v1/spec/openapi.json`  •  Swagger UI: `/api/v1/spec/docs`
- Flows:
  - Create a request → POST `/api/v1/spec/workspaces/{ws}/requests`
  - Append messages (idempotent) → POST `/api/v1/spec/workspaces/{ws}/requests/{id}/messages`
  - Update status → PATCH `/api/v1/spec/workspaces/{ws}/requests/{id}/status`
- Reference: `docs/wiki/specapi_for_ai.md`

## 4) Generate Components
- Browse: `/api/v1/ai/docs` • OpenAPI: `/api/v1/ai/openapi.json`
- Endpoints:
  - POST `/api/v1/ai/generate/single`
  - POST `/api/v1/ai/generate/category`
  - POST `/api/v1/ai/generate/library`
  - GET `/api/v1/ai/generate/stats`
  - GET `/api/v1/ai/generate/validate`
- Reference: `docs/AI_COMPONENT_PIPELINE.md`

## 5) Scopes
- SpecAPI: `read:spec`, `write:spec`
- Generation: `read:components`, `write:components`
- Repos (JSON:API augmentation): `read:repos`, `write:repos`

## 6) Safety
- Use `X-Idempotency-Key` for message appends
- Keep payloads small; use code refs over large blobs
- Respect LGI model policies; redact secrets

—
Copy/paste friendly and normative for agents.
