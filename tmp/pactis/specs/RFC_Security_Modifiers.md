RFC: Security Modifiers for Pactis Specs and APIs

Status: Draft
Authors: Pactis Team (Loc + Codex)
Target: v1 baseline (enforcement staged)

1) Problem Statement
- Specs, resources, and endpoints require consistent, machine-readable security attributes.
- Current docs/specs lack a unified taxonomy for sensitivity, authz scope, retention, and approval gates.
- Goal: Add “security modifiers” that annotate JSON‑LD specs and drive validation, UI labels, and runtime enforcement.

2) Goals
- Define a minimal, interoperable vocabulary for security modifiers in JSON‑LD.
- Enable static validation in CI and runtime checks in Pactis services.
- Surface security posture in the UI (badges/tooltips) and in OpenAPI export.
- Provide backwards compatibility and a migration path.

Non‑Goals
- Replace tenant/org policy engines; we provide signals/constraints those engines consume.
- Implement cloud IAM provisioning (out of scope; we propagate requirements).

3) Threat Model (summary)
- Tenancy: workspace/org scoped isolation; no cross‑tenant leakage.
- Data: PII/PHI tradeoffs, access logs, audit trails.
- Transport/At rest: TLS, KMS/SSE for object store.
- Human workflows: read/write approvals, break‑glass flows.

4) Vocabulary (JSON‑LD)
- Prefix: `security:` → `https://pactis.dev/vocab/security#`
- Modifiers (apply to Spec Resources, Actions, and Data Artifacts):
  - `security:classification`: one of `public|internal|confidential|restricted`.
  - `security:authScopeRequired`: array of scope strings (e.g., `write:components`, `read:specs`).
  - `security:dataSensitivity`: array e.g., `pii|phi|credentials|keys|secrets`.
  - `security:encryptionRequired`: boolean (true if at rest + in transit required).
  - `security:retention`: object `{ days: number, reason: string }`.
  - `security:approvalLevel`: one of `none|peer|lead|security`.
  - `security:auditLogRequired`: boolean.
  - `security:exportControls`: array (e.g., `gdpr|ccpa|hipaa|soc2`).

Example (SpecRequest JSON‑LD excerpt):
```json
{
  "@context": [
    { "security": "https://pactis.dev/vocab/security#" }
  ],
  "@type": "SpecRequest",
  "name": "User Email Export",
  "security:classification": "restricted",
  "security:authScopeRequired": ["read:specs", "export:personal-data"],
  "security:dataSensitivity": ["pii"],
  "security:encryptionRequired": true,
  "security:retention": { "days": 30, "reason": "CSR investigation" },
  "security:approvalLevel": "security",
  "security:auditLogRequired": true
}
```

5) Validation & Tooling
- Mix task: `mix pactis.jsonld.validate --dir` extended with security checks:
  - Classification present for exportable artifacts.
  - If `dataSensitivity` includes `pii`, require `encryptionRequired` and `auditLogRequired`.
  - If `approvalLevel` ≥ `lead`, require `authScopeRequired`.
- Lints for specs in `priv/jsonld/resources/**/*`.
- Docs: add guidance + examples for each modifier.

6) Runtime Enforcement
- AuthZ: SpecAPI endpoints compare `security:authScopeRequired` with token scopes.
- Storage: If `encryptionRequired`, ensure object store uses SSE/KMS; reject if misconfigured (warn in dev).
- Retention: Background job enforces retention windows on artifacts (Mem + S3);
  override only with explicit `break_glass` header + audit.
- Audit: If `auditLogRequired=true`, write structured audit events on read/write.

7) UI/UX
- Badges on pages (e.g., Restricted, PII, Approval: Security).
- Detailed tooltip summarizing modifiers.
- Preflight warnings when attempting export/download that violates policy.

8) OpenAPI / Service Manifest
- Include security modifiers in OpenAPI extensions (x‑pactis‑security).
- Add to `priv/service.manifest.jsonld` so clients can pre‑decide UI affordances.

9) Migration Plan
- Phase 1 (warn): Validate modifiers in CI; allow missing fields with warnings.
- Phase 2 (enforce): Fail CI for missing critical modifiers on new/changed specs.
- Phase 3 (runtime): Block operations that violate modifiers unless break‑glass.

10) Backwards Compatibility
- Missing modifiers default to safe values in dev; warnings emitted.
- Prod requires explicit settings for exportable artifacts by date X.

11) Implementation Tasks
- Vocab: Add `security.context.jsonld` under `priv/jsonld/resources/Security/`.
- Validator: Extend `mix pactis.jsonld.validate` with security rules.
- SpecAPI: Check token scopes vs `security:authScopeRequired` on actions (read/export).
- Storage: Add SSE/KMS checks in S3 provider; log warning/error if unmet.
- Retention: Add TTL enforcement job for sensitive artifacts.
- Audit: Add sink for required audit events and wire into critical handlers.

12) Open Questions
- Default classification if omitted? Suggest `internal` for private repos.
- Should break‑glass require dual‑approval tokens? (future)
- How to model dynamic policy overrides (e.g., per‑org exceptions)?



Replay Overrides (AshEvents)
```elixir
# Example module where replay overrides can live
defmodule Pactis.Events.Replay do
  # Placeholder; adjust to actual AshEvents DSL
  # replay_overrides do
  #   replay_override Pactis.Accounts.User, :create do
  #     versions ["v1"]
  #     route_to Pactis.Accounts.User, :old_create_v1
  #   end
  # end
end
```
