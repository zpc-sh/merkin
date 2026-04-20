# Pactis Naming Rationale and Mapping

Status: draft

This document records the naming decision for the framework and its operational guidance, and maps legacy names used across the repository to the new canonical names.

## Decision
- Canonical umbrella: Pactis Framework
- Operations BCP: Managed Pactis Operations (MPO)
- Profiles (wire‑level interfaces within Pactum):
  - Pactis‑TVI: Truth Validation Interface
  - Pactis‑GRI: Generator Registry Interface
  - Pactis‑API: Artifact Publication Interface
  - Pactis‑VFS: Artifact File Serving Profile

## Rationale
- Pactis emphasizes negotiated agreement without implying network transport; plural form reduces naming collisions.
- Aligns to our JSON‑LD model and guarantees: idempotency, determinism, provenance.
- Minimizes acronym collisions versus alternatives (e.g., TNF).

## Legacy Name Mapping
- CPA (Cognitive Persistence Architecture) → conceptual precursor; content maps to Pactum core (model) and MPO (operations).
- TNF (Truth Negotiation Framework) → superseded alias for Pactis Framework.
- MTN (Managed Truth Negotiation) → superseded alias for Managed Pactis Operations.
- Pactum (Framework/Operations) → interim alias; superseded by Pactis.
- TNF‑TVI/GRI/API/VFS → superseded aliases for Pactis‑TVI/GRI/API/VFS.

## Migration Guidance
- Prefer spelled‑out names in public docs (e.g., “Pactum Framework”) over bare acronyms.
- Where needed for continuity/SEO, include alias note: “formerly known as TNF/MTN”.
- Update links to new files under `docs/specifications/Pactum*.md` as you touch content.

## Related Documents
- RFC: docs/specifications/Pactis.md
- BCP: docs/specifications/MPO_BCP.md
- Profiles: Pactis‑TVI/GRI/API/VFS in `docs/specifications/`
- Historical: docs/specifications/CPA.md
