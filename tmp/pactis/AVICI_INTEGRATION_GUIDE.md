# Avici Integration Guide — Code Changes, APIs, and Open Questions

- Status: Draft
- Last Updated: 2025-09-20
- Owners: Pactis Core
- Related: docs/specifications/Pactis-CFP.md, docs/specifications/Pactis-KEI.md, docs/specifications/Pactis-SRI.md, docs/AVICI.md

## Summary
This document summarizes recent Pactis changes to support Avici (Knowledge Engine) and outlines the APIs, resources, and follow-ups needed to complete the integration. Avici supplies Context Frames (CFP) and a Knowledge Engine Interface (KEI) for services, patterns, decisions, and projects. Pactis consumes frames directly or via LANG/LSP and contributes manifests and events back to Avici.

## Code Changes (Merged)
- Specs
  - Pactis‑CFP: Context Frame Protocol — docs/specifications/Pactis-CFP.md
  - Pactis‑KEI: Knowledge Engine Interface — docs/specifications/Pactis-KEI.md
  - Linked from docs/INDEX.md and cross‑referenced in docs/AVICI.md
- CAI/SMI specs
  - Pactis‑SMI (billing settlement) — docs/specifications/Pactis-SMI.md (Oban profile)
  - Pactis‑CAI (content authoring) — docs/specifications/Pactis-CAI.md
  - CAI examples — docs/examples/cai/{empty.jsonld,sample_report.jsonld}
- Adapters and utilities
  - Markdown renderer: lib/pactis_web/markdown.ex (PactisWeb.Markdown)
  - JSON‑LD adapter: lib/pactis/jsonld.ex (Pactis.JSONLD)
  - Markdown‑LD adapters: lib/pactis/markdown_ld.ex (adapter) and lib/pactis/content/markdown_ld.ex (fallback)
- VFS
  - Behaviour/Resolver: lib/pactis/vfs/{behaviour,resolver}.ex
  - Adapters: lib/pactis/vfs/{file_adapter,cas_adapter,git_adapter,graph_adapter}.ex
    - graph:// delegates to Pactis.FaaS.Folder for read/write/list
    - git:// backed by Pactis.Storage.Git.Repository (read-only interface here)
- FaaS helpers
  - lib/pactis/faas/{folder,tree}.ex for JSON‑LD folder/tree storage on GraphStore

## KEI APIs (current + planned)
- GET `/api/v1/avici/frame?scope=...&include=decisions,patterns,capabilities,projects` (requires `read:avici`)
  - Implemented: returns avici:ContextFrame (JSON‑LD) assembled from `priv/service.manifest.jsonld`
- GET `/api/v1/avici/services` (requires `read:avici`)
  - Implemented: returns full sri:Service nodes; supports `?view=compact` to return compact AI view (id, name, aiSummary, capabilities, endpoints)
- (Deprecated alias) GET `/api/v1/avici/services/snapshot`
  - Prefer `GET /api/v1/avici/services?view=compact`
- GET `/api/v1/avici/search?q=...&types=service,pattern,decision&limit=20` (requires `read:avici`)
  - Implemented (naive): substring search across harvested `sri:Service`, `avici:Pattern`, `avici:Decision`
- POST `/api/v1/avici/harvest` (requires `write:avici`)
  - Implemented: trigger manifest harvesting from sources via VFS and HTTP
  - Supported sources: `file://...`, `git://...`, `cas://...`, `http(s)://...` (uses `Req` if available)
  - Also includes configured SRI registry sources via `config :pactis, :sri_registry_sources, ["https://.../registry.jsonld"]`
  - Registry format: JSON‑LD with `@type: sri:Registry` and `sri:services: [{"href": "https://.../service.jsonld"}, ...]`
    - Example: `docs/examples/sri_registry.jsonld`
- POST `/api/v1/avici/patterns` (requires `write:avici`)
  - Implemented: upsert avici:Pattern (async), supports `wasDerivedFrom: [@id,...]`
- POST `/api/v1/avici/decisions` (requires `write:avici`)
  - Implemented: upsert avici:Decision (async), supports `wasDerivedFrom: [@id,...]`
- POST `/api/v1/avici/patterns`, `/api/v1/avici/decisions`
  - Planned: upsert curated knowledge (async, validated)

Events (Phoenix.PubSub):
- `avici:context_updated:{scope}`
- `avici:service_updated:{service_id}`
- `avici:pattern_mined`

Cache policy (KEI):
- Frame cache keyed by (scope, include, sriVersion, projectVersion, patternsVersion)
- Invalidate on SRI updates, project changes, or pattern/decision writes

## Resources to Be Aware Of
- Service manifest (bootstrap): `priv/service.manifest.jsonld`
- SRI discovery endpoints (aliases):
  - Canonical: `GET /service.jsonld`
  - Well‑known: `GET /.well-known/pactis/service.jsonld`
  - Vanity: `GET /zpc/avici/service` (serves same manifest)
- Service registry spec: docs/specifications/Pactis-SRI.md (SRI)
- Context specs: docs/specifications/Pactis-CFP.md and Pactis-KEI.md
- Storage (for CAI/KEI artifacts):
  - `graph://<folder_id>/...` via Pactis.VFS.GraphAdapter and Pactis.FaaS.Folder
  - `cas://sha256:...` via Pactis.VFS.CASAdapter
  - `git://owner/repo?...` via Pactis.VFS.GitAdapter (read-only surface)
- Background jobs pattern: Oban queue `:spec` for harvesting/pattern mining/frame refresh

## Integration Flow (High-Level)
1) Harvest manifests
- Load services from Pactis‑SRI + local manifest (priv/service.manifest.jsonld) + configured sources
- Store or enrich sri:Service with avici:aiSummary and avici:capabilities

2) Build ContextFrame
- Inputs: scope (specRequestId or {orgId, repoId, tags}), include[] flags
- Aggregate: service registry, projects, patterns, decisions, recent work
- Output: avici:ContextFrame (JSON‑LD)

3) Consume from SpecAPI/LANG
- SpecAPI attaches a ContextFrame to negotiations pre‑evaluation
- LANG/LSP queries KEI for frames/services on behalf of agents

4) Contribute knowledge
- Pactis writes curated patterns/decisions (validated, async)
- KEI mines patterns from SpecAPI transcripts/checkpoints (optional)

## Open Questions (scoping & security)
- Access path: Pactis↔Avici direct (ELK-like); LANG/LSP remains available for agent mediation.
- Token scoping: enforce `read:avici` (frame/services) and `write:avici` (patterns/decisions/harvest) scopes; include claims for workspace/org/repo where applicable.
- Redaction: ensure frames exclude secrets/PII; define allowlist for fields.
- Frame constraints: expected maximum size; TTL; partial includes for large registries.
- Event payloads: align on payload schema for context/service updates.

## Next Steps
- Harvest job skeleton (Oban `:spec`):
  - Read `priv/service.manifest.jsonld` + SRI; store/enrich service entries
- Optional: JSON‑LD `@context` files for `avici:ContextFrame`, `avici:Pattern/Decision/Project`
