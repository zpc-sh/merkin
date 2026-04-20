# Merkin API Reference v0.1

Consolidated API surface reference for Merkin library, CLI, daemon, WASM, and compatibility conversation contracts.

Date baseline: `2026-04-18`.

## 1) API Areas and Modes

Merkin API is best understood as areas crossed with modes.

Areas:

- `core`: hash/tree/model/store/storage primitives
- `boundary`: ingress normalization, ghost-byte hygiene, trust posture
- `surface`: ratio/genius/daemon command and runtime interfaces
- `federation` (emerging): union'd Merkin exchange surfaces (firmament/skai/projection)

Modes:

- operation mode: `ratio | genius | daemon`
- trust mode: `observe | sanitize | strict | quarantine`

Current default for boundary posture in emitted finger surface: `sanitize`.

## 2) Library APIs (MoonBit Imports)

## 2.1 Core hashing/tree

- `@hash.Hash::of_bytes`
- `@hash.Hash::semantic`
- `@tree.MerkinTree::ingest`
- `@tree.MerkinTree::seal`
- `@tree.MerkinTree::sparse`
- `@tree.diff_sparse_trees`

## 2.2 Storage/policy/runtime

- `@storage.ReplicationPolicy::*`
- `@storage.UnionStore::put_blob|get_blob|has_blob`
- `@daemon.DaemonNode::handle_oci_put`
- `@daemon.DaemonNode::sparse_view|diff_from_sparse|diff_views`

## 2.3 Identity/attestation

- `@model.GeniusProcsiAttestation::*`
- `@model.AppEnvelopeRecord::*`
- `@model.ProcsiAttestedSectionV1::emit_pr1_custom_section`
- `@model.ProcsiAttestedSectionV1::parse_pr1_custom_section`

## 2.4 Yata and plan

- `@model.YataGraph::*` (hole lifecycle, topology, replay projection)
- `@model.YataPlan::to_wire`
- `@model.YataPlan::parse_wire_strict`
- `@model.YataAddress::canonicalize|parse_strict`

## 2.5 Triad package

- `@triad.seed_sparse_tree`
- `@triad.abi_expected_exports`
- `@triad.abi_status`
- `@triad.emit_contract`

## 3) CLI API Surface

## 3.1 Ratio (`merkin ratio ...`)

- `init`
- `loci new|ls|graph`
- `app put|inspect|emit-pr1|parse-pr1`
- `status`
- `pack`

## 3.2 Genius (`merkin genius ...`)

- `enter`
- `sign`
- `trail`
- `where`
- `residue`

Attestation requirement:

- procsi flags are required unless `--bootstrap-genius` is used.

## 3.3 Daemon (`moon run cmd/main -- daemon ...`)

Categories:

- `oci`: `capabilities`, `put`
- `tree`: `sparse`, `diff`
- `conv`: `turn`, `replay`, `embed`, `embed-purge`
- `yata`: `topology`, `wasm-plan`, `triad-contract`
- `cognitive`: bridge-only
- `adapter`: bridge-only

Legacy `--action` form remains supported.

## 4) WASM/API Surface

From `api/api.mbt` and `wasm_entry/entry.mbt`:

- `bloom_add|bloom_check|bloom_serialize|bloom_popcount`
- `tree_ingest|tree_sparse|tree_seal|tree_epoch|tree_node_count`
- `plan_finger_wasm|plan_drift_commitment`
- `triad_abi_status|triad_contract_wasm`
- `hash_bytes|reset`

## 5) finger.plan Boundary Posture Fields

Current compact posture lines emitted in `plan_finger_wasm` include:

- `boundary_mode`
- `boundary_cognitive`
- `boundary_domain`
- `boundary_refs_total`
- `boundary_refs_sanitized`
- `boundary_refs_quarantined`
- `boundary_ghost_u200b`
- `boundary_ghost_u200c`
- `boundary_ghost_ufeff`
- `boundary_bidi_controls`
- `boundary_ascii_controls`
- `boundary_ticks`
- `boundary_attention_score`
- `boundary_attention_gradient`
- `boundary_attention_saturated`
- `boundary_status`

Interpretation:

- `boundary_cognitive=1` means boundary-filtered representation is being asserted as a cognitive boundary.
- `boundary_status=attention` indicates ghost-byte sanitization occurred.
- `boundary_status=containment` indicates bidi or disallowed ASCII controls were observed.
- `boundary_attention_score` and `boundary_attention_gradient` represent deterministic attention pressure (tick-based FSM signal, not intelligence).

## 6) Conversation API Compatibility Stub (Pactis Legacy Form)

Spec surfaces:

- `docs/PACTIS_CONVERSATIONAL_API_SPEC.md`
- `docs/PACTIS_CONVERSATIONAL_OPENAPI.yaml`

Runtime alignment today:

- daemon conversation actions (`conv turn|replay|embed|embed-purge`) map to core hall/thread/turn/replay concepts.
- in-memory host scaffold exists; full networked API server is not yet implemented in this repo.

Direction:

- treat current Pactis-form docs/schema as compatibility stub only
- primary direction is union'd Merkin conversation surfaces rather than a separate long-term Pactis shape

## 7) Yata Contract Language (Compiler-Facing)

Primary contract references:

- `docs/YATA_PLAN_SPEC.md`
- `docs/YATA_CONTRACT_LANGUAGE_PROFILE_v0.1.md`
- `model/yata_protocol.mbt` strict parser behavior

Compiler guidance:

- strict-parse emitted `.plan` as a build gate
- rely on machine error codes from parser outcomes
- treat warning codes as policy-configurable advisory or blocking signals

## 8) Implementation Status Matrix

Stable and implemented:

- hash/tree/storage policy core
- daemon OCI/tree/conv/yata actions
- WASM drift + triad emission
- procsi/app `.pr1` emit/parse
- boundary posture signaling in finger output

Bridge-only:

- `daemon cognitive *`
- `daemon adapter validate`

Scaffolded/pending:

- several filesystem-backed ratio/genius views (`loci ls`, `where`, `trail`, `residue`, `status`)
- `ratio pack` full serializer/output path wiring
- composition primitive rollout (`consume|union|atop|subtraction`) for next version

## 9) Canonical References

- `docs/MERKIN_MASTER_DOCUMENT.md`
- `docs/MERKIN_USER_MANUAL.md`
- `docs/DAEMON_CLI.md`
- `docs/LIBRARY_API_GUIDE.md`
- `docs/YATA_CONTRACT_LANGUAGE_PROFILE_v0.1.md`
- `docs/RATIO_BOUNDARY_SHIM_SPEC_v0.1.md`
- `docs/MERKIN_COMPOSITION_PRIMITIVES_v0.1.md`
