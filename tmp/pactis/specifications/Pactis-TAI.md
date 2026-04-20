# Pactis‑TAI: Test API Interface

- Status: Draft
- Last Updated: 2025-09-20
- Owners: Pactis Core
- Related: SpecAPI, Pactis‑CFP, Pactis‑KEI, RFC_JSONLD_LIBRARY.md, JSONLD_SPEC_PIPELINE.md

## Summary
Pactis‑TAI specifies a JSON‑LD model and API for tests, suites, runs, and results so that tests are portable, machine‑readable, and correlatable across services and repos. It complements SpecAPI by enabling test execution, storage, and reporting as first‑class JSON‑LD artifacts.

## Concepts & JSON‑LD Shapes
- TestSuite (`test:TestSuite`): contains metadata and a list of TestCase IRIs
- TestCase: name, purpose, inputs, expected vs. oracle, tags
- TestRun: execution of a suite/case, environment, version, outcome
- TestResult: per-case outcome attached to a TestRun
- Correlation: link to SpecAPI Request/Thread and repository commits

Example (minimal):
```
{
  "@context": {"test": "https://pactis.dev/test#", "spec": "https://pactis.dev/spec#"},
  "@type": "test:TestSuite",
  "@id": "urn:pactis:test:suite:button-accessibility",
  "test:title": "Button Accessibility Suite",
  "test:cases": [
    {"@id": "urn:pactis:test:case:contrast"}
  ]
}
```

## Operations (reference)
- SubmitSuite: POST `/api/v1/test/suites` — create/update suite (JSON‑LD)
- RunSuite: POST `/api/v1/test/runs` — body `{ suiteId, env, inputs }`
- ListRuns: GET `/api/v1/test/runs?scope=...`
- GetRun: GET `/api/v1/test/runs/:id` — returns TestRun + TestResult[]

## Events & Observability
- PubSub: `test:run_enqueued`, `test:run_started`, `test:run_completed`, `test:artifact_ready`
- Telemetry: timings per run, pass/fail counts, flake rate

## Conformance
- Suites and runs MUST have stable `@id` and declare `@context`
- A TestRun MUST remain immutable after completion; re‑runs produce new IDs with `prov:wasDerivedFrom`
- Artifacts (logs/screenshots/traces) are referenced via CAS/VFS URIs

## Integrations
- SpecAPI: link TestRun to a Spec Request via `spec:request`
- KEI/CFP: Surface recent TestRun summaries into ContextFrames for conversations
- VFS: Attach run artifacts via `graph://` and `cas://` URIs

## Privacy & Security
- No raw secrets in JSON‑LD; redact tokens and PII
- Use capability scopes: `read:test`, `write:test`

## Examples
- TestSuite: `docs/examples/tai_test_suite.jsonld`
- TestRun: `docs/examples/tai_test_run.jsonld`
- Correlated (SpecRequest + TestRun + LogEntry): `docs/examples/observability_correlated.jsonld`
