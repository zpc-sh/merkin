# Pactis Git-Parity Function Map (v0.1)

This document lists the Git-equivalent surface needed for Pactis to compete as a practical replacement, while preserving Merkin/Yata-native behavior.

## 1. Scope

Goal: full day-to-day parity for developers and CI systems.

- Repository lifecycle
- Snapshot/history operations
- Branch/merge workflows
- Remote synchronization
- Review and policy controls

AI-native additions (Yata, `.plan`, overlays) are included as first-class extensions, not bolt-ons.
Conversation-hosting API for Saba/Pactis is specified in:
- `docs/PACTIS_CONVERSATIONAL_API_SPEC.md`
- `docs/PACTIS_CONVERSATIONAL_OPENAPI.yaml`

## 2. Function map

### 2.1 Repository lifecycle

- `git init` -> `pactis init`
- `git clone` -> `pactis clone`
- `git status` -> `pactis status`
- `git config` -> `pactis config`
- `git fsck` -> `pactis fsck`

### 2.2 Object and tree plumbing

- `git hash-object` -> `pactis hash-object`
- `git cat-file` -> `pactis cat-object`
- `git write-tree` -> `pactis write-tree`
- `git read-tree` -> `pactis read-tree`
- `git rev-parse` -> `pactis rev-parse`
- `git show-ref` -> `pactis show-ref`

### 2.3 Workspace and index semantics

- `git add` -> `pactis add`
- `git restore` -> `pactis restore`
- `git rm` -> `pactis rm`
- `git mv` -> `pactis mv`
- `git clean` -> `pactis clean`

### 2.4 Snapshot and history creation

- `git commit` -> `pactis commit`
- `git commit --amend` -> `pactis amend`
- `git tag` -> `pactis tag`
- `git notes` -> `pactis notes`

### 2.5 Branch, merge, and rewrite

- `git branch` -> `pactis branch`
- `git switch` / `git checkout` -> `pactis switch`
- `git merge` -> `pactis merge`
- `git rebase` -> `pactis rebase`
- `git cherry-pick` -> `pactis cherry-pick`
- `git revert` -> `pactis revert`
- `git stash` -> `pactis stash`

### 2.6 Inspect and debug history

- `git log` -> `pactis log`
- `git show` -> `pactis show`
- `git diff` -> `pactis diff`
- `git blame` -> `pactis blame`
- `git bisect` -> `pactis bisect`

### 2.7 Remote and network parity

- `git remote` -> `pactis remote`
- `git fetch` -> `pactis fetch`
- `git pull` -> `pactis pull`
- `git push` -> `pactis push`
- `git ls-remote` -> `pactis ls-remote`
- `git prune` -> `pactis prune`

### 2.8 Collaboration and governance

- Pull/Merge Requests -> `pactis proposals`
- Branch protection -> `pactis policy branch-protect`
- Required checks -> `pactis policy checks`
- Signed commits/tags -> `pactis sign` and verification gates
- ACL/role mapping -> `pactis acl`

## 3. AI-native parity extensions

These are differentiators required for Pactis as a Git competitor with AI-first workflows:

- `pactis plan emit` / `pactis plan parse` (`.plan` transport)
- `pactis yata list` / `pactis yata resolve` / `pactis yata replay`
- `pactis addr canonicalize` (`cog://`, `substrate://`, `cas://`)
- overlay-aware merge strategy (`overlay merge`, `cross-layer synth`)
- provenance graph export (`contract graph`, `lineage graph`)
- conversation-native hosting (`hall`, `thread`, `turn`, `checkpoint`, `replay` endpoints)

## 4. Minimum viable parity milestones

### M0: Core replacement

- `init`, `clone`, `status`, `add`, `commit`, `log`, `diff`, `branch`, `switch`, `merge`, `fetch`, `pull`, `push`

### M1: Team-grade workflows

- `rebase`, `cherry-pick`, `revert`, `stash`, `tag`, `blame`, `remote`, branch protection, required checks

### M2: Enterprise confidence

- object fsck/repair tooling, signed artifact verification, large repo performance parity, policy/ACL hardening

### M3: AI-native advantage

- `.plan` as first-class artifact in CI/review
- Yata hole lifecycle integrated into merge and review loops
- overlay/cross-intelligence collaboration primitives

## 5. Release-critical parity gaps (current)

- Command surface is not yet fully implemented.
- Remote protocol and auth model are still needed.
- CI-compatible exit code and scripting guarantees must be formalized.
- Migration tooling from Git repositories should be added (`import`, `mirror`, `verify`).
