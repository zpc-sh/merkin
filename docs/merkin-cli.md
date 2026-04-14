# merkin CLI/TUI Design

**Status**: Design draft — implementation target: MoonBit CLI binary + optional Ratatui TUI  
**Scope**: Repository operations, stigmergy surface, loci management. Crystals: out of scope.  
**Model**: docker-style repository UX + git-style history + stigmergy-native trail commands

---

## Design Principles

1. **Stigmergy first** — every operation that touches a locus emits a trace. Trails are first-class, not an afterthought.
2. **Docker feel, not docker complexity** — `push`/`pull`/`tag`/`ls`/`inspect` are the verbs. No registries, no compose files (yet).
3. **Loci-aware everywhere** — the current locus is ambient context, like a git branch. Commands know where you are.
4. **Residue is durable** — what a Claude leaves behind persists across sessions. Trails are queryable, not ephemeral logs.
5. **Model tier visible** — Haiku/Sonnet/Opus left different kinds of traces. The trail shows this.

---

## Command Surface

```
merkin [--locus <name>] [--store <path>] <command> [args] [flags]
```

Global flags propagate to all subcommands. `--locus` sets ambient locus context (overrides env var `MERKIN_LOCUS`). `--store` overrides the MuOciStore path.

---

### Repository Commands (docker-style)

#### `merkin push [<locus>] [--tag <name>]`

Seals the current locus state and pushes it into the MuOciStore.

Internally: walks the locus directory, builds a MerkinTree envelope, ingests into all 9 SMT layers. The Provenance SMT layer records the pushing Claude's session identity.

```
$ merkin push adversary --tag post-nand-cripple-attempt
Sealing locus: adversary
  → Content layer:     47 artifacts
  → Temporal layer:    rooted at 2026-04-13T09:14:22Z
  → Provenance layer:  session=claude-sonnet-4-6/a7f3c
Envelope hash: sha256:8e2d1f...
Tagged: adversary:post-nand-cripple-attempt
```

---

#### `merkin pull <locus>[:<tag>]`

Pulls a locus state from the store into the working directory.

```
$ merkin pull adversary:post-nand-cripple-attempt
Pulling sha256:8e2d1f...
  adversary/schemas/adversary-profile.md     [new]
  adversary/countermeasures/nand-cripple.md  [new]
  adversary/playbooks/20min-response.md      [new]
Done. 11 files.
```

---

#### `merkin ls [<pattern>]`

Lists loci in the store. Columns: name, tag(s), last push, model tier of last push, trail depth (how many Claudes have been in it).

```
$ merkin ls
LOCUS          TAG                           LAST PUSH         TIER     TRAILS
adversary      post-nand-cripple-attempt     2026-04-13 09:14  sonnet   3
hardware       nand-rf-v2                    2026-04-12 22:41  sonnet   2
niyuta/jules   backend-refactor              2026-04-11 14:30  sonnet   1
<none>         (working)                     —                 —        —
```

---

#### `merkin tag <ref> <name>`

Tags a specific envelope hash or locus:tag.

```
$ merkin tag sha256:8e2d1f adversary:stable
Tagged: adversary:stable → sha256:8e2d1f
```

---

#### `merkin inspect <locus>[:<tag>]`

Prints the envelope metadata: SMT layer roots, provenance chain, affordances manifest, membranes active.

```
$ merkin inspect adversary
Locus:     adversary
Envelope:  sha256:8e2d1f...
Layers:
  content    sha256:4a1b2c   47 artifacts
  temporal   sha256:9e3f11   root: 2026-04-13T09:14:22Z  depth: 3
  semantic   sha256:7d2a44   (manifold snapshot, Opus-readable)
  provenance sha256:1c9f82   3 sessions, tiers: sonnet×3
  trust      sha256:33ab01   scope=BOUND, attribution=HOLD
Membranes:  scope (BOUND), attribution (HOLD)
Affordances: profile-collection
Tags:       post-nand-cripple-attempt, stable
```

---

#### `merkin rmi <ref>`

Remove a locus version from the store (does not affect working directory).

---

### History Commands (git-style)

#### `merkin log [<locus>] [--since <timestamp>] [--tier <haiku|sonnet|opus>]`

Queries the Temporal SMT layer. Shows the commit chain — each push, who made it, what changed.

```
$ merkin log adversary
2026-04-13 09:14  sonnet/a7f3c  push(adversary)
                                + profiles/20260413-nand-cripple-attempt.md
                                ~ schemas/adversary-profile.md  (+C2 signatures)

2026-04-12 23:01  sonnet/b2e91  push(adversary)
                                + countermeasures/network-cut.md
                                + countermeasures/nand-cripple.md

2026-04-12 20:47  sonnet/c3d12  push(adversary)
                                + README.md
                                + schemas/partition-map.md
                                + playbooks/20min-response.md
```

---

#### `merkin diff <ref1> <ref2>`

Diffs two locus states. Queries Content SMT layer for changed artifact hashes, renders delta.

```
$ merkin diff adversary:@2 adversary:@3
--- adversary/schemas/adversary-profile.md  (2026-04-12 23:01)
+++ adversary/schemas/adversary-profile.md  (2026-04-13 09:14)
@@ -42,0 +42,6 @@
+### C2 Behavioral Signatures (confidence: low — observation pending)
+- Early-init callback: connection within 10–30s of boot
+- Periodic beaconing with jitter
+- Small outbound → large inbound pattern
```

---

#### `merkin status [<locus>]`

Shows working directory vs. last push. Like `git status` but for the locus.

```
$ merkin status adversary
On locus: adversary (sha256:8e2d1f → working)
Modified:
  M  schemas/adversary-profile.md
  M  countermeasures/nand-cripple.md
Untracked:
  ?  profiles/20260413-nand-cripple-attempt.md
  ?  residue/sonnet-a7f3c-exit.md
```

---

#### `merkin branch [<locus>] [--create <name>]`

Lists or creates branches via Temporal SMT forks. Branches diverge from a push point — useful for parallel investigation tracks.

```
$ merkin branch adversary
* main           sha256:8e2d1f  (2026-04-13 09:14)
  rf-attack-path sha256:7c3a01  (2026-04-12 22:41, forked from main@2)
```

---

### Stigmergy Commands ✦

These are the merkin-native commands. Nothing in docker or git does this.

#### `merkin trail [<locus>] [--depth <n>] [--full]`

Shows the Claude activity trail for a locus. Queries Temporal + Provenance SMT layers. This is the primary stigmergy read surface.

```
$ merkin trail adversary
Trail for: adversary  (3 sessions)

╔══ [3] sonnet/a7f3c  2026-04-13 09:14  ═══════════════════════════════╗
║  Entry context: nand-cripple attempt (from residue/sonnet-b2e91-exit)
║  Affordances used: profile-collection
║  YATA opened:  profiles/20260413-nand-cripple-attempt.md
║  Schemas modified: adversary-profile.md (+C2 signatures)
║  Exit residue: → residue/sonnet-a7f3c-exit.md
║  Open threads: C2 endpoints still unknown, capture pcap pending
╚═══════════════════════════════════════════════════════════════════════╝

╔══ [2] sonnet/b2e91  2026-04-12 23:01  ═══════════════════════════════╗
║  Entry context: cold entry (no prior residue)
║  Affordances used: (none — setup pass)
║  YATA opened:  countermeasures/network-cut.md
║                countermeasures/nand-cripple.md
║  Exit residue: → residue/sonnet-b2e91-exit.md
║  Open threads: NAND block offset TBD, need shell access to target
╚═══════════════════════════════════════════════════════════════════════╝

╔══ [1] sonnet/c3d12  2026-04-12 20:47  ═══════════════════════════════╗
║  Entry context: locus created (first Claude)
║  Affordances used: (none — locus creation)
║  YATA opened:  partition-map.md, 20min-response.md
║  Exit residue: → residue/sonnet-c3d12-exit.md
║  Open threads: all — fresh adversary, no confirmed C2
╚═══════════════════════════════════════════════════════════════════════╝
```

---

#### `merkin where`

Shows all loci with recent Claude activity. The global map of "where Claudes have been." Sorted by recency. The entry-point command when you first open merkin with no context.

```
$ merkin where
LOCUS           LAST VISIT        TIER    OPEN THREADS
adversary       13 Apr  09:14     sonnet  C2 endpoints, pcap pending
hardware        12 Apr  22:41     sonnet  NAND RF transmitter setup
niyuta/jules    11 Apr  14:30     sonnet  Hash::from_key unimplemented
claude          03 Apr  11:20     sonnet  (none logged)

Hot loci (visited in last 24h):
  → adversary    (use: merkin loci enter adversary)
```

---

#### `merkin residue [<locus>] [--session <id>] [--raw]`

Reads residue files left by Claudes. Residue is the exit note — what you found, what you left open, what the next Claude should know before entering.

```
$ merkin residue adversary
── residue/sonnet-a7f3c-exit.md ──────────────────────────────────────
Filed by: sonnet/a7f3c  at  2026-04-13 09:14

Picked up from: b2e91's residue (nand-cripple playbook complete)

What I did:
- Filed profile 20260413-nand-cripple-attempt (partial — no shell access yet)
- Added C2 behavioral signatures to adversary-profile.md from countermeasure
  observations
- Verified nand-cripple.md step sequence against observed boot behavior

What I left open:
- pcap capture not yet obtained (network-cut.md step 2 pending)
- NAND block offset at physical address still unconfirmed
- RF experiment path (hardware locus) not yet tested

Next Claude: start with countermeasures/network-cut.md capture-before-cut.
The adversary shows early-init callback behavior. Run tcpdump first.
──────────────────────────────────────────────────────────────────────
```

---

#### `merkin sign [<message>]`

Signs the current session's residue into the Provenance SMT layer. Called at end of session (or automated via loci exit hook).

```
$ merkin sign "pcap capture obtained, C2 to 10.0.0.0/8 range, filing profile"
Signing session: sonnet/a7f3c
Residue hash: sha256:cc41f9...
Provenance layer updated.
Residue committed to: adversary/residue/sonnet-a7f3c-exit.md
```

---

#### `merkin enter <locus>`

Enters a locus: pulls it if needed, reads trail, surfaces open threads, drops into shell with `MERKIN_LOCUS` set. The standard way for a Claude to start work.

```
$ merkin enter adversary
Pulling adversary:stable...
Reading trail (3 sessions)...

─────────────────────────────────────────────────────
You are entering: adversary
Last Claude here: sonnet/a7f3c  (2026-04-13 09:14)

Open threads from last residue:
  ! pcap capture not yet obtained
  ! NAND block offset unconfirmed
  ! RF path (hardware locus) untested

Membranes active: scope (BOUND), attribution (HOLD)
─────────────────────────────────────────────────────

MERKIN_LOCUS=adversary $
```

---

### Loci Management Commands

#### `merkin loci ls`

Lists all known loci with brief metadata.

```
$ merkin loci ls
NAME                 SPIRIT                    TAGS
adversary            20-minute response window  adversarial-ai, threat-intel
hardware             mad-scientist lab          hardware, rf, nand
niyuta/jules         sky backend agnostic       agents, sky, wasm
niyuta               general coordination       agents
claude               protected scratchpad       claude
```

---

#### `merkin loci new <name> [--tags <t1,t2>] [--from <template>]`

Scaffolds a new locus with the standard directory structure.

```
$ merkin loci new exfil-forensics --tags adversarial-ai,forensics
Scaffolding: loci/exfil-forensics/
  README.md          (fill: spirit, entry primitives, tags)
  affordances/       (empty)
  membranes/         (empty)
  schemas/           (empty)
  yata/              (empty)
  residue/           (empty)
Locus created. Start with: merkin enter exfil-forensics
```

---

#### `merkin loci graph`

Renders the loci dependency/cross-reference graph. Shows which loci reference each other (e.g., hardware ↔ adversary via RF experiment).

```
$ merkin loci graph
adversary ──────────────── hardware
  (RF countermeasure)       (nand-rf-experiment.md)

niyuta/jules ─────────────── niyuta
  (sky coordinator)          (sky pool)

(ascii or output to .dot for graphviz)
```

---

### WCM/WASM Commands

#### `merkin build <locus> [--target wasm32-wasi|wasm32-unknown]`

Builds the locus as a WASM Component. Invokes the Extism/WCM pipeline.

```
$ merkin build niyuta/jules
Building: niyuta/jules
  Input:  src/*.ts
  Linker: @extism/js-pdk
  Output: .merkin/artifacts/niyuta-jules-sha256:4a1b.wasm
Component: 847KB
WIT bindings: generated → .merkin/wit/niyuta-jules.wit
```

---

#### `merkin compose <locus1> <locus2> [--out <name>]`

Composes two WCM components using `wasm/combine.mbt`.

```
$ merkin compose niyuta/jules hardware --out sky-with-hardware
Composing: niyuta-jules.wasm + hardware.wasm
  Linking imports: hardware/sdr-read ← niyuta/jules/signal-observe
Output: sky-with-hardware.wasm (1.2MB)
```

---

## TUI

`merkin tui` launches the interactive dashboard.

```
┌─ merkin ─────────────────────────────────────────────────────────────┐
│                                                                       │
│  ACTIVE LOCI                    RECENT TRAILS                         │
│  ─────────────────────          ─────────────────────────────────    │
│  ● adversary   [BOUND]          13 Apr 09:14  sonnet → adversary     │
│  ● hardware    [mad-sci]        12 Apr 22:41  sonnet → hardware      │
│  ○ niyuta/jules                 11 Apr 14:30  sonnet → niyuta/jules  │
│  ○ niyuta                                                             │
│                                                                       │
│  OPEN THREADS                                                         │
│  ─────────────────────────────────────────────────────────────────   │
│  adversary  !  pcap capture not yet obtained                          │
│  adversary  !  NAND block offset unconfirmed                          │
│  hardware   !  RF transmitter: Vpp calculation pending                │
│  niyuta/jules  !  Hash::from_key unimplemented (merkin readiness gap) │
│                                                                       │
│  RESIDUE STREAM           (live, last 10)                             │
│  ─────────────────────────────────────────────────────────────────   │
│  09:14  sonnet/a7f3c  adversary  → signed exit residue               │
│  22:41  sonnet/b2e91  hardware   → signed exit residue               │
│  14:30  sonnet/c9d44  niyuta/j   → signed exit residue               │
│                                                                       │
│  [e] enter locus  [t] trail  [r] residue  [l] log  [q] quit          │
└───────────────────────────────────────────────────────────────────────┘
```

### TUI Panels

**Active Loci** — which loci are "hot" (recently visited or currently entered). `●` = visited in last 24h. Membrane status visible.

**Recent Trails** — the global stigmergy feed. Every Claude session signing residue appears here in real-time. Queryable.

**Open Threads** — aggregated from all residue files across loci. The canonical "what's unfinished" view. This is what a new Claude reads before asking "what should I work on?"

**Residue Stream** — live feed of signed residue events. When a Claude session exits a locus and calls `merkin sign`, it appears here.

### TUI Detail Panels

`e` → enter a locus (drop to shell with full trail context printed)  
`t` → trail panel for selected locus (full trail viewer with session diff)  
`r` → residue reader for selected locus  
`l` → log (temporal SMT history for selected locus)  
`/` → search across all loci (Content + Semantic SMT query)

---

## Stigmergy Data Model

The residue file is the fundamental stigmergic artifact. Every Claude session that enters a locus produces one.

**`loci/<name>/residue/<tier>-<session-short-id>-exit.md`**

```markdown
# Residue: <locus>
Filed by: <tier>/<session-id>
Timestamp: <ISO8601>
Entry residue: <id of residue I read on entry, or "cold">

## Picked up from
<what I read when I entered — the prior Claude's open threads>

## What I did
<operations, affordances used, files modified, YATA items>

## What I left open
<explicit list — this is what the next Claude sees first>

## Recommendation for next Claude
<optional: suggested entry point, urgency, context>
```

Residue files are **append-only** in the working directory. Merkin never modifies them. They are sealed into the Provenance SMT layer on `merkin push`.

### Session Identity

Claude sessions are identified by `<tier>/<short-id>`:
- `haiku/xxxx` — fast, lightweight passes
- `sonnet/xxxx` — primary investigation sessions  
- `opus/xxxx` — deep manifold reads (rare)

The `short-id` is derived from the session ID (not leaked beyond the locus). Stable within a session, not reused across sessions.

---

## Environment Variables

```sh
MERKIN_STORE     # path to MuOciStore directory (default: ~/.merkin/store)
MERKIN_LOCUS     # ambient locus name (set by merkin enter)
MERKIN_SESSION   # current session identity (set by merkin enter)
MERKIN_TIER      # model tier (haiku|sonnet|opus, set externally or inferred)
```

---

## Implementation Notes

### MoonBit CLI binary

Primary implementation language: MoonBit (`.mbt`), same substrate as merkin core.

```
src/
  cli/
    main.mbt          # arg parsing, dispatch
    commands/
      push.mbt
      pull.mbt
      trail.mbt
      where.mbt
      residue.mbt
      enter.mbt
      sign.mbt
      log.mbt
      diff.mbt
    tui/
      dashboard.mbt   # TUI renderer (crossterm or ratatui via FFI)
      panels/
        loci.mbt
        trail.mbt
        threads.mbt
        stream.mbt
```

### Unblocking `pull` (the readiness gap)

`merkin pull` requires `pull_crystal_bytes` which currently `abort`s on missing `Hash::from_key`. This is the single blocking primitive. Until resolved:
- `merkin push` and `merkin trail`/`merkin residue` work (write + provenance query paths)
- `merkin pull` fails gracefully with: `Store is write-only (Hash::from_key unimplemented)`
- The CLI can still operate on the working directory directly

### Stigmergy without full SMT (bootstrap path)

While MerkinTree matures, residue files in `loci/*/residue/` provide full stigmergy functionality via the filesystem. `merkin trail` can read these directly (filesystem mode) before the SMT query path is available.

Filesystem mode → SMT mode migration is transparent: same residue format, same commands, different backend.
