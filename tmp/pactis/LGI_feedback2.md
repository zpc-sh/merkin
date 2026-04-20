This is in great shape. You’ve hit the right primitives and the SSHS pattern is clean. Below are focused, spec-level upgrades you can drop in to round out operability, interop, and security. I’ve kept them concise and concrete. For SSHS details, see docs/specifications/Pactis-SSHS.md.

Critical additions

Model discovery endpoint
GET /api/v1/lgi/models
Returns canonical models with capability tags and provider mappings.
Each entry: {name, provider, provider_model, caps[], ctx_window, cost{input,output,unit,currency}, status{enabled/deprecated}, meta.provider{}}
Standard headers and identity
Required/recognized:
Idempotency-Key: string (POSTs)
X-LGI-Tenant: string
X-LGI-Actor: string (or pair X-LGI-Actor-Type, X-LGI-Actor-Id)
traceparent, tracestate (W3C)
Response propagation: echo correlation_id, event_ids[], trace ids.
Error model (uniform)
Shape: {error:{code, message, type, details?, event_ids?}}
HTTP mappings:
400 validation_error
401 unauthorized
403 policy_denied
404 not_found
409 idempotency_conflict
422 unprocessable (schema fails)
429 rate_limited (Retry-After)
5xx provider_error/internal
Always include event_ids for audit linkage.
Streaming protocol (SSE/WS)
SSE event types:
chat.delta: {id, idx, content_delta, finish_reason?}
chat.completed: {id, usage, cost, event_ids}
model.call.started/completed
heartbeat: {} every 15s
error: {error:{}}
Contract:
Server sends retry: 3000
Close semantics: final chat.completed or error terminates stream
Backpressure: server may buffer up to N events; on overflow send error: backpressure and close
Idempotency details
Canonicalization: inputs must be normalized (stable JSON ordering, trimmed strings, numeric canonical form) before hashing for idempotency_key comparison.
Scope: tenant + tool + idempotency_key; TTL configurable (default 24h).
Replay event: LGI.Event.V1.IdempotentReplay with original result reference.
Tool schema/versioning
ToolDeclared must include:
tool_id, version (semver), schema_hash (SHA-256 of JSON Schema normalized), source_ref (git SHA/URL), capabilities, timeout_s, side_effects: none|idempotent|non_idempotent
Tool input schema: JSON Schema draft-07+; allow $ref; enforce max sizes.
Tool result: explicitly typed, with an errors[] array optional.
Policy and allow-lists
Model registry-based routing: resolve by caps set (e.g., {chat, tools, json_mode, code}), not literal names.
Pre-call policy outputs:
decision: allow|deny
reasons: [rule_ids]
redactions: [{field_path, method, hash|range}]
enforced_limits: {max_tokens, json_only:true|false, stop_sequences[]}
Dry-run response includes would_call: {provider, model, estimated_cost}, and what would be redacted/blocked.
Observability hardening
OpenTelemetry spans:
lgi.http.inbound (server span)
lgi.chat, lgi.tool.invoke (child)
lgi.model.call (child): attrs provider, model, tokens.in/out, latency_ms, retry_count, backoff_ms, cached, http_status, provider_request_id
Sampling: per-tenant config (head-based, rate, tail-sampled on error/latency)
Cost accounting
Separate estimated vs actual costs:
stats.estimated_cost at policy/routing
stats.actual_cost at ModelCallCompleted
If provider returns token counts, record both and delta.
Security notes (explicit)
PII/secret redaction performed before persistence and before emitting events.
Redactions are irreversible (hash or range markers); raw inputs only in transient memory.
Size limits: enforce per-field and total body; reject oversize with 413 and guidance.
SSHS refinements (finalize)

Normative resolution order
*_API_KEY_FILE → *_API_KEY → provider-managed identity (cloud/VM) → PROCSI → error
OpenAI compatibility: also honor OPENAI_BASE_URL, OPENAI_ORG_ID, OPENAI_PROJECT
Contract
SECRETSDIR: 0700; files 0600; macOS dir name ends with .noindex; exclude from Spotlight and Time Machine.
Symlink ~/.sshs/<project> → SECRETSDIR for non-inherited agents.
TTL: recommend 30–60m via keychain auto-lock or RAM-disk teardown.
Client conventions
Adopt *_API_KEY_FILE widely; also allow *_KEY_FILE for non-API-key creds as needed.
CLI flag: --secrets-dir PATH sets *_API_KEY_FILE implicitly for known providers.
Doctor command
mix ai.keys.doctor prints resolution order, verifies file permissions, lists accessible models, and runs smoke tests per provider.
Provider interop notes

OpenAI (API)
Use chat/completions; recommend models: gpt-4o, gpt-4o-mini, o4-mini (tagged code).
There is no public “gpt5”; map user aliases to registry entries.
Azure-style providers
Different base URLs and headers (often api-key header vs Bearer); model names map to deployments; your registry should record header_style and path templates per provider.
Operational details to add

Timeouts and retries
Default per-call timeout (e.g., 60s chat, 30s tool); exponential backoff for 429/5xx with jitter; max_retries default 2.
Respect Retry-After for 429; emit retry_count/backoff_ms in spans and events.
Pagination
GET /tools and /models support limit/offset or cursor pagination; stable sort by name/version.
Caching
Optional local response cache keyed by canonicalized request for pure functions (side_effects == none). Emit cached: true in stats.
Attachments
Plan for inputs with binary artifacts (images, files) by adding a pre-signed URL ingestion endpoint, returning URIs referenced in chat/tool inputs. Record size and type in events; run policy checks on MIME and size before upload.
Concrete examples to include in the spec

Error JSON example (429)
HTTP/1.1 429 Too Many Requests
Retry-After: 5
{
"error": {
"code": "rate_limited",
"message": "Rate limit exceeded for tenant acme. Try again in 5 seconds.",
"type": "policy",
"details": {"limit": "rpm:60", "tenant": "acme"},
"event_ids": ["01J8…"]
}
}

SSE frames
event: chat.delta
data: {"id":"m_123","idx":0,"content_delta":"Hello","finish_reason":null}

event: chat.delta
data: {"id":"m_123","idx":1,"content_delta":" world","finish_reason":null}

event: chat.completed
data: {"id":"m_123","usage":{"input_tokens":42,"output_tokens":13},"event_ids":["01J8…"]}

ToolDeclared
{
"type": "LGI.Event.V1.ToolDeclared",
"event_id": "01J8A4…",
"occurred_at": "2025-09-27T18:42:10Z",
"tenant": "acme",
"actor": {"type": "system", "id": "lgi"},
"tool_id": "sql.query",
"version": "1.3.2",
"schema_hash": "sha256-…",
"source_ref": {"git":"https://…#a1b2c3"},
"capabilities": ["json_only"],
"timeout_s": 30,
"side_effects": "none",
"meta": {"provider": {}}
}

Model registry entry
{
"name": "gpt-4o-mini",
"provider": "openai",
"provider_model": "gpt-4o-mini",
"caps": ["chat","code","json_mode","tools","streaming"],
"ctx_window": 128000,
"cost": {"input":0.00015,"output":0.0006,"unit":"per_1k_tokens","currency":"USD"},
"status": {"enabled":true,"deprecated":false}
}

Implementation nudges for @openai/codex

Support OPENAI_API_KEY_FILE and SECRETSDIR automatically:
If OPENAI_API_KEY unset:
read OPENAI_API_KEY_FILE if set
else read $SECRETSDIR/openai_api_key if present
Add --secrets-dir PATH option that sets OPENAI_API_KEY_FILE for the process.
Honor OPENAI_BASE_URL to work with a localhost header-injecting proxy (future hardening path).
Print a clear diagnostic if no key resolved: “Set OPENAI_API_KEY, OPENAI_API_KEY_FILE, or use SSHS (SECRETSDIR/openai_api_key).”
Final pass: what you already have is strong. Adding the endpoints, uniform error model, streaming contract, idempotency canonicalization, and model registry formalism will make LGI battle-ready and easy for vendors/clients to target. SSHS is now a crisp, normative section that teams can adopt with minimal friction and strong security posture.
