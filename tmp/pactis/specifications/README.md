## Pactis Specifications Index

This folder contains the Pactis Framework umbrella RFC and the set of interface profiles used across the platform. Entries follow a consistent header (Status, Last Updated, Owners, Related) and use JSON‑LD examples with `https://pactis.dev/vocab#`.

Key documents
- [CODEX Contractual Architecture Map](./CODEX_CONTRACTUAL_ARCHITECTURE.md) — Consolidated constitutional map of invariants, interfaces, runtime anchors, and reboot rules
- [contract_matrix.jsonld](./contract_matrix.jsonld) — Machine-readable contract registry with conformance tags
- [SABHA_MERKIN_HANDOFF.md](./SABHA_MERKIN_HANDOFF.md) — Copy map for Merkin Tree vs Saba transfer
- [Pactis.md](./Pactis.md) — Umbrella framework RFC (normative core, profiles index)
- [Pactis-Framework-v2.md](./Pactis-Framework-v2.md) — Rationale and changelog (informative)
- [Pactis-CCV2.md](./Pactis-CCV2.md) — Conversational Computing v2 umbrella (Sabha profile)

Conversational Computing v2 (Sabha profile)
- [Pactis-Sabha-Schemas.md](./Pactis-Sabha-Schemas.md) — Canonical substrate, session, and crystallization object contracts
- [Pactis-Sabha-Operations.md](./Pactis-Sabha-Operations.md) — Move membrane, service boundaries, and operation contracts
- [Pactis-Sabha-Dialects.md](./Pactis-Sabha-Dialects.md) — Dialect adapter contract for AI-native styles
- [Pactis-Sabha-RPD-Profile.md](./Pactis-Sabha-RPD-Profile.md) — RPD/CSG symbolic grammar profile (+ `⊚` Saba extension)
- [Pactis-Sabha-Conformance.md](./Pactis-Sabha-Conformance.md) — Determinism, replay, archive/restart, and dialect conformance suites
- [SABA_PROJECT_STARTER.md](./SABA_PROJECT_STARTER.md) — Consolidated Saba kickoff plan
- [saba_bootstrap.jsonld](./saba_bootstrap.jsonld) — Machine-readable Saba bootstrap seed

Interfaces
- [Pactis-PAI.md](./Pactis-PAI.md) — Authentication (password, OAuth2, API tokens)
- [Pactis-Auth.md](./Pactis-Auth.md) — Authentication, API tokens, invitations, events (consolidated)
- [Pactis-PSI.md](./Pactis-PSI.md) — Specification conversations and workflows
- [Pactis-PGI.md](./Pactis-PGI.md) — Git Smart HTTP with conversation mode
- [Pactis-PCI.md](./Pactis-PCI.md) — Repo contents API with conversation context
- [Pactis-PEI.md](./Pactis-PEI.md) — Event model and sinks (JSON‑LD)
- [Pactis-POI.md](./Pactis-POI.md) — Observability integration and metrics
- [Pactis-SDI.md](./Pactis-SDI.md) — Service self-description and discovery
- [Pactis-SMI.md](./Pactis-SMI.md) — Settlement and metering (Oban profile)
- [Pactis-VFS.md](./Pactis-VFS.md) — Content-addressed file serving profile
- [Pactis-TVI.md](./Pactis-TVI.md) — Validation API and error taxonomy
- [Pactis-GRI.md](./Pactis-GRI.md) — Generator registry and semver resolution
- [Pactis-API.md](./Pactis-API.md) — Artifact publication interface
- [Pactis-SRI.md](./Pactis-SRI.md) — Service registry aggregation/catalog
- [Pactis-CAI.md](./Pactis-CAI.md) — Content authoring/projection pipeline
- [Pactis-CFP.md](./Pactis-CFP.md) — Context frame protocol
- [Pactis-DAI.md](./Pactis-DAI.md) — Design assets interface
- [Pactis-KEI.md](./Pactis-KEI.md) — Knowledge engine integration
- [Pactis-LGI.md](./Pactis-LGI.md) — Language gateway interface
- [Pactis-SSHS.md](./Pactis-SSHS.md) — Secure Secrets via SSH Keys (ephemeral mount)
- [Pactis-TAI.md](./Pactis-TAI.md) — Test artifacts and runs
 - [Pactis-OSI.md](./Pactis-OSI.md) — Organization Services Index (org-level)
 - [Pactis-RBP.md](./Pactis-RBP.md) — Resource Blueprint Protocol (schema + API)

Conventions
- JSON‑LD examples use `application/ld+json` with `https://pactis.dev/vocab#`.
- Headings use ASCII hyphens; filenames match titles.
- Security and conformance sections appear in each profile.
