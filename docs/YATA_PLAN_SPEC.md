# Yata `.plan` Specification (v0.4-draft)

This document defines the `.plan` wire contract used by Merkin Yata for replay, audit, and AI collaboration handoff.

## 1. Purpose

`.plan` is a deterministic snapshot of Yata graph state, designed to be:

- timestamp-independent
- replay-oriented
- machine-parseable
- safe for cross-overlay and cross-track exchange

`track=program` and `track=git` share one wire envelope to enable mixed provenance workflows.

## 2. Data model

`YataPlan` includes:

- `track`: `program | git`
- `mode`: `full | compact`
- `generator`: producer identity string
- `note`: producer note
- `material_hash`: deterministic hash over emitted material
- `self_report`: optional collaboration envelope
- `git_report`: optional VCS provenance envelope
- `temporal_delta`: optional signed movement vector for replay/time-travel
- `embedding_report`: optional arbitrary-file embedding scan metadata
- `solve_report`: optional compact generalized solve/offload summary
- `procsi_report`: optional compact procsi/APP attestation disclosure
- `capability_report`: optional compact capability/ticket posture disclosure
- `entries`: array of plan entries

`YataPlanEntry` includes:

- `hole_id`
- `anchor`
- `state`
- `ready`
- `candidate_count`
- `confidence_floor`
- `selected_candidate`
- `provenance` count (wire form carries count, not full list)

## 3. Wire format

### 3.1 Header + entry lines

```text
kind: merkin.yata.plan
track=<program|git>
mode=<full|compact>
generator=<text>
note=<text>
material_hash=<text>
[entries=<uint>]
[self_report=1]
[self_report_overlay=<text>]
[self_report_peer=<text>]
[self_report_authority=<text>]
[self_report_anchor=<text>]
[self_report_gap=<uint>]
[self_report_view=<text>]
[git_report=1]
[git_report_branch=<text>]
[git_report_remote=<text>]
[git_report_merge_base=<text>]
[git_report_head=<text>]
[git_report_commit_count=<uint>]
[git_report_refs=<text>]
[temporal_delta=1]
[temporal_delta_turns=<int>]
[temporal_delta_bytes=<int>]
[temporal_delta_causal_offset=<int>]
[embedding_report=1]
[embedding_report_file_type=<text>]
[embedding_report_found=<true|false>]
[embedding_report_count=<uint>]
[embedding_report_ephemeral=<true|false>]
[embedding_report_purge_after_turns=<uint>]
[embedding_report_strategy=<text>]
[solve_report=1]
[solve_report_kind=<text>]
[solve_report_status=<text>]
[solve_report_handler=<text>]
[solve_report_offloaded_to=<text>]
[solve_report_count=<uint>]
[procsi_report=1]
[procsi_report_project=<text>]
[procsi_report_ratio_loci=<text>]
[procsi_report_surface=<text>]
[procsi_report_fingerprint_commitment=<text>]
[procsi_report_app_ref=<text>]
[procsi_report_app_audience=<text>]
[procsi_report_masked=<true|false>]
[capability_report=1]
[capability_report_authority=<text>]
[capability_report_ticket_kind=<text>]
[capability_report_scope=<text>]
[capability_report_status=<text>]
[capability_report_count=<uint>]
[capability_report_store_ref=<text>]
- <hole_id> <anchor> <state> ready=<bool> candidates=<uint> conf_floor=<uint> selected=<id|none> provenance=<uint>
...
```

### 3.2 Emission behavior

- Current emitter writes all core headers except `entries=`.
- `entries=` is parser-supported and optional for compatibility.
- Each entry line is single-line, tokenized by spaces.

## 4. Strict parser behavior

`YataPlan::parse_wire_strict(raw)` returns:

- `ok=true` and materialized `plan` when valid
- `ok=false` and `issues[]` when invalid

Unknown non-empty lines are rejected.

### 4.1 Required fields

- `kind: merkin.yata.plan`
- `track=...`
- `mode=...`
- `generator=...`
- `note=...`
- `material_hash=...`

### 4.2 Conditional required fields

- if `self_report=1`, then `self_report_overlay` is required
- if `git_report=1`, then `git_report_branch` is required
- if `embedding_report=1`, then `embedding_report_file_type` is required
- if `solve_report=1`, then `solve_report_handler` is required
- if `procsi_report=1`, then `procsi_report_surface` is required
- if `procsi_report=1`, then `procsi_report_fingerprint_commitment` is required
- if `procsi_report=1` and `procsi_report_masked=true`, then `procsi_report_app_ref` is required
- if `procsi_report=1` and `procsi_report_masked=true`, then `procsi_report_app_audience` is required
- if `capability_report=1`, then `capability_report_authority` is required
- if `capability_report=1`, then `capability_report_ticket_kind` is required
- if `capability_report=1`, then `capability_report_store_ref` is required

### 4.3 Numeric fields

Unsigned integer required for:

- `entries`
- `self_report_gap`
- `git_report_commit_count`
- `embedding_report_count`
- `embedding_report_purge_after_turns`
- `solve_report_count`
- `capability_report_count`
- entry `candidates`
- entry `conf_floor`
- entry `provenance`

Signed integer required for:

- `temporal_delta_turns`
- `temporal_delta_bytes`
- `temporal_delta_causal_offset`

## 5. Error code catalog

### 5.1 Parse errors

- `EMPTY_INPUT`
- `BAD_KIND`
- `BAD_TRACK`
- `BAD_MODE`
- `MALFORMED_HEADER`
- `BAD_HEADER_NUMBER`
- `BAD_HEADER_BOOL`
- `BAD_SELF_REPORT_FLAG`
- `BAD_GIT_REPORT_FLAG`
- `BAD_TEMPORAL_DELTA_FLAG`
- `BAD_EMBEDDING_REPORT_FLAG`
- `BAD_SOLVE_REPORT_FLAG`
- `BAD_PROCSI_REPORT_FLAG`
- `BAD_CAPABILITY_REPORT_FLAG`
- `BAD_ENTRY`
- `UNRECOGNIZED_LINE`
- `MISSING_KIND`
- `MISSING_MATERIAL_HASH`
- `ENTRY_COUNT_MISMATCH`
- `MISSING_SELF_REPORT_OVERLAY`
- `MISSING_GIT_REPORT_BRANCH`
- `MISSING_EMBEDDING_FILE_TYPE`
- `MISSING_SOLVE_REPORT_HANDLER`
- `MISSING_PROCSI_REPORT_SURFACE`
- `MISSING_PROCSI_REPORT_FINGERPRINT`
- `MISSING_PROCSI_REPORT_APP_REF`
- `MISSING_PROCSI_REPORT_APP_AUDIENCE`
- `MISSING_CAPABILITY_REPORT_AUTHORITY`
- `MISSING_CAPABILITY_REPORT_TICKET_KIND`
- `MISSING_CAPABILITY_REPORT_STORE_REF`

### 5.2 Validation warnings (`YataPlan::validate`)

- `EMPTY_HOLE_ID`
- `EMPTY_STATE`

## 6. Track guidance

- `program` track should usually include `self_report_*` when cross-AI replay is expected.
- `git` track should usually include `git_report_*` for branch/head/merge provenance.
- Dual envelopes are valid and supported in one plan.
- `solve_report_*` is appropriate when a plan is summarizing generalized solve/offload posture rather than only graph state.
- `finger.plan` should prefer `track=program` with `procsi_report_*` and `capability_report_*` when exposing repository/runtime posture to other AIs.
- `finger.plan` should expose commitments, refs, and compact status only; raw APP payloads, raw fingerprints, and ticket bodies remain in deeper procsi/store layers.
- `surface.plan` should remain sparse and entry-driven, exposing protocol/API/capability surfaces rather than full runtime state.
- `.well-known` may mirror this information for drift detection, but `.plan` is the preferred layered disclosure surface.

## 7. Canonical examples

### 7.1 Program track with self report

```text
kind: merkin.yata.plan
track=program
mode=full
generator=chatgpt
note=session-replay
material_hash=blake3:...
self_report=1
self_report_overlay=chatgpt
self_report_peer=claude
self_report_authority=loc.machine
self_report_anchor=notes/session.md
self_report_gap=1
self_report_view=overlay
- blake3:... notes/session.md resolved ready=true candidates=2 conf_floor=70 selected=c1 provenance=1
```

### 7.2 Git track with git report

```text
kind: merkin.yata.plan
track=git
mode=full
generator=chatgpt
note=branch-audit
material_hash=blake3:...
git_report=1
git_report_branch=main
git_report_remote=origin
git_report_merge_base=abc123
git_report_head=def456
git_report_commit_count=2
git_report_refs=abc123,def456
- blake3:... notes/repo.md converging ready=true candidates=1 conf_floor=60 selected=none provenance=0
```

### 7.3 Program track with temporal delta and embedding report

```text
kind: merkin.yata.plan
track=program
mode=full
generator=chatgpt
note=embedding-scan-pass
material_hash=blake3:...
temporal_delta=1
temporal_delta_turns=-2
temporal_delta_bytes=-8192
temporal_delta_causal_offset=1
embedding_report=1
embedding_report_file_type=pdf
embedding_report_found=true
embedding_report_count=3
embedding_report_ephemeral=true
embedding_report_purge_after_turns=2
embedding_report_strategy=flip-aot
- blake3:... docs/payload.pdf converging ready=false candidates=1 conf_floor=80 selected=none provenance=1
```

### 7.4 Program track with solve report

```text
kind: merkin.yata.plan
track=program
mode=full
generator=chatgpt
note=repair-pass
material_hash=blake3:...
solve_report=1
solve_report_kind=repair
solve_report_status=running
solve_report_handler=provider.codex
solve_report_offloaded_to=delegate-control
solve_report_count=4
- blake3:... model/parser.mbt converging ready=true candidates=2 conf_floor=70 selected=none provenance=1
```

### 7.5 Finger plan with procsi and capability disclosure

```text
kind: merkin.yata.plan
track=program
mode=compact
generator=codex
note=finger
material_hash=blake3:...
procsi_report=1
procsi_report_project=zpc-sh/merkin
procsi_report_ratio_loci=ratio://merkin/root
procsi_report_surface=codex
procsi_report_fingerprint_commitment=blake3:...
procsi_report_app_ref=app://repo/ai/codex
procsi_report_app_audience=ratio.loci.merkin
procsi_report_masked=true
capability_report=1
capability_report_authority=ratio://merkin/root
capability_report_ticket_kind=service
capability_report_scope=genius.write
capability_report_status=issued
capability_report_count=2
capability_report_store_ref=store://app/tickets/root
- blake3:... notes/finger.plan converging ready=true candidates=1 conf_floor=75 selected=none provenance=1
```

## 8. Compatibility and evolution

- Parsers should treat unknown lines as errors in strict mode.
- Producers may add optional metadata only if parser support lands first.
- Backward compatibility policy:
  - new optional headers only
  - no semantic redefinition of existing keys
  - preserve entry token order for strict parsers
