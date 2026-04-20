# Pactis‑SMI: Settlement & Metering Interface

- Status: Draft
- Last Updated: 2025-09-20
- Owners: Pactis Core
- Related: docs/BILLING_OVERVIEW.md, config/config.exs

## Summary
Pactis‑SMI specifies a standardized interface for inter‑service settlement that covers usage metering, rating, invoicing, and payment/collections. This document defines concepts, operations, events, and conformance for SMI. An implementation profile (Oban) describes how Pactis realizes SMI with asynchronous workers without blocking request paths.

## Motivation
- Ensure scalability and reliability under burst traffic and usage spikes.
- Prevent controller actions from performing synchronous billing work.
- Centralize retries, backoff, and dead-letter handling.
- Provide consistent observability and eventing for product and finance ops.

## Non‑Goals
- Implementing provider‑specific payment gateways.
- Designing subscription catalog/pricing models.
- Building reporting/BI pipelines beyond emitted events and invoices.

## Design Overview
SMI defines the canonical operations and events for settlement. In Pactis, these are implemented asynchronously. Controllers and call sites enqueue jobs through `Pactis.Billing.*_async` helpers. Workers are idempotent, retry with exponential backoff, publish domain events, and update persistent state atomically.

Implementation Profile — Oban

All SMI operations are modeled as Oban jobs on the `billing` queue.

## Vocabulary & JSON‑LD Shapes

Base context (reference):

```json
{
  "@context": {
    "pactis": "https://pactis.dev/vocab#",
    "schema": "https://schema.org/",
    "sosa": "http://www.w3.org/ns/sosa/",
    "prov": "http://www.w3.org/ns/prov#",
    "xsd": "http://www.w3.org/2001/XMLSchema#"
  }
}
```

### UsageEvent
- Type: `pactis:UsageEvent` (aligns with `sosa:Observation` semantics)
- Required: `pactis:subscriptionId`, `pactis:eventType`, `pactis:quantity`, `pactis:occurredAt`, `pactis:idempotencyKey`
- Optional: `pactis:unit`, `schema:description`, `prov:wasGeneratedBy`

Example:

```json
{
  "@context": {"pactis": "https://pactis.dev/vocab#", "schema": "https://schema.org/"},
  "@id": "urn:pactis:usage:ue_01HZY0GMG4Z6",
  "@type": "pactis:UsageEvent",
  "pactis:subscriptionId": "sub_123",
  "pactis:eventType": "api_call",
  "pactis:quantity": 1,
  "pactis:unit": "count",
  "pactis:occurredAt": "2025-09-20T12:34:56Z",
  "pactis:idempotencyKey": "ue_01HZY0GMG4Z6",
  "schema:description": "One API call"
}
```

### RatingRule
- Type: `pactis:RatingRule`
- Fields: `pactis:appliesToEventType`, `pactis:currency`, `pactis:unit`, `pactis:tiers`
- `pactis:tiers`: ordered list of `{ upTo?, unitPrice }`

Example:

```json
{
  "@context": {"pactis": "https://pactis.dev/vocab#"},
  "@id": "urn:pactis:rule:api_call_tiered",
  "@type": "pactis:RatingRule",
  "pactis:appliesToEventType": "api_call",
  "pactis:currency": "USD",
  "pactis:unit": "count",
  "pactis:tiers": [
    {"upTo": 1000, "unitPrice": "0.10"},
    {"upTo": 5000, "unitPrice": "0.08"},
    {"unitPrice": "0.05"}
  ]
}
```

### LineItem
- Type: `pactis:LineItem`
- Fields: `pactis:description`, `pactis:eventType?`, `pactis:quantity`, `pactis:unit?`, `pactis:unitPrice`, `pactis:amount`, `pactis:ratingRule?`

### Invoice
- Type: `pactis:Invoice`
- Required: `pactis:subscriptionId`, `pactis:periodStart`, `pactis:periodEnd`, `pactis:status`, `pactis:currency`, `pactis:total`
- Optional: `pactis:subtotal`, `pactis:tax`, `pactis:discount`, `pactis:lineItem[]`, `schema:identifier`

Example:

```json
{
  "@context": {"pactis": "https://pactis.dev/vocab#", "schema": "https://schema.org/"},
  "@id": "urn:pactis:invoice:inv_1001",
  "@type": "pactis:Invoice",
  "pactis:subscriptionId": "sub_123",
  "pactis:periodStart": "2025-09-01T00:00:00Z",
  "pactis:periodEnd": "2025-10-01T00:00:00Z",
  "pactis:status": "open",
  "pactis:currency": "USD",
  "pactis:subtotal": "120.00",
  "pactis:tax": "10.80",
  "pactis:total": "130.80",
  "schema:identifier": "INV-1001",
  "pactis:lineItem": [
    {
      "@type": "pactis:LineItem",
      "pactis:description": "API calls",
      "pactis:eventType": "api_call",
      "pactis:quantity": 1200,
      "pactis:unit": "count",
      "pactis:unitPrice": "0.10",
      "pactis:amount": "120.00",
      "pactis:ratingRule": {"@id": "urn:pactis:rule:api_call_tiered"}
    }
  ]
}
```

### SettlementAttempt
- Type: `pactis:SettlementAttempt`
- Fields: `pactis:attemptNumber`, `pactis:status` (e.g., `succeeded|failed|pending`), `pactis:gateway`, `pactis:transactionId?`, `pactis:createdAt`

Example:

```json
{
  "@context": {"pactis": "https://pactis.dev/vocab#"},
  "@type": "pactis:SettlementAttempt",
  "pactis:attemptNumber": 1,
  "pactis:status": "failed",
  "pactis:gateway": "stripe",
  "pactis:transactionId": "pi_abc123",
  "pactis:createdAt": "2025-10-01T01:00:00Z"
}
```

Conformance notes:
- `pactis:UsageEvent` MUST carry a stable `pactis:idempotencyKey`.
- `pactis:Invoice` SHOULD be immutable after settlement; updates produce a replacement with provenance links.
- Monetary strings SHOULD be `string` decimal to avoid float errors; currency as ISO 4217 code.

Oban configuration:

```elixir
config :pactis, Oban,
  repo: Pactis.Repo,
  queues: [spec: 10, billing: 5],
  plugins: [Oban.Plugins.Pruner, Oban.Plugins.Cron]
```

## Operations (Implementation Profile: Oban Workers)

### 1) InvoiceGeneration — `lib/pactis/billing/invoice_generation_job.ex`
- Queue: `billing`
- Purpose: Generate invoices for subscription billing periods.
- Responsibilities:
  - Calculate subscription charges and usage overages.
  - Create invoice records and line items.
  - Trigger payment processing.
- Args (minimum): `%{"subscription_id" => binary(), optional => %{"period_end" => DateTime}}`.
- Idempotency: Upsert invoice per subscription + period window; guard with unique key.
- Concurrency: One active job per subscription period (use Oban unique / lock semantics).
- Retries: Exponential backoff; stop on permanent calculation errors with DLQ entry.
- Emits: `billing:payments` (after payment trigger), telemetry for timing and result.

### 2) SubscriptionRenewal — `lib/pactis/billing/subscription_renewal_job.ex`
- Queue: `billing`
- Purpose: Handle subscription lifecycle events.
- Responsibilities:
  - Process monthly/yearly renewals and trial endings.
  - Manage cancellations/reactivations and reset usage quotas.
- Args: `%{"subscription_id" => binary(), "action" => "renew" | "cancel" | "reactivate"}`.
- Idempotency: Reapply state transitions safely; no duplicate renewals per period.
- Scheduling: Typically scheduled at `subscription.current_period_end`.
- Retries: Backoff on transient DB or state update failures.
- Emits: Telemetry for transition; optionally quota reset events.

### 3) UsageAggregation — `lib/pactis/billing/usage_aggregation_job.ex`
- Queue: `billing`
- Purpose: Track and aggregate usage events.
- Responsibilities:
  - Batch process usage events for performance.
  - Update subscription usage quotas and detect violations.
  - Send usage notifications on thresholds.
- Args: either a single event `%{"subscription_id" => binary(), "event_type" => string(), "quantity" => number()}` or a batch `%{"subscription_id" => binary(), "events" => [event]}`.
- Idempotency: Deduplicate by event idempotency key when available; otherwise coalesce by timestamp bucket.
- Retries: Backoff on storage or contention; DLQ events with skipped duplicates are acceptable.
- Emits: `billing:quota_violations` when thresholds exceed; telemetry for batch sizes and latency.

### 4) PaymentProcessing — `lib/pactis/billing/payment_processing_job.ex`
- Queue: `billing`
- Purpose: Process payments and handle failures.
- Responsibilities:
  - Charge payment methods and persist attempts.
  - Handle payment retries with exponential backoff.
  - Manage dunning and collection flows; update payment status.
- Args: `%{"invoice_id" => binary(), optional => %{"attempt" => integer()}}`.
- Idempotency: Ensure a single settled payment per invoice; safe to retry.
- Retries: Exponential backoff with capped attempts; DLQ after terminal failures.
- Emits: `billing:payments` events for success/failure; dunning lifecycle events; telemetry.
- Security: Never log PAN or secrets; only opaque tokens and last4.

## Public API Surface
Helpers enqueue jobs and enforce async usage:

- `Pactis.Billing.generate_invoice_async/2`
- `Pactis.Billing.schedule_subscription_renewal/3`
- `Pactis.Billing.track_usage_async/2` and `.../4` for enriched events
- `Pactis.Billing.track_usage_batch_async/3`
- `Pactis.Billing.process_payment_async/2`

These functions return either `{:ok, %Oban.Job{}}` or `{:error, reason}` for enqueue failures.

## Integration Guidelines

### Controllers and Services
- Gate requests with `Pactis.Billing.can_make_request?(org_id)`.
- Enqueue usage tracking asynchronously, never inline calculations.

Example (good):

```elixir
def create(conn, params) do
  if Pactis.Billing.can_make_request?(org_id) do
    # Domain work
    Pactis.Billing.track_usage_async(subscription_id, "api_call")
    send_resp(conn, 202, "accepted")
  else
    send_resp(conn, 429, "quota exceeded")
  end
end
```

### High‑Volume Usage
Batch events for efficiency:

```elixir
usage_events = [
  %{"event_type" => "api_call", "quantity" => 1},
  %{"event_type" => "storage_usage", "quantity" => 0.5}
]
Pactis.Billing.track_usage_batch_async(subscription_id, usage_events)
```

### Scheduled Operations
Use `scheduled_at` for period‑end actions:

```elixir
Pactis.Billing.generate_invoice_async(subscription_id, scheduled_at: subscription.current_period_end)
Pactis.Billing.schedule_subscription_renewal(subscription_id, "renew", scheduled_at: subscription.current_period_end)
```

## Events & Observability
- PubSub topics:
  - `billing:payments` — Payment success/failure
  - `billing:quota_violations` — Usage quota thresholds exceeded
  - `billing:dunning` — Collection lifecycle events
- Telemetry: emit start/stop, durations, result tags per worker; meter queue latency and job age.
- Logging: structured logs with job id, subscription id, invoice id; avoid PII.

## Conformance: Idempotency, Retries & DLQ
- Workers implement exponential backoff and bounded retries.
- Permanent failures are logged with context and moved to DLQ (via Oban’s discard/error handling pattern).
- Alerting hooks can subscribe to DLQ telemetry to page ops.

## Testing
- In `test` env, workers are bypassed with `config :pactis, :use_oban, false`.
- Execute workers directly for integration tests:

```elixir
%Oban.Job{args: %{"subscription_id" => sub_id}}
|> Pactis.Billing.InvoiceGenerationJob.perform()
```

- For enqueue tests, assert on returned `{:ok, %Oban.Job{}}` without requiring Oban to run.

## Migration Guidelines
1) Replace synchronous calls with async equivalents.  
2) Add error handling around enqueue failures; fall back to compensation where needed.  
3) Update tests to account for async behavior and direct job execution.  
4) Monitor `billing` queue metrics for performance and failures post‑deploy.

## Security & Compliance
- Treat all payment details as sensitive; store only tokens, never raw PAN.
- Do not log PII or payment secrets; scrub structured logs.
- Constrain job args to non‑sensitive identifiers.
- Ensure least‑privilege access for workers touching payment providers.

## Alternatives Considered
- Synchronous billing in request path — rejected due to latency and reliability risk.
- Custom queue library — rejected; Oban provides robust, battle‑tested primitives and telemetry.

## Open Questions
- Should dunning strategies be pluggable per plan?  
- Do we expose configurable quota thresholds via admin UI?  
- SLA targets for invoice generation and payment settlement latency?
