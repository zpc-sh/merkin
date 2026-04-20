# Pactis‑DAI: Design API Interface

Status: draft

## Purpose
Expose design language artifacts (org TokenSet, repo EffectiveTokenSet, branding assets) via a cohesive API under `/api/v1/design`.

## Endpoints
- `GET /api/v1/design/tokens/org/:org_id/:version`
  - Returns org TokenSet (JSON‑LD) for a given version.
- `POST /api/v1/design/tokens/org/:org_id`
  - Create/update org TokenSet; triggers recompute jobs.
- `GET /api/v1/design/tokens/repo/:owner/:repo?org_version=vX`
  - Returns EffectiveTokenSet (JSON‑LD) derived from org tokens with repo overrides.
- `GET /api/v1/design/branding/logo.svg?owner=:owner&repo=:repo&org_version=:v&text=&size=`
  - Dynamic SVG logo from tokens.
- `GET /api/v1/design/branding/theme.css?owner=:owner&repo=:repo&org_version=:v`
  - CSS variables derived from tokens (primary color, font families).

## Generation Workflow
- On TokenSet change or repo overrides: enqueue `BrandingGenerateJob` to render SVG and CSS.
- Artifacts are stored content‑addressed under `/cas/sha256/{digest}.{ext}` and referenced in the service manifest.

## JSON‑LD
- Context: `/jsonld/pactis.context.jsonld`
- Key types: `pactis:TokenSet`, `pactis:EffectiveTokenSet`, `pactis:ServiceDescriptor`.
- Branding assets may be described with `schema:ImageObject` and `schema:MediaObject` including `contentUrl`, `encodingFormat`, `sha256`.

## Validation (TVI)
- Lint TokenSets: required keys, scopes, value formats.
- Branding checks: SVG-sanitization, contrast thresholds, URL integrity.

## Notes
- Existing routes kept for backward compatibility; DAI consolidates them for clarity.
- Extend with batch endpoints later (e.g., `/api/v1/design/tokens/batch`).

