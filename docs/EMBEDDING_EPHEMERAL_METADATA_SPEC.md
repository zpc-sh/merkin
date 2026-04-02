# Embedding Ephemeral Metadata Spec (v0.1-draft)

This document defines how Merkin/Yata tracks potential malicious embeddings across arbitrary file types while supporting ahead-of-time flipping and ephemeral purge.

## 1. Scope

- Any file type is eligible (`pdf`, `png`, `docx`, `zip`, binary blobs, etc.).
- Metadata is content-layer and transport-layer independent.
- Findings can be attached to `.plan` and to standalone file annotations.

## 2. Core model

From `model/embedding_metadata.mbt`:

- `EmbeddingFinding`
  - detector id
  - signature token
  - byte offsets
  - confidence
- `EmbeddingMetadata`
  - `file_ref`
  - `file_type`
  - `mime_type`
  - `found`
  - `findings[]`
  - `action`: `Observe | FlipAot | Purge`
  - `ephemeral`
  - `purge_after_turns`
  - `note`

## 3. Recommended lifecycle

1. `Observe`: scan and attach findings.
2. `FlipAot`: transform risky embedding vectors to inert semantic-safe equivalents before AI ingestion.
3. `Purge`: remove transient embedding traces based on causal turn age.

## 4. Purge semantics

- Ephemeral mode is default.
- `should_purge(turn_age)` evaluates against `purge_after_turns`.
- Purge is causal-turn based, not filesystem timestamp based.

## 5. `.plan` integration

`.plan` can carry one embedding summary envelope:

- `embedding_report=1`
- `embedding_report_file_type=...`
- `embedding_report_found=true|false`
- `embedding_report_count=<uint>`
- `embedding_report_ephemeral=true|false`
- `embedding_report_purge_after_turns=<uint>`
- `embedding_report_strategy=observe|flip-aot|purge`

This report is a compact transport envelope; detailed findings stay in artifact-local metadata.

## 6. Threat-model notes

- The system does not assume complete detection certainty.
- Findings are probabilistic signals; workflow should remain fail-safe.
- Flipping and purge policies should be auditable through `.plan` and thread checkpoints.
