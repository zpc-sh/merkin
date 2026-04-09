# nocsi/merkin

Merkin is a MoonBit substrate for deterministic hashing, tree sealing, storage policy control, daemon workflows, and Yata graph semantics.

## Documentation hub

If you're looking for "where everything is", start here:

- `docs/DOCUMENTATION_INDEX.md` — full documentation map by use-case
- `docs/LIBRARY_API_GUIDE.md` — library-first usage guide
- `docs/DAEMON_CLI.md` — CLI commands and flags

## Fastest adoption path (lazy Merkle-like mode)

If you want the minimal approach, treat Merkin like a Merkle-style tree pipeline:

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
- `conformance/` — profile-based conformance and benchmark checks
- `cmd/main/` — CLI entry point
- `docs/` — specifications, API docs, and release docs

## Testing and benchmarking

Primary commands (when MoonBit tooling is available):

```bash
moon test
moon bench -p nocsi/merkin/conformance
moon bench
```

More detail: `docs/TESTING_AND_BENCHMARKING.md`.
