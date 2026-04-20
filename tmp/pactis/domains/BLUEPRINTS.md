# Pactis.Blueprints Domain

- Purpose: Owns blueprint resources and related entities used to define, publish, search, and analyze shareable components.
- Domain module: `Pactis.Blueprints`
- Resource modules (registered in this domain):
  - `Pactis.Blueprints.Blueprint`
  - `Pactis.Blueprints.BlueprintCategory`
  - `Pactis.Blueprints.Collection`
  - `Pactis.Blueprints.CollectionItem`
  - `Pactis.Blueprints.Review`
  - `Pactis.Blueprints.Issue`
  - `Pactis.Blueprints.ChangelogEntry`
  - `Pactis.Blueprints.QualityMetrics`
  - `Pactis.Blueprints.PackageDependency`
  - `Pactis.Blueprints.UsageMetric`

Usage
- When performing Ash reads/writes on blueprints or related resources, pass `domain: Pactis.Blueprints`.
- Example:
  - `Ash.read(Pactis.Blueprints.Blueprint, domain: Pactis.Blueprints)`
  - `Ash.create(Pactis.Blueprints.Blueprint, params, domain: Pactis.Blueprints)`

Notes
- Resource modules remain under `Pactis.Blueprints.*` to minimize churn; the domain is the grouping mechanism.
- Repositories and Git artifacts live under `Pactis.Repositories`.
- Spec resources live under `Pactis.Spec`.
