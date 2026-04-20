Pactis Launch Checklist

Preflight
- Domain: DNS for `app.pactis.dev` → Fly app (CNAME or A record per Fly docs)
- Neon Postgres: connection string ready (`sslmode=require`)
- Redis: managed `REDIS_URL` (Upstash/Redis Cloud), TLS preferred (`rediss://`)
- Mailgun: `MAILGUN_API_KEY`, `MAILGUN_DOMAIN=pactis.dev`
- Sentry: `SENTRY_DSN` (optional but recommended)

Secrets (Fly)
- Set once:

      flyctl secrets set \
        SECRET_KEY_BASE=$(mix phx.gen.secret) \
        DATABASE_URL="postgres://USER:PASS@HOST:PORT/DB?sslmode=require" \
        REDIS_URL="rediss://:password@host:port/0" \
        MAILGUN_API_KEY="key-***" \
        MAILGUN_DOMAIN="pactis.dev" \
        PACTIS_BASE="https://app.pactis.dev" \
        SENTRY_DSN="https://***@***.ingest.sentry.io/***"

Optional (Object Storage)
- Cloudflare R2 or S3-compatible:

      flyctl secrets set \
        AWS_ACCESS_KEY_ID=... \
        AWS_SECRET_ACCESS_KEY=... \
        AWS_S3_BUCKET=pactis-prod \
        AWS_S3_ENDPOINT=<acct>.r2.cloudflarestorage.com \
        AWS_REGION=auto

Deploy
- One-time app create/region:

      flyctl apps create pactis
      flyctl regions set iad

- Deploy from CLI or push to `main` (GitHub Action):

      flyctl deploy --remote-only

Smoke
- Health: `GET /healthz` → 200 `ok`
- Ready: `GET /readyz` → 200 JSON `{db: ok, redis: ok}`
- JSON:API docs: `GET /api/v1/docs`

Scaling & TLS
- TLS is automatic once DNS is pointed to Fly.
- Optional HA: `flyctl scale count 2`

Monitoring
- Sentry enabled if `SENTRY_DSN` is set.
- Prometheus metrics: `/metrics` (guarded by BasicAuth if `METRICS_USER/PASS` set)

Rollback (if needed)
- Deploy previous image via `flyctl releases` and `flyctl deploy --image <image_ref>`

