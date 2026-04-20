# RFC: Pactis JSON-LD Specs Library and Pipeline

- Status: Draft
- Authors: Pactis Team
- Last-Updated: 2025-09-17
- Target Version: 0.1.0

## 1. Abstract

This RFC specifies the JSON-LD-based specification library and pipeline owned by Pactis. It defines the data model, tooling, packaging, and operational processes for producing, validating, executing, and distributing machine-readable specs as a reusable library for third parties.

## 2. Goals

- Provide a canonical JSON-LD vocabulary and templates for Resources, Blueprints, Components, and Test Suites.
- Offer end-to-end tooling: authoring (Markdown→JSON-LD), validation, execution (tests), and packaging.
- Enable repeatable export and distribution of the library as a versioned tarball artifact.

## 3. Non-Goals

- Defining a universal context registry or remote context fetching semantics beyond local references.
- Shipping a full conformance suite; initial validator focuses on structural checks with optional schema validation follow-up.

## 4. Terminology

- JSON-LD: JSON for Linked Data.
- SpecResource / SpecBlueprint / ComponentBlueprint: Pactis types describing system elements.
- TestSuite/TestCase/TestStep/Assertion: Pactis SpecTest vocabulary for executable tests.

## 5. Architecture Overview

The pipeline produces and consumes JSON-LD artifacts through these stages:
- Author → Convert → Validate → Execute (optional) → Package → Distribute

### 5.1 High-Level Flow

1) Authoring: specs created as JSON-LD or converted from Markdown tables.
2) Validation: structural checks; future schemaRef validation.
3) Execution: optional tests (HTTP status/jsonPath), streamed via UI.
4) Packaging: contexts, templates, examples, and tests bundled as a tarball.
5) Distribution: artifact attached in CI and optionally downloadable in-app.

## 6. Data Model (Contexts and Types)

- Spec context: `priv/jsonld/resources/Spec/context.jsonld`
  - Types: SpecResource, SpecBlueprint, ComponentBlueprint
  - Common properties: name, description, version, tags, dependsOn, hasTestSuite

- SpecTest context: `priv/jsonld/resources/SpecTest/context.jsonld`
  - Types: TestSuite, TestCase, TestStep, Assertion
  - Properties: variables, secrets (by ref), asserts (status/jsonPath/schemaRef)

- Templates: `priv/jsonld/resources/Templates/*.jsonld`
  - Resource/Blueprint/Component boilerplate with recommended fields

- Examples: HeartCheck JSON-LD examples

## 7. Tooling & Commands

- Export: `mix pactis.jsonld.export [--expanded] [--domains ...]`
- Validate: `mix pactis.jsonld.validate --dir priv/jsonld [--strict]`
- Markdown→JSON-LD: `mix pactis.jsonld.md_to_jsonld --in docs/specs.md --out priv/jsonld/tmp --type SpecResource`
- Package: `mix pactis.jsonld.package --out dist --version 0.1.0-draft [--dry-run]`

## 8. Execution (Test Runner)

- Runner supports TestSuite documents:
  - HTTP Step: method, urlTemplate, headers, body
  - Assertions: expect.status, jsonPath operators (equals, matches), schemaRef (TBD)
- UI: `/jsonld/runner` for paste-and-run; “Run Tests” also exists in Workflow Editor.
- Results: Test runs are persisted as JSON-LD under `priv/jsonld/results/` (type: `TestRun`) with per-case `TestResult` entries.

## 9. Packaging and Distribution

- Manifest: `priv/jsonld/library/manifest.jsonld`
  - Declares contexts, templates, examples, tests, and docs to include.
- Package format: tar (optionally compressed by :erl_tar).
- CI: GitHub Actions workflow builds and uploads artifact on push to main.
- Feature flag: optional in-app download endpoint guarded by config.

## 10. Security Considerations

- No raw secrets in JSON-LD; use secret references.
- Tests only perform declarative HTTP calls; execution is sandboxed.
- Future schema validation should guard against malformed inputs.

## 11. Backwards Compatibility

- Templates include `version` for evolution.
- Contexts are additive; removing or renaming terms is a breaking change.

## 12. Observability

- Validation logs and counts (ok/warn/error).
- UI shows test results; can extend to stream per-assertion outcomes.

## 13. Rollout Plan

- Phase 1: Stabilize contexts/templates; add schemaRef validation.
- Phase 2: Publish library artifact per release; enable in-app download toggle.
- Phase 3: Document external integration; add examples per language/runtime.

## 14. Appendix: File Map

- Contexts: `priv/jsonld/resources/Spec/context.jsonld`, `priv/jsonld/resources/SpecTest/context.jsonld`
- Templates: `priv/jsonld/resources/Templates/*.jsonld`
- Examples: `priv/jsonld/resources/Heartcheck/*.jsonld`
- Manifest: `priv/jsonld/library/manifest.jsonld`
- Tasks: `lib/mix/tasks/pactis.jsonld.*.ex`
- Runner UI: `/jsonld/runner`
- CI: `.github/workflows/jsonld_library.yml`

---

designed by codex(s)
