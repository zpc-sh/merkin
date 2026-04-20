# Pactis-Auth: Authentication, Tokens, Invitations

- Status: Draft
- Last Updated: 2025-09-26
- Owners: Pactis Core
- Related: docs/authentication.md (dev), Pactis-API.md, Pactis-PSI.md

## Overview

Pactis uses AshAuthentication for session and API authentication. Two credential types are supported:

- JWT (session) for browser flows
- API tokens (long‑lived, scope‑based) for programmatic access

Events (audit trails) are captured via AshEvents.

## Authentication Model

- Session (browser):
  - AshAuthentication routes under `/auth`
  - Router pipelines include `plug :load_from_session` for browser pages
- API (bearer):
  - Router pipelines include:
    - `plug :load_from_bearer`
    - `plug :set_actor, :user`
    - `plug PactisWeb.Plugs.AttachAuthContext` → assigns `api_token` and `scopes`
    - `plug PactisWeb.Plugs.RequireApiAuth` for endpoints that require auth
    - `plug PactisWeb.Plugs.RequireScope, scopes: [..]` where needed

## API Tokens

- Resource: `Pactis.Accounts.ApiKey` (AshAuthentication API token strategy)
- Format: `cdfm_...` (intentionally structured to allow secret scanning)
- Scopes: string list; include `admin` or granular scopes (e.g., `read:components`, `write:components`)
- Management endpoints:
  - `GET /api/v1/tokens` — list current user’s tokens
  - `POST /api/v1/tokens` — create token (returns plaintext once)
  - `GET /api/v1/tokens/:id` — show token metadata
  - `DELETE /api/v1/tokens/:id` — revoke token

Security notes:
- Plaintext token is returned only at creation time; store securely client‑side
- Server stores only hash and prefix

## Invitations

- Resource: `Pactis.Accounts.Invitation`
- Flow: org admin/owner invites by email → recipient gets accept link with token
- API:
  - `GET /api/v1/orgs/:org_id/invitations` — list
  - `GET /api/v1/orgs/:org_id/invitations/:id` — show
  - `POST /api/v1/orgs/:org_id/invitations` — create (role, message, expiry)
  - `DELETE /api/v1/orgs/:org_id/invitations/:id` — revoke
  - `POST /api/v1/orgs/:org_id/invitations/:id/resend` — regenerate and resend
  - `GET /auth/invitations/accept?token=...` — accept page
  - `POST /auth/invitations/accept` — accept action (requires session auth)

## Secrets & OAuth

- Signing secret: `AUTH_SIGNING_SECRET` (env) or `:pactis, :auth_signing_secret`; no hardcoded defaults
- OAuth GitHub/Google:
  - `OAUTH_GITHUB_CLIENT_ID`, `OAUTH_GITHUB_CLIENT_SECRET`, `OAUTH_GITHUB_REDIRECT_URI`, `OAUTH_GITHUB_BASE_URL`
  - `OAUTH_GOOGLE_CLIENT_ID`, `OAUTH_GOOGLE_CLIENT_SECRET`, `OAUTH_GOOGLE_REDIRECT_URI`, `OAUTH_GOOGLE_BASE_URL`
  - Redirect URI defaults: `<base>/auth/{provider}/callback` if unset

## Events (Audit)

- Resource action events: resources declare `events do event_log(Pactis.Events.Event) end`
- Business events: emit via `Pactis.Events.emit("Domain.Event", version: "v1", ...)`
- Include `actor`, `resource`, `tenant` when available; avoid sensitive payloads

## Multitenancy

- Current model: GitHub‑style workspace scoping (single DB). Per‑org access enforced by relationships and policies.
- Optional: Ash attribute‑strategy multitenancy can be introduced per‑resource if stronger boundaries are needed.
