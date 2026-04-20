# Pactis-TVI: Truth Validation Interface

- Status: Draft
- Last Updated: 2025-09-26
- Owners: Pactis Core
- Related: Pactis.md, Pactis-API.md
- Notice: Pactis™ is an open specification by Pactis and is not affiliated with any other entity using similar names. ™ indicates an unregistered trademark claim.

## Purpose
Wire‑level interface for validating Pactis Blueprints and related JSON‑LD against Pactis’s validation tiers and error taxonomy.

## Scope
- Accepts JSON‑LD inputs; returns ValidationReport with machine‑friendly errors.
- No side effects; stateless, deterministic.

## API Sketch
- POST /validate: payload = Blueprint (JSON‑LD); response = ValidationReport.
- Error taxonomy: codes structured by tier (syntax/schema/policy).

## Conformance
- Determinism across runs; stable error codes; golden vectors.

## Security Considerations
- Validate content size and complexity; bound graph expansions.
- Do not persist inputs; treat as stateless; redact sensitive content in logs.
