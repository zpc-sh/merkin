Fly.io Deployment for Pactis

Prerequisites
- Fly account + `flyctl` installed: https://fly.io/docs/hands-on/install-flyctl/
- DNS for `pactis.dev` (or subdomain) if using a custom hostname.
- Managed Postgres (Neon) connection string.
- Managed Redis URL (e.g., Upstash/Redis Cloud).
- Mailgun domain + API key for pactis.dev.

App Setup
1) Create app (or use existing) and set region
   flyctl apps create pactis
   flyctl regions set iad

2) Configure `fly.toml`
   - `app = "pactis"`
   - `primary_region = "iad"` (or your nearest region)
   - `PHX_HOST = "app.pactis.dev"` (or your hostname)

Secrets
Set production secrets once (values are examples/placeholders):

  flyctl secrets set \
    SECRET_KEY_BASE=$(mix phx.gen.secret) \
    DATABASE_URL="postgres://USER:PASSWORD@HOST:PORT/DB?sslmode=require" \
    REDIS_URL="redis://:password@host:port/0" \
    MAILGUN_API_KEY="key-***" \
    MAILGUN_DOMAIN="pactis.dev" \
    PACTIS_BASE="https://app.pactis.dev" \
    SENTRY_DSN="https://***@***.ingest.sentry.io/***"

Notes
- Neon: copy the full Postgres connection URL; include `sslmode=require` if needed.
- Redis: use your provider’s URL. Pactis reads `REDIS_URL`.
- Mailgun: `MAILGUN_API_KEY` + `MAILGUN_DOMAIN` are used by outbound mail.
- Sentry: optional; see Error Tracking doc.

DB Migrations
- `fly.toml` defines a `release_command` that runs before starting each deploy:
  /app/bin/pactis eval "Pactis.Release.migrate()"

Deploy
  flyctl deploy --remote-only

HTTP + TLS
- Fly provides TLS certs automatically for your hostname when DNS is pointed to Fly.
- Update DNS: CNAME `app.pactis.dev` → your Fly app’s hostname.

Zero Downtime Tips
- Scale to 2 machines if desired: `flyctl scale count 2`
- Consider `min_machines_running = 1` for lower cost; increase for HA.

CI Integration (GitHub Actions)
- Add `FLY_API_TOKEN` (Org/User deploy token) to repo secrets.
- `.github/workflows/fly-deploy.yml` deploys on pushes to `main`.



Redis Providers
- Upstash Redis (recommended): low‑ops, TLS (`rediss://`), integrates with Fly and Cloudflare.
  - Create DB in Upstash; set `REDIS_URL` to the provided `rediss://...` URL.
  - Or via Fly: `fly redis create` (provisions an Upstash instance) and export the URL.
- Redis Cloud (Redis Labs): managed Redis with TLS; set `REDIS_URL` accordingly.
- Alternatives: Aiven/Render/Railway all provide compatible Redis.
- Self‑hosted: You can run Valkey/KeyDB on Fly, but managed is recommended for launch.

Cloudflare R2 (S3‑compatible)
- Works as S3 for Pactis via ExAws; set these env vars:

      AWS_ACCESS_KEY_ID=...           # R2 access key
      AWS_SECRET_ACCESS_KEY=...       # R2 secret
      AWS_S3_ENDPOINT=<acct>.r2.cloudflarestorage.com  # or your custom domain
      AWS_S3_BUCKET=pactis-prod       # your bucket name
      AWS_REGION=auto                 # R2 accepts "auto"

- Pactis config detects `AWS_S3_ENDPOINT` at runtime and points ExAws to it.
- If using a custom domain for R2, set `AWS_S3_ENDPOINT` to that hostname.


Scaling & Performance Tips
- HTTP concurrency: `fly.toml` uses connection mode with soft/hard limits (800/1000). Adjust as needed.
- Minimum machines: keep at least 1 running (`min_machines_running = 1`); consider `scale count 2` for HA.
- CPU/RAM: choose a VM size that matches DB pool + workload; start small and scale up.
- Redis latency: choose a region close to your app region for Upstash/Redis Cloud.
