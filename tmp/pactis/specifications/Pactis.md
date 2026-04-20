# Pactis Framework — Standards Track RFC

Status: draft
Notice: Pactis™ is an open specification by Pactis and is not affiliated with any other entity using similar names. ™ indicates an unregistered trademark claim.
Aliases: formerly referred to as "Pactum Framework (PF)" and "Truth Negotiation Framework (TNF)" in earlier docs.

Recommended naming
- Umbrella (Standards Track): Pactis Framework
  - Rationale: "Pactis" (plural of pactum) emphasizes negotiated agreement without implying transport, matching the JSON‑LD data model, invariants, and guarantees (idempotency, determinism, provenance).

Layering model
- Pactis (framework): Defines canonical JSON‑LD shapes (Blueprint, ArtifactPointer, Generator, Provenance), context policy, validation taxonomy, determinism, and conformance. No network coupling mandated.
- Profiles (wire‑level "interfaces" within Pactis): Each specifies an API/contract for a specific function. Use "Interface" to avoid ambiguity:
  - Pactis‑TVI: Truth Validation Interface (validation API responses + error taxonomy)
  - Pactis‑GRI: Generator Registry Interface (capabilities, versions)
  - Pactis‑API: Artifact Publication Interface (enroll, generate, fetch artifacts)
  - Pactis‑VFS: Artifact File Serving Profile (CAS/VFS access semantics)
  - Pactis‑SDI: Service Self-Description Interface (service metadata discovery + aggregation) [NEW]
  - Pactis‑SMI: Settlement & Metering Interface (usage tracking + billing)
  - Pactis‑CAI: Context Administration Interface (context management)
  - Pactis‑CFP: Context Frame Protocol (context envelope exchange)
  - Pactis‑DAI: Design Asset Interface (design system artifacts)
  - Pactis‑KEI: Knowledge Engine Interface (context synthesis and harvesting)
  - Pactis‑CCV2: Conversational Computing v2 (Sabha profile over PSI/CFP/KEI/PGI/PCI)
- Pactis‑LGI: Ledger Gateway Interface (blockchain integration)
- Pactis‑SRI: Service Registry Interface (runtime discovery)
- Pactis‑TAI: Trust Anchor Interface (certificate management)

## Tenancy Model (Informative)
Pactis implements a GitHub‑style workspace model over a single database. Organization/workspace membership governs access to repositories, specifications, and related resources. Where stronger boundaries are needed, Ash’s attribute‑strategy multitenancy can be introduced on a per‑resource basis (e.g., scoping by `org_id`) without a global migration.

RFC Outline

## Abstract
Define "negotiated truth": converging a negotiated truth from authored JSON‑LD via validation, producing signed, deterministic, content‑addressed artifacts.

## Terminology & Normative Language
Define key terms (Blueprint, ArtifactPointer, GeneratorDescriptor, ValidationReport, Provenance, ServiceDescriptor), RFC‑2119/8174 normative language.

## Context Policy
- Allowed prefixes and versioning rules.
- Context pinning and freshness guarantees.
- Backwards/forwards compatibility guidance.

## JSON‑LD Shapes (normative)
- Blueprint: required keys; examples.
- ArtifactPointer: immutable; CAS digests; signing; examples.
- GeneratorDescriptor: capabilities, inputs, semver.
- ValidationReport: error taxonomy structure.
- ServiceDescriptor: service metadata, capabilities, dependencies.

## Validation Tiers
- Syntax → Schema → Policy.
- Error codes and machine‑friendly forms.

## Determinism & Idempotency Guarantees
- Input set → unique pointer and CAS digests.
- Idempotent key = (source_id, framework, generator_version).

## Provenance & Signing
- ed25519 over canonicalized JSON (URDNA2015 baseline) using W3C Data Integrity.
- Verification requirements and failure modes.

## Conformance
- Golden vectors.
- Determinism checks.
- Error taxonomy conformance.
- Signature verification conformance.

## Security Considerations
- Tampering, stale contexts, supply chain, signature spoofing.

## Profiles Index
Pointers to interface specs:
- Pactis‑TVI: docs/specifications/Pactis-TVI.md
- Pactis‑GRI: docs/specifications/Pactis-GRI.md
- Pactis‑API: docs/specifications/Pactis-API.md
- Pactis‑VFS: docs/specifications/Pactis-VFS.md
- Pactis‑SDI: docs/specifications/Pactis-SDI.md [Service Self-Description]
- Pactis‑SMI: docs/specifications/Pactis-SMI.md [Settlement & Metering]
- Pactis‑CAI: docs/specifications/Pactis-CAI.md
- Pactis‑CFP: docs/specifications/Pactis-CFP.md
- Pactis‑DAI: docs/specifications/Pactis-DAI.md
- Pactis‑KEI: docs/specifications/Pactis-KEI.md
- Pactis‑CCV2: docs/specifications/Pactis-CCV2.md
- Pactis‑LGI: docs/specifications/Pactis-LGI.md
- Pactis‑SRI: docs/specifications/Pactis-SRI.md
- Pactis‑TAI: docs/specifications/Pactis-TAI.md

## Conversational Computing v2 Profile Map

Pactis-CCV2 formalizes artifact-first discourse with a thin invariant membrane:

- PSI: conversation and move logging adapter surface (`SpecRequest` / `SpecMessage`)
- CFP: context frame distribution and bootstrap context
- KEI: knowledge and frame synthesis (Avici inputs)
- PGI: Git transport and workflow integration for conversational residues
- PCI: artifact and projection access surface

CCV2 canonical semantics are defined by SymbolForm, commitments, lineage, and replay layers rather than winner-based debate outcomes.

## Context & Prefixes
- Preferred JSON‑LD context: `/jsonld/pactis.context.jsonld`
- Vocab base: `https://pactis.dev/vocab#`
- QName prefix: use `pactis:` for terms and IDs, for example:
  - `"@id": "pactis:components/button-primary"`
  - `"@type": "pactis:TokenSet"`
  - `"pactis:validatedAgainst": ["pactis:policy/color-contrast"]`
  - `"@type": "pactis:ServiceDescriptor"` [for service metadata]
  - `"pactis:capabilities": ["pactis:capability/data-storage"]`
- When embedding Pactis terms in other graphs, include the context or map `pactis` to the vocab URL.

## Service Mesh Integration (Informative)
The Pactis‑SDI interface enables service mesh topology discovery and metadata aggregation:
- Services self-describe using ServiceDescriptor shapes at well-known locations
- Platform tools discover and validate metadata following SDI protocol
- Aggregated metadata enables dependency tracking, capability mapping, and topology visualization
- Integration with SMI enables usage-based metering per service
- Integration with SRI enables runtime service discovery

## Implementation Profiles
- Oban: Asynchronous job processing (used by SMI)
- PromptOps: AI-driven automation (used by SDI fallback generation)
- Well-Known URIs: RFC 5785 discovery (used by SDI)

## Change Log
- v0.9: Initial draft with core interfaces
- v1.0: Added Pactis‑SDI for service self-description
- v1.1: Integration patterns for service mesh topology

---
*Pactis Framework v1.0 - Negotiated Truth Through Structured Data*
