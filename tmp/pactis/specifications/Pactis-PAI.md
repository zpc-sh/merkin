# Pactis-PAI: Pactis Authentication Interface

- Status: Implemented
- Last Updated: 2025-09-26
- Owners: Pactis Core
- Related: Pactis-PSI.md, Pactis-PGI.md, Pactis-KEI.md
- Notice: Pactis™ is an open specification by Pactis and is not affiliated with any other entity using similar names. ™ indicates an unregistered trademark claim.

## Summary

Multi-strategy authentication for users and services: password, OAuth2 (Google, GitHub), and API tokens. Provides token management, email confirmation workflows, workspace scoping, and semantic event emission across all auth flows.

## Abstract

PAI defines a unified authentication surface with enterprise-grade features while remaining compatible with Pactis’s semantic model. Implementations integrate with AshAuthentication and emit JSON‑LD events for observability, audit, and automation.

## Authentication Strategies

- Password: Bcrypt hashing, sign-in tokens, password reset with email tokens, lockout protections.
- OAuth2: Standard flows (Google, GitHub); registration and sign-in actions; scoped claims.
- API Tokens: Multiple tokens per user, scoped permissions, rotation/expiration, hashed at rest.
  - Format: `cdfm_…` (secret-scannable prefix)
  - Store only hashes and prefixes; plaintext is returned once at creation

## Token Management

- Signed tokens (JWT) with persistent storage for audit and revocation.
- Configurable lifetimes and required token presence for authentication.
- Global sign-out and token invalidation on sensitive changes (e.g., password update).

## Email Confirmation

- New user verification and re-confirmation on email change.
- Interaction-required flows with confirmation links and custom templates.
- Auto-confirm exceptions for defined admin actions.

## Multi-Tenant Security

- Workspace-scoped identities and permissions.
- Tenant data isolation and cross-tenant access prevention.
- Repository and project-level access checks where applicable.

## Semantic Integration

- All auth flows emit JSON‑LD events (login, logout, password reset, email confirm, OAuth2 grants, API token usage).
- Users modeled as semantic resources with JSON‑LD serialization and graph relationships.

## API Endpoints (Illustrative)

```
POST /auth/user/password/sign_in
POST /auth/user/password/register
POST /auth/user/password/request_password_reset
POST /auth/user/password/reset
POST /auth/user/oauth2/:provider/sign_in
POST /auth/user/oauth2/:provider/register
GET    /api/v1/tokens                # list
POST   /api/v1/tokens                # create (returns plaintext once)
GET    /api/v1/tokens/:id            # show
DELETE /api/v1/tokens/:id            # revoke
POST /auth/user/logout_everywhere
```

## Security Considerations

- Enforce rate limits and backoff on auth endpoints.
- Use secure defaults (Pepper, strong hash params, TLS everywhere).
- Store only API token hashes; never store plaintext tokens.
- Emit audit events for all sensitive actions.

## Conformance

- Implement at least one interactive strategy (password or OAuth2) and one programmatic strategy (API token).
- Provide tenant-aware enforcement and event emission.
- Supply OpenAPI/JSON‑LD descriptions for endpoints using `application/ld+json` where JSON‑LD payloads are returned.

## Appendix: Security & Rate Limits

### Scopes

Pactis uses human-readable string scopes for API tokens:

- Component operations: `read:components`, `write:components`
- Blueprints: `read:blueprints`, `write:blueprints`
- Users: `read:user`, `write:user`
- Admin: `admin` (implies all scopes)

Scope checks enforce least privilege and appear in responses (e.g., headers or JSON metadata) when relevant.

### OAuth Environment Variables

Implementations SHOULD configure OAuth via environment variables or equivalent secrets management:

- GitHub: `OAUTH_GITHUB_CLIENT_ID`, `OAUTH_GITHUB_CLIENT_SECRET`, `OAUTH_GITHUB_REDIRECT_URI`, `OAUTH_GITHUB_BASE_URL`
- Google: `OAUTH_GOOGLE_CLIENT_ID`, `OAUTH_GOOGLE_CLIENT_SECRET`, `OAUTH_GOOGLE_REDIRECT_URI`, `OAUTH_GOOGLE_BASE_URL`

Redirect URIs default to `<base>/auth/{provider}/callback` when not configured.

### Rate Limits

Clients SHOULD respect rate limit headers:

```
X-RateLimit-Limit: 120
X-RateLimit-Remaining: 42
X-RateLimit-Reset: 1732579200
```

On `429 Too Many Requests`, clients SHOULD back off until `Retry-After` elapses.
