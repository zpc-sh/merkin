Pactis Billing Overview

This project uses an asynchronous billing pipeline built on Oban. All billing operations are performed in background jobs to keep API requests fast and resilient. For the canonical interface specification, see [Pactis‑SMI: Settlement & Metering Interface](specifications/Pactis-SMI.md).

Workers (queue: `billing`):
- InvoiceGenerationJob: Generates invoices and triggers payment.
- SubscriptionRenewalJob: Handles renewals, trial endings, and cancellations.
- UsageAggregationJob: Aggregates usage and enforces quotas.
- PaymentProcessingJob: Processes payments with retries and dunning.

Integration entrypoints:
- `Pactis.Billing.track_usage_async(subscription_id, "api_call" | "storage_usage", quantity \\ 1, opts \\ [])`
- `Pactis.Billing.track_usage_batch_async(subscription_id, usage_events, opts \\ [])`
- `Pactis.Billing.generate_invoice_async(subscription_id, scheduled_at: dt)`
- `Pactis.Billing.schedule_subscription_renewal(subscription_id, "renew" | "end_trial", scheduled_at: dt)`

PubSub topics:
- `billing:payments` — payment success/failure
- `billing:quota_violations` — usage quota violations
- `billing:dunning` — dunning and collection notifications

Testing:
- Tests bypass Oban by default via `config :pactis, :use_oban, false`.
- You can call `perform/1` on workers directly for integration tests.

Configuration:
- `config :pactis, Oban, repo: Pactis.Repo, queues: [spec: 10, billing: 5], plugins: [Oban.Plugins.Pruner, Oban.Plugins.Cron]]`

Dunning + Notifications:
- Nightly dunning runs via `Pactis.Billing.DunningJob` (`@daily` cron).
- Batches limited by `config :pactis, :billing_dunning, max_invoices_per_run: 200, batch_backoff_minutes: 10`.
- Emails gated by `config :pactis, :billing_emails_enabled, true|false` (default false).
- Optional webhooks via `config :pactis, :billing_webhook_url, "https://example.com/hooks"`.

Notes:
- Subscription resource exposes explicit actions used by workers: `cancel_immediately`, `cancel_at_period_end`, `reactivate`, `due_for_renewal/1`, `trials_ending/1`.
- Invoice resource includes `mark_paid/3` and `mark_failed/2` for payment outcomes.
