# Testing & Results

## SpecTest Vocabulary
- TestSuite → hasTestCase → hasStep → asserts
- Assertions: `expect.status`, `jsonPath` (`equals`, `matches`), `schemaRef` (TBD)

## Runner
- UI: `/jsonld/runner` and Workflow Editor → Run Tests
- Code: `Pactis.Spec.TestRunner.run_suite_file(path, persist: true, results_dir: "priv/jsonld/results")`

## Results Persistence
- Test runs are persisted as JSON‑LD (`@type`: TestRun) under `priv/jsonld/results/`.
- Each includes `results` (array of TestResult) with per-step responses and assertions.

See: [Pipeline & Orchestration](pipeline_orchestration.md)
