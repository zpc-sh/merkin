# Pactis-POI: Pactis Observability Interface

- Status: Implemented
- Last Updated: 2025-09-26
- Owners: Pactis Core
- Related: Pactis-PEI.md, Pactis-PSI.md, Pactis-PGI.md
- Notice: Pactis™ is an open specification by Pactis and is not affiliated with any other entity using similar names. ™ indicates an unregistered trademark claim.

## Summary

Observability for semantic operations and platform behavior via Elixir Telemetry and semantic events. POI defines metrics, events, and integration patterns for application, infrastructure, and system layers.

## Abstract

POI specifies telemetry categories, event shapes, and emission rules to provide actionable visibility across Pactis services. Implementations standardize metric names, tags, and JSON‑LD event payloads for downstream analytics and alerting.

## Telemetry Architecture

- Application metrics: conversation lifecycle, Git operations, ResourceEncoder performance, storage I/O.
- Infrastructure metrics: HTTP timings, DB queries, WebSocket metrics, job processing.
- System metrics: memory/CPU, network I/O, disk usage.

## Semantic Events

Base context:
```json
{
  "@context": {
    "pactis": "https://pactis.dev/vocab#",
    "schema": "https://schema.org/",
    "prov": "http://www.w3.org/ns/prov#"
  }
}
```

Event shape (illustrative):
```json
{
  "@context": {"pactis": "https://pactis.dev/vocab#"},
  "@type": "pactis:Event",
  "pactis:correlationId": "uuid",
  "pactis:actor": {"@id": "pactis:users/123"},
  "pactis:tenant": {"@id": "pactis:tenants/abc"},
  "pactis:category": "observability",
  "schema:description": "Cache hit",
  "pactis:payload": {"cache": "repo_index", "hit": true}
}
```

## Integration

- Emit Telemetry and Pactis events in parallel for critical flows.
- Normalize metric names and tags; prefer low-cardinality labels.
- Provide dashboards for golden paths (e.g., spec merge, artifact generation).

## Security Considerations

- Redact secrets and PII in event payloads.
- Respect tenant boundaries in logs/metrics and cross-tenant aggregation.
- Rate limit and sample high-volume event sources.

## Conformance

- Implement baseline metrics for HTTP, DB, jobs, and conversations.
- Emit JSON‑LD events for key lifecycle transitions using `application/ld+json` where applicable.
- Provide alerting thresholds for SLOs on golden paths.

