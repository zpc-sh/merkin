# App Bundles as JSON-LD

This document outlines representing entire applications as JSON-LD graphs, enabling a codebase to be built, packaged, deployed, and marketed from a semantic source of truth rather than a Git repo.

## Goals

- Treat an app as a graph (capabilities, services, routes, jobs, data models, policies, artifacts)
- Make the graph portable (install, upgrade, diff, rollback) via normalized JSON-LD
- Generate code and assets on demand; publish deployable artifacts
- Power a marketplace of composable, battle-tested “morsels” and full apps

## Vocabulary

- `AppBundle`: top-level app descriptor (`@id`, `name`, `version`, `license`, `maintainer`, `tags`)
- `Component`: reusable spec/component with `sourceTemplate` and optional `generator`
- `Service`: web or worker units with `routes`, `events`, `jobs`
- `DataModel`: domain resources and migrations
- `Policy`: auth/billing gates, constraints
- `BuildRecipe`: how to generate/build (language/generators)
- `Artifact`: outputs (e.g., Docker image via `ociRef`, static assets)

Context: `priv/jsonld/resources/Spec/app_context.jsonld`

## Files

- Example bundle: `priv/jsonld/resources/Spec/app_bundle.example.jsonld`
- Loader: `lib/pactis/spec/app_bundle.ex` (`Pactis.Spec.AppBundle.load_file/1`)

## Pipeline

1) Author: create/update an `AppBundle` + components in JSON-LD
2) Validate: `JsonldEx.validate_document/1` and shape checks
3) Normalize: compute a stable hash (URDNA-like) for CAS storage (future)
4) Generate: invoke generators for handlers/UI from components/specs
5) Build: compile + package into `Artifact`(s) (e.g., Docker/OCI)
6) Publish: push artifacts and register bundle in marketplace index
7) Install: pull bundle graph, generate/build locally or fetch artifacts
8) Operate: expose routes, launch jobs, enforce policies (billing gates)

## Marketplace

- Indexes AppBundles and Components by `@id`, `tags`, `capabilities`
- Supports content-addressed fetch and partial sync by following edges
- Licensing, billing, and telemetry baked into the graph (policies + events)

## Why This Beats Repos

- Portable: move apps by syncing graph + artifacts; no repo juggling
- Composable: mix-and-match components with clear interfaces
- Reproducible: generation/build steps are declared, not ad-hoc
- Observable: events and tests travel with the bundle

## Next Steps

- Add CAS hashing to archive/restore graphs
- Add a Mix task to build/publish `AppBundle`
- Extend generators to accept `AppBundle` for project creation
- Wire a small marketplace index JSON-LD and install command

