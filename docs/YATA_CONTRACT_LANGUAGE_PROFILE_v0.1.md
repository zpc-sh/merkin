# Yata Contract Language Profile v0.1

Compiler-facing contract language profile for Yata `.plan` and related parse/validation semantics.

Date baseline: `2026-04-18`.

## 1) Purpose

Define a compact, implementation-aligned contract vocabulary that compiler/runtime tooling can rely on.

Primary target:

- strict machine contracts over `.plan` wire generation and ingestion
- deterministic diagnostics suitable for CI gates and compiler adapters

## 2) Canonical Sources

- `docs/YATA_PLAN_SPEC.md`
- `model/yata_protocol.mbt` (`YataPlan::parse_wire_strict`, `YataPlan::validate`)
- `model/yata_lineage.mbt` (`YataPlan::to_wire`)

When conflicts exist, implementation parser behavior is authoritative.

## 3) Contract Vocabulary

Normative terms:

- `MUST`: hard validity requirement
- `MUST NOT`: hard prohibition
- `SHOULD`: recommended for compatibility and portability
- `MAY`: optional

Semantic classes:

- `wire-header`: top-level `.plan` header lines
- `wire-entry`: `- <hole_id> ...` entry lines
- `report-block`: optional metadata families (`self_report`, `git_report`, `procsi_report`, etc.)
- `cursor`: post-parse summary (`expected_entries`, `observed_entries`, warnings)

## 4) Minimum Wire Contract

A strict-valid `.plan` MUST include:

- `kind: merkin.yata.plan`
- `track=<program|git>`
- `mode=<full|compact>`
- `generator=<text>`
- `note=<text>`
- `material_hash=<text>`

Unknown non-empty lines MUST be rejected in strict mode.

## 5) Conditional Report Contracts

If enabled flag is present (`...=1`), required partner fields MUST be present:

- `self_report=1` -> `self_report_overlay`
- `git_report=1` -> `git_report_branch`
- `embedding_report=1` -> `embedding_report_file_type`
- `solve_report=1` -> `solve_report_handler`
- `procsi_report=1` -> `procsi_report_surface`, `procsi_report_fingerprint_commitment`
- `procsi_report=1` and `procsi_report_masked=true` -> `procsi_report_app_ref`, `procsi_report_app_audience`
- `capability_report=1` -> `capability_report_authority`, `capability_report_ticket_kind`, `capability_report_store_ref`

## 6) Numeric and Bool Contracts

Unsigned fields MUST parse as unsigned integers:

- `entries`
- `self_report_gap`
- `git_report_commit_count`
- `embedding_report_count`
- `embedding_report_purge_after_turns`
- `solve_report_count`
- `capability_report_count`
- entry `candidates`, `conf_floor`, `provenance`

Signed fields MUST parse as signed integers:

- `temporal_delta_turns`
- `temporal_delta_bytes`
- `temporal_delta_causal_offset`

Boolean fields MUST be exactly `true` or `false`.

## 7) Parse Outcome Contract

`YataPlan::parse_wire_strict(raw)` returns:

- `ok=true` with `plan` when strict-valid
- `ok=false` with `issues[]` when strict-invalid

Compiler adapters SHOULD fail closed on `ok=false`.

`YataPlan::validate` MAY produce warnings even when parse succeeds.

## 8) Error Code Contract (Stable Surface)

Compiler integrations SHOULD treat these as stable machine codes:

- parse structure: `EMPTY_INPUT`, `BAD_KIND`, `BAD_TRACK`, `BAD_MODE`, `MALFORMED_HEADER`, `BAD_HEADER_NUMBER`, `BAD_HEADER_BOOL`, `BAD_ENTRY`, `UNRECOGNIZED_LINE`
- conditional requirements: `MISSING_*` variants (report-specific)
- flag validity: `BAD_*_FLAG` variants
- count consistency: `ENTRY_COUNT_MISMATCH`

Validation warning codes:

- `EMPTY_HOLE_ID`
- `EMPTY_STATE`

## 9) Compiler Integration Guidance

For compiler-facing pipelines:

1. emit `.plan` using deterministic field ordering
2. immediately strict-parse emitted wire as a self-check
3. fail build on parse error codes
4. route warning codes to advisory channel unless policy elevates them
5. include `procsi_report_*` and `capability_report_*` when exposing AI/runtime posture

## 10) Boundary/Cognitive Link

When `.plan` is used as boundary surface:

- producers SHOULD include compact boundary posture (`boundary_*`) in compatible carriers (for example `finger.plan.wasm`)
- consumers MUST treat boundary-marked outputs as representation-safe summaries, not raw authority payloads

## 11) Versioning

This profile is `v0.1`.

Any incompatible changes to required fields, strict parse behavior, or machine error codes MUST:

- bump profile version
- update `docs/YATA_PLAN_SPEC.md`
- update parser behavior and test coverage in the same change
