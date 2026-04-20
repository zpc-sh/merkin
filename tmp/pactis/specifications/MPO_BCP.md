<!-- This BCP now aligns with Pactis (plural of pactum). Formerly described as Managed Pactum Operations and Managed Truth Negotiation. -->

# Managed Pactis™ Operations (MPO) — Best Current Practice

Status: draft
Notice: Pactis™ is an open specification by Pactis and is not affiliated with any other entity using similar names. ™ indicates an unregistered trademark claim.
Aliases: aligns to earlier “Managed Truth Negotiation (MTN)” and “Managed Pactum Operations (MPO)” naming.

Recommended naming
- Operations (BCP): Managed Pactis Operations (MPO)
  - Rationale: MPO describes how teams should operate Pactis in practice: queues, retries, observability, storage governance, migrations.

## Operational Architecture
- Asynchronous worker pipeline; idempotent jobs; recovery from partial failure.
- Separation of compute, storage (GraphStore/CAS), and orchestration.

## Retry/Backoff/Dead Letter
- Exponential backoff with jitter.
- Criteria for retry vs permanent failure.
- Dead letter queue (DLQ) payload: doc snapshot + validation report + provenance chain.

## Pub/Sub Events
- Event names/payloads; consumers; SLOs.
- Examples: validation outcomes, artifact published, signature verification, quota violations.

## Observability
- Structured logs, metrics, traces/spans.
- Suggested dashboards and SLOs (latency, success rate, determinism drift).

## Storage Governance
- GraphStore compaction; CAS lifecycle; pointer immutability policy.
- Signature verification policy; key rotation.

## Migration & Deprecation
- Context lifecycle; schema changes; deprecations surfaced in CI and publish logs.
- Rollout plans and compatibility windows.

## Security Practice
- Key management for signing; verification enforcement; audit logs.
- Supply‑chain controls and artifact provenance attestation.

## Incident Playbooks
- Drift detection (self‑healing) and rebuild from authoritative truth.
- DLQ triage and deterministic replay.
