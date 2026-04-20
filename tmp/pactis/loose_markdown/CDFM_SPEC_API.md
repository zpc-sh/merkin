# Pactis Spec API (Workspace‑Scoped)

A concise, implementation‑ready specification for centralizing Spec Requests in Pactis. This replaces error‑prone FS handoffs with a clean HTTP API that integrates with Ash resources, AshAuthentication, Billing limits, and Ash PubSub events. It is designed to be the source of truth while preserving parity with existing Mix tasks.

## Overview

- Base path: `/api/v1/workspaces/:workspace_id/spec`
- Scope: All operations are scoped to a user’s workspace (authorization required)
- Source of truth: Pactis DB (Ash resources)
- Attachments: stored and referenced by relative paths (disk/S3)
- Auth: Bearer tokens via AshAuthentication pipeline (`:require_authenticated_api`)
- Billing: admission gates and usage events through existing billing pipeline
- Events: publish via `Ash.Notifier.PubSub` (no raw `Phoenix.PubSub` in controllers)

## Resources (Ash)

- Workspace (existing): used for scoping; includes `organization_id`
- SpecRequest
  - `id` (string, client‑supplied or server‑generated)
  - `workspace_id` (FK), `project` (string), `title` (string)
  - `status` enum: `proposed|accepted|in_progress|implemented|rejected|blocked`
  - `metadata` (map), `created_by` (user id), timestamps
- SpecMessage
  - `id` (string; client may supply for idempotency)
  - `request_id`, `workspace_id`
  - `type` enum: `comment|question|proposal|decision`
  - `from` (%{project, agent}), `body` (string)
  - `ref` (%{path, json_pointer}) optional
  - `attachments` ([string rel paths])
  - `created_at` (ISO8601) or set server‑side
- SpecAttachment (optional explicit table)
  - `id`, `request_id`, `workspace_id`, `path`, `content_type`, `size`, `checksum_sha256`, `storage_url|storage_key`
- SpecStatusTransition (optional audit)
  - `id`, `request_id`, `old_status`, `new_status`, `changed_by`, `changed_at`

## Authentication & Limits

- Authentication: `authorization: Bearer <token>` (AshAuthentication)
- Authorization: ensure token has access to `workspace_id`
- Billing gate on mutating routes (POST):
  - `Lang.Billing.can_make_request?(workspace.organization_id)`
  - On success: `Lang.Events.track_event/1` (usage)

## Eventing (Ash PubSub)

Publish via `Ash.Notifier.PubSub` with `module(CdfmWeb.Endpoint)` and transformed payloads.

- Topics (examples):
  - `spec:ws:<workspace_id>:request:<id>:message`
  - `spec:ws:<workspace_id>:request:<id>:status`
  - `spec:ws:<workspace_id>:request:<id>:export`
- Payloads:
  - Message: `%{request_id, message: <map>, at}`
  - Status: `%{request_id, status, previous, at}`
  - Export: `%{request_id, artifact: "jsonld", at}`

## Endpoints

All paths are prefixed with `/api/v1/workspaces/:workspace_id/spec`.

### 1) Create/Upsert Request
- POST `/requests`
- Body:
```json
{ "id": "demo-001", "project": "markdown_ld", "title": "Centralize spec tracking", "metadata": {"priority":"high"} }
```
- 200 OK (upsert) / 201 Created → request record

### 2) Get Request
- GET `/requests/:id`
- 200 OK → `{ id, project, title, status, metadata, created_by, message_count, last_message_at, ... }`

### 3) List Requests (optional MVP)
- GET `/requests?project=...&status=...&q=...&limit=50&after=<cursor>`

### 4) Append Message
- POST `/requests/:id/messages`
- Headers: `Idempotency-Key: <uuid>` (optional)
- Body:
```json
{
  "message": {
    "id": "client-msg-id-1",
    "type": "proposal",
    "from": {"project":"markdown_ld","agent":"codex"},
    "body": "Please update workflow_version to 0.1",
    "ref": {"path":"priv/spec_workflow.json","json_pointer":"/workflow_version"},
    "attachments": ["attachments/patch.json"],
    "created_at": "2025-09-01T12:00:00Z"
  },
  "attachments_content": {
    "attachments/patch.json": "<base64>"
  }
}
```
- Validated against existing `work/spec_requests/message.schema.json`
- 201 Created → canonical message JSON + stored attachments metadata

### 5) Pull Messages
- GET `/requests/:id/messages?since=<ISO8601>&limit=100&include_attachments=inline`
- 200 OK → ascending messages since `since`
- When `include_attachments=inline`, embed small `attachments_content` `{rel_path=>base64}`

### 6) Update Status
- POST `/requests/:id/status`
- Body: `{ "status": "in_progress" }`
- Validate transitions; record audit (optional)
- 200 OK → `{ id, status, updated_at }`

### 7) Export JSON‑LD (canonical)
- GET `/requests/:id/export.jsonld`
- 200 OK →
```json
{
  "request": {"@context":".../spec.jsonld","@type":"SpecRequest", ...},
  "ack": {"@type":"SpecAck", ...},
  "messages": [ {"@type":"SpecMessage", ...}, ... ]
}
```
- Use your existing JSON‑LD context (spec.jsonld) and compacted output

## Error Model

- 400 Invalid params → `{ error: { code: "bad_request", message, details } }`
- 401 Unauthorized → bearer missing/invalid
- 403 Forbidden → workspace access denied
- 404 Not Found → workspace/request not found
- 409 Conflict → idempotency key reused with different body
- 422 Validation error → schema/shape violations
- 429 Rate limited → billing/admission limit exceeded
- 500 Server error

## Semantics & Defaults

- `created_at` on messages accepted from client; default to server time if missing
- Idempotency: identical body + same `Idempotency-Key` → 200 OK (no duplicate); different body → 409 Conflict
- Pagination: `limit` + opaque `after` cursor on list endpoints
- `include_attachments=inline` must be size‑capped (e.g., ≤ 2MB total)

## Storage Strategy

- Start with disk:
  - `priv/spec_attachments/<workspace_id>/<request_id>/<rel_path>`
  - Compute `checksum_sha256`; dedupe or reuse existing blobs
- Later: S3 with `ex_aws_s3` (store `storage_key`, return signed URLs)

## Implementation Notes (Ash/Phoenix)

- Domain: `Cdfm.Spec` with resources `SpecRequest`, `SpecMessage`, `SpecAttachment`
- Controllers (suggested):
  - `CdfmWeb.Api.SpecRequestsController` (create/show/list)
  - `CdfmWeb.Api.SpecMessagesController` (create/index)
  - `CdfmWeb.Api.SpecStatusController` (create)
  - `CdfmWeb.Api.SpecExportController` (show)
- Pipelines: `:api` + `:require_authenticated_api`
- Authorization: verify `workspace_id` membership → derive `organization_id`
- Billing: gate POSTs; on success, `Lang.Events.track_event(%{event_type: "api_call_made", user_id, organization_id})`
- Validation: use embedded JSON Schemas; sanitize/limit sizes; reject path traversal
- Events: publish with `Ash.Notifier.PubSub` only (no raw Phoenix calls from controllers)
- Async: use Oban for heavy export jobs; publish `export` events when ready

## Mix Task Client Parity

Your existing Mix tasks can talk to this API:

- Push (messages):
  - `mix spec.msg.push --id <id> --api https://pactis.example.com --token <token>`
- Pull (messages):
  - `mix spec.msg.pull --id <id> --api https://pactis.example.com [--since <iso>]`
- Status:
  - `mix spec.status --id <id> --set in_progress --api https://pactis.example.com --token <token>`
- Export JSON‑LD (hub sync):
  - `mix spec.export.jsonld --id <id> --project <p> --hub <hub> --api https://pactis.example.com --token <token>`

## OpenAPI Path Sketch

```
POST /api/v1/workspaces/{workspace_id}/spec/requests
GET  /api/v1/workspaces/{workspace_id}/spec/requests/{id}
GET  /api/v1/workspaces/{workspace_id}/spec/requests
POST /api/v1/workspaces/{workspace_id}/spec/requests/{id}/messages
GET  /api/v1/workspaces/{workspace_id}/spec/requests/{id}/messages
POST /api/v1/workspaces/{workspace_id}/spec/requests/{id}/status
GET  /api/v1/workspaces/{workspace_id}/spec/requests/{id}/export.jsonld
```

## Example Payloads

- Create request
```http
POST /api/v1/workspaces/ws_123/spec/requests
Authorization: Bearer <token>
Content-Type: application/json

{ "id": "demo-001", "project": "markdown_ld", "title": "Centralize spec tracking" }
```

- Append proposal (with attachment content)
```http
POST /api/v1/workspaces/ws_123/spec/requests/demo-001/messages
Authorization: Bearer <token>
Idempotency-Key: 0b0f6e2f-...
Content-Type: application/json

{
  "message": {
    "type": "proposal",
    "from": {"project":"markdown_ld","agent":"codex"},
    "body": "Update workflow_version",
    "attachments": ["attachments/patch.json"]
  },
  "attachments_content": {
    "attachments/patch.json": "<base64>"
  }
}
```

- Pull messages since
```http
GET /api/v1/workspaces/ws_123/spec/requests/demo-001/messages?since=2025-09-01T15:00:00Z&limit=100
Authorization: Bearer <token>
```

- Update status
```http
POST /api/v1/workspaces/ws_123/spec/requests/demo-001/status
Authorization: Bearer <token>
Content-Type: application/json

{ "status": "in_progress" }
```

- Export canonical JSON‑LD
```http
GET /api/v1/workspaces/ws_123/spec/requests/demo-001/export.jsonld
Authorization: Bearer <token>
```

---

This document is portable: drop it into Pactis’s repo under `docs/` and implement using Ash resources, Phoenix controllers, and your existing auth/billing/eventing pipelines.

