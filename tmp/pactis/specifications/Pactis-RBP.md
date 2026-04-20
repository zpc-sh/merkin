# Pactis‑RBP: Resource Blueprint Protocol (v1)

Status: draft

Summary
- Defines a JSON schema and JSON‑LD context for encoding Ash resources into portable “resource blueprints”, suitable for validation, transport, and code generation.
- Provides API endpoints and CLI tasks to encode, decode (Igniter preview), and validate.

Shape
- Top‑level fields:
  - `@context` (optional), `@type: "AshResourceBlueprint"`, `rbp:version` (default `1`)
  - `module_name` (string), `table_name` (string|null)
  - Sections: `attributes[]`, `relationships[]`, `actions[]`, `validations[]`, `calculations[]`, `aggregates[]`, `preparations[]`, `changes[]`, `meta`
- JSON Schema: `priv/jsonld/schemas/rbp/rbp.schema.v1.json`
- JSON‑LD Context: `priv/jsonld/contexts/rbp.context.jsonld`

Conformance Levels
- Minimal: required headers + `attributes[]`
- Standard: headers + `attributes[]` + `relationships[]` + `actions[]` (schema‑valid)
- Complete: all sections present and schema‑valid

Validation
- Structural: JSON Schema (`ex_json_schema`) against `rbp.schema.v1.json`
- Semantic (baseline): primary key presence (e.g., id: uuid), relationship completeness (name/type/destination)
- Semantic (future): arg/attr type checks, relationship path validation

API
- GET `/api/v1/blueprints/schema.json` — serves JSON Schema (v1)
- GET `/api/v1/blueprints/context.jsonld` — serves JSON‑LD context
- POST `/api/v1/blueprints/validate` — body=blueprint, returns `{conformance, errors[], warnings[], version}`
- POST `/api/v1/blueprints/encode` — `{module: "MyApp.Resource"}` → encoded RBP (respects `resource_blueprint` DSL)
- POST `/api/v1/blueprints/decode` — `{blueprint, target_domain?}` → Igniter command preview (dry‑run)
 - POST `/api/v1/blueprints/run-tests` — `{ blueprint?, testRefs?, testSuiteId?, conformanceProfile?, workspace_id? }` → enqueues test run, returns `{ job_id }`

CLI
- `mix rbp.schema.print` — print schema
- `mix rbp.validate --file rbp.json` — validate against schema + semantic checks
- `mix rbp.encode --module MyApp.Resource [--out rbp.json]` — encode module
- `mix rbp.decode --file rbp.json [--target_domain Pactis.Core]` — preview decode

DSL (Ash)
- Extension: `AshResourceBlueprint.Extension`
- Resource DSL: `resource_blueprint do` with `jsonld_context`, `include`, `exclude`
- Backwards-compat DSL: `resource_encoder` (deprecated shim)

Versioning
- Embed `rbp:version` in documents (default: 1)
- Future versions served under `priv/jsonld/schemas/rbp/rbp.schema.v{n}.json`

Security
- Endpoints accept JSON only; consider `Idempotency-Key` for POST.
- Decoding is preview only; no code is applied server‑side via these endpoints.

Examples
- Minimal: `priv/jsonld/examples/rbp/minimal_user.json`
- Complete: `priv/jsonld/examples/rbp/complete_user.json`

Tests, Resolution & Registries (Optional)
- Purpose: Keep blueprints small while allowing rich, evolving test suites.
- Optional fields (under `meta`):
  - `rbp:tests` — inline small `rbp:TestCase` documents
  - `rbp:testRefs` — array of IRIs/URNs pointing to external test cases/suites
  - `rbp:testSuiteId` — IRI of a test suite to resolve from a registry
  - `rbp:conformanceProfile` — string (e.g., `standard`, `complete`, `org:custom`)
- Resolution order:
  1. Inline `rbp:tests`
  2. Dereference `rbp:testRefs`
  3. Load by `rbp:testSuiteId` or `rbp:conformanceProfile` from the registry
- Registries:
  - Workspace-scoped (example): `GET /api/v1/workspaces/{ws}/rbp/tests/{id}.jsonld`
  - Org-scoped (example): `GET /api/v1/orgs/{org}/rbp/tests/{id}.jsonld`
  - Support ETag and content-addressed IDs (e.g., `urn:sha256:...`) for immutability
- Execution model:
  - Keep `POST /api/v1/blueprints/validate` fast (structural + semantic only)
  - Separate endpoint to run tests: `POST /api/v1/blueprints/run-tests` (enqueues job; returns report handle)
  - Report shape: `{ conformance, errors[], warnings[], tests: {passed, failed, skipped}, version }`
 - Example test (seed): `priv/jsonld/examples/rbp/tests/example_case.jsonld`
