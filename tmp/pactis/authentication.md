Authentication Overview

- Web (browser):
  - Router uses AshAuthentication routes/macros under `/auth`.
  - Browser pipeline includes `plug :load_from_session`.
  - LiveViews use on_mount hooks in `PactisWeb.LiveUserAuth`.

- API (bearer):
  - Pipelines include:
    - `plug :load_from_bearer`
    - `plug :set_actor, :user`
    - `plug PactisWeb.Plugs.AttachAuthContext` (exposes `assigns.api_token` and `assigns.scopes`)
    - `plug PactisWeb.Plugs.RequireApiAuth` where authentication is required
    - `plug PactisWeb.Plugs.RequireScope, scopes: [..]` where specific scopes are needed
  - Rate limiting identifies clients using `assigns.api_token` or `assigns.current_user`.

- Long-lived API tokens:
  - Implemented by `Pactis.Accounts.ApiKey` (AshAuthentication API key strategy).
  - `Pactis.Accounts.ApiToken` is a compatibility module delegating to `ApiKey`.
  - Tokens start with `cdfm_` and support scopes, revocation, usage tracking, and expiry.

- Plugs:
  - `PactisWeb.Plugs.AttachAuthContext`: Detects API token sign-in and assigns `:api_token` and `:scopes`.
  - `PactisWeb.Plugs.RequireApiAuth`: Ensures `:current_user` is present (401 otherwise).
  - `PactisWeb.Plugs.RequireScope`: Enforces scope lists against `assigns.scopes`.
  - `PactisWeb.Plugs.GitAuth`: Git HTTP auth (basic + token) remains separate.

