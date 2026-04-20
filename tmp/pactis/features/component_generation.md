# AI Component Generation (Blueprints)

This feature programmatically generates UI Components (Blueprints) using LLMs and persists them in the Blueprints domain for preview and reuse. It is production‑ready and integrated with the usage/billing pipeline.

## Overview

- Input: brief + constraints (props, variants, tokens, accessibility)
- Generate: LLM produces a Blueprint package (resource_definition, component_files, readme)
- Validate: structural + semantic checks; safe content filters
- Persist: `Pactis.Blueprints.Blueprint` + optional repo export (Git storage)
- Preview: render demo in the preview app; variants/states
- Publish: discoverability, tags, categories; optional versioning/forking
- Telemetry/Billing: increments usage (components_created, api_calls)

## Package Format

- `manifest.json`: name, slug, description, version (semver), license, tags[], category, visibility, provenance
- `resource_definition` (map):
  - `module_name`, `attributes[]` (name/type/required/default), `relationships[]`, `actions[]`, `meta{resource_type: "component", ui: {variants, tokens}}`
- `component_files` (map<string path, string content>):
  - `lib/pactis_web/components/<slug>.ex`
  - `lib/pactis_web/components/<slug>.heex`
  - `assets/css/<slug>.css`
- `readme` (string): usage, variants, accessibility notes, props table
- `jsonld` (emitted):
  - Compact: `priv/jsonld/resources/components/<slug>.jsonld`
  - Expanded: `priv/jsonld/resources/components/<slug>.expanded.jsonld`

## Persistence

- Database: insert `Pactis.Blueprints.Blueprint` (fields: name, slug, description, version, license, tags, resource_definition, readme, component_files)
- Optional Repo export: use `Pactis.Git.StorageAdapter` to write blobs/trees and commit; create Spec Request for review if needed
- JSON‑LD: emit compact + expanded files for docs/navigation

## Validation

- Required: name, slug (kebab), version (semver), resource_definition.module_name, attributes[], actions[], readme, component_files (at least a main component)
- Accessibility: readme must contain an Accessibility section
- File safety: strip dangerous HTML/JS; enforce size/extension limits
- JSON‑LD sanity: presence of @context and @type

## Usage & Billing

- UsageTracker events: `components_created` (+1), `api_calls` (LLM tokens)
- Quotas/Plans: soft/hard limits by plan (quota alerts via PubSub)

## Generation Entry Points

- RPC (AshTypescript): `Pactis.AI.ComponentGenerator`
  - `generate_single/4`, `generate_category/3`, `generate_library/2`, `get_stats/0`, `validate_library/0`
- Oban job (recommended for long‑running): wrap generation calls in jobs and stream progress

## Seeding

- Preferred: `mix pactis.generate_components --count 20 --category ui` (job per component)
- Offline ingest: place package JSON under `priv/blueprint_packages/<slug>/` and import with a Mix task

