# Pactis-PRI: Pactis Resource Interface

Status: Implemented
Implementation: lib/pactis/resource_encoder.ex

## Abstract
Universal semantic serialization for any computational resource - code, APIs, UI components, themes, or blueprints.

## The Invention
Born from the annoyance of rewriting API resources repeatedly, PRI enables ANY Ash resource to become a semantic, shareable, versionable artifact.

## Core Innovation
```elixir
ResourceEncoder.to_jsonld(literally_anything) → Semantic Web Object
Vocabulary

pactis:Blueprint - Universal container for any resource type
pactis:package_type - ["blueprint", "component", "theme", "api", ...]
pactis:exports - Multi-format export capabilities
