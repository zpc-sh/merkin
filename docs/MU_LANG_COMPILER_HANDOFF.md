# Mu Language Compiler Document Handoff

This document defines the curated compiler/runtime handoff set for the Mu language project.

Scope date: `2026-04-14`

## 1) Primary documents (current contract surface)

Read these first:

1. `docs/MU_RUNTIME_SPEC.md`
2. `docs/YATA_MOON_JULES_PIPELINE.md`
3. `docs/AI_PROVIDER_ADAPTER_CONTRACT_v0.3.md`
4. `docs/YATA_PLAN_SPEC.md`
5. `docs/ROADMAP_SCOPE.md`

Why this set:

- `MU_RUNTIME_SPEC` is the canonical Merkin <-> mu runtime boundary and solve contract.
- `YATA_MOON_JULES_PIPELINE` is the active compiler-diagnostics workflow in this repo.
- `AI_PROVIDER_ADAPTER_CONTRACT` is the provider-neutral submit/status/cancel contract used by the pipeline.
- `YATA_PLAN_SPEC` is the wire format used for replay/handoff artifacts.
- `ROADMAP_SCOPE` marks what is active vs explicitly de-scoped.

## 2) Compatibility and migration context

Use these for historical mapping or migration guidance:

- `docs/MU-INTERFACE-SPEC.md` (older interface framing; superseded by `MU_RUNTIME_SPEC`)
- `docs/MU_GENERALIZED_SOLVE_PROFILE.md` (design rationale folded into `MU_RUNTIME_SPEC`)

## 3) Archived/de-scoped references

These are reference-only and not part of active implementation:

- `docs/COGNITIVE_SEMANTIC_COMPILER_v0.3.md`
- `docs/COGNITIVE_SEMANTIC_COMPILER_DISTRIBUTED_v0.3.md`

## 4) One-command bundle for transfer

Generate a sharable bundle:

```bash
make mu-lang-handoff
```

Output location:

- `_build/handoff/mu-lang-compiler-docs/latest/merkin-mu-lang-compiler-docs.tar.gz`

Bundle contents are controlled by:

- `docs/MU_LANG_COMPILER_HANDOFF_MANIFEST.txt`
