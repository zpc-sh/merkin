# Pactis‑OSI: Organization Services Index

Status: draft

Purpose
- Define an org‑level JSON‑LD document enumerating repositories/services, design‑hub settings, and parent/child relationships.
- Acts as a centralized pointer list for crawlers/UI to collect each repo’s `service.jsonld` and render grouped views.

Location
- Recommended: `priv/services.config.jsonld` in the org’s primary repository.
- Public (optional): `GET /.well-known/services.jsonld` (serve the same content or a dereferenced @graph).

Context
- `"/jsonld/pactis.context.jsonld"`
- Prefixes: `schema`, `pactis`

Shape: `pactis:OrgServices`
- `pactis:orgId` (string): Organization slug/id
- `schema:name` (string)
- `pactis:designHub` (map): `{ logoUrl, themeCss, tokenSetRef }`
- `pactis:repositories` (array): entries describing repos/services
  - `@id` (IRI): stable service id, e.g., `pactis:service/avici`
  - `owner`, `repo` (strings)
  - `kind` (enum): `api-service|cli|mobile-sdk|web-app|lib`
  - `serviceUrl` (string, optional): override path/URL to repo’s `service.jsonld`
  - `pactis:parent`/`schema:isPartOf` (IRI): parent service id (for children only)
  - `tags[]` (array of strings)

Relationships
- Children declare `pactis:parent` and `schema:isPartOf` → parent service id.
- Parents MAY declare `schema:hasPart` → list of child service ids.
- SDI (`service.jsonld`) remains the canonical descriptor at the repo level; OSI is an index.

Example
- See `priv/services.config.jsonld` in this repo.

Validation
- Use `mix pactis.service.validate` for individual manifests.
- A future `mix pactis.osi.validate` can cross‑check `parent/isPartOf` consistency and URL reachability.

Integration
- Registry/crawler resolves each entry’s `serviceUrl` (or default locations) and collects manifests.
- UI renders grouped services per parent and applies `designHub` branding for org views.

Security/Change Control
- Treat OSI like code: PRs, reviews, branch protections. Consider signing releases for stable org states.

