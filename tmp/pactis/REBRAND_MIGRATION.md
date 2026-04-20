Pactis Rebrand Migration Guide

Scope
- Mix tasks: `mix cdfm.*` → `mix pactis.*` (all tasks under `lib/mix/tasks` and `priv/lib/mix/tasks`).
- MIME types: `application/vnd.cdfm.*` → `application/vnd.pactis.*`.
- Domains: `*.cdfm.dev` → `*.pactis.dev`, `api.cdfm.io` → `api.pactis.io`.
- Env vars: `CDFM_*` → `PACTIS_*` (e.g., `PACTIS_BASE`, `PACTIS_TOKEN_SIGNING_SECRET`).
- Atoms/metrics: `:cdfm_*` → `:pactis_*`, telemetry names `cdfm.*` → `pactis.*`.

Compatibility Notes
- Content-Type: `MemController` will respond with `application/vnd.cdfm.mem.manifest.v1+json` if the request `Accept` header contains `vnd.cdfm.*`; otherwise it uses `vnd.pactis.*`.
- Headers: Prefer `X-Pactis-Workspace` and `X-Pactis-System-Token`. If you have clients sending the old `X-CDFM-*` headers, update them.

Dev Environment
- Update `.env` or copy `.env.example`:
  - `POSTGRES_DB=pactis_dev`
  - Remove hardcoded `DATABASE_URL` or set to `ecto://postgres:postgres@localhost:${POSTGRES_PORT:-5432}/pactis_dev`.
- Clear caches (optional):
  - Delete `tmp/`, `priv/ops_artifacts/`, `priv/jsonld/specs/` if stale.

Client Updates
- Update any integrations to send/accept `application/vnd.pactis.*` content types.
- Replace old domains (`cdfm.dev`, `api.cdfm.io`) with Pactis endpoints.
- Replace CLI examples `mix cdfm.*` with `mix pactis.*`.

Verifications
- `mix help | grep pactis` lists Pactis tasks.
- `mix compile` succeeds.
- `mix pactis.smoke --base http://localhost:4000` passes.

Troubleshooting
- MIME mismatch: Check the `Accept` header; legacy `vnd.cdfm.*` is still served by MemController.
- Table/atom renames: If you rely on persisted ETS/Mnesia tables with `:cdfm_` names, migrate or reset dev data.

