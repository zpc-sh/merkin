# CI: Branding Generation and Service Manifest Validation

This snippet runs branding generation and validates the service manifest on PRs.

## GitHub Actions

```yaml
name: Pactis Branding & Manifest
on:
  pull_request:
    paths:
      - 'priv/**'
      - 'lib/**'
      - 'docs/specifications/**'
      - '.github/workflows/pactis-branding.yml'

jobs:
  branding:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@v1
        with:
          elixir-version: '1.15'
          otp-version: '26'
      - name: Cache deps
        uses: actions/cache@v4
        with:
          path: deps
          key: ${{ runner.os }}-mix-${{ hashFiles('**/mix.lock') }}
      - run: mix deps.get
      - name: Generate branding artifacts
        run: mix pactis.branding.generate --owner acme --repo ui --version v1
      - name: Validate service manifest
        run: mix pactis.service.validate
```

## Notes
- Adjust `--owner/--repo/--version` to match your repo.
- Include this in `.github/workflows/pactis-branding.yml` or another CI system.

