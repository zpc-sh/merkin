# Spec API Extension: Method Spec Registry (JSON‑LD)

This document formalizes the Nullity/Pactis method specification extensions under a portable, implementation‑ready Spec API add‑on. It defines a workspace‑scoped registry of "method specs" expressed in JSON‑LD or YAML, with normalized JSON Schemas for inputs/outputs, OpenAPI export, and optional persistence via Ash resources.

## Goals
- Registry of executable method specifications that pair naturally with Spec Requests.
- First‑class JSON‑LD support with deterministic hashing for idempotent upserts.
- Derived JSON Schemas (`params_schema`, `result_schema`) for tooling and OpenAPI.
- Pluggable persistence: Ash resource or filesystem (for bootstrapping).

## Data Model

MethodSpec (normalized shape, derived from `priv/specapi/nullity_cdfm/spec.ex`):
- `id` (string): Source identifier (`@id`, compact IRI, or name)
- `name` (string): Canonical dot‑name (e.g., `lang.agent.spawn`)
- `category` (string, nullable): Derived from name (e.g., `agent`)
- `description` (string, nullable)
- `priority` (string: `Critical|High|Medium|Low`, nullable)
- `spec_status` (string: `implemented|in_progress|not_implemented`, nullable)
- `impl_file` (string): Suggested implementation file path
- `impl_module` (string, nullable)
- `impl_function` (string/atom, default: `handle`)
- `impl_arity` (integer, default: `2`)
- `params_schema` (object, nullable): JSON Schema object built from `parameters[]`
- `result_schema` (object, nullable): JSON Schema object from `returns.success/error`
- `metadata` (object): Freeform metadata; includes `spec_hash` when available
- `links` (object): Related documentation/URLs

Notes:
- JSON‑LD inputs may contain: `@context`, `@id`, `parameters` (array), `returns` (object).
- XSD types map to JSON types: `xsd:string→string`, `xsd:boolean→boolean`, `xsd:integer→integer`, `xsd:number|float|double→number`, `xsd:array→array`, `xsd:object→object`.
- A deterministic `spec_hash` is computed (e.g., JSON‑LD dataset hash) to enable idempotent upserts.

## API Endpoints (Design)

Base: `/api/v1/workspaces/:workspace_id/spec/methods`

- `GET /` — List method specs
  - Query: `q` (search), `category`, `status`, pagination params
  - 200 → `[{name, category, spec_status, priority, ...}]`

- `GET /:name` — Fetch a single method spec by canonical name
  - 200 → full MethodSpec
  - 404 → not found

- `POST /` — Upsert method spec (JSON‑LD or YAML)
  - Headers: `Content-Type: application/ld+json | application/yaml | application/json`
  - Body: single spec or array of specs
  - Behavior: normalize, validate, compute `spec_hash`, upsert; reject on conflicting hash for same name
  - 201/200 → `{ inserted: n, updated: m, conflicts: [] }`
  - 409 → conflict on `Idempotency-Key` or `spec_hash`

- `DELETE /:name` — Remove a method spec
  - 200 → `{deleted: true}` | 404 → not found

- `GET /openapi.json` — Export OpenAPI 3 document composed from registry
  - Components derived from `params_schema` and `result_schema`
  - Tagged by `category`

Security & Limits:
- Read: `:api_optional_auth` acceptable for public workspaces; otherwise `:api_authenticated`.
- Write (POST/DELETE): `:api_authenticated` + `BillingGate` (tracks usage via Oban).

## Persistence Options

- Option A (Ash, recommended): add `Pactis.Spec.MethodSpec` resource with fields matching the model above; implement `upsert` action keyed by `{workspace_id, name}`; add read/list/delete actions. The Nullity adapter shows an example pattern in `priv/specapi/nullity_cdfm/adapters/store/ash.ex`.
- Option B (Filesystem bootstrap): store specs under `priv/lsp/specs/**/*.jsonld|yaml`; read/update by scanning files (see `read_all_from_specs_dir/1`). Use until DB resources are in place.

## Validation

Lightweight validations (see `priv/specapi/nullity_cdfm/validator.ex`):
- Required: `name`, derived `category`, non‑empty `impl_file`.
- `priority` ∈ {Critical, High, Medium, Low}
- `spec_status` ∈ {implemented, in_progress, not_implemented}
- Schema build succeeds for `parameters`/`returns`.

## OpenAPI Composition

- For each method: create a synthetic path (`/methods/{name}:invoke`) when useful, or publish schemas only.
- Components:
  - `params`: from `params_schema`
  - `result`: from `result_schema` (may use `oneOf`)
- Optional: group by tag = `category`; include `x-pactis-impl` with `{module,function,arity}`.

## Events & Observability

- Publish events on create/update/delete: `spec:ws:<ws>:methods` with payload `{action, name, spec_hash}`.
- Track write usage via `Pactis.Billing.track_usage_async/4` with `event_type: "spec_method.update"`.
- Oban jobs for heavy tasks: OpenAPI generation, large batch imports.

## Integration with Spec Requests

- Link proposals to methods: SpecMessage may include `repository_context` or `code_ref` referencing a `MethodSpec` name; UIs can deep‑link to `/spec/methods/:name`.
- Export workflow artifacts (JSON‑LD) that include both negotiation log and referenced MethodSpecs.

## Implementation Notes

- Keep controller logic thin; delegate to a service module (e.g., `Pactis.Spec.MethodRegistry`).
- Ensure workspace scoping on all queries; support `X-Pactis-Workspace` for cross‑API consistency.
- Respect existing test guideline: Oban workers bypassed in test (`config :pactis, :use_oban, false`).

## Next Steps (Incremental)
1) Add Ash resource `Pactis.Spec.MethodSpec` and a service module.
2) Implement list/get/upsert/delete controllers and routes under `/spec/methods`.
3) Add OpenAPI generator that composes from registry (Oban job).
4) Integrate billing gates and usage tracking on write endpoints.
5) Wire PubSub events.

This extension remains compatible with the current Spec API and can be adopted incrementally without breaking existing workflows.
