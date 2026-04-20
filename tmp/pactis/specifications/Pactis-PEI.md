# Pactis-PEI: Pactis Event Interface

- Status: Implemented
- Last Updated: 2025-09-26
- Owners: Pactis Core
- Related: Pactis-POI.md, Pactis-PSI.md, Pactis-SMI.md
- Implementation: `lib/pactis/events/`
- Notice: Pactis™ is an open specification by Pactis and is not affiliated with any other entity using similar names. ™ indicates an unregistered trademark claim.

## Summary

Unified semantic event model with multiple sinks (console, DB, telemetry, bridges). Events are JSON‑LD, correlation-friendly, and tenant-aware.

## Architecture

```text
Event → [Console, DB, Telemetry, Bridges]
```

Event shape (illustrative):

```json
{
  "@context": {"pactis": "https://pactis.dev/vocab#", "schema": "https://schema.org/"},
  "@type": "pactis:Event",
  "pactis:correlationId": "uuid",
  "pactis:actor": {"@id": "pactis:users/123"},
  "pactis:tenant": {"@id": "pactis:tenants/abc"},
  "schema:description": "Spec accepted",
  "pactis:payload": {"requestId": "spec-123", "status": "accepted"}
}
```

## Sinks

- Console: development visibility and structured logs.
- Database: durable audit trail and analytics.
- Telemetry: counters/histograms with low-cardinality labels.
- Bridges: forward to external systems (webhooks, queues).

## Security Considerations

- Redact secrets/PII; enforce tenant isolation; apply rate limits.
- Sign or authenticate event channels as needed; include `trace_id` for diagnostics.

## Conformance

- Emit JSON‑LD (`application/ld+json`) for event payloads.
- Include `correlationId`, `actor`, and `tenant` when available.
- Provide sink configuration and backpressure handling.

## Authoring Guidance

See `docs/events.md` for event naming, versioning, correlation/causation, and sensitivity guidelines used across Pactis implementations.
