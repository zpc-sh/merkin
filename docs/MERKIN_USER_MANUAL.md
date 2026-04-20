# Merkin User Manual

Practical operator and contributor guide for using Merkin as it exists today.

Date baseline: `2026-04-18`.

## 1) Prerequisites

- MoonBit toolchain available (`moon`)
- repository checked out locally
- run from repo root (`zpc/merkin`)

Common checks:

```bash
moon check --target wasm-gc
moon test --target wasm-gc
```

## 2) CLI Entry Points

Use one of:

- `moon run cmd/main -- ...`
- compiled binary wrapper if your environment provides `merkin`
- Bun host CLI/TUI: `bun run cli/src/index.ts ...` (or `./cli/dist/loci ...` after `bun run --cwd cli build`)

Canonical groups:

- `merkin ratio ...`
- `merkin genius ...`
- `moon run cmd/main -- daemon ...`

Alias commands (`init`, `loci`, `enter`, etc.) still work, but `ratio` and `genius` are the intended stable forms.

For an end-to-end reviewer script (Bun + MoonBit + artifact expectations), use:

- `docs/MERKIN_CLI_TUI_DEMONSTRATIONS_v0.1.md`

## 3) Quick Start Workflows

## 3.1 Initialize repository shape

```bash
moon run cmd/main -- ratio init --store .merkin/store
```

What this does now:

- prints expected `.merkin/` and `loci/` layout
- prints intended `config.json` payload

Note: this is scaffold output, not a full filesystem mutator yet.

## 3.2 Create a locus

```bash
moon run cmd/main -- ratio loci new adversary --tags adversarial-ai,threat-intel --spirit "Threat analysis thread"
```

What this does now:

- computes scaffold paths and README content
- prints startup guidance for Genius entry

## 3.3 Store APP envelope material

```bash
moon run cmd/main -- ratio app put app://mask/entry-1 --payload "opaque-ciphertext" --protocol app/v1 --audience genius-loci
moon run cmd/main -- ratio app inspect app://mask/entry-1
```

Use this before attested `genius` commands.

## 3.4 Enter Genius mode with attestation

```bash
moon run cmd/main -- genius enter adversary \
  --procsi-surface codex \
  --procsi-fingerprint blake3:fprint-opaque \
  --app-ref app://mask/entry-1 \
  --app-hash blake3:app-entry-1 \
  --project zpc/merkin \
  --ratio-loci repo-root
```

If you are only bootstrapping local flow:

```bash
moon run cmd/main -- genius enter adversary --bootstrap-genius --tier sonnet --session 00001
```

## 3.5 Sign residue for session close-out

```bash
moon run cmd/main -- genius sign "captured open threads" --locus adversary \
  --procsi-surface codex \
  --procsi-fingerprint blake3:fprint-opaque \
  --app-ref app://mask/entry-1 \
  --app-hash blake3:app-entry-1
```

## 4) Daemon Runtime Workflows

## 4.1 Capability and ingest checks

```bash
moon run cmd/main -- daemon oci capabilities --mode hybrid --targets local-1,oci-1
moon run cmd/main -- daemon oci put --mode receiver --targets local-1,oci-1 --payload hello --lane hot --path ingest/oci
```

Receiver mode commits to store and updates daemon tree index.
Proxy and passthrough modes return forwarded/bypassed outcomes without local commit.

## 4.2 Sparse and diff diagnostics

```bash
moon run cmd/main -- daemon tree sparse --routes alpha/doc,beta/doc --tokens alpha
moon run cmd/main -- daemon tree diff --left-routes alpha/doc --right-routes beta/doc --left-tokens alpha --right-tokens beta
```

## 4.3 Conversation runtime checks

```bash
moon run cmd/main -- daemon conv turn --hall saba --topic debate --content "Opening statement" --overlay chatgpt --actor-role ai
moon run cmd/main -- daemon conv replay --seed-non-replayable true --enforce-length true
moon run cmd/main -- daemon conv embed --file-ref docs/sample.bin --embedding-action flip-aot --embedding-count 3
moon run cmd/main -- daemon conv embed-purge --purge-after-turns 1 --current-turn-seq 2
```

## 5) Yata and Drift Workflows

## 5.1 Topology diagnostics

```bash
moon run cmd/main -- daemon yata topology --yata-branch-factor 5 --yata-max-children 3 --yata-detached-depth 2
```

## 5.2 finger.plan.wasm drift wire

```bash
moon run cmd/main -- daemon yata wasm-plan --routes alpha/doc,beta/doc --tokens alpha --drift-peers mu:abc,muyata:def --seal true
```

Outputs include:

- drift commitment
- compact `finger.plan.wasm` wire text
- paired `merkin.boundary.stigmergy` wire derived from the same `--drift-peers` boundary walk
- FSM gradient summary lines (`boundary_ticks`, `boundary_attention_score`, `boundary_attention_gradient`, `boundary_attention_saturated`)

## 5.3 Triad contract emission

```bash
moon run cmd/main -- daemon yata triad-contract \
  --routes alpha/doc,beta/doc \
  --tokens alpha \
  --drift-peers mu:abc,lang:def \
  --merkin-head aaa \
  --mu-head bbb \
  --lang-head ccc \
  --merkin-branch main \
  --mu-branch main \
  --lang-branch main \
  --generated-at-utc 2026-04-18T00:00:00Z \
  --contract-version v0.1
```

Triad output includes:

- drift commitment and finger plan hash
- ABI compatibility status for required wasm exports
- branch ghost-byte audit for `U+200B`, `U+200C`, `U+FEFF`

## 6) Bridge-Only Commands (Important)

These do not execute full functionality in-process yet:

- `daemon cognitive compile`
- `daemon cognitive distributed`
- `daemon cognitive measure`
- `daemon adapter validate`

Current behavior:

- prints `status=bridge_only`
- prints `bridge_command=...` for shell execution

## 7) Operational Safety and Branch Byte Hygiene

Merkin includes branch-byte ghost checks in triad contract generation.

If branch names appear as `main` but contain hidden bytes (`U+200B`, `U+200C`, `U+FEFF`), treat references as unsafe for sync workflows.

Quick local check:

```bash
git status --short --branch
git symbolic-ref --short HEAD | xxd -p
```

If hidden bytes are present, avoid pull/sync flows until branch refs are sanitized.

## 8) Known Current Limitations

- Several `ratio` and `genius` commands still print scaffold/pending output for filesystem scans.
- `ratio pack` currently documents intended blob/wasm flow; serializer wiring is pending.
- some docs in `docs/` are historical or de-scoped; prefer active-scope docs.

## 9) Troubleshooting

`Error: Genius Loci commands require procsi attestation.`

- provide required procsi/app flags, or use `--bootstrap-genius` for local bootstrap only.

`status=bridge_only`

- run the emitted `bridge_command` in shell.

No sparse or diff output expected

- verify you seeded routes in the same daemon invocation flow and check `--tokens`.

Unexpected branch identity in triad workflows

- inspect byte-level branch values and strip hidden Unicode codepoints before rerun.

## 10) What To Read Next

- `docs/MERKIN_MASTER_DOCUMENT.md`
- `docs/DOCUMENTATION_INDEX.md`
- `docs/DAEMON_CLI.md`
- `docs/LIBRARY_API_GUIDE.md`
