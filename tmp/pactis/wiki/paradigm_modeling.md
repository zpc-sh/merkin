# Paradigm & Modeling

## Core Types
- SpecResource, SpecBlueprint, ComponentBlueprint: structural descriptions of resources and UI components
- TestSuite, TestCase, TestStep, Assertion: executable validation for specs

## Best Practices
- Always include `version` on specs for evolution.
- Link suites via `hasTestSuite` to formalize contract.
- Prefer references (URNs) to avoid brittle file paths; include `@id`.

## Relationships
- `dependsOn` to express composition across specs/blueprints.
- `hasTestSuite` to bind tests to a spec.

See also: [Authoring Specs](authoring_specs.md)
