Error Tracking (Sentry) for Pactis

Why
- Capture unhandled exceptions and performance signals in production.
- Triage errors by release and environment.

Dependency
- Add `sentry` to `mix.exs` deps (runtime-only in prod is typical):

      {:sentry, "~> 10.4"}

Config (runtime)
- In `config/runtime.exs`, under `if config_env() == :prod do` block, add:

      if dsn = System.get_env("SENTRY_DSN") do
        config :sentry,
          dsn: dsn,
          environment_name: :prod,
          enable_source_code_context: false,
          included_environments: [:prod]
      end

Plug + Logger Integration
- In your endpoint or top-level supervision tree, you can enable Logger integration.
- For Phoenix, add a Plug or use the Logger backend as needed. Minimal setup works via Logger integration:

      # config/config.exs
      config :logger, backends: [:console, Sentry.LoggerBackend]

      config :sentry, 
        send_default_pii: false

Release Metadata (optional)
- Set `SENTRY_RELEASE` and `SENTRY_ENVIRONMENT` during deploy to enrich event grouping.

Secrets
- Set `SENTRY_DSN` in Fly secrets:

      flyctl secrets set SENTRY_DSN="https://***@***.ingest.sentry.io/***"

Notes
- Start with minimal config; tune sampling and performance later.
- If you prefer a different provider (e.g., Honeybadger, AppSignal), adapt the same pattern.

