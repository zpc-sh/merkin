Object Storage (S3 or Cloudflare R2)

Overview
- Pactis uses ExAws to talk to any S3‑compatible provider.
- You can use AWS S3, MinIO, Cloudflare R2, or other compatible services.

Environment Variables
- Shared (all providers):

      AWS_ACCESS_KEY_ID=...
      AWS_SECRET_ACCESS_KEY=...
      AWS_S3_BUCKET=pactis-prod
      AWS_REGION=us-east-1   # or "auto" for R2

- Optional endpoint override (for R2/MinIO):

      AWS_S3_ENDPOINT=<acct>.r2.cloudflarestorage.com
      # or a custom domain that points to your R2 bucket

Cloudflare R2
- R2 is S3‑compatible. Steps:
  1) Create an R2 bucket and create an API token (access key + secret).
  2) Set env vars (above), with `AWS_S3_ENDPOINT=<acct>.r2.cloudflarestorage.com` and `AWS_REGION=auto`.
  3) (Optional) Use a custom domain mapped to your R2 bucket; set `AWS_S3_ENDPOINT` to that domain.

Development
- Enable dev S3 via:

      AWS_S3_ENABLED=true
      AWS_S3_ENDPOINT=s3.nocsi.org
      AWS_S3_BUCKET=pactis-dev
      AWS_ACCESS_KEY_ID=...
      AWS_SECRET_ACCESS_KEY=...

- If `AWS_S3_ENABLED` is not true, Pactis uses local disk at `priv/storage/dev`.

Runtime Behavior
- If `AWS_S3_ENDPOINT` is set at runtime, Pactis configures ExAws S3 to use that host.
- ExAws signs all requests with AWS Signature v4; R2 accepts these signatures.

