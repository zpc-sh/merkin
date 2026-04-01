# Yata `.plan` Specification (v0.3-draft)

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

### 4.3 Numeric fields

Unsigned integer required for:

- `entries`
- `self_report_gap`
- `git_report_commit_count`
- entry `candidates`
- entry `conf_floor`
- entry `provenance`

## 5. Error code catalog

### 5.1 Parse errors

- `EMPTY_INPUT`
- `BAD_KIND`
- `BAD_TRACK`
- `BAD_MODE`
- `MALFORMED_HEADER`
- `BAD_HEADER_NUMBER`
- `BAD_SELF_REPORT_FLAG`
- `BAD_GIT_REPORT_FLAG`
- `BAD_ENTRY`
- `UNRECOGNIZED_LINE`
- `MISSING_KIND`
- `MISSING_MATERIAL_HASH`
- `ENTRY_COUNT_MISMATCH`
- `MISSING_SELF_REPORT_OVERLAY`
- `MISSING_GIT_REPORT_BRANCH`

### 5.2 Validation warnings (`YataPlan::validate`)

- `EMPTY_HOLE_ID`
- `EMPTY_STATE`

## 6. Track guidance

- `program` track should usually include `self_report_*` when cross-AI replay is expected.
- `git` track should usually include `git_report_*` for branch/head/merge provenance.
- Dual envelopes are valid and supported in one plan.

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

## 8. Compatibility and evolution

- Parsers should treat unknown lines as errors in strict mode.
- Producers may add optional metadata only if parser support lands first.
- Backward compatibility policy:
  - new optional headers only
  - no semantic redefinition of existing keys
  - preserve entry token order for strict parsers
