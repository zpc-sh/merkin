# Pactis‑KEI: Knowledge Engine Interface

- Status: Draft
- Last Updated: 2026-04-02
- Owners: Pactis Core
- Related: Pactis‑CCV2, Pactis‑CFP, Pactis‑SRI, SpecAPI, LANG (LSP)

## Summary
Pactis‑KEI specifies how the Knowledge Engine (Avici) builds and serves ContextFrames (CFP) and how services contribute knowledge (services, patterns, decisions, projects). KEI defines read/write APIs, events, caching, and harvesting rules (e.g., service manifests) so agents and tools can share context consistently.

## CCV2 Compatibility (Sabha Profile)

Under Pactis-CCV2, KEI is the primary knowledge/context feed for Avici crystallization and Sabha replay:

1. KEI frame construction supplies pre-run and mid-run context for Hall sessions
2. KEI harvesting enriches branch/crystal analysis inputs
3. KEI remains auxiliary to canonical SymbolForm + commitment lineage

Reference:

- [Pactis-CCV2.md](./Pactis-CCV2.md)
- [Pactis-Sabha-Schemas.md](./Pactis-Sabha-Schemas.md)
- [Pactis-Sabha-Operations.md](./Pactis-Sabha-Operations.md)

## Operations
- BuildFrame: aggregate a ContextFrame from inputs (scope, include[]).
- HarvestManifests: ingest service manifests and registries (Pactis‑SRI, local service.manifest.jsonld).
- UpsertPattern/Decision/Project: record curated knowledge with provenance.
- ListServices: AI‑oriented view of SRI services with summaries and capabilities.

## HTTP API (reference)
- GET `/api/v1/avici/frame?scope=<...>&include=decisions,patterns,capabilities,projects`
  - Returns: avici:ContextFrame (JSON‑LD)
- POST `/api/v1/avici/patterns` → upsert avici:Pattern (async validated)
- POST `/api/v1/avici/decisions` → upsert avici:Decision (async validated)
- GET `/api/v1/avici/services` → list sri:Service with avici:aiSummary, avici:capabilities
- Workspace discovery: `GET /api/v1/workspaces/:workspace_id/workspace.jsonld` (links to services, LGI models, SpecAPI)
- Workspace services: `GET /api/v1/workspaces/:workspace_id/services` (runtime view)
- Service health report: `POST /api/v1/workspaces/:workspace_id/services/:id/health/report`
- Secrets mount health report: `POST /api/v1/workspaces/:workspace_id/ops/lgi/secrets/report`
- POST `/api/v1/avici/harvest` → trigger manifest harvesting (Oban job)

Notes:
- Writes enqueue background jobs; controllers validate and enqueue only.
- Authentication/authorization mirrors SpecAPI; audit logs include scope and provenance.

## Events & Cache
- PubSub:
  - `avici:context_updated:{scope}` — frame cache updated
  - `avici:service_updated:{id}` — service capability/summary change
  - `avici:pattern_mined` — detected from SpecAPI checkpoints
- Cache:
  - Keyed by (scope, include, sriVersion, projectVersion, patternsVersion)
  - Invalidate on SRI updates, project state changes, or pattern/decision writes

## Harvesting: Service Manifests
- Sources:
  - Pactis‑SRI registry (authoritative service list)
  - Local manifest: `priv/service.manifest.jsonld` (used during bootstrap)
  - Additional manifests from configured URIs (git://, file://, http(s)://)
- Expected fields per service (extends Pactis‑SRI):
  - `sri:Service` with id, name, endpoints, version
  - `avici:aiSummary` — short, capability-focused description
  - `avici:capabilities[]` — compact tokens for agent routing (e.g., "ai-memory")
  - Optional: `avici:examples[]` with minimal request/response snippets

## JSON‑LD Shapes (additions)
- avici:Pattern — `@id`, `title`, `description`, `scope`, `tags[]`, `lastUsedAt`, `prov:wasDerivedFrom`
- avici:Decision — `@id`, `title`, `rationale`, `date`, `linkedTo[]` (spec:Request, repo/PR), `tags[]`
- avici:Project — `@id`, `name`, `status`, `areas[]`
- sri:Service — from Pactis‑SRI; KEI adds `avici:aiSummary`, `avici:capabilities[]`

## Conformance
- Frames MUST meet Pactis‑CFP and include only resolvable references (or inline minimal stubs).
- Harvesting MUST be idempotent by manifest `@id` and `version`.
- Writes MUST be queued and retried with backoff; failures produce validation reports.
- No secrets in frames; redact sensitive fields.

## Layering & Links
- SDI (repo) provides `service.jsonld` — what a service is.
- RSI (repo) provides `manifest.jsonld` — repo capabilities and subresource links.
- KEI (workspace) provides inventory and health — what is available now.
- Instances (running services) provide `/service.jsonld` — live instance metadata.

## Integration Paths
- SpecAPI: pre-negotiation frame enrichment; post-negotiation mining (optional).
- LANG/LSP: agents query KEI via LSP mediator; CFP is the canonical payload.
- Kyozo: supply session references to maintain continuity.
