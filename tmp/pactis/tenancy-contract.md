# Tenancy Contract

This document defines the tenancy model Pactis enforces across APIs.

## Model

- Single database (GitHub-style): Tenancy is enforced by org/workspace scoping, not per-tenant schemas.
- Organization → Workspace → Resources hierarchy.
- Access is granted via membership of a user to an organization.

## Enforcement

- Workspace-scoped APIs require a `workspace_id` path param.
- `RequireWorkspaceAccess` plug:
  - Loads workspace and checks membership in its organization.
  - Returns 401/403/404 on failure.
- Resources with cross-object links validate workspace alignment (e.g., SpecMessage.repository_context.repository_id belongs to the same workspace).

## Tenant Tag (forward-compatible)

- `SetAshTenant` plug sets `conn.private[:ash_tenant]` using Organization’s `ToTenant` protocol.
- No DB prefixes are used now, but this tag allows switching to `:context` multitenancy later without changing callers.

## Scopes

- APIs enforce OAuth2 scopes (e.g., SpecAPI uses `read:spec` / `write:spec`).
- Scopes are checked per endpoint; tokens are minted in Accounts domain.

## Guidelines

- Always include `workspace_id` in route params for workspace-scoped operations.
- Don’t trust client-provided repository/workspace links; validate on the server.
- Keep scope names stable and document them in the OpenAPI and docs.

