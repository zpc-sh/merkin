# Codex Revitalization Roadmap — Completion to Launch

Status: Active Planning  
Last Updated: 2026-03-26  
Owners: Pactis Core, AI Council, Platform Ops

## Mission
Take Pactis from current recovered state to an operational launch by executing against the contractual architecture with explicit gates, measurable outcomes, and reversible rollout.

## Launch North Star
By launch date, Pactis must demonstrate:
1. **Contract coherence**: specs, JSON-LD artifacts, and runtime behavior are aligned.
2. **Conversation-native workflow**: spec/conversation path is production-usable.
3. **Repo + artifact path**: git/content/VFS flow works end-to-end with auditability.
4. **Operational readiness**: health, readiness, observability, and incident controls in place.
5. **Safe rollout posture**: staged release with rollback rehearsal completed.

---

## Phase 0 — Recovery Baseline (Week 0–1)

### Objectives
- Re-establish trustworthy development baseline and remove unknown execution surfaces.
- Capture architectural state in one contract map.

### Deliverables
- Repository sanitization artifacts and repeatable sanitization script.
- Codex Contractual Architecture map (single constitutional source).
- Migration provenance review and reset strategy.

### Exit Criteria
- Security docs accepted by AI Council.
- Core team agrees on canonical contract sources and drift handling rule.

---

## Phase 1 — Contract Reconciliation (Week 1–3)

### Objectives
- Align specs to runtime truth and mark maturity of every interface.

### Workstreams
1. **Contract Matrix**
   - Build `contract_matrix.jsonld` from spec inventory.
   - Label each interface: `implemented | partial | draft | deprecated`.
2. **Drift Resolution**
   - For each mismatch: create explicit decision record (accept/update/deprecate).
3. **API Surface Lock**
   - Freeze v1 surface for PSI + PGI/PCI/VFS core path.

### Exit Criteria
- No unresolved P0 contract drift.
- Publicly consumable v1 contract matrix generated.

---

## Phase 2 — Core Product Vertical (Week 3–7)

### Objectives
Ship one complete vertical proving the model:
**Conversation request → review/decision → artifact/result publication → retrieval/export**.

### Workstreams
1. **PSI First**
   - Hardening for request/message/status/export pathways.
   - Idempotency and replay validation.
2. **Repository Bridge**
   - PGI/PCI/VFS integration for content and context-aware retrieval.
3. **Provenance Everywhere**
   - Link decisions/artifacts/events with stable IDs and signatures where applicable.

### Exit Criteria
- End-to-end demo script runs reliably in staging.
- Golden-path integration tests pass for PSI + repo/artifact flow.

---

## Phase 3 — Reliability, Security, and Cost Guardrails (Week 6–10)

### Objectives
Make launch-safe under load and failure.

### Workstreams
1. **Operational Hardening**
   - SLO instrumentation, dashboards, alerts, and runbooks.
   - Queue/backoff/dead-letter verification for async jobs.
2. **Security Hardening**
   - Secrets posture validation (SSHS), token/scope verification, access-path audit.
   - Binary/provenance guardrails for repo intake.
3. **Performance Validation**
   - P95 targets for core endpoints and artifact retrieval.
   - Capacity and soak testing for launch profile.

### Exit Criteria
- SLOs met in staging for sustained soak window.
- Security checklist passed; rollback drill completed.

---

## Phase 4 — Launch Execution (Week 10–12)

### Objectives
Deliver controlled external launch with reversible rollout.

### Workstreams
1. **Soft Launch**
   - Limited tenant cohort + launch war room.
   - Daily contract drift review and issue triage.
2. **General Availability Gate**
   - Feature flags promoted to default.
   - Documentation and onboarding finalized.
3. **Post-Launch Stabilization (2 weeks)**
   - Incident review cadence and rapid patch lane.

### Exit Criteria
- GA checklist complete.
- First external users complete full core workflow successfully.

---

## Cross-Phase Management Tracks

### A) Governance + Decisioning
- All architecture-impacting changes require:
  - Decision record
  - Spec update
  - Contract matrix update

### B) Release Controls
- Feature flags for high-risk capabilities.
- Soft freeze two weeks before target launch.
- Hard freeze 72 hours before GA.

### C) Documentation as Product
- Specs site generated from canonical docs.
- Versioned changelog for all interface contracts.

---

## Milestone Checklist

- [ ] M1: Contract Matrix Published
- [ ] M2: PSI Vertical Stable in Staging
- [ ] M3: Repo/Artifact Bridge Stable
- [ ] M4: Reliability + Security Gates Passed
- [ ] M5: Soft Launch Complete
- [ ] M6: GA Launch Complete

## Immediate Next 10-Day Plan

1. Generate initial `contract_matrix.jsonld` from current spec inventory.
2. Run contract drift triage and mark top 10 mismatches.
3. Lock PSI v1 endpoints and publish examples.
4. Build staging demo script for end-to-end conversation-to-artifact flow.
5. Stand up launch dashboard (health, readiness, queue depth, error budget).

This roadmap is the execution bridge from revived architecture to launch.
