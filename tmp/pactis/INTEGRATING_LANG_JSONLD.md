# Integrating LANG JSON-LD Pipeline into Pactis

This document summarizes the practical steps we took to align Pactis with LANG’s JSON‑LD pipeline and how to use the new tools.

## What’s Added

- MIME support for JSON‑LD and Markdown‑JSON‑LD (mdld)
- Mix task: Validate JSON‑LD (`mix pactis.jsonld.validate`)
- Mix task: Markdown → JSON‑LD (`mix pactis.jsonld.md_to_jsonld`)
- JSON‑LD Runner page: `/jsonld/runner` (paste JSON‑LD; executes TestSuite or echoes typed docs)

## Configure & Build

No extra steps required; config was updated in `config/config.exs`:
- `:mime` types for `application/ld+json` and `application/markdown-ld+json`
- Phoenix format encoders: `jsonld` and `mdld` via Jason

## Commands

- Validate all JSON‑LD under a directory:
  - `mix pactis.jsonld.validate --dir priv/jsonld`
- Validate with stricter mode (warnings fail build):
  - `mix pactis.jsonld.validate --dir priv/jsonld --strict`
- Convert Markdown table → JSON‑LD files:
  - `mix pactis.jsonld.md_to_jsonld --in docs/specs.md --out priv/jsonld/tmp --type SpecResource`

## UI Runner

- Navigate: `/jsonld/runner`
- Paste a JSON‑LD document, click Run.
  - If `@type` == `TestSuite`, runs via `Pactis.Spec.TestRunner` and shows pass/fail summary.
  - Otherwise echoes the parsed document.

## Next Steps

- Extend validator to resolve and validate `schemaRef` via ExJsonSchema.
- Add a Markdown converter profile for LSP‑style function specs if desired.
- Unify PubSub topics and cron jobs with LANG’s schedules where appropriate.

## References
- LANG pipeline analysis: `docs/LANG_JSONLD_PIPELINE_REPORT.md` (in LANG repo)
- Pactis test vocab & example suites: `priv/jsonld/resources/SpecTest/`
