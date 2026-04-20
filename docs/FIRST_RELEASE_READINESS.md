# First Release Readiness: Specification, Documentation, and Test Coverage

This document is a release-preparation snapshot for `zpc/merkin` and is intended to answer:

1. Do we have adequate specification coverage for a first release?
2. Do we have adequate operational/developer documentation?
3. Do we have broad enough test coverage to declare a release candidate?

---

## 1) Specification coverage matrix

| Domain | Primary spec docs | Implementation anchors |
|---|---|---|
| Core substrate model | `docs/MERKIN_SUBSTRATE_SPEC_v0.1.md` | `merkin.mbt`, `model/`, `tree/`, `store/` |
| MU interfaces and behaviors | `docs/MU_RUNTIME_SPEC.md` (canonical), `docs/MU-INTERFACE-SPEC.md` (compatibility) | `model/`, `daemon/`, `storage/` |
| Conversational protocol contract | `docs/PACTIS_CONVERSATIONAL_API_SPEC.md`, `docs/PACTIS_CONVERSATIONAL_OPENAPI.yaml` | `daemon/`, `cmd/main/` |
| Storage and metadata semantics | `docs/STORAGE_LAYER_DRAFT.md`, `docs/EMBEDDING_EPHEMERAL_METADATA_SPEC.md` | `storage/`, `store/`, `model/embedding_metadata.mbt` |
| Yata graph and governance semantics | `docs/YATA_FRAMEWORK.md`, `docs/YATA_PLAN_SPEC.md`, `docs/YATA_PLAN_GOVERNANCE.md` | `model/yata*.mbt`, `model/imprint*.mbt` |
| Hash/tree determinism and parity concepts | `docs/PACTIS_GIT_PARITY_FUNCTION_MAP.md`, `docs/IMPRINT_MIRAGE_FRAMEWORK.md` | `hash/`, `tree/`, `model/imprint.mbt` |

Coverage status: **broadly complete for an initial release candidate**, with some docs still explicitly marked as drafts or `v0.1`.

---

## 2) Documentation coverage matrix

| Audience | Documentation | Release utility |
|---|---|---|
| Integrators | `docs/PACTIS_CONVERSATIONAL_API_SPEC.md`, `docs/PACTIS_CONVERSATIONAL_OPENAPI.yaml` | API contract and transport details |
| Operators | `docs/DAEMON_CLI.md` | Runtime/CLI behavior and invocation model |
| Storage implementers | `docs/STORAGE_LAYER_DRAFT.md` | Storage model and extension direction |
| Core contributors | `docs/MERKIN_SUBSTRATE_SPEC_v0.1.md`, `docs/MU_RUNTIME_SPEC.md` | Conceptual architecture and invariants |
| Release managers | `docs/YATA_RELEASE_CHECKLIST.md`, this document | Readiness gating and explicit release checks |
| QA/perf maintainers | `docs/TESTING_AND_BENCHMARKING.md` | Test and benchmark execution guidance |

Coverage status: **strong baseline documentation exists**, now complemented by this explicit release-readiness matrix.

---

## 3) Test coverage map

### Package-level tests present

- Root package: `merkin_test.mbt`, `merkin_wbtest.mbt`
- `hash/`: `hash_test.mbt`
- `bloom/`: `bloom_test.mbt`
- `tree/`: `tree_test.mbt`, `sparse_diff_test.mbt`, `sparse_perf_wbtest.mbt`
- `model/`: `model_test.mbt`, `yata_test.mbt`, `yata_protocol_test.mbt`, `yata_addressing_test.mbt`, `imprint_test.mbt`
- `store/`: `store_test.mbt`
- `storage/`: `storage_test.mbt`, `queue_test.mbt`, `oci_test.mbt`, `oci_http_test.mbt`
- `daemon/`: `daemon_test.mbt`
- `gaussian/`: `gaussian_test.mbt`
- `conformance/`: `core_profile_test.mbt`, `optional_profiles_test.mbt`, `conformance_bench_test.mbt`

### Conformance and benchmark gates

Defined under `conformance/` and documented in `docs/TESTING_AND_BENCHMARKING.md`:

- Core profile invariants are implemented in `core_profile_test.mbt`.
- Optional profiles are explicit placeholders in `optional_profiles_test.mbt`.
- Baseline performance checks are implemented in `conformance_bench_test.mbt`.

Coverage status: **broad functional test coverage exists across major modules**.

---

## 4) First-release gate checklist

Mark all items before tagging `v0.1.0-rc1`:

- [ ] MoonBit toolchain is available in CI and local release environment.
- [ ] `moon test` is green across all packages.
- [ ] `moon bench -p zpc/merkin/conformance` produces stable non-regressing baseline numbers.
- [ ] `docs/PACTIS_CONVERSATIONAL_OPENAPI.yaml` is validated and synchronized with API prose.
- [ ] Draft-labeled specs are either promoted or explicitly accepted as release-time drafts.
- [ ] `moon.mod.json` metadata is finalized (description, repository, keywords) for public consumption.

---

## 5) Immediate pre-release action plan

1. **Tooling gate**: ensure `moon` is installed in release CI image and contributor setup docs.
2. **Metadata polish**: finalize module metadata and project README positioning.
3. **Contract freeze**: lock API + core substrate invariants for `v0.1.x` compatibility.
4. **Release runbook**: execute full test + bench suite and record artifacts with commit SHA.

If these are completed, the project is in a credible first-release posture for downstream projects to consume as their store substrate.
