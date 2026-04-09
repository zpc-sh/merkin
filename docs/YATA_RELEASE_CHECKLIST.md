# Yata Release Checklist (Scaffolding -> v0.3)

> For full cross-project release gating (spec/doc/test readiness), see `docs/FIRST_RELEASE_READINESS.md`.

## Current state

- Core Yata hole model and graph lifecycle exist.
- `.plan` wire format supports:
  - strict parse outcomes and diagnostics
  - optional `self_report_*` collaboration envelope
  - optional `git_report_*` provenance envelope
- One-shot snapshot helper exists (`snapshot_with_reports`).
- Address layer supports:
  - `cog://`, `substrate://`, and `cas://`
  - relative parsing
  - slash normalization and canonical re-emission

## Must-pass gates before release

- `moon info && moon fmt` runs clean with expected `.mbti` deltas only.
- `moon test` passes across model and protocol suites.
- Address parser behavior is frozen with golden snapshots for:
  - slash-heavy inputs
  - CAS digest-only targets
  - mixed overlay/track/id query forms
- `.plan` strict parser has explicit tests for:
  - required-field failures
  - envelope-flag failures
  - malformed numeric headers

## Integration gates

- CLI or API command for canonicalizing addresses is wired (`canonicalize` entrypoint).
- `.plan` producer path can emit both envelopes from one call in normal workflow.
- Documentation examples match parser expectations (no pseudo-entry formatting).
- Conversational hosting API contract is published (`hall/thread/turn/checkpoint/replay`).
- Length-envelope checks are enforced on both ingress and egress in runtime handlers.

## Hardening gates

- Backward compatibility notes for old `cog://` and `substrate://` forms.
- Error code catalog documented for parser consumers.
- Performance sanity pass for large `.plan` payloads and dense dependency graphs.

## Recommended release order

1. Freeze schema and address canonical rules.
2. Run full tests and fix breakages.
3. Regenerate interfaces and format output.
4. Publish docs/changelog with migration notes.
