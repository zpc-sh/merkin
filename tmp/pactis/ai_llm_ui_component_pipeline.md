# AI LLM → UI Component Pipeline (Blueprints)

This document describes how we generate UI components (Blueprints) with an LLM, validate and persist them, expose the capability to users (UI + API), and integrate billing/quotas. The feature is implemented — this doc covers how to use it and how to wire AshTypescript for typed clients.

## TL;DR — Seed Components Today

- Generate N components for a category (synchronous run):

  ```bash
  # Example: generate 10 cards components
  mix pactis.generate_components --category cards --count 10
  ```

- Update docs bundle after seeding:

  ```bash
  mix docs.all
  open priv/docs/index.html
  ```

- Find components in the DB under `Pactis.Blueprints.Blueprint` with populated
  `resource_definition`, `component_files`, and `readme`. JSON‑LD is in
  `priv/jsonld/resources/components/` if your generator emits it.

## Pipeline Overview

1) Input: brief + constraints (props, variants, design tokens, accessibility).
2) Generate: LLM returns a Blueprint Package JSON:
   - `manifest.json` (metadata, provenance)
   - `resource_definition` (Ash-friendly spec)
   - `component_files` (path→content)
   - `readme` (usage + accessibility)
3) Validate: structural + semantic checks; safe content filters.
4) Persist: insert `Pactis.Blueprints.Blueprint`; optional Git export.
5) JSON‑LD: emit compact + expanded under `priv/jsonld/resources/components/`.
6) Preview/Publish: show in UI; search/discovery; versioning/forking.
7) Billing/Quotas: track `components_created`, tokens (`api_calls`), and enforce limits.

## Package Structure Details

- `manifest.json`: name, slug (kebab), description, version (semver), license, tags[], category, visibility, provenance (model, prompt_hash)
- `resource_definition` (map):
  - `module_name` (CamelCase), `attributes[]` (name/type/required/default), `relationships[]`, `actions[]`
  - `meta`: `{ resource_type: "component", ui: { variants: [], tokens: {} } }`
- `component_files` (map):
  - `lib/pactis_web/components/<slug>.ex`
  - `lib/pactis_web/components/<slug>.heex`
  - `assets/css/<slug>.css`
- `readme` (string): usage, variants, accessibility notes, props table
- `jsonld`: compact + expanded (emitted to `priv/jsonld/resources/components/`)

## Validation Checks

- Required fields: name, slug, version, resource_definition.module_name, attributes[], actions[], readme, component_files (≥1 main component)
- Slug sanitize: kebab-case, unique
- Version: semver
- Accessibility: README Must include an Accessibility section
- Safety: deny remote code, eval, unsafe HTML; restrict file size/extension
- JSON‑LD: presence of @context and @type, valid shape

## How to Generate

- Direct (Elixir):

  ```elixir
  # Single component
  Pactis.AI.ComponentGenerator.generate_single(:cards, "StatsCard", "Stats with trend")

  # Category batch
  Pactis.AI.ComponentGenerator.generate_category(:cards, 5)

  # Library with distribution
  Pactis.AI.ComponentGenerator.generate_library(50)
  ```

- Mix task (convenience):

  ```bash
  mix pactis.generate_components --category cards --count 10
  ```

This calls the existing generator and will persist validated components.

## Exposing to Users

- UI Service:
  - Add a Generator page (form: name, category, constraints) invoking typed RPC
  - Show progress via PubSub or job polling; navigate to preview on success
- Public API:
  - REST endpoints (async via jobs):
    - POST `/api/components/generate` → `{ job_id }`
    - GET `/api/components/jobs/:id` → `{ status, result? }`
  - Rate limited, JWT/API token auth, workspace-scoped

See also: `docs/api/component_generation.md` for request/response shapes.

## AshTypescript Integration (Typed Clients)

- Goal: Expose typed RPCs to the front‑end without custom REST wrappers.
- Approach: Add a thin resource wrapper (e.g., `Pactis.AI.Generator`) with RPC‑style create/read actions that delegate to `Pactis.AI.ComponentGenerator`.
- In your domain using `AshTypescript.Rpc`, add:

  ```elixir
  typescript_rpc do
    resource Pactis.AI.Generator do
      rpc_action :generate_single, :generate_single_action
      rpc_action :generate_category, :generate_category_action
      rpc_action :generate_library, :generate_library_action
      rpc_action :get_stats, :get_stats_action
    end
  end
  ```

- Each action delegates to the module functions and returns typed results. Then generate the TS client and consume in the UI.

## Billing & Quotas

- UsageTracker events:
  - `components_created` (+1 on success)
  - `api_calls` (+ tokens used; provider usage data)
- Plans:
  - Soft/hard limits per dimension; return 429 on hard limit; PubSub alerts near thresholds

## JSON‑LD Emission

- Emit compact + expanded JSON‑LD per component to `priv/jsonld/resources/components/`.
- Add links in the package to reference files/variants for docs systems.

## Roadmap

- [ ] Oban job wrapper for long‑running generation + progress UI
- [ ] REST endpoints as documented (async job, status)
- [ ] AshTypescript RPC resource wrapper + TS client generation
- [ ] Generator UI (form + progress + preview)
- [ ] Billing polish (dimension mapping, quotas per plan, admin dashboards)
- [ ] Marketplace discoverability (search facets for tags/variants/tokens)
