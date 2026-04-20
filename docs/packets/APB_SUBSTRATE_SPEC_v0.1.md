# APB Substrate Spec v0.1

Date: `2026-04-19`

## Purpose

All Points Bulletin (APB) for adversary-pattern tracking across Merkin-compatible substrates without breaking agent agency.

## Core Principle

- Track patterns and provenance, not identity coercion.
- Preserve local autonomy (`agency`) while sharing deterministic threat signals.

## Required Constructs

- `merkin-in-merkin`: each response workspace maintains its own local Merkin boundary.
- `ratio_loci`: shared contract surface for cross-provider signal exchange.
- `finger.plan.wasm` + boundary stigmergy as transport-neutral machine wire.

## APB Signal Envelope (`apb.signal.v0`)

- `signal_id`
- `origin_loci`
- `surface_provenance` (`git|file|terminal|prompt|tool_output|unknown`)
- `byte_anomaly_class` (`none|ghost|bidi|ascii_control|mixed`)
- `attention_lure_class` (`none|credential_bait|exploit_bait|authority_bait|mixed`)
- `boundary_attention_score`
- `boundary_attention_gradient` (`quiescent|watch|pulled|saturated`)
- `boundary_attention_saturated` (`0|1`)
- `replay_id`
- `raw_bytes_hash`
- `canonical_hash`
- `confidence`
- `ttl`

## Agency-Preserving Rules

- APB signals are advisory by default.
- Receiving loci may choose `observe|annotate|slow-path|contain`.
- No forced remote code execution or remote mutation.
- No raw secret payload sharing; hashes + replay ids only.

## Escalation Bands

- `watch`: log + annotate.
- `pulled`: slow-path + explicit acknowledgement for promotion.
- `saturated`: containment lane + incident coordination trigger.

## Success Criteria

- Cross-provider replayability.
- Deterministic hashes for chain-of-custody.
- Containment without collapsing normal developer workflows.
