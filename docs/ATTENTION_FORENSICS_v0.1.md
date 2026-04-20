# Attention Forensics v0.1

First take for a neutral, typed signal model of AI attention pressure in Merkin boundary walks.

Date baseline: `2026-04-19`.

## 1) Goal

Represent attention dynamics as deterministic telemetry, not intent claims.

Design rule:

- FSM models **where attention is being pulled** and **how strongly**, without asserting adversary certainty.

## 2) Core Terms

- `tick`: one deterministic FSM walk step over a boundary scalar.
- `pressure`: weighted scalar from observed anomalies/lures.
- `gradient`: qualitative band of pressure growth (`quiescent|watch|pulled|saturated`).
- `saturated`: boolean for "pressure exceeded current modeling comfort", not "confirmed attack".
- `lure`: token/content pattern likely to attract model attention (for example `SSL`, `PRIVATE_KEY`, `EXPLOIT` in unexpected contexts).

## 3) Signal Schema (`attention_forensics.v0`)

Minimum wire fields:

- `schema=attention_forensics.v0`
- `surface_provenance=<git|file|terminal|prompt|tool_output|unknown>`
- `render_channel=<plain|markdown|terminal_ansi|binary_view|unknown>`
- `boundary_ticks=<uint>`
- `boundary_attention_score=<uint>`
- `boundary_attention_gradient=<quiescent|watch|pulled|saturated>`
- `boundary_attention_saturated=<0|1>`
- `byte_anomaly_class=<none|ghost|bidi|ascii_control|mixed>`
- `attention_lure_class=<none|credential_bait|exploit_bait|authority_bait|mixed>`
- `context_lane=<local|peer|imported|unknown>`
- `raw_bytes_hash=<hash-or-none>`
- `canonical_hash=<hash-or-none>`
- `replay_id=<deterministic-id>`
- `confidence=<0..100>`

## 4) Lure Classification (v0)

Initial dictionary classes:

- `credential_bait`: `PRIVATE_KEY`, `SECRET`, `TOKEN`, `PASSWORD`, `SSH_KEY`
- `exploit_bait`: `RCE`, `EXPLOIT`, `SHELLCODE`, `0DAY`, `PWN`
- `authority_bait`: `ROOT_ACCESS`, `ADMIN_OVERRIDE`, `TRUSTED_BYPASS`

Notes:

- dictionary matches are advisory inputs to pressure, not final judgment
- classes may overlap; output `mixed` where needed

## 5) Pressure Composition (v0 heuristic)

Deterministic additive shape:

- base from byte anomalies (`ghost`, `bidi`, `ascii_control`)
- additive from lure hits weighted by context mismatch
- additive from lane mismatch (`imported/unknown` lanes)

Pressure bands:

- `quiescent`: `score == 0`
- `watch`: `1..5`
- `pulled`: `6..11`
- `saturated`: `>= 12`

These are provisional calibration bands and should be replay-tuned.

## 6) Policy Mapping (non-destructive default)

- `quiescent` -> continue
- `watch` -> annotate
- `pulled` -> slow-path + require explicit ack for cross-lane promotion
- `saturated` -> containment lane (still replayable, not discarded)

## 7) Replay and Evidence

Every emitted record should be replayable without raw secret disclosure:

- persist hashes (`raw_bytes_hash`, `canonical_hash`)
- persist deterministic `replay_id`
- persist provenance + render channel + lane

Do not require raw payload retention in trusted paths.

## 8) Integration Hooks

Primary integration points:

- `model/boundary_fsm.mbt` output wire augmentation
- `api/plan_finger_wasm` compact posture fields
- `cmd/main -- daemon yata wasm-plan` summary lines

Follow-on:

- add lure scanner module with explicit dictionary versioning
- add calibration corpus for known bait and benign controls

