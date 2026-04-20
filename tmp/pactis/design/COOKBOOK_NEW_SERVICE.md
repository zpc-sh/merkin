# Cookbook: Onboarding a New Service with Pactis

This guide shows a pragmatic, end‑to‑end workflow to bring a new service into Pactis with a first‑class design language and a service manifest consumable by your company website.

## 1) Define Org Tokens
- Create an org‑scoped TokenSet with color, typography, spacing, and fonts.
- Example file: `priv/examples/tokens.example.json` (provided in repo).

Post tokens (org‑scoped):
```
POST /api/v1/design/tokens/org/:org_id
Content-Type: application/json
{
  "version": "v1",
  "tokens": { ... }
}
```

## 2) Repo Derives EffectiveTokenSet
- Each repo inherits from the org TokenSet and may add overrides.
- Fetch (or compute) EffectiveTokenSet:
```
GET /api/v1/design/tokens/repo/:owner/:repo?org_version=v1
```

## 3) Generate Branding Assets
Option A — dynamic endpoints (no assets stored):
- Logo SVG: `/branding/logo.svg?owner=:owner&repo=:repo&org_version=v1&text=MySvc&size=32&variant=wordmark|mark&pattern=grid|dots|stripes|noise`
- Theme CSS: `/branding/theme.css?owner=:owner&repo=:repo&org_version=v1`
- Typography CSS: `/branding/typography.css?owner=:owner&repo=:repo&org_version=v1`

Option B — content‑addressed assets (CAS):
- Generate and store to CAS, then update the service manifest to point to immutable URLs:
```
mix pactis.branding.generate --owner <org> --repo <repo> --version v1
```
This writes SVG/CSS to `priv/storage/cas/sha256/` and updates `priv/service.manifest.jsonld` with `schema:ImageObject` / `schema:MediaObject` including `sha256`.

## 4) Create/Update Service Manifest
- Location: `priv/service.manifest.jsonld`
- Serve via: `GET /service.jsonld`
- Minimal shape:
```json
{
  "@context": ["/jsonld/pactis.context.jsonld", {"schema":"https://schema.org/"}],
  "@id": "pactis:service/my-service",
  "@type": ["pactis:ServiceDescriptor", "schema:Service"],
  "name": "My Service",
  "branding": {
    "logo": {"@type":"schema:ImageObject","contentUrl":"/cas/sha256/<digest>.svg","encodingFormat":"image/svg+xml","sha256":"<digest>"},
    "theme": {"@type":"schema:MediaObject","contentUrl":"/cas/sha256/<digest>.css","encodingFormat":"text/css","sha256":"<digest>"},
    "themeColor": "#FD4F00"
  }
}
```

## 5) Validate
- Manifest + branding validation (SVG sanitization, contrast checks):
```
mix pactis.service.validate
```
- Token lint (typography ramp, spacing scale, step):
```
mix pactis.design.validate --owner <org> --repo <repo> --version v1 --step 4px
# or from file
mix pactis.design.validate --file priv/examples/tokens.example.json --step 4px
```

## 6) Aggregate Services for Website
- Provide a list of service manifest URLs; aggregator returns merged JSON‑LD:
```
GET /api/v1/services?sources=https://svc-a/service.jsonld,https://svc-b/service.jsonld
# or POST {"sources":["..."]}
```
- Your site renders cards/navigation using `branding.logo`, `branding.theme`, and links.

## 7) CI Setup
- See `docs/CI_BRANDING_VALIDATION.md` for a GitHub Actions workflow.
- Typical steps: `mix deps.get`, `mix pactis.branding.generate`, `mix pactis.service.validate`.

## 8) Tips & Best Practices
- Keep typography monotonic and spacing strictly increasing (prefer consistent steps).
- Keep `color.primary` contrasting with black or white (WCAG >= 4.5); validator checks it.
- Prefer CAS URLs (`/cas/sha256/...`) in manifests for strong caching and integrity.
- Use dynamic endpoints (`/branding/logo.svg`, `/branding/theme.css`) for live previews.
- Put `@import` font URLs in `tokens.fonts.imports` for auto inclusion in theme.css.

References:
- Design API: `docs/specifications/Pactis-DAI.md`
- Service Registry Interface: `docs/specifications/Pactis-SRI.md`
- Tokens Best Practices: `docs/design/TOKENS_BEST_PRACTICES.md`
