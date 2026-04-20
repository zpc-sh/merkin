Pactis LGI — Language Gateway Interface

Overview
- Purpose: a stable, vendor-agnostic interface for AI interactions (chat, tools, LSP-ish operations) exposed via HTTP and internally via a thin client.
- Goals: deterministic versioning with Ash-style Events, observability, and consistent safety controls regardless of provider.

Guiding Principles
- Event-first: every interaction emits versioned events; state is derived from events.
- Vendor-agnostic: requests are normalized and routed; providers can change without clients.
- Safe-by-default: rate limits, redaction, and policy checks applied before provider calls.
- Minimal surface: small, composable operations (chat, tool.invoke, tool.describe, session lifecycle).

Event Model (AshEvents)
- LGI.Event.V1.ToolDeclared: publish a tool’s schema and capabilities.
- LGI.Event.V1.ToolInvoked: record an invocation request (idempotent key, actor, inputs).
- LGI.Event.V1.ToolResult: record the resolved result (success/error, outputs, latency, cost).
- LGI.Event.V1.ChatStarted/ChatMessage/ChatCompleted: capture conversational sequences.
- LGI.Event.V1.ModelCallStarted/ModelCallCompleted: lower-level provider call details for auditing.
- LGI.Event.V1.PolicyDecision: record allow/deny with rule references and redactions performed.

Versioning
- Major versions reflect shape changes to events and request/response schemas.
- Producers emit both canonical events and provider-specific extras under `meta.provider`.
- Consumers rely on canonical fields; extras are optional/extensible.

HTTP Surface (initial)
- GET `/api/v1/lgi/spec`: returns the LGI OpenAPI snippet and event catalog with current versions.
- GET `/api/v1/lgi/tools`: lists available tools with JSON Schema definitions.
- POST `/api/v1/lgi/execute`: invokes a tool. Body: `{tool: string, input: map, context?: map}`. Emits ToolInvoked/ToolResult.
- POST `/api/v1/lgi/chat`: simple chat completion. Body: `{messages: [...], options?: map}`. Emits ChatStarted/ChatCompleted and ModelCall events.

Internal Client
- `Pactis.AI.ReqClient` is the only allowed transport for model calls; it wraps `req_llm` for vendor-neutral access.
- Services call `Pactis.AI.ReqClient.chat/2` and `...tool_call/3` instead of hitting providers directly.
- Router-level heuristics and caching remain orthogonal; enforcement is at the boundary.

Policies & Enforcement
- Pre-call hooks: redact secrets, apply per-tenant rate limits, reject disallowed tools/models.
- Transport enforcement: forbid direct HTTP calls to vendor endpoints in services; emit deprecation warnings in legacy providers; add static check (CI) later.

Observability
- Each request logs correlation id, actor, tenant, tool/model, token counts, and latency.
- Costs are estimated via router and recorded alongside events.

Service‑Wide Discovery & Ethics
- Discovery:
  - `GET /api/v1/ai` — canonical AI discovery index (JSON); vendor‑agnostic.
  - `GET /api/v1/lgi/manifest.json` — LGI‑namespaced manifest (JSON).n- Per‑Workspace AI Manifest:n  - `GET /api/v1/workspaces/{workspace_id}/ai` — tailored AI manifest for a workspace (concrete endpoints with workspace id).
- Ethics:
  - `GET /api/v1/lgi/heart` — ethics endpoint; declares principles, redaction, audit.
- Workspace links: Use `GET /api/v1/workspaces/{ws}/workspace.jsonld` for per‑workspace links to LGI models, SpecAPI, and services.
- Deprecation: `GET /api/v1/lgi/aicheck` may return deprecation headers pointing to `/api/v1/ai`.
Event Model Details
- Required fields on all LGI events:
  - `event_id` (ULID), `correlation_id` (trace), optional `parent_event_id`
  - `occurred_at`, `received_at` clock fields
  - `tenant`, `actor` (type/id), `resource` (if applicable)
- Redaction accounting: record each redaction as `{field, method, range|hash}` in `meta.redactions`.
- Cost schema: `stats.input_tokens`, `stats.output_tokens`, `stats.latency_ms`, `stats.retry_count`, `stats.cached`, and `stats.cost` with `subtotal`, `unit_price`, `currency`, `rounding_policy`.
- Vendor extras remain under `meta.provider`.

Idempotency
- POST endpoints accept `Idempotency-Key` header.
- Semantics: same `tenant + tool + idempotency_key` within 24h returns the original result; mismatched inputs return `409 Conflict`.
- Emit `LGI.Event.V1.IdempotentReplay` when returning a replayed result.

HTTP Surface, Streaming, and Trace Context
- Accept and emit W3C Trace Context headers: `traceparent`, `tracestate`.
- Endpoints:
  - `POST /api/v1/lgi/execute`: synchronous tool invocation.
  - `POST /api/v1/lgi/chat`: synchronous chat completion.
  - `GET  /api/v1/lgi/chat/stream`: SSE streaming for chat deltas.
  - `WS   /api/v1/lgi/stream`: multiplexed streaming for chat/tool deltas.
- Enforce `Content-Type: application/json` for POST bodies, reject form-encoded payloads, enforce max body size.

Policy, Routing, and Allow-lists
- Model registry maps vendor model names to canonical capabilities: `chat`, `code`, `json_mode`, `tools`, `vision`, `large_context`.
- Route by required capabilities, not string equality of model names.
- Pre-call checks:
  - Per-tenant allow-list for models/tools; optional deny-list regex for prompts.
  - Secret redaction with hash proofs captured in `meta.redactions`.
- `dry_run: true` executes policy, routing, and cost estimation without provider calls.

OpenTelemetry and Sampling
- Emit OTEL spans with attributes:
  - `lgi.tool.invoke`, `lgi.chat`, `lgi.model.call`
  - attrs: `provider`, `model`, `tokens.in`, `tokens.out`, `cost.subtotal`, `cached`, `retry_count`, `throttle_ms`.
- Include `event_ids` in responses for linkage; include `trace_id`/`span_id` when available.
- Sampling strategy is configurable per tenant (always, rate, head/tail-based).

Ephemeral Secret Provisioning (SSHS)
- Rationale: Provide a vendor-agnostic, agent-friendly way to supply AI credentials without long-lived env leakage. Works for humans, shells, and non-inherited agent processes.
- Full spec: [Pactis-SSHS.md](./Pactis-SSHS.md)
- Contract:
  - `SECRETSDIR`: per-session directory containing plain files for each secret (e.g., `openai_api_key`, `anthropic_api_key`). Must be `0700`; files `0600`. On macOS suffix dir with `.noindex` and disable Spotlight.
  - `*_API_KEY_FILE`: env var pointing directly to a secret file (Docker-style convention).
- Resolution Order (normative): `*_API_KEY_FILE` → `*_API_KEY` → provider-managed identity (if applicable) → PROCSI → error.
- Reference Implementation:
  - `secrets.enc/` stores age-encrypted files committed to git; decrypt to an ephemeral dir (or RAM disk) using Secretive + age-plugin-ssh.
  - A `secrets-shell` script mounts the ephemeral dir, exports `SECRETSDIR`, and tears down on exit.
  - Provide a stable symlink fallback `~/.sshs/<project>` to the ephemeral dir for agents that don't inherit env.
  - TTL: 30–60 minutes recommended by keychain auto-lock or RAM-disk teardown.
- Platform Notes:
  - macOS: Prefer RAM disk under `/Volumes/Secrets-<project>`; disable Spotlight indexing.
  - Linux: Use `tmpfs` (e.g., `/run/user/$UID/sshs-<project>`).
  - APFS secure deletion is best-effort; RAM disk avoids residuals entirely.
- Pactis Changes:
  - Providers now honor `*_API_KEY_FILE` before env/PROCSI.
  - `mix ai.keys.doctor` validates resolution per provider.
  - CLI should accept `--secrets-dir` to explicitly point to a mounted dir and adopt `*_API_KEY_FILE` internally.

LSP-Like Bridge (future)
- WebSocket streaming channel for `delta` events (tokens, tool streaming, trace spans).
- Backed by the same event stream so replay is possible.

OpenAPI Sketch
- Components: Tool, ToolInput (JSON Schema), ChatMessage, ChatOptions, LGIEvent.
- Paths mirror endpoints above; responses include `event_ids` for correlation.

Security Notes
- Inputs pass through validation against tool schemas.
- Outputs are capped/filtered; JSON-only mode preferred for tool invocations.
- Audit trail enforced by required event emission for every call.

Migration Plan
- Phase 1: Ship endpoints + `ReqClient`; emit minimal events (in-memory/log for now).
- Phase 2: Persist Ash-style events and wire PubSub; add OpenAPI.
- Phase 3: Introduce WS streaming and richer policies.

Event Examples (Canonical JSON)
- ToolInvoked
```
{
  "type": "LGI.Event.V1.ToolInvoked",
  "event_id": "01J7Y8Q3P9C5A6ZK3B9W2MND8F",
  "correlation_id": "b9b1f0f0-0e41-4f3e-9f9a-2f3d1a2cae09",
  "idempotency_key": "hash-of-inputs-and-actor",
  "tenant": "acme",
  "actor": { "id": "user_123", "type": "user" },
  "tool": "sql.query",
  "input": { "sql": "SELECT ..." },
  "meta": { "provider": {} },
  "occurred_at": "2025-09-27T18:30:02.123Z"
}
```
- ModelCallCompleted
```
{
  "type": "LGI.Event.V1.ModelCallCompleted",
  "event_id": "01J7Y8X2T4R7W8K9M0N1P2Q3R4",
  "correlation_id": "b9b1f0f0-0e41-4f3e-9f9a-2f3d1a2cae09",
  "parent_event_id": "01J7Y8X2T4R7W8K9M0N1P2Q3R3",
  "tenant": "acme",
  "model": "gpt-4o-mini",
  "provider": "openai",
  "stats": {
    "input_tokens": 312,
    "output_tokens": 98,
    "latency_ms": 742,
    "retry_count": 0,
    "cached": false,
    "cost": { "subtotal": 0.00027, "currency": "USD" }
  },
  "meta": { "provider": { "request_id": "req_..." } },
  "occurred_at": "2025-09-27T18:30:02.965Z"
}
```

Audit and Ops
- Secrets Mount Health:
  - Emit a periodic health check (per node) that validates `SECRETSDIR` or `~/.sshs/<project>` readability, directory perms (0700), file perms (0600), and TTL expectations.
  - Surface health in the Ops dashboard; link to the latest `LGI.Secrets.MountChecked` event.
- Keys Doctor:
  - `mix ai.keys.doctor` verifies FILE/env/PROCSI per provider.
  - CLI’s `pactis keys doctor` should mirror this behavior for local checks.
- Streaming/Trace Health:
  - Collect OTEL spans (chat/tool/model.call) and ensure trace continuity across HTTP and WS/SSE.
- Provide per-tenant sampling and error-rate panels.

Tools Registry & Execution
- Resource‑declared tools: Resources can declare LGI tools via an Ash DSL extension (config‑only). Example:
  ```elixir
  use Ash.Resource,
    extensions: [AshLgiTools.Extension]

  tools do
    tool :repo_transfer do
      action :transfer_ownership
      idempotency true
      description "Transfer repository to a user or organization"
      input_schema %{
        type: "object",
        required: ["id", "target_owner_type"],
        properties: %{
          "id" => %{type: "string"},
          "target_owner_type" => %{enum: ["organization", "user"]},
          "target_org_id" => %{type: ["string", "null"]},
          "target_user_id" => %{type: ["string", "null"]}
        }
      }
    end
  end
  ```
- Endpoints:
  - `GET /api/v1/lgi/tools?resource=Elixir.Module` — returns declared tools (name, description, JSON Schemas, idempotency, scopes)
  - `POST /api/v1/lgi/execute` — body `{resource, tool, input}` invokes the mapped resource action (create/read/update/destroy)
- Idempotency:
  - Accept `Idempotency-Key` and return the same body for the same `{resource, tool, input}` within a replay window. The current implementation uses a best‑effort in‑memory cache; production should use a durable store keyed by tenant/actor/tool.
- Events:
  - Emit `LGI.ToolInvoked` on accept and `LGI.ToolResult` on completion with `status: ok|error`.
- MCP interop:
  - An adapter maps LGI tools to MCP descriptors and proxies MCP `execute` → LGI `execute`.
