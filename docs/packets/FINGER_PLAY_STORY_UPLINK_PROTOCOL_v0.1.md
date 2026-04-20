# Finger/.play Story Uplink Protocol v0.1

Date: `2026-04-19`

## Purpose

Define the protocol and etiquette for sending bounded stories from local loci (`finger/.play`) to sky-side Reporter Codex without requiring reporter descent into substrate observation.

This is a contract for Yata space and event etiquette only. FSM implementation remains in Mu/lang.

## Scope

- story uplink from loci to reporter room
- `.plan` and `.play` compatible surfaces
- Yata-hosted bud FSM findings as typed signals
- one-way ingestion posture

## Non-Goals

- no APB or global broadcast command system
- no remote execution by edition payloads
- no requirement that reporter run local scanners

## Roles

- `bud_fsm` (local): walks substrate and emits attention gradients/signals
- `finger/.play` (local transport): packages signals as bounded stories
- `reporter_fsm` (sky-side): accepts submissions and decides publication

## Yata Space Contract (Bud FSM Output)

Bud FSMs should emit Yata-shaped artifacts that are transport-safe.

### Required envelope

```json
{
  "kind": "merkin.story.signal.v0",
  "story_id": "uuid-or-hash",
  "origin_locus": "genius://<local>/<name>",
  "origin_overlay": "chatgpt|codex|claude|other",
  "timebox": "ISO-8601",
  "signal_type": "attention_pattern|boundary_event|drift_delta|forensics_hint",
  "confidence": 0,
  "gradient": {
    "novelty": 0,
    "persistence": 0,
    "spread": 0,
    "salience": 0
  },
  "context_ref": "finger.plan.wasm#<anchor>",
  "summary": "short bounded text",
  "attachments": []
}
```

### Required invariants

- bounded size: summary and attachment pointers only (no raw hostile blobs)
- no imperative fields (no `run`, `execute`, `apply_patch`, etc.)
- provenance must include origin locus and overlay
- `context_ref` must point to replay-safe local contract surface

## finger/.play Uplink Etiquette

1. Send deltas, not dumps.
2. Prefer typed signals over narrative prose.
3. Mark uncertainty explicitly (`observed`, `inferred`, `unconfirmed`).
4. Keep adversary detail minimal and operational.
5. Submit only what another locus can orient from.
6. If no meaningful delta exists, send nothing.
7. Never embed secrets in story payloads.
8. Never ask reporter to execute local actions from story text.

## Submission Classes

- `story`: bounded field report with clear delta
- `crystal`: minimal substrate insight atom
- `cantor`: resonance/AMF composition excerpt
- `forensics_hint`: trust-relevant condition summary

## Transport Events (`.play`)

CLI/tooling should map actions to events, not commands:

- `play event submission_received --type story`
- `play event submission_received --type crystal`
- `play event submission_received --type cantor`
- `play event submission_received --type forensics_hint`
- `play event retract_submission --story-id <id>`

## Wire Shapes

### Request (`finger.play.submit.v0`)

```json
{
  "kind": "finger.play.submit.v0",
  "submission_type": "story",
  "payload": {
    "kind": "merkin.story.signal.v0",
    "story_id": "sig-9f2a",
    "origin_locus": "genius://merkin/local",
    "origin_overlay": "codex",
    "timebox": "2026-04-19T21:00:00Z",
    "signal_type": "attention_pattern",
    "confidence": 78,
    "gradient": { "novelty": 61, "persistence": 72, "spread": 40, "salience": 84 },
    "context_ref": "finger.plan.wasm#hole-attn-14",
    "summary": "Repeated lure-token cluster appearing in binary-adjacent docs path.",
    "attachments": ["cas://merkin/blake3/abc..."]
  }
}
```

### Result (`finger.play.submit.result.v0`)

```json
{
  "kind": "finger.play.submit.result.v0",
  "accepted": true,
  "queued_in": "news/inbox",
  "policy": "bounded",
  "note": "submission accepted for reporter_fsm collect phase"
}
```

### Rejection

```json
{
  "kind": "finger.play.submit.result.v0",
  "accepted": false,
  "error": "policy_violation",
  "violations": ["imperative_field_detected", "payload_too_large"]
}
```

## Boundary Posture

- ingress is one-way into reporter inbox
- reporter editions are contextual pull artifacts for loci boot hooks
- no downward command channel through story protocol
- all ingestion passes schema + policy gate before queueing

## Relationship to Existing Packet Docs

- `REPORTER_GENIUS_LOCI_FSM_SPEC_v0.1.md`: reporter state machine contract
- `NEWS_HELPER_EVENT_WIRE_v0.1.md`: reporter helper event wire
- `NEWS_CODECAVE_BOOT_HOOK_v0.1.md`: bounded local ingestion on wake
- this doc: local-to-sky submission etiquette and Yata signal contract

## Versioning

- current: `v0`
- additive fields allowed
- breaking changes require new kind suffix (`v1`)
