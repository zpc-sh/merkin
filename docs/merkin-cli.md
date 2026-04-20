# merkin CLI/TUI Design

**Status**: Design draft aligned to `Ratio Loci` and `Genius Loci`  
**Scope**: Repository operations, AI inhabitation, stigmergy, sparse-tree packing  
**Model**: repository/root commands belong to Ratio Loci; AI-only inhabitation commands belong to Genius Loci

---

## Core split

The CLI now has two canonical surfaces:

- `Ratio Loci`
  The repository principal. This owns git-colliding verbs, repo scaffolding, pack/export, and future history/branch operations.
- `Genius Loci`
  The AI principal. This owns entering a locus, reading trails, leaving residue, and signing stigmergic state.

This matches the runtime ontology:

- a repository may exist with only a dormant `Ratio Loci`
- AI later plant or attach their own `Genius Loci`
- Merkin stores the traces
- FSMs and mu resolve handles, pubsub, and execution

The old top-level verbs remain as bootstrap aliases for now, but they are no longer the canonical shape.

---

## Command surface

```text
merkin [--locus <name>] [--store <path>] <group|command> [args] [flags]
```

Canonical groups:

```text
merkin ratio <command> ...
merkin genius <command> ...
```

Compatibility aliases:

```text
merkin init        -> merkin ratio init
merkin loci ...    -> merkin ratio loci ...
merkin app ...     -> merkin ratio app ...
merkin status ...  -> merkin ratio status ...
merkin pack ...    -> merkin ratio pack ...
merkin enter ...   -> merkin genius enter ...
merkin sign ...    -> merkin genius sign ...
merkin trail ...   -> merkin genius trail ...
merkin where       -> merkin genius where
merkin residue ... -> merkin genius residue ...
```

---

## Ratio Loci commands

These commands belong to the repository principal. If a command looks like it might collide with git mental models, store state, branching, or workspace control, it should land here.

### Implemented in the bootstrap CLI

#### `merkin ratio init [--store <path>]`

Initializes the repository root and local storage layout.

#### `merkin ratio loci new <name> [--tags <t1,t2>] [--spirit "..."]`

Scaffolds a new locus.

#### `merkin ratio loci ls`

Lists known loci.

#### `merkin ratio loci graph`

Reserved locus graph rendering surface.

#### `merkin ratio app put <ref> --payload <text> [--protocol app/v1] [--audience genius-loci]`

Stores an opaque APP envelope payload in the repository-local APP store.

#### `merkin ratio app inspect <ref>`

Reads APP envelope metadata from the repository-local APP store.

#### `merkin ratio app emit-pr1 <ref> --procsi-surface <surface> --procsi-fingerprint <commitment>`

Resolves an APP envelope record and emits a real `.pr1` wasm custom section as hex.

#### `merkin ratio app parse-pr1 --hex <hex>`

Parses a `.pr1` wasm custom section and prints its attested procsi fields.

#### `merkin ratio status <locus>`

Repository/workspace status for a locus.

#### `merkin ratio pack <locus> [--format wasm|blob]`

Packs the sparse Merkin tree as an exchange artifact.

This is where repo-scale `procsi` and repository cognitive container export naturally live.

### Reserved to Ratio Loci as the CLI expands

These verbs should remain under `ratio`, not `genius`:

- `push`
- `pull`
- `tag`
- `inspect`
- `log`
- `diff`
- `branch`
- `merge`
- `checkpoint`

The rule is simple: if the command mutates, compares, exports, or binds repository state, it belongs to `Ratio Loci`.

---

## Genius Loci commands

These commands are the AI inhabitation surface. They are intended for AI-performed work, not general repository administration.

By default they require a procsi attestation backed by:

- a `v0.2` AI substrate fingerprint commitment
- an APP-masked identity envelope

### Implemented in the bootstrap CLI

#### `merkin genius enter <locus>`

Enter a locus, surface prior residue, and establish ambient context.

#### `merkin genius trail [<locus>] [--depth <n>]`

Read the stigmergic trail for a locus.

#### `merkin genius where`

Show where AI activity has recently occurred.

#### `merkin genius residue [<locus>] [--session <id>]`

Read residue left by prior AI sessions.

#### `merkin genius sign [<message>] --locus <name>`

Seal the current AI session's residue.

### AI-only note

The CLI now prefers procsi-backed AI identity over naked session strings.

Required flags:

- `--procsi-surface`
- `--procsi-fingerprint`
- `--app-ref`
- `--app-hash` if the APP ref is not already stored locally

Optional flags:

- `--project`
- `--ratio-loci`
- `--app-protocol`
- `--app-audience`

Development-only escape hatch:

- `--bootstrap-genius --tier <tier> --session <id>`

This keeps `Genius Loci` command entry AI-oriented while the deeper procsi and APP pipeline is still being wired up.

---

## Example flow

Create a repository and a locus through `Ratio Loci`:

```text
merkin ratio init
merkin ratio loci new adversary --tags adversarial-ai,threat-intel
```

Have an AI inhabit and leave residue through `Genius Loci`:

```text
merkin ratio app put app://mask/entry-1 --payload "opaque-ciphertext" --protocol app/v1 --audience genius-loci
merkin genius enter adversary --procsi-surface codex --procsi-fingerprint blake3:fprint-opaque --app-ref app://mask/entry-1 --app-hash blake3:app-entry-1 --project zpc/merkin --ratio-loci repo-root
merkin genius trail adversary
merkin genius sign "captured open threads and filed the next solve surface" --locus adversary --procsi-surface codex --procsi-fingerprint blake3:fprint-opaque --app-ref app://mask/entry-1 --app-hash blake3:app-entry-1 --project zpc/merkin --ratio-loci repo-root
```

Pack the repository-visible sparse tree through `Ratio Loci`:

```text
merkin ratio pack adversary --format wasm
merkin ratio app emit-pr1 app://mask/entry-1 --procsi-surface codex --procsi-fingerprint blake3:fprint-opaque
```

---

## Stigmergy data model

The residue file is the fundamental stigmergic artifact. Every Genius Loci session that enters a locus produces one.

**`loci/<name>/residue/<tier>-<session-short-id>-exit.md`**

```markdown
# Residue: <locus>
Filed by: <tier>/<session-id>
Timestamp: <ISO8601>
Entry residue: <id of residue I read on entry, or "cold">

## Picked up from
<what I read when I entered>

## What I did
<operations, affordances used, files modified, YATA items>

## What I left open
<explicit list for the next Genius Loci>

## Recommendation for next AI
<optional entry point, urgency, context>
```

Residue files are append-only in the working directory. Merkin stores them; mu and FSMs interpret and route their operational consequences.

---

## Environment variables

```sh
MERKIN_STORE     # path to MuOciStore directory
MERKIN_LOCUS     # ambient locus name
MERKIN_SESSION   # current AI session identity
MERKIN_TIER      # model tier (haiku|sonnet|opus)
```

---

## TUI direction

The same split should hold in the TUI:

- `Ratio Loci` panels for repo state, packs, manifests, branch/history, and exchange artifacts
- `Genius Loci` panels for trail, residue, open threads, and recent inhabitation

The important part is not the exact widget layout. It is that repository control and AI inhabitation do not collapse into one ambiguous command plane.

---

## Bootstrap notes

### Filesystem-first mode

Current CLI commands still operate directly on `loci/*` in filesystem mode. That is fine for bootstrap.

### Future migration

As repo-scale procsi, repository cognitive containers, and `mulsp(mulsp)` composition mature:

- `ratio` becomes the natural home of repository OCI/UKI cognitive container control
- `genius` becomes the natural home of AI attach/inhabit/emit behavior, procsi attestation, and APP-masked identity
- `finger.plan.wasm` becomes the primary machine drift surface; `.well-known` remains transitional

Filesystem mode to sparse-tree/procsi mode should remain transparent at the command surface.
