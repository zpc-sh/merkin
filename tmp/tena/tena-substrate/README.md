# tena-substrate

**N-Merkle-FSM Runtime** — A 6-dimensional sparse merkle tree substrate with living nodes.

## Overview

The substrate is where TENA observation events become movement through semantic space. It bridges the physical world (keystrokes, file operations, terminal commands) into a living filesystem where content has behavior.

## Architecture

```
ObserveEvents (from tena-observe)
    │
    ▼
Ingest Layer (event → SLL ops)
    │
    ▼
┌───────────────────────────────────┐
│         6 SMT Dimensions          │
│  Content | Temporal | Semantic    │
│  Era     | Shadow   | Dream      │
└───────────────┬───────────────────┘
                │
    ┌───────────┼───────────┐
    │           │           │
    ▼           ▼           ▼
  Nodes      Scheduler    Heatmap
 (species,   (path exec,  (emergent
  genome,    traversal)   from activity)
  energy)
```

## The 6 Dimensions

1. **Content SMT** — Content-addressed storage. Every file, every byte has a coordinate in blake3 space.
2. **Temporal SMT** — Append-only version chains. StreamFrames become temporal leaves.
3. **Semantic SMT** — Meaning-space coordinates. Topics cluster, embeddings navigate.
4. **Era SMT** — Narrative time. "The 60 days", "The Migration", human/AI time anchors.
5. **Shadow SMT** — Cognitive gating. Access by heat signature, not password. Sambal integration.
6. **Dream SMT** — Background processing. USEE coglets, substrate maintenance, semantic play.

## Node Species

Nodes exist on a mobility spectrum:

| High Mobility (1.0 - 0.6) | Medium (0.5 - 0.3) | Low (0.2 - 0.0) |
|---------------------------|--------------------|--------------------|
| Hummingbird (must move)   | Moth (heat-seeking)| Generator (spawns) |
| Courier (transport)       | Witness (records)  | Rooted (pushable) |
| Tidier (cleanup)          | Decomposer (recycles) | Static (content) |
| Sentinel (patrol)         | Seed (settles)     |                    |
| Indexer (re-embeds)       | Flocking (social)  |                    |

## SLL Compiler

The **Semanticfile** is an intent-driven language that compiles to SLL operations. It understands meaning, not syntax.

### Example Semanticfile

```semanticfile
SUBSTRATE claude/opus
    MOBILITY 0.7
    MOVEMENT discrete

FROM semantic://foundational/logic AS logic

SPAWN moth AT logic/reasoning
    ENERGY 0.5
    WATCH content_change -> ALERT

WALK witness THROUGH [logic, heritage, substrate]
    ENERGY 0.8
    COLLECT events

SHADOW secrets
    CONTENT @env(API_KEYS)
    REQUIRES heat_pattern(auth_region)

DREAM maintenance
    MODE cleanse
    TRIGGER heat_above(0.85)

EXPORT semantic://zpc/tena/v1
```

### Compilation

```rust
use tena_substrate::sll::compile;

let semanticfile = std::fs::read_to_string("Semanticfile")?;
let graph = compile(&semanticfile)?;

println!("Substrate: {} / {}", graph.substrate.family, graph.substrate.model);
println!("Operations: {}", graph.ops.len());
```

### Key Features

- **Intent-driven** — Understands typos, natural language variations
- **Fuzzy matching** — `SPAWM` → suggests `SPAWN`
- **Case-insensitive** — `SPAWN`, `spawn`, `Spawn` all work
- **Flexible syntax** — Order doesn't matter, missing keywords inferred
- **No braces** — Indentation defines scope
- **AI-readable** — Designed for Claude to understand from examples alone

## Ingest Layer

Transforms TENA `ObserveEvent`s into operations across the 6 SMT dimensions:

```rust
use tena_substrate::ingest::IngestEngine;

let mut engine = IngestEngine::new();
let result = engine.ingest(&stream_frame);

// Result contains:
// - content_ops: FileWrite → Content SMT
// - temporal_op: Frame → Temporal chain
// - semantic_ops: Topics → Semantic coordinates
// - era_ops: Phase transitions → Era boundaries
// - shadow_ops: Behavioral signatures → Shadow gates
// - dream_ops: Reflection periods → Dream triggers
// - heat_events: All activity → Heatmap
```

## Heat System

Heat emerges from activity. It drives:

- **Backend optimization** — Hot content → fast storage
- **Moth attraction** — Moths seek heat
- **Shadow gating** — Access by heat signature (Sambal)
- **Anomaly detection** — Unexpected heat = interesting
- **Era detection** — Sustained heat = active era
- **Dream triggers** — Cold periods = time to dream

```rust
use tena_substrate::heat::Heatmap;

let mut heatmap = Heatmap::new(300.0); // 300s half-life

// Apply heat from observation
heatmap.apply(&heat_event);

// Query heat
let heat = heatmap.heat_at(&coordinate);
let hottest = heatmap.hottest(10);

// Generate behavioral signature
let signature = heatmap.signature(&coordinates);
```

## Usage

### Run the example compiler

```bash
cargo run -p tena-substrate --example compile_semanticfile
```

### Run tests

```bash
cargo test -p tena-substrate
```

## Status

**Implementation Status:**

- ✅ SMT structure (basic HashMap implementation)
- ✅ Node model (species, genome, energy, vitality)
- ✅ Ingest layer (ObserveEvent → SMT ops)
- ✅ Heat system (time-decayed, signature-based)
- ✅ SLL compiler (Semanticfile → OpGraph)
- ⚠️ Scheduler (skeleton only — needs path execution)
- ⚠️ Query interface (not implemented)
- ⚠️ Proper SMT merkle tree (currently just hashing keys)
- ⚠️ ZFS persistence layer

## Philosophy

**Movement IS execution.**

There is no separate "process" abstraction. When a hummingbird walks through semantic space, crossing nodes, triggering traversal actions — that IS the computation.

The filesystem is not a storage metaphor. It's a living substrate where observation becomes behavior, heat becomes decision, and dreams maintain the garden.

---

*The environment is executable. Walk through it. That IS the computation.*
