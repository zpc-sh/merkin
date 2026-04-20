# Codex Contractual Architecture (Pactis)

Status: Working Contract Map  
Last Updated: 2026-04-02  
Owners: Pactis Core + AI Council

## Purpose
This document consolidates the **contractual architecture** of Pactis into one place so the system can be rebooted and evolved rapidly without losing normative intent.

Machine-readable registry: `docs/specifications/contract_matrix.jsonld`

It is a map of:
1. **Core invariants** (what must always hold)
2. **Interface contracts** (spec families)
3. **Runtime implementation anchors** (where contracts live in code)
4. **Reboot rules** for safe rapid change

---

## 1) Contract Invariants (Non-Negotiable)

1. **Negotiated truth over static merge workflow**
   - Changes are mediated through typed conversation/spec workflows.
2. **Determinism + idempotency + provenance**
   - Artifacts and decisions must be traceable and reproducible.
3. **JSON-LD as semantic contract plane**
   - Contract terms remain machine-readable and graph-compatible.
4. **Profile/interface composition instead of monolith coupling**
   - Capabilities are composed through bounded interfaces.
5. **Operational resilience by async orchestration + supervision**
   - Failure isolation and replayability matter more than linear pipelines.

---

## 2) Contract Layers

### Layer A — Framework Contract (Umbrella)
- `Pactis.md` defines canonical shapes, validation taxonomy, determinism, conformance and profile registry.

### Layer B — Interface Contracts (Profiles)
- Authentication / authorization: PAI, Auth
- Spec conversation & negotiation: PSI
- Conversational computing v2 (Sabha profile): CCV2 + Sabha schema/operations/dialects/conformance docs
- Git/content/version flow: PGI, PCI, VFS, RSI
- Validation + generation: TVI, GRI, API, RBP
- Discovery/context: SDI, SRI, CFP, KEI
- Observability/events/testing: PEI, POI, LGI, TAI
- Metering/billing: SMI
- Design/content: DAI, CAI, ComponentGeneration
- Secrets/security posture: SSHS

### Layer C — Runtime/Execution Contract
- Ash resources, Phoenix controllers, LiveView flows, Oban jobs, storage adapters.

### Layer D — Governance Contract
- Naming policy, trademark policy, migration notes, BCP docs.

---

## 3) Interface Registry (Contractual Surface)

| Contract | Primary Role | Status (spec file) |
|---|---|---|
| Pactis (Umbrella RFC) | Canonical model + invariants | draft |
| PAI / Auth | Identity, tokens, invitations, scopes | Implemented / Draft |
| PSI | Conversation-native spec lifecycle | Draft |
| PGI | Git smart HTTP + conversation mode | Draft |
| PCI | Repository/content API semantics | Draft |
| VFS | `graph://`, `cas://`, `git://`, `file://` serving semantics | Draft |
| TVI | Validation tiers + error taxonomy | Draft |
| GRI | Generator capability/semver registry | Draft |
| API | Artifact publication and retrieval | Draft |
| SDI | Service self-description | Draft |
| SRI | Service registry aggregation | draft |
| CFP | Context frame exchange protocol | Draft |
| KEI | Knowledge/decision context plane | Draft |
| CCV2 | Artifact-first conversational computing (Sabha profile) | Draft |
| PEI | Event contract + sinks | Implemented |
| POI | Observability contract | Implemented |
| LGI | Language gateway/tool execution | Draft |
| SMI | Metering/settlement | Draft |
| TAI | Test artifact/run contract | Draft |
| DAI | Design asset contract | draft |
| CAI | Content authoring/projection | Draft |
| SSHS | Secrets handling via ephemeral mounts | Draft |
| RBP | Resource blueprint schema + API | draft |
| RSI | Repository service interface pattern | Draft |
| PRI/PQI | Resource/query interface contracts | Implemented / Draft |

---

## 4) Runtime Anchors (Code Truth)

These implementation domains anchor the contractual layers:

- `Pactis.Spec*` → PSI/negotiation lifecycle
- `Pactis.Repositories*` + `Pactis.VFS*` + storage adapters → PGI/PCI/VFS/RSI
- `Pactis.Events*` + telemetry controllers/plugs → PEI/POI/LGI
- `Pactis.Billing*` + usage jobs → SMI
- `Pactis.DesignTokens*` + effective token jobs → DAI/CAI integration
- `Pactis.Avici*` + frame builder/harvest jobs → SDI/SRI/CFP/KEI
- `Pactis.Sabha*` substrate/crystallization resources + `Pactis.Avici*` context services → CCV2/Sabha contracts
- `Pactis.Accounts*` + auth routes/plugs → PAI/Auth

Rule: if spec and implementation disagree, treat it as **contract drift incident** and resolve by explicit decision record.

---

## 5) Reboot/Revamp Rules (Codex Mode)

1. **Spec-first changes**
   - Any contract-affecting change requires spec update + changelog note.
2. **Generated, not hand-edited migration baseline**
   - Prefer Ash Postgres generation for baseline schema evolution.
3. **Rapid iteration with preserved contract boundary**
   - Move fast inside domains; do not silently break interface semantics.
4. **Operational sanitization as a repeatable control**
   - Use repository sanitization script in suspicious-state recovery.
5. **Decision capture over implicit behavior**
   - Record major architectural moves as explicit decision artifacts.

---

## 6) Immediate Next Codex Work (Recommended)

1. Keep `docs/specifications/contract_matrix.jsonld` in sync with this registry.
2. Add conformance tags per interface: `implemented | partial | draft | deprecated`.
3. Wire a docs page for “contract drift dashboard”.
4. Connect conversational API decisions to contract changes (automatic provenance links).
5. Execute launch plan: `docs/roadmap/CODEX_REVITALIZATION_LAUNCH_ROADMAP.md`.

This document is the current **single-page constitutional map** for Pactis contractual architecture.
