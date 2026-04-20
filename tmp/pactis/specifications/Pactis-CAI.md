# Pactis‑CAI: Content Authoring Interface

- Status: Draft
- Last Updated: 2025-09-20
- Owners: Pactis Core
- Related: JSONLD_SPEC_PIPELINE.md, RFC_JSONLD_LIBRARY.md, IMPLEMENTING_SEMANTIC_PIPELINE.md

## Summary
Pactis‑CAI specifies the content pipeline that renders canonical JSON‑LD artifacts to Markdown‑LD for authoring, publishes content to channels (HTML, PDF, site, docs), and synchronizes user edits back to JSON‑LD. CAI enables round‑trip authoring with deterministic projections and conflict‑aware merges.

## Concepts & Data Model
- JSON‑LD Source: canonical graph with contexts and shapes (see Pactis.md).
- Markdown‑LD: author‑friendly markdown annotated with JSON‑LD semantics via inline attributes and front‑matter.
- Projection: deterministic mapping JSON‑LD → Markdown‑LD, preserving stable ids and anchors.
- Inversion: deterministic mapping Markdown‑LD → JSON‑LD, preserving graph identity.
- Channel: a publication target (e.g., `html`, `pdf`, `site`, `docs`).
- ContentVersion: immutable versioned object with provenance and hash of source graph and projection params.
- EditIntent: a user edit unit carrying idempotency key and author metadata.

## Operations
- RenderContent: project JSON‑LD → Markdown‑LD.
- PublishContent: render channel output from Markdown‑LD.
- SyncEdits: invert Markdown‑LD edits → JSON‑LD patch (shape‑validated).
- ResolveConflicts: 3‑way merge of graph vs. edited Markdown‑LD vs. base projection.
- ValidateProjection: ensure projection/inversion determinism and shape conformance.

Implementation Profile — Async Workers
- Queue: `spec` (Oban)
- Jobs:
  - ContentRenderJob: `%{"artifact_id" => id, "profile" => string(), "opts" => map}`
  - ContentPublishJob: `%{"artifact_id" => id, "channel" => string(), "version" => string}`
  - ContentSyncJob: `%{"artifact_id" => id, "edit_intent_id" => id}`
- Idempotency: stable projection keys (artifact, profile, version); edit intents deduped by idempotency key.
- Events (Phoenix.PubSub):
  - `content:rendered`, `content:published`, `content:sync`, `content:conflict`
- Telemetry: timings per operation, sizes (chars/bytes), channel, result.

## Markdown‑LD Shape
- Front‑matter carries `@context`, `@id`, `@type`, and projection metadata.
- Inline spans/blocks carry `data-ld-prop` attributes for reversible mapping.
- Stable anchors for headings and list items based on `@id`.
- Prohibit lossy transformations; require reversible formatting for structured fields.

## Conformance
- Deterministic projection/inversion for supported shapes.
- Preservation of `@id` and identity across round‑trips.
- Shape validation before accepting inverted patches.
- Structured conflict markers with machine‑resolvable hints; human‑readable diff.

## Integration Guidelines
- Editors call CAI operations asynchronously; UI subscribes to events for progress.
- Avoid synchronous rendering in request path; enqueue jobs to `spec` queue.
- Store only non‑sensitive content; avoid embedding secrets in Markdown‑LD.

## Testing
- Golden tests for projection/inversion determinism.
- Schema/shape validation on inverted patches.
- Worker execution via direct `perform/1` in tests when Oban disabled.

## Examples
- Empty template: `docs/examples/cai/empty.jsonld`
- Sample report: `docs/examples/cai/sample_report.jsonld`

## Open Questions
- Standardize Markdown‑LD attribute syntax vs. fenced blocks?
- Channel‑specific templating registry and caching policy.
- Editorial workflows: review/approval events and permissions model.
