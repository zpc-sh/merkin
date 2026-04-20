# Pipeline & Orchestration

## Stages
1. Author → 2. Convert → 3. Validate → 4. Execute (optional) → 5. Package → 6. Distribute

## CI
- GitHub Actions builds a tar artifact of the library on main.

## Feature Flags
- JSON-LD library download endpoint guarded by `config :pactis, :jsonld_library`.

See: [Packaging & Distribution](packaging_distribution.md)
