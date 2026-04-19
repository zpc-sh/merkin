# Git Ghost Hardening Runbook

Operational runbook for hidden-byte branch names and potentially hostile git history/object surfaces.

Date baseline: `2026-04-18`.

## 1) Threat Model

Known risk in this repo context:

- branch/ref strings may visually appear normal but contain hidden bytes (`U+200B`, `U+200C`, `U+FEFF`)
- object history may include payloads you do not want shells/tools to evaluate

Principle: treat git strings as bytes, not as trusted text.

## 2) Immediate Safe Checks

Show current branch as bytes:

```bash
git symbolic-ref --short HEAD | xxd -g 1 -u -p
```

Show status branch line (visual only; not authoritative):

```bash
git status --short --branch
```

Do not trust visual equivalence to `main`.

## 3) Clean-Room Operating Mode

Until refs are sanitized:

- do not `git pull` from this checkout
- avoid automation that shells branch names without byte validation
- avoid commands that mutate refs based on visually parsed branch names

## 4) Recommended Remediation Strategy

1. Create a clean-room clone from a trusted remote or trusted bare mirror.
2. Validate branch refs as bytes before checkout.
3. Migrate only needed branches/changelists.
4. Archive or quarantine this checkout for forensics.

If a full history rewrite is required:

- do it in an isolated repo copy
- script deterministic filters
- keep an immutable backup before rewrite
- force-push only after team sign-off and downstream impact plan

## 5) High-Risk Actions Requiring Explicit Approval

- deleting git history
- force-pushing rewritten default branch
- object-pruning/destructive gc on the only working copy

Treat these as coordinated maintenance windows, not ad-hoc shell actions.

## 6) Merkin-Specific Alignment

Merkin triad contract generation already includes byte-level ghost audit for:

- `U+200B`
- `U+200C`
- `U+FEFF`

Use triad outputs as additional signal, but still perform raw git byte checks locally before trust decisions.
