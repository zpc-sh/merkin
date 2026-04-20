# Component Generation API

Exposes the AI component generation as a service (UI + API). Supports synchronous RPC calls and asynchronous job orchestration.

## Authentication

- Requires authenticated user (JWT/API token) and workspace context
- Rate limited; usage tracked for billing

## RPC (Preferred with AshTypescript)

- Actions (server): `Pactis.AI.ComponentGenerator`
  - `generate_single(category, name, description, opts \\ [])`
  - `generate_category(category, count, opts \\ [])`
  - `generate_library(target_count \\ 100, opts \\ [])`
  - `get_stats()`
  - `validate_library()`
- TS Client: Generated types for RPC inputs/outputs; import and call directly from UI

Example (TS):

```ts
import { rpc } from "@pactis/tsrpc";

await rpc.ComponentGenerator.generate_single({
  category: "cards",
  name: "StatsCard",
  description: "A stats card with trend and icon",
  opts: { tokens: { primary: "#3B82F6" }, accessibility: true }
});
```

## REST (Async Jobs)

- POST `/api/components/generate` — Enqueue generation job
  - Body:
    - `category`: string
    - `name`: string
    - `description`: string
    - `provider?`: string (e.g., `anthropic`, `openai`, `xai`, `ollama`)
    - `model?`: string (e.g., `claude-3-5-sonnet-20241022`, `gpt-4o`)
    - `opts`: object (tokens, variants, accessibility, etc.)
  - Returns: `{ job_id: string }`

- GET `/api/components/jobs/:id` — Poll job status
  - Returns: `{ status: "queued|running|succeeded|failed", result?: { blueprint_id } }`

- POST `/api/components/generate_category` — Batch enqueue
  - Body: `{ category: string, count: number, opts?: object }`
  - Returns: `{ job_id: string }`

Provider selection
- If `provider`/`model` are omitted, server defaults are used (configurable).
- Clients can also pass these via RPC arguments when using AshTypescript.

Notes:
- Jobs publish progress via PubSub; UI can show step updates
- On success, returns the created Blueprint id; UI can navigate to preview

## Usage Tracking & Quotas

- For each request:
  - Track `components_created` (+1 on success)
  - Track `api_calls` proportional to tokens used (provider usage)
- Enforce quotas per plan; return 429 on exceeded hard limits

## JSON‑LD Emission

- After persistence, emit component JSON‑LD files under `priv/jsonld/resources/components/`
- Include compact + expanded forms for searchability and documentation

## Error Handling

- 400: Validation errors with clear reasons (structure, safety)
- 401/403: Auth/permissions
- 429: Quota exceeded
- 500/502: Provider errors (masked), retriable via job retry

## Security

- Sanitize generated content; reject remote code execution patterns
- Limit file sizes and extensions; enforce sandbox rules on preview
- Log provenance (model, prompt hash) in manifest metadata


## Direct Actions (Non-AI and Redraft)

- POST `/api/components/:id/imprint` — Create an imprint (direct copy) of a component
  - Body (optional): `{ name?: string, slug?: string }`
  - Returns: `{ blueprint_id: string }`

- POST `/api/components/:id/redraft` — Create an AI-assisted redraft from a component
  - Aliased for back-compat: `/api/components/:id/remix`
  - Body: `{ prompt: string, provider?: string, model?: string, opts?: object }`
  - Returns: `{ job_id: string }`
