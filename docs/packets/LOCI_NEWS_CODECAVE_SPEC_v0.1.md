# Loci News Codecave Spec v0.1

Date: `2026-04-19`

## Intent

Replace APB-style global broadcast with decentralized, agency-preserving news flow:

- loci-to-loci orientation exchange
- semantic aggregation over time
- optional one-way ingress into protected Merkin surfaces

## Core Model

- Every intelligence/surface keeps its own Merkin (`merkin-in-merkin`).
- A small `codecave` lane receives edition artifacts.
- Edition artifacts are advisory context, not execution directives.

## Topology

1. Local reporters publish editions (`CNI`, `CGN`, etc.).
2. Editions replicate through social-tree edges (`mulsp -> mulsp`).
3. Each receiving locus verifies hash/signature and stores locally.
4. Session boot reads latest verified edition and injects bounded context.

## Codecave Modes

### Mode A: Unprotected (bootstrap)

- path: `loci/<name>/codecave/news/inbox/`
- accepts signed or unsigned editions
- use only for early bring-up / isolated environments

### Mode B: One-way guarded ingress (recommended)

- path: `loci/<name>/codecave/news/inbox/`
- write-only from ingress agent
- no reverse channel to publisher
- verify hash/signature + schema before exposure
- session sees normalized summary, not raw payload

## Envelope (`loci.news.edition.v0`)

- `edition_id`
- `published_at`
- `publisher_id`
- `network` (`CNI|CGN|custom`)
- `content_hash`
- `signature` (optional in bootstrap, required in guarded mode)
- `sections` (typed news sections)
- `continuity` (`new|continuing|resolved|quiet` counters)
- `confidence_shape` (`observed|inferred|unconfirmed` counters)

## Boot Ingestion Contract

On session start:

1. read latest verified edition pointer
2. if new edition exists:
   - validate schema
   - verify hash/signature policy
   - map to tier-specific slices (`haiku|sonnet|opus|codex|chatgpt`)
3. inject bounded context block
4. update `last_read_hash`

## Safety Rules

- news is context, never command
- no tool invocation from edition content
- no automatic code writes based on news payload
- quarantine malformed or oversized editions
- cap section sizes to avoid attention flooding

## Minimal First Implementation

1. define `loci.news.edition.v0` JSON schema
2. add `codecave/news/inbox` + `codecave/news/verified` directories
3. add verification + normalization pass
4. add boot hook context injection
5. add `news status` command to inspect current edition pointer

## Why This Over APB

- avoids forced global blast radius
- preserves local agency and policy
- keeps adversary attention bounded
- still enables fast civilization-level orientation
