## Pactis “Master Cache” Design (AI‑Assist Memory)

This document summarizes the proposed layered cache and tracing design to “save the AI’s mind” — maximizing reuse and speed while staying safe, scoped, and bill‑aware.

### Goals

- Minimize recomputation for common renders, tools, and apply flows
- Provide ahead‑of‑time recommendations (recipes) to agents/UI
- Keep privacy/safety: metadata‑first, redaction, opt‑in
- Align with billing: cache hits are discounted; charges are explicit
- Be portable: same shapes over REST/SSE and (optional) LSP

### Layers

- Result cache (high ROI)
  - Key: hash([JSON‑LD resource, params, env fingerprint, generator version])
  - Value: diff artifact, rendered outputs manifest, logs summary
  - Invalidation: resource/generator/env change → new key (content‑addressed)

- Tool output cache
  - Key: [tool_name, normalized_args, version]
  - Value: tool stdout + code + status

- Recipes (recommendations)
  - Learned from successful Ops runs: {blueprint_id, param_pattern, target_path, success_rate, avg_runtime, cache_hit_rate}
  - Served via GET /ops/recipes and SSE “ops_hint” events

- Insight/fact cache
  - Verified environment facts (e.g., “repo uses Tailwind in assets/…”) with provenance

- Prompt/policy snippets (optional)
  - Operational hints only (non‑authoritative), signed/verified if trusted

- Traces (metadata‑only)
  - AgentRun/AgentStep with durations, sizes, cache_hit/ miss
  - No PII/raw content by default

### Storage

- Hot: Redis (TTL)
  - Result cache entries/meta; recent runs; counters/quotas
- Durable: Postgres
  - Recipes, memory indexes, traces (metadata)
- Artifacts: Object storage (S3 or local)
  - Referenced by storage_key; not duplicated in DB
- Semantic (optional): pgvector or vector DB
  - For “similar tasks” search; opt‑in and redacted

### APIs

- Memory endpoints (optional later)
  - POST /api/v1/ai/memory {domain, type, tags[], key_hash, payload, ttl?}
  - GET /api/v1/ai/memory/search?domain=…&tags=…&semantic=…
- Recommendations
  - GET /api/v1/workspaces/:ws/ops/recipes
  - SSE events “ops_hint” on /ops/changes/:id/stream

### Safety & Governance

- Opt‑in per workspace; metadata‑first design
- Redaction pipeline for any raw text stored
- Tenancy boundaries: workspace/org scoping enforced
- Retention policy: default TTL (7–30 days), explicit “keepers” for recipes
- Provenance: record generator/version/env fingerprint and validation status

### Billing Alignment

- Track charges with op/units/cost_usd per step (preview/apply request & run; cache hit/miss)
- Cache hits billed at a discount (configurable)
- Charges recorded in UsageMetric.metadata (for reporting)

### How Big Can It Get?

It depends on usage patterns and retained TTLs. Order‑of‑magnitude estimates (tunable):

- Result cache entries
  - Diff artifact avg 25–100 KB (text diffs compress well); manifest/logs ~2–10 KB
  - 1,000 cached renders ≈ 25–110 MB artifacts + 2–10 MB metadata
- Tool cache entries
  - Highly variable; e.g., codegen snippet 5–50 KB per unique input
- Recipes/traces (DB)
  - Metadata only; ~0.5–2 KB per run/step
  - 100k runs/month ≈ 50–200 MB DB storage (with indexes)
- Vector embeddings (optional)
  - 768‑dim float32 ≈ 3 KB per item; 100k items ≈ 300 MB + index overhead

Recommended limits (per workspace; adjust as needed):

- Redis memory target: 250–500 MB with LRU eviction
- Artifact TTL: 7 days; hard cap 2–5 GB per workspace (older artifacts pruned)
- Traces DB retention: 30–90 days (metadata only)
- Vector memory (optional): 100k–500k items (pruned by recency/signal)

Back‑of‑the‑envelope sizing for a “busy” workspace (per 30 days):

- 10k renders; 30% unique (cache miss)
  - 3k artifacts × 50 KB ≈ 150 MB artifacts (7‑day TTL)/rolling
- 10k runs traces × 1 KB ≈ 10 MB DB
- 2k recipes/insights × 2 KB ≈ 4 MB DB
- Result: typically << 1 GB hot; a few 100s MB DB; grows with TTL and traffic

### Operations & Hygiene

- TTL cleanup jobs (BackgroundJobs) for priv/ops_artifacts and priv/jsonld/specs
- LRU in Redis + key prefixes for selective busting
- Quota endpoints (admin) to view/reset/purge caches per workspace

### Defaults (tunable)

- Artifact TTL: 7 days
- Redis TTL for results: 1–7 days
- Allowed write paths: ["lib/", "assets/", "priv/templates/"]
- SSE heartbeat: 20s
- Billing discounts: cache hit = 50% units (example)

### Rollout Plan

1) Result cache + billing on hit/miss
2) Recipes + SSE hints + /ops/recipes endpoint
3) Memory APIs + redaction + retention policies; optional semantic
4) Tool cache + prompt/policy snippets (signed)

### Agent DX

- One call “plop” (POST /ops/changes) with JSON‑LD + params
- SSE for status/logs/artifacts and hints (cache hit predicted, path conventions)
- Preview‑only in isolated staging → Apply on explicit call (no repo littering)
- Short‑lived agents benefit from cache + hints; editors use LSP if needed

---

This design intentionally scales with usage while keeping cost and safety predictable. Start small (short TTLs, modest Redis) and dial up as patterns emerge.
