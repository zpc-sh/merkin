# zpc/merkin

Merkin is a MoonBit substrate for deterministic hashing, tree sealing, storage policy control, daemon workflows, and Yata graph semantics.

## Documentation hub

If you're looking for "where everything is", start here:

- `docs/MERKIN_MASTER_DOCUMENT.md` — cohesive project-wide current-state reference
- `docs/MERKIN_USER_MANUAL.md` — practical usage and operations manual
- `docs/MERKIN_PACK_STANDARD_v0.1.md` — pack standard and implementation-state reference
- `docs/GIT_GHOST_HARDENING_RUNBOOK.md` — git byte-hygiene and hardening runbook
- `docs/RATIO_BOUNDARY_SHIM_SPEC_v0.1.md` — design for git boundary filtering into Merkin
- `docs/MERKIN_COMPOSITION_PRIMITIVES_v0.1.md` — composition maneuvers (`consume|union|atop`) and invariants
- `docs/MERKIN_API_REFERENCE_v0.1.md` — consolidated API reference (library/CLI/daemon/WASM/Pactis alignment)
- `docs/YATA_CONTRACT_LANGUAGE_PROFILE_v0.1.md` — Yata contract language profile for compiler/runtime integrations
- `docs/BOUNDARY_WALKER_FSM_v0.1.md` — first boundary FSM for bidi/ghost markup and stigmergy emission
- `docs/MERKIN_CLI_TUI_DEMONSTRATIONS_v0.1.md` — contest-friendly Bun/TS + MoonBit demo script and artifact walkthrough
- `docs/DOCUMENTATION_INDEX.md` — full documentation map by use-case
- `docs/ROADMAP_SCOPE.md` — active scope and de-scoped tracks
- `docs/LIBRARY_API_GUIDE.md` — library-first usage guide
- `docs/DAEMON_CLI.md` — CLI commands and flags
- `docs/YATA_MOON_JULES_PIPELINE.md` — moon build diagnostics -> Yata holes -> Jules tasks

## Fastest adoption path (lazy tree mode)

If you want the minimal approach, treat Merkin as a deterministic tree pipeline:

1. hash payload bytes with `@hash.Hash::of_bytes`
2. ingest ids into `@tree.MerkinTree`
3. seal epochs with `MerkinTree::seal`

Then adopt policy/daemon/Yata layers only when you need them.

## Repository layout

- `hash/` — deterministic digest primitives
- `bloom/` — bloom filter implementation and tests
- `gaussian/` — salience field implementation and tests
- `tree/` — tree, sparse projection, and diff logic
- `model/` — artifacts, envelopes, anchors, Yata graph models
- `store/` — in-memory artifact storage behavior
- `storage/` — queue + OCI storage adapters and policy logic
- `daemon/` — daemon runtime and conversation scaffolding
- `triad/` — typed triad-contract emission wrapper (`merkin` + `mu` + `lang`)
- `conformance/` — profile-based conformance and benchmark checks
- `cmd/main/` — CLI entry point
- `docs/` — specifications, API docs, and release docs

## Testing and benchmarking

Primary commands (when MoonBit tooling is available):

```bash
moon test
moon bench -p zpc/merkin/conformance
moon bench
```

More detail: `docs/TESTING_AND_BENCHMARKING.md`.
