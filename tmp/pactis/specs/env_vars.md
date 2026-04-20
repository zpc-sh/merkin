Pactis Environment Variables

Core
- `SECRET_KEY_BASE`: Phoenix secret (generate with `mix phx.gen.secret`).
- `PHX_HOST`: public hostname (prod: `app.pactis.dev`).
- `PORT`: listen port (Fly sets to 8080/`PORT`; we remap to 4000 internally).

Database
- `DATABASE_URL`: Postgres connection string (Neon: include `sslmode=require`).
- `POOL_SIZE`: DB pool size (default 10).

Redis
- `REDIS_URL`: `rediss://:password@host:port/0` (preferred; Upstash/Redis Cloud).
- (fallbacks in dev) `REDIS_HOST`, `REDIS_PORT`, `REDIS_DATABASE`.

Mail
- `MAILGUN_API_KEY`, `MAILGUN_DOMAIN`: Mailgun credentials.
- `MAILGUN_BASE_URL`: optional (EU region/custom base).

S3 / Object Storage (optional)
- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`.
- `AWS_S3_BUCKET`: bucket name.
- `AWS_REGION`: region (`us-east-1`, or `auto` for R2).
- `AWS_S3_ENDPOINT`: S3-compatible host (e.g., `<acct>.r2.cloudflarestorage.com`, `s3.nocsi.org`).
- `AWS_S3_SCHEME`: `http` or `https` (default https; dev proxies may need http).
- `AWS_S3_PORT`: optional port (dev MinIO behind proxies).
- `AWS_S3_PATH_STYLE`: `true` to force path-style addressing in proxies.
- Dev toggle: `AWS_S3_ENABLED=true` to use S3 in dev; otherwise local disk.

Telemetry / Metrics
- `SENTRY_DSN`: Sentry DSN to send errors and logs.
- `METRICS_USER`, `METRICS_PASS`: BasicAuth for `/metrics`.

Misc
- `PACTIS_BASE`: external base URL (e.g., `https://app.pactis.dev`).
- `DNS_CLUSTER_QUERY`: for clustering in distributed deployments.

Secrets (AI Providers)
- Prefer the Docker-style `*_FILE` convention to avoid exporting raw keys:
  - `OPENAI_API_KEY_FILE`, `ANTHROPIC_API_KEY_FILE`, `XAI_API_KEY_FILE`, `GEMINI_API_KEY_FILE`, `MISTRAL_API_KEY_FILE`, `AI21_API_KEY_FILE` → paths to files containing the API key.
- Providers resolve in this order: `*_API_KEY_FILE` → `*_API_KEY` → PROCSI (if configured) → error.
- For agent workflows, Pactis recommends an ephemeral `SECRETSDIR` containing files like `openai_api_key`, `anthropic_api_key`, etc., and setting the corresponding `*_API_KEY_FILE` to those paths.

Provider-specific (compatibility)
- OpenAI:
  - `OPENAI_BASE_URL`: override base API URL (e.g., for a localhost proxy)
  - `OPENAI_ORG_ID`, `OPENAI_PROJECT`: optional routing/account hints
  - CLI and agents should honor `OPENAI_API_KEY_FILE`/`OPENAI_API_KEY` with `OPENAI_BASE_URL` when present
