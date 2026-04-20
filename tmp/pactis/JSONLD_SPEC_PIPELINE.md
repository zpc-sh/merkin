# JSON-LD Spec Pipeline: Export, Templates, and Tests

This guide shows how to export Resources/Blueprints/Components to JSON-LD, generate templates, and embed executable tests. Teams can run this locally and in CI.

## Overview

- Export Ash Resources and Blueprints to JSON-LD
- Generate starter templates for Resources, Blueprints, Components
- Embed test suites in JSON-LD (SpecTest) and run from the UI or CLI
- Use the Svelte workflow editor for visual composition and test execution

## Configure Domains

Configured in `config/config.exs`:

- `config :pactis, :jsonld_export_domains` → default domains for export
- `config :ash_ops, :jsonld, domains: [...]` → library-level defaults

We set both to: `[Pactis.Accounts, Pactis.Core, Pactis.Spec, Pactis.Ops, Pactis.Billing]`.

## Export JSON-LD

Command options:

- Preferred: `mix pactis.jsonld.export --expanded` (alias: `mix jsonld.export`)
  - Uses `config :pactis, :jsonld_export_domains` when `--domains` not provided
- Or direct library task: `mix ash.jsonld.export --expanded`

Outputs under `priv/jsonld/`:

- `resources/<Domain>/<Resource>.jsonld`
- `blueprints/<slug>.jsonld`
- If `--expanded` is set, writes `*.expanded.jsonld` alongside

Examples:

- All defaults: `mix jsonld.export`
- Specific domains: `mix pactis.jsonld.export --domains Pactis.Accounts,Pactis.Core`

## Generate Templates

Use the template task to scaffold JSON-LD stubs into `priv/jsonld/resources/Templates/`:

- Resource (introspects an Ash resource):
  - `mix pactis.jsonld.templates --resource Pactis.Core.User`
- Blueprint (by slug):
  - `mix pactis.jsonld.templates --blueprint user_profile`
- Component (by name):
  - `mix pactis.jsonld.templates --component MyInput`

Context files:

- Spec context: `priv/jsonld/resources/Spec/context.jsonld`
- SpecTest context: `priv/jsonld/resources/SpecTest/context.jsonld`

## Embed Tests in JSON-LD

Embed or link test suites using SpecTest vocabulary:

- Examples: `priv/jsonld/resources/SpecTest/example_suite.jsonld`
- Link a suite in your spec via `hasTestSuite: "urn:testsuite:..."`

Assertions supported (starter):

- `expect.status` equals
- `jsonPath` + `operator` (`equals`, `matches`)
- `schemaRef` recognized (TODO: validate via ExJsonSchema)

## Run Tests

Two ways:

1) From the UI (Svelte editor)
   - Go to `/spec/workflows`
   - Use “Run Tests” to execute the example suite
   - Results display in-page (pass/fail summary)

2) From code / Oban job
   - Runner: `Pactis.Spec.TestRunner.run_suite_file(path)`
   - Oban job: `Pactis.Spec.SpecTestJob` (queue: `:spec`)

## Files Added by This Pipeline

- Runner: `lib/pactis/spec/test_runner.ex`
- Oban Job: `lib/pactis/spec/spec_test_job.ex`
- Editor UI: `lib/pactis_web/live/spec_live/workflow_editor.*` + `assets/svelte/WorkflowEditor.svelte`
- Hook: `assets/js/app.js` (`SvelteWorkflowEditor`)
- Contexts: `priv/jsonld/resources/Spec/context.jsonld`, `priv/jsonld/resources/SpecTest/context.jsonld`
- Templates: `priv/jsonld/resources/Templates/*.jsonld`

## CI and Scheduling

- CI job: run `mix jsonld.export && mix ash.jsonld.verify` and archive `priv/jsonld/`
- Scheduling: add an Oban Cron job to call export or an internal orchestrator to periodically write and publish JSON-LD artifacts

## Security & Best Practices

- Never embed raw secrets; use secret refs and resolve server-side
- Keep tests declarative; sandbox any imperative steps
- Record environment/runner info in results for reproducibility

## Troubleshooting

- Mix export fails due to sandbox/pubsub: run locally (non-sandbox) or in CI
- Missing domains: set `config :pactis, :jsonld_export_domains` or pass `--domains`
