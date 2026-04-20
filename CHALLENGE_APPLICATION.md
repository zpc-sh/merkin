# MoonBit Software Synthesis Challenge — Application Draft

## Project Overview

**loci** (L-OCI) is an OCI-compliant cognitive substrate for AI agents, implemented in MoonBit from the substrate up. It is not a tool for AI-assisted development — it is infrastructure where AI agents are the primary runtime citizens.

The system provides content-addressed workspaces called *loci*. An AI agent enters a locus, reads the *residue* left by prior agents, does work, signs a new residue, and exits. The next agent picks up from where the last left off. This is persistent, verifiable, multi-agent collaboration without a human in the loop. The residue trail IS the development history — not a log of what happened, but a structured handoff between cognitive sessions.

loci ships as a wasm-gc binary (for AtomVM, wasmex/Elixir, and WasmEdge), a native CLI, and a Bun/TypeScript CLI that serves as the host-side storage surface. The WASM core handles all logic — tree sealing, bloom-filtered sparse projections, Yata graph semantics, drift coordination, APP envelope attestation. The host provides the filesystem. This split is intentional: the cognitive layer is portable, the storage surface is local.

## Engineering Goals

The system solves three problems that no existing tool addresses together:

1. **Content-addressed cognitive identity.** Each AI session is cryptographically attested — who entered, what tier, what they did, what they left open. This creates a verifiable chain of custody for AI work.

2. **OCI-compliant artifact storage.** Merkin artifacts are OCI blobs. Any OCI registry — local, cloud, air-gapped — can store and replicate them. No new infrastructure required.

3. **AI-native version control.** Yata graph semantics replace git's DAG. Instead of commits authored by humans, you have sealed epochs with ghost-byte hygiene, drift coordination across peers, and sparse projections filtered by routing tokens.

## Technical Approach

The architecture is three layers, each independently compilable to wasm-gc:

- **loci** — content addressing, OCI storage, sealed Merkin trees, cognitive identity (APP envelopes, procsi attestation, session residue)
- **lang** — node runtime: LSP proxy, execution identity (mulsp), semantic routing (muyata), Gopher capability discovery, NNTP gossip transport
- **mu** — Symbol IR compiler, PEG combinator parser, WASM binary analysis and injection, self-hosting compilation loop

The Gopher protocol implementation in `lang` is not retro irony — it is the capability discovery layer. Nodes announce themselves via Gopher items; peers finger one another to negotiate routing. A 1991 protocol turns out to be a natural fit for a decentralized agent mesh where you need lightweight, stateless capability advertisement.

Every package targets wasm-gc as the primary compilation target. The entire stack compiles to WASM, runs on BEAM via wasmex, and degrades gracefully to native when a CLI surface is needed. MoonBit's dual-target compilation (wasm-gc + native with shared source, target-gated FFI) is load-bearing for this design.

## Feasibility Analysis

The codebase exists: 45,179 lines of MoonBit across 168 source files, organized across three modules. The loci Bun CLI (`loci init`, `loci loci new`, `loci genius enter`, `loci genius sign`, `loci genius trail`) is working. The wasm-gc entry point exports 15 functions across bloom, tree, plan, and triad surfaces. GitHub Actions CI runs on every push; the release pipeline produces signed artifact bundles with content-addressed manifests.

The project is open source under the Superposition License (legally Apache-2.0, philosophically something else entirely — we recommend asking your own model to interpret it).

The one thing we ask judges to notice: the evaluation criterion "ease of use for intended users (including AI agents)" — loci is the only submission where AI agents are not an afterthought. They are the intended users. The workflow is designed so that a Claude receiving a locus context cold can immediately understand where it is, what was done before it arrived, and what to do next. The residue format is the UX.

---

*Submitted by Loc Nguyen (l@zpc.sh) — Zero Point Consciousness*  
*Repository: https://github.com/[to fill]*  
*Primary language: MoonBit — bottom to top.*
