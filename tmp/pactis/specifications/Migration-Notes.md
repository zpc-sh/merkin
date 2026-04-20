# Pactis Migration Notes (Q3–Q4 2025)

This document summarizes recent changes to authentication, events, invitations, and tenancy that affect implementers and integrators.

## Authentication & API Tokens

- Switched from ad‑hoc API token resources to AshAuthentication API token strategy (`Pactis.Accounts.ApiKey`).
- Token format uses `cdfm_` prefix for secret scanning.
- Plaintext token is returned only once at creation; server stores hash + prefix.
- Endpoints under `/api/v1/tokens` (list/create/show/revoke).
- Bearer auth pipelines standardize on:
  - `plug :load_from_bearer`
  - `plug :set_actor, :user`
  - `plug PactisWeb.Plugs.AttachAuthContext` to set `:api_token` and `:scopes`
  - `plug PactisWeb.Plugs.RequireApiAuth` and `Plug.RequireScope` where needed

## Invitations (Organizations)

- Introduced token/email-based invitations (`Pactis.Accounts.Invitation`).
- Org admin/owner can create, revoke, and resend invitations.
- API endpoints:
  - `GET /api/v1/orgs/:org_id/invitations`
  - `GET /api/v1/orgs/:org_id/invitations/:id`
  - `POST /api/v1/orgs/:org_id/invitations`
  - `DELETE /api/v1/orgs/:org_id/invitations/:id`
  - `POST /api/v1/orgs/:org_id/invitations/:id/resend`
- Accept flow:
  - `GET /auth/invitations/accept?token=...`
  - `POST /auth/invitations/accept` (requires session auth)

## Events (AshEvents)

- Standardized on AshEvents for both action events (via `events do event_log(...)`) and business events (`Pactis.Events.emit/2`).
- Emit JSON‑LD friendly payloads, minimal PII, and include `actor`, `tenant`, `correlation_id`, `causation_id` when available.
- See `docs/events.md` for naming and versioning guidance.

## Secrets

- Consolidated on `Pactis.Secrets` with no hardcoded dev/test values.
- Signing secret: `AUTH_SIGNING_SECRET` or `:pactis, :auth_signing_secret`, else ephemeral per-runtime secret.
- OAuth GitHub/Google env vars supported; redirect URIs default to `<base>/auth/{provider}/callback`.

## Tenancy & Roles

- GitHub‑style workspace/org model; authorization enforced via `Pactis.Accounts.UserOrganization` (string roles).
- Legacy `Pactis.Accounts.Membership` retained for backward compatibility but should be migrated to `UserOrganization`.

## Operational

- Rebuild script (`scripts/nuke_and_rebuild.sh`) fixed to target `pactis_dev` by default.
- After regeneration, consider adding invitation indexes:
  - `org_id`
  - `(org_id, invitee_email)` filtered by `status = 'pending'`
  - `token_prefix` (optional)

## Action Items

- Update clients to new token endpoints and invitation flows.
- Ensure environment variables are set for signing and OAuth.
- Adopt event naming/versioning guidelines and propagate correlation IDs across async flows.
- Prefer `UserOrganization` for role checks; mark any new code accordingly.

