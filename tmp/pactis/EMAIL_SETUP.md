Email Setup (Swoosh)

Overview
- Dev: uses `Swoosh.Adapters.Local` and mailbox preview at `/dev/mailbox`.
- Test: uses `Swoosh.Adapters.Test` (assert deliveries in tests).
- Prod: configured for Mailgun via `Swoosh.Adapters.Mailgun` (Req client).

Prod configuration (env vars)
- `MAILGUN_API_KEY`: your Mailgun API key
- `MAILGUN_DOMAIN`: sending domain (e.g., mg.example.com)
- `MAILGUN_BASE_URL` (optional): set for EU region or custom base URL
- `MAIL_FROM`: sender email (e.g., noreply@example.com)
- `MAIL_FROM_NAME`: sender name (e.g., Pactis)
- `SUPPORT_EMAIL`: support contact for templates

Dev notes
- Enable dev routes to access `/dev/mailbox` (already enabled in `config/dev.exs`).
- No emails are sent externally; messages render in the mailbox preview.

Senders
- Account confirmation is handled by `Pactis.Accounts.ConfirmationSender` (used by AshAuthentication confirm add-on).
- Additional flows (magic link, update email) can be wired similarly with Swoosh emails and added assertions under `test/`.

