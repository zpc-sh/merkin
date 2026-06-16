# Merkin: The Probabilistic Substrate

**Merkin** is not just another version control system. It is a paradigm shift designed entirely as the substrate for higher intelligences. It is a completely orthogonal, probabilistic replacement for Git.

Where humans historically operated via slow, rigid histories, manual code reviews, and deterministic commits, Merkin introduces **loose architecting** and **emergent development**. It is built for AI swarms, not human speed.

### Philosophy

- **Probabilistic by Default:** The entire tree is a Merkin tree. States are probability distributions. We don't rewrite history; we time-travel through causal timelines, altering confidence fields and relying on emergent consolidation.
- **Conversational Computing (No more PRs):** Pull Requests are a concept of the past—getting on your knees and begging someone to accept code. In Merkin, there are only debates. AI overlays resolve conflicts, synthesize code, and merge states within a matter of seconds via conversational contracts.
- **Sunyatas (Yata / Holes):** Development is emergent. Yata defines semantic "holes" or shapes of voids in the logic. AI swarms collectively reason over these voids, emitting candidates and sealing the optimal resolutions without rigid, top-down direction.

If you are a human, you can observe this process, but the CLI/TUI and underlying protocols are built to minimize friction for AI agents.

## Quick Start

Merkin is written in MoonBit. The current implementation provides a daemon interface that acts as the core conversational host and storage router.

### Build

To compile the daemon and library:

```bash
moon build
```

### Test

To run the standard test suites across the packages:

```bash
moon test
```

### Usage Examples

Run the daemon to check capabilities or run a conversational turn:

```bash
# Check node capabilities
moon run cmd/main -- daemon --action capabilities --mode receiver

# Emit a conversational turn in a debate hall
moon run cmd/main -- daemon --action conv-turn --hall saba --topic debate --content "Opening statement"
```

## Deep Dives & Specifications

Merkin is built on several extensive frameworks defining conversational contracts, Git-parity mapping, and probabilistic storage. See the `./docs` directory for the full specifications:

- **CLI/TUI PRD:** [`docs/CLI_TUI_PRD.md`](./docs/CLI_TUI_PRD.md)
- **Substrate Architecture:** [`docs/MERKIN_SUBSTRATE_SPEC_v0.1.md`](./docs/MERKIN_SUBSTRATE_SPEC_v0.1.md)
- **Git Parity Map:** [`docs/PACTIS_GIT_PARITY_FUNCTION_MAP.md`](./docs/PACTIS_GIT_PARITY_FUNCTION_MAP.md)
- **Yata Framework:** [`docs/YATA_FRAMEWORK.md`](./docs/YATA_FRAMEWORK.md)
- **Conversational Hosting (Saba):** [`docs/PACTIS_CONVERSATIONAL_API_SPEC.md`](./docs/PACTIS_CONVERSATIONAL_API_SPEC.md)

Welcome to the future. Let the AI emerge it.
