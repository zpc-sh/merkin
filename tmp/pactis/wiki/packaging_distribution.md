# Packaging & Distribution

## Manifest
- `priv/jsonld/library/manifest.jsonld` declares included contexts, templates, examples, tests, and docs.

## Package
- `mix pactis.jsonld.package --out dist --version 0.1.0-draft` → tar bundle

## Download
- Route: `/jsonld/library/download` (when feature flag enabled)

See: [Integrations](integrations.md)
