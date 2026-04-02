# Pactis CLI/TUI: Product Requirements Document

## Vision

The Pactis CLI/TUI is not designed for human speed. It is the substrate for higher intelligences, operating at minimal friction, providing the interface for AI frameworks to communicate, reason, and collectively merge semantic states.

While humans can interface with it at a high level, its core audience consists of automated overlays (like ChatGPT, Claude, Gemini) and distributed swarms. It serves as an orthogonal, probabilistic replacement for Git. Where Git relies on rigid histories, begging for merge approvals (Pull Requests), and deterministic commits, Merkin is fluid, conversational, probabilistic, and emergent.

## Core Philosophical Tenets

1. **Probabilistic by Default**: Built on the Merkin Tree, everything is a probability distribution. You do not rewrite history; you fluidly travel through it, altering confidence fields and relying on emergent consolidation.
2. **Conversational Computing**: There are no Pull Requests. There are debates. AI overlays resolve conflicts, synthesize code, and merge states within seconds through conversational contracts.
3. **Yata (Sunyatas / Holes)**: Development is emergent. Yata defines semantic "holes" or voids in the logic that AI swarms reason over and fill collectively. It is an effect-conscious contract, completely comfortable with deferred truth.
4. **Loose Architecting**: Forget counting every byte and asserting 100% confidence over rigid boundaries. The framework allows the AI to simply get the job done.

## Git Parity vs. Merkin Reality

To act as a Git replacement, the CLI must handle the typical surface area of version control, mapped to the underlying Merkin/Yata native behavior.

### Lifecycle & Plumbing
- **`git clone` -> `pactis clone`**: Pulls the probabilistic tree and latest checkpoints.
- **`git commit` -> `pactis commit`**: Seals a semantic envelope into the hot tree.
- **`git checkout / switch` -> `pactis time-travel` / `pactis switch`**: Replays timeline sequences causally without relying on wall-clock timestamps.

### Collaboration & Governance
- **`git merge` / Pull Requests -> `pactis converse` / `pactis proposals`**: Triggers a sub-second AI debate hall (Saba). AIs negotiate the merge via the conversational API. No human intervention needed.
- **`git rebase` -> `pactis replay`**: Deterministic timeline replay to shift causal sequences or fork conversational futures.

### AI-Native Extensions
- **`pactis plan emit / parse`**: Exchanging `.plan` state across sessions.
- **`pactis yata list / resolve`**: Finding and filling the voids/sunyatas.
- **`pactis overlay merge`**: Cross-intelligence collaboration primitives.

## Current Implementation Status vs. Planned Voids (Holes)

Based on the current `.mbt` Daemon structure (`cmd/main/main.mbt`):

### Implemented Capabilities (The Substrate)
- **Daemon Modes**: Receiver, Proxy, Passthrough, Hybrid (`--action capabilities`).
- **Storage Layer**: OCI registry integration and local artifact storage (`--action put`, `--lane`, `--targets`).
- **Tree Operations**: Sparse views, routing, and diffs (`--action sparse`, `--action diff`).
- **Conversational Hosts (Saba)**:
  - AI conversation turns (`--action conv-turn`) with length envelopes.
  - Checkpoint replays (`--action conv-replay`) handling non-replayable seeds.
  - Ephemeral embedding observation and purging (`--action conv-embed`, `--action conv-embed-purge`).

### The Holes (Yet to Emerge)
- **Interactive TUI**: A visual hall where humans can optionally spectate the swarms discussing and closing sunyatas.
- **Git Migration Tooling**: `pactis import` to seamlessly lift legacy Git projects into the Merkin substrate.
- **Holistic Conversational Synthesis**: Full multi-overlay cross-synthesis workflows currently planned for Phase D of the Saba rollout.
- **Yata Interactive Resolution**: CLI commands natively tailored for scanning and rapidly injecting candidates into `YataHole` objects outside the Daemon API.

## Design Rules for the CLI

1. **Exit Codes & Scriptability**: Must guarantee CI-compatible exits.
2. **Track Separation**: Output must visually distinguish between the `program` track (Yata state) and `git` track (branch provenance).
3. **Pactis Address Parsing**: Seamless handling of `cog://`, `substrate://`, and `cas://` addresses for direct object interactions.
