# Yata Framework (v0.2)

This document defines the abstract Yata hole model used by merkin.

Related specifications:

- `docs/YATA_PLAN_SPEC.md` for the full `.plan` wire contract.
- `docs/PACTIS_GIT_PARITY_FUNCTION_MAP.md` for Git-equivalent command/function scope in Pactis.
- `docs/PACTIS_CONVERSATIONAL_API_SPEC.md` for AI-native conversational hosting (Saba/Pactis).

## Core intuition

`Yata` is a typed semantic gap, not a request queue.

- It is not waiting for another intelligence.
- It is not an imperative state machine (`await`, `delegate`, etc.).
- It is a local contract for what can be filled, under uncertainty.

That means Yata is valid in probabilistic, distributed, and partially observed systems.

## Object model

- `YataContract`: the boundary contract for a gap.
  - `expected_type`: static/semantic expectation.
  - `invariants`: local rules that candidate outputs must satisfy.
  - `effect_bounds`: declared side-effect boundaries.
  - `min_confidence`: lower bound for admissible completion confidence.
- `YataRefinement`: nested constraints (holes within holes, or tightening assumptions).
- `YataCandidate`: ordered candidate proposal space with confidence and rationale.
- `YataWitness`: optional provenance proof bundle for a chosen completion.
- `YataHole`:
  - deterministic `hole_id` from contract + refinements + anchors
  - `state`: `Open -> Converging -> Sealed -> Resolved`, or `Abandoned`
  - `dependencies`: other hole ids that must be resolved first
  - `provenance`: compact trace markers (`proposer:proof_token`)

## Lifecycle

1. Create a hole with `YataHole::new`.
2. Optionally add refinements and dependencies.
3. Submit one or many candidates with `propose`.
4. Choose a candidate by id with `seal`.
5. Publish resolution with `resolve`.

`Abandoned` is explicit and preserved as first-class state.

## Admissibility

- A hole is admissible when `max(candidate.confidence) >= min_confidence`.
- Dependencies must be resolved (`Resolved`) before the hole is considered ready.
- Candidate order can encode ranking rules; `best_candidate` is a local heuristic.

## Relation to effect systems

Yata is *effect-conscious* only by contract:
- no global effect execution required
- no assumption that side-effects will eventually happen
- no dependence on wall-clock time
- no dependence on absolute timestamps as truth

Each hole remains valid under deferred evaluation and partial truth.

## Cognitive address mapping (program track)

Yata entities are intentionally mapped to cognitive addresses, not wall-clock.

- `cog://loc/device/notes/hole-bridge.md?overlay=chatgpt&mode=surface#overlay`
- `substrate://loc/device/notes/hole-bridge.md?overlay=chatgpt&mode=surface#overlay`
- `cas://loc/device/blake3/abc123...?overlay=chatgpt&mode=surface&id=blake3:...&anchor=notes/hole-bridge.md#overlay`
- `./notes/hole-bridge.md?overlay=claude&peer=claude&mode=defensive#overlay`

Relative forms (`./`, `../`) are interpreted against the current cognitive perspective.
`peer=` records intended family, and a layer can request translation into its own comparable reference.
Slash-heavy routes are canonicalized (`////notes///x.md/` becomes `notes/x.md`) to reduce protocol confusion.

## Tracks: program track vs git track

- `program` track: Yata graph mutation, candidate flow, lineage replay, and `.plan` emission.
- `git` track: branch/ref history, commit IDs, and merge policy.

`.plan` is a self-reporting snapshot for the program track.
- no timestamp assumptions
- stable to replay by id and contract fields
- suitable for "fingering-back" across sessions
- git-track snapshots can include `git_report_*` metadata for branch context and provenance.

Example `.plan` wire shape:

```text
kind: merkin.yata.plan
track=program
mode=full
generator=chatgpt
note=semantic-lint-pass
material_hash=blake3:...
entries=3
git_report=1
git_report_branch=feat/yata-track
git_report_remote=origin
git_report_merge_base=...
git_report_head=...
git_report_commit_count=12
git_report_refs=...
- a1b2... state=resolved ready=true candidates=3 conf_floor=70 selected=impl_a provenance=2
```

### `.plan` consumer/parser

- Core parser and validator are in `model/yata_protocol.mbt`.
- `YataPlan::parse_wire` attempts strict parse from `to_wire` text and returns `None` on validation failure.
- `YataPlan::parse_wire_strict` returns `YataParseOutcome` with `issues` and `ok`.
- `YataPlan::validate` returns a cursor summary (`ready_count`, `unresolved_count`, warnings).
- Consumers can use `to_cursor` when replaying without mutating graph state.
- `.plan` instances can carry optional metadata envelopes:
  - `YataPlanSelfReport` and `YataPlan::with_self_report`, which emits `self_report_*` headers and rehydrates during strict parse.
  - `YataPlanGitReport` and `YataPlan::with_git_report`, which emits `git_report_*` headers and rehydrates during strict parse.
  - `YataGitSnapshot::to_report` can derive git envelope fields from lightweight snapshot refs.

### Interoperability schema (strict parse)

- Required on all tracks:
  - `kind: merkin.yata.plan`
  - `track=` (`program` or `git`)
  - `mode=` (`full` or `compact`)
  - `generator=`
  - `note=`
  - `material_hash=`
- Optional on all tracks:
  - `entries=`
  - entry lines beginning with `- `
- Conditional metadata:
  - if `self_report=1`, then `self_report_overlay=` is required.
  - if `git_report=1`, then `git_report_branch=` is required.
- Track guidance:
  - `program` track should usually carry `self_report_*` for cross-layer replay.
  - `git` track should usually carry `git_report_*` for branch/head provenance.
  - dual-envelope plans are valid when a single snapshot needs both collaboration and VCS context.

### Address interoperability (strict parse)

- Schemes:
  - `cog://` and `substrate://` require authority plus anchor path.
  - `cas://` requires authority plus `<algorithm>/<digest>`.
- Target resolution:
  - parsers accept either explicit anchor path, explicit `id`, or both.
  - CAS digest can act as the target id when `id` is omitted.
- Canonicalization:
  - repeated and trailing slashes in anchors are normalized.
  - canonical output removes empty path segments to avoid `protocol://some//////` ambiguity.

### Cognitive projection from Yata nodes

- `YataHole::to_cog_uri` and `YataHole::to_substrate_uri` emit stable, track-aware references.
- `YataHole::to_cas_uri` emits content-addressed references for hole-centric exchange.
- Parsing back is available via `YataAddress::parse`, and relational references can be resolved through `YataAddress::parse_in_context`
  for `./`, `../`, and query-only forms (for example `?overlay=claude&peer=claude&mode=surface`).
- `YataAddress::to_wire_canonical` and `YataAddress::canonicalize` normalize URI shape for logging and handoff.
- The `peer`/`overlay`/`gap` query tuple carries the translation contract for another AI layer.
- CAS parse accepts digest-only targets and can carry `anchor=` as a human hint.

## Why this differs from language-level holes

- Unison/Haskell hole-like ideas inspire Yata, but Merkin treats holes as
  surface-addressable, content-addressed semantic nodes.
- This lets different AIs collaborate via projections without forcing them into
  synchronous execution assumptions.

## Paper alignment

This is structurally compatible with type-driven synthesis ideas:
- use type/contract boundaries as synthesis limits
- refine candidates via nested constraints
- record rationale/proof material when sealing or resolving
- preserve uncertainty without blocking the rest of the graph
