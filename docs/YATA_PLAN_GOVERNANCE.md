# Yata `.plan` Governance (v0.1)

This project is the canonical home for `.plan` specification and evolution.

## Ownership

- Owner: Merkin core project (`zpc/merkin`).
- Primary spec: `docs/YATA_PLAN_SPEC.md`.
- Historical references (including finger protocol lineage) are informative, not normative.

## Versioning

- Spec version uses semantic intent:
  - additive metadata fields: minor bump
  - behavioral or parser strictness changes: major bump
  - editorial-only clarifications: patch bump

## Compatibility policy

- Strict parser remains authoritative for conformance.
- New headers must be optional first.
- Existing keys cannot be redefined with incompatible semantics.
- Entry token ordering is stable for strict parser implementations.

## Extension process

1. Propose field family and semantics in `YATA_PLAN_SPEC.md`.
2. Add parser and emitter support in code.
3. Add strict parse tests (happy + malformed).
4. Update governance/changelog notes.

## Reserved namespaces

- Core headers:
  - `kind`, `track`, `mode`, `generator`, `note`, `material_hash`, `entries`
- Metadata families:
  - `self_report_*`
  - `git_report_*`
  - `temporal_delta_*`
  - `embedding_report_*`

## Security posture

- Embedding metadata can mark findings but should not force retention.
- Ephemeral policy and purge windows are first-class.
- `.plan` can carry summary metadata while detailed evidence remains artifact-local.
