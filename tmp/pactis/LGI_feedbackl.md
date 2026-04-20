High‑impact refinements to the spec

Note: References to SSHS point to the normative spec at docs/specifications/Pactis-SSHS.md.

Event model
Include: event_id (ULID), correlation_id (trace), parent_event_id, idempotency_key (where relevant), actor, tenant, clock fields (occurred_at, received_at).
Redaction accounting: record redactions as list of {field, method, range/hash}, not just “performed.”
Cost fields: standardized units (input_tokens, output_tokens, unit_price, subtotal, currency, rounding_policy). Keep vendor extras under meta.provider.
Idempotency
Require Idempotency-Key header on POST /execute and optionally /chat.
Semantics: same tenant+tool+key within 24h returns the original ToolResult; return 409 if inputs differ.
Emit LGI.Event.V1.IdempotentReplay in replays for auditing.
HTTP surface and streaming
Adopt W3C trace context: accept and emit traceparent/tracestate.
Streaming: add GET /api/v1/lgi/chat/stream (SSE) and WS /api/v1/lgi/stream for delta events. Keep POST /chat synchronous.
Content-type strictness: application/json only; enforce max body size; reject application/x-www-form-urlencoded.
Policy and allow‑lists
Model registry: keep a model table with capability tags (code, vision, json_mode, tools, large_context) and map vendor names to canonical capabilities. Route by capability, not string equality.
Pre-call checks: allow‑list models/tools per tenant; optional deny‑list by regex for prompts; secret redaction with hash proof.
“Dry-run” flag that exercises policy and cost estimation without calling providers.
Observability
OpenTelemetry spans:
lgi.tool.invoke, lgi.chat, lgi.model.call with attributes: model, provider, tokens.in/out, cost, cached, retry_count, throttle_ms.
Emit event_ids in response for linkage; include span_id/trace_id.
Sampling strategy configurable per tenant.
SSHS (Secure Secrets via SSH keys) refinements

Resolution order (normative)
*_API_KEY_FILE → *_API_KEY → provider-specific (e.g., Azure managed identity) → error.
Also honor OPENAI_BASE_URL, OPENAI_ORG_ID, OPENAI_PROJECT for OpenAI compatibility.
SECRETSDIR contract
Directory must be 0700; files 0600; name should end with .noindex on macOS.
Suggested filenames: openai_api_key, anthropic_api_key, gemini_api_key, xai_api_key.
Optional symlink: ~/.sshs/<project> → SECRETSDIR for agents that don’t inherit env.
TTL: default 30–60 minutes by keychain auto-lock or RAM-disk teardown; document how to adjust.
Reference implementations
RAM disk (macOS): /Volumes/Secrets-<project>.noindex; disable Spotlight and Time Machine.
tmpfs (Linux): /run/user/$UID/sshs-<project>.
Provide scripts:
secrets-shell: decrypt age/age-plugin-ssh encrypted files into ephemeral dir/mount; export SECRETSDIR; exec a subshell; cleanup on exit and signals.
secrets-doctor: validate perms, presence, keychain accessibility, and provider-specific reachability (list models + smoke test).
Security notes
The secrets-dir pattern intentionally exposes raw keys to processes under the user. If you need stronger isolation, the localhost header-injecting proxy pattern avoids exposing keys to agents entirely while still enabling access.
Add optional file-access auditing: fs watcher that logs first-access per secret file to your LGI audit stream (no contents).
Provider interop specifics (OpenAI)

Supported environment keys
OPENAI_API_KEY_FILE, OPENAI_API_KEY, OPENAI_BASE_URL, OPENAI_ORG_ID, OPENAI_PROJECT.
There is no public “gpt5.” Prefer gpt-4o, gpt-4o-mini, or o4-mini and map via your model registry.
@openai/codex integration changes
Add support for OPENAI_API_KEY_FILE and SECRETSDIR:
If OPENAI_API_KEY is unset and OPENAI_API_KEY_FILE is set, read and trim file contents.
If both unset and SECRETSDIR is set, look for $SECRETSDIR/openai_api_key.
Add CLI flag: --secrets-dir PATH to set SECRETSDIR for the current run.
Honor OPENAI_BASE_URL for the localhost proxy pattern (easy future hardening).
Minimal code snippets you can drop in

Elixir: resolve provider credentials (LGI boundary)
def resolve_openai_auth(env \ System.get_env()) do
key =
case env["OPENAI_API_KEY_FILE"] do
path when is_binary(path) and File.regular?(path) ->
File.read!(path) |> String.trim()
_ ->
env["OPENAI_API_KEY"] ||
(case env["SECRETSDIR"] do
dir when is_binary(dir) ->
path = Path.join(dir, "openai_api_key")
if File.regular?(path), do: File.read!(path) |> String.trim(), else: nil
_ -> nil
end)
end

base = env["OPENAI_BASE_URL"] || "https://api.openai.com/v1"
org  = env["OPENAI_ORG_ID"]
proj = env["OPENAI_PROJECT"]

if is_nil(key) or key == "" do
{:error, :missing_openai_credentials}
else
{:ok, %{api_key: key, base_url: base, org_id: org, project: proj}}
end
end

Elixir: enforce HTTP egress only via LGI
CI static check: grep disallow vendor hosts in non-LGI code.
Runtime: wrap HTTP clients (Finch/Tesla) in a module that rejects api.openai.com unless caller == Pactis.AI.ReqClient.
Node (@openai/codex): OPENAI_API_KEY_FILE support
import fs from "node:fs";
function readKeyFromFile(path) {
try { return fs.readFileSync(path, "utf8").trim(); } catch { return ""; }
}
const keyFromFile = process.env.OPENAI_API_KEY_FILE ? readKeyFromFile(process.env.OPENAI_API_KEY_FILE) : "";
const apiKey = process.env.OPENAI_API_KEY || keyFromFile || undefined;
// pass apiKey to the OpenAI SDK; support OPENAI_BASE_URL transparently

CLI UX for codex
Add codex --secrets-dir PATH which internally sets OPENAI_API_KEY_FILE="$PATH/openai_api_key" for the process.
Print a clear hint if neither env nor file is resolved: “No OpenAI API key. Set OPENAI_API_KEY, OPENAI_API_KEY_FILE, or run via SSHS (SECRETSDIR/openai_api_key).”
Policy/routing hardening

Model registry entry example
{
"name": "gpt-4o-mini",
"provider": "openai",
"caps": ["chat", "code", "json_mode", "tools", "streaming"],
"ctx_window": 128000,
"cost": { "input": 0.00015, "output": 0.0006, "unit": "per_1k_tokens", "currency": "USD" }
}

Route by capability, not name: “code+tools+json_mode” for tool use; “vision” for image.
Event JSON examples (publish in your spec)

ToolInvoked
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

ModelCallCompleted
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

Testing/doctor checklist

SSHS
SECRETSDIR perms 0700; files 0600; directory ends with .noindex on macOS.
Keychain/Secretive prompts on first decrypt; session teardown wipes and detaches RAM disk/tmpfs.
*_API_KEY_FILE resolution passes; provider smoke tests succeed.
LGI boundary
Direct vendor egress blocked in app code; only Pactis.AI.ReqClient can call vendors.
Policy denies disallowed models/tools; costs and token counts recorded.
Idempotency: replay returns prior result; mismatched inputs → 409.
Migration/interop notes for the blog

“gpt5” is not a public model; recommend gpt-4o, gpt-4o-mini, o4-mini (tagged code).
For teams, prefer the proxy pattern when you must prevent raw key exposure to agents; otherwise SSHS is simplest and entirely native.
Encourage providers/clients to adopt *_API_KEY_FILE and OPENAI_BASE_URL to work seamlessly with SSHS.
If you want, I can:

Open a minimal PR to @openai/codex adding OPENAI_API_KEY_FILE + --secrets-dir and a short README “Using SSHS with Codex.”
Provide a reference repo (MIT) containing:
secrets-shell (RAM disk + tmpfs modes)
secrets-doctor
model registry example + routing by capability
LGI events schema + JSON examples
codex wrappers and tests
This will land well as a best practice: it reduces friction for agents, keeps secrets out of the global env, and gives you strong auditability and policy hooks at the LGI boundary without introducing heavy new infrastructure.
