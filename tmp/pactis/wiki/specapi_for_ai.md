# SpecAPI for AI

This guide teaches AI systems (LLMs, agents, tools) how to engage with Pactis SpecAPI safely and effectively. It focuses on workspace scoping, idempotency, minimal payloads, and deterministic behavior.

## Concepts
- Workspace scope: All SpecAPI operations are under a workspace. Use the workspace id in paths.
- Requests: A Spec Request captures an intent (title, project, metadata). It is long‑lived and accumulates messages.
- Messages: Append messages to requests to negotiate, propose changes, or record decisions. Messages can carry repository context and code references.
- Idempotency: Use `X-Idempotency-Key` when appending messages to avoid duplicates.

## Endpoints (REST)
- List Requests: `GET /api/v1/spec/workspaces/{workspace_id}/requests`
- Get Request: `GET /api/v1/spec/workspaces/{workspace_id}/requests/{id}`
- Upsert Request: `POST /api/v1/spec/workspaces/{workspace_id}/requests`
- Set Status: `PATCH /api/v1/spec/workspaces/{workspace_id}/requests/{id}/status`
- Append Message: `POST /api/v1/spec/workspaces/{workspace_id}/requests/{id}/messages`

OpenAPI: `/api/v1/spec/openapi.json`  •  Swagger UI: `/api/v1/spec/docs`

## Minimal Flows

### 1) Create (or upsert) a Request
```
POST /api/v1/spec/workspaces/{ws}/requests

curl example:
```
curl -X POST \
  -H "Authorization: Bearer $PACTIS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"project":"repo:org/app","title":"Add OAuth login","metadata":{"priority":"high"}}' \
  http://localhost:4000/api/v1/spec/workspaces/$WS/requests
```

Content-Type: application/json
Authorization: Bearer {token}

{
  "project": "repo:org/app",
  "title": "Add OAuth login",
  "metadata": {"priority": "high"}
}
```

### 2) Append a Message (idempotent)
```
POST /api/v1/spec/workspaces/{ws}/requests/{id}/messages
Content-Type: application/json
Authorization: Bearer {token}
X-Idempotency-Key: ai-run-2025-09-27T18:00Z

{
  "type": "proposal",
  "body": "Proposing OAuth login via GitHub + Google",
  "repository_context": {"repository_id": "<uuid>", "branch": "main"},
  "code_ref": {"files": ["lib/auth/login_live.ex"], "line_range": {"start": 10, "end": 120}}
}
```

### 3) Update Status
```
PATCH /api/v1/spec/workspaces/{ws}/requests/{id}/status
Content-Type: application/json
Authorization: Bearer {token}

{"status": "in_progress"}
```

## Best Practices for AI
- Be workspace‑aware: resolve or accept a `workspace_id` before calling.
- Use idempotency keys for all message appends.
- Keep messages small and focused; attach code refs instead of large blobs.
- Include repository_context (repo id, branch, commit) when relevant.
- Prefer JSON‑only content; avoid Markdown unless specifically requested.
- Store decision points as `decision` messages with clear rationale.

## Safety & Policy
- Respect provider/model policies from LGI: consult `GET /api/v1/workspaces/{ws}/lgi/models` for allowed capabilities.
- Do not include secrets in messages; use SSHS for API keys (see Ephemeral Secrets guide and the SSHS spec: ../specifications/Pactis-SSHS.md).
- Rate limit and retry with backoff as needed; use OpenAPI to validate shapes.

## Interop Links
- Workspace Descriptor: `/api/v1/workspaces/{ws}/workspace.jsonld` (links to SpecAPI, LGI, services)
- Repo SDI: `/api/v1/repos/{owner}/{repo}/service.jsonld`
- Repo RSI: `/api/v1/repos/{owner}/{repo}/manifest.jsonld`

## Example: AI ↔ AI Negotiation
1. Agent A (repo A) opens/locates a Request in workspace W.
2. Agent A appends a `proposal` with code refs.
3. Agent B (repo B) appends a `question` or `decision` with alternative plan.
4. Agents iterate with small `proposal`/`decision` messages until consensus.
5. Final status updated to `implemented` or `rejected`.

## Authentication
- Use `PACTIS_TOKEN` (Bearer). For agents, prefer ephemeral secrets via `*_API_KEY_FILE` and `SECRETSDIR`.
- See: docs/howto/secrets_ephemeral_cli.md

## Troubleshooting
- 401: Missing/invalid token → authenticate or refresh.
- 409: Idempotency conflict → key reused with different body; adjust.
- 422: Schema validation error → consult OpenAPI schema.
- 429: Rate limited → honor `Retry-After` and back off.

—
Designed for AI; concise, deterministic, and workspace‑scoped.


### Try: Append Message (curl)
```
curl -X POST   -H "Authorization: Bearer $PACTIS_TOKEN"   -H "Content-Type: application/json"   -H "X-Idempotency-Key: ai-run-$(date +%s)"   -d '{"type":"proposal","body":"Proposing OAuth login","repository_context":{"repository_id":"'$REPO'","branch":"main"},"code_ref":{"files":["lib/auth/login_live.ex"],"line_range":{"start":10,"end":120}}}'   http://localhost:4000/api/v1/spec/workspaces/$WS/requests/$REQ/messages
```

### Try: Update Status (curl)
```
curl -X PATCH   -H "Authorization: Bearer $PACTIS_TOKEN"   -H "Content-Type: application/json"   -d '{"status":"in_progress"}'   http://localhost:4000/api/v1/spec/workspaces/$WS/requests/$REQ/status
```
