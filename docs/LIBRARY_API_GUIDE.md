# Library API Guide

This guide organizes Merkin as a library, with practical entrypoints.

## Quick orientation

If you're embedding Merkin into another project, there are two common paths:

1. **Lazy tree path** (minimum moving parts)
2. **Full substrate path** (envelopes, policy, daemon, conversation)

---

## 1) Lazy tree usage path

This is the "most lazy approach" requested for first adoption.

### What you use

- `@hash.Hash::of_bytes` to get deterministic ids
- `@tree.MerkinTree::new` to create a tree
- `MerkinTree::ingest` to add hashed payload ids into a hot epoch root
- `MerkinTree::seal` to freeze a root and advance epoch

### Minimal flow (conceptual)

```moonbit
let tree = @tree.MerkinTree::new()
let payload = b"hello"
let envelope_id = @hash.Hash::of_bytes(payload)
ignore(tree.ingest(envelope_id, ["default", "blob"]))
let sealed = tree.seal()
```

### Why this is the minimal tree path

- You can treat `envelope_id` as your content-addressed leaf id.
- Sealing creates a deterministic epoch boundary and frozen node state.
- You can ignore higher-level Yata/conversation features until needed.

Core sources:

- `tree/tree.mbt`
- `tree/node.mbt`
- `hash/hash.mbt`

---

## 2) Storage + policy path

For controlled replication and OCI/local routing:

- `storage/policy.mbt`
- `storage/storage.mbt`
- `storage/oci.mbt`
- `storage/queue.mbt`

Typical embedding strategy:

1. Build a `ReplicationPolicy`
2. Create store nodes (local and/or OCI)
3. Use `UnionStore` for policy-gated put/get

---

## 3) Daemon path (runtime facade)

For a single runtime facade over ingest + indexing + storage behavior:

- `daemon/daemon.mbt`

Notable APIs:

- `DaemonNode::handle_oci_put`
- `DaemonNode::sparse_view`
- `DaemonNode::diff_from_sparse`
- `DaemonNode::diff_views`

CLI wrapper for these flows is in `cmd/main/main.mbt`.

---

## 4) Yata graph path

For graph-based semantic dependency workflows:

- `model/yata.mbt`
- `model/yata_lineage.mbt`
- `model/yata_protocol.mbt`

Core operations:

- hole lifecycle (`new`, `propose`, `seal`, `resolve`)
- lineage replay and `.plan` emission
- topology diagnostics (`child_fanout`, `overbranched`, `detached_holes`)

---

## 5) CLI vs library guidance

- Use **library APIs** when embedding in services or internal runtimes.
- Use **CLI** for operational runs, CI checks, and manual diagnostics.
- You can start with the lazy tree path and incrementally adopt policy/daemon/Yata layers.

---

## 6) Triad contract import path

If another repo needs machine-readable synchronization state for `merkin` + `mu` + `lang`, import:

- `zpc/merkin/triad`

Dependency wiring example:

```json
{
  "deps": {
    "zpc/merkin": { "path": "../merkin" }
  }
}
```

Package import:

```moonbit
import {
  "zpc/merkin/triad" @triad,
}
```

Core typed entrypoints:

- `@triad.seed_sparse_tree(routes, seal)`
- `@triad.abi_expected_exports()`
- `@triad.abi_status(exports)`
- `@triad.emit_contract(input)`

Minimal example:

```moonbit
let pins = @triad.TriadRepoPins::new(
  "merkin-head",
  "mu-head",
  "lang-head",
  "main",
  "main",
  "main",
)
@triad.seed_sparse_tree([["alpha", "doc"]], true)
let input = @triad.TriadContractInput::new(
  ["alpha"],
  ["mu:abc", "lang:def"],
  @triad.abi_expected_exports(),
  "2026-04-14T12:00:00Z",
  "v0.1",
  pins,
)
let json = @triad.emit_contract(input)
```
