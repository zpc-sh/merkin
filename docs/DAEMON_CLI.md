# Daemon CLI and OCI Facilities

`cmd/main` now exposes a daemon-oriented CLI with configurable OCI behavior.

## Commands

```bash
moon run cmd/main -- daemon --action capabilities --mode hybrid --targets local-1,oci-1
moon run cmd/main -- daemon --action put --mode receiver --targets local-1,oci-1 --payload hello --lane hot --path ingest/oci
moon run cmd/main -- daemon --action sparse --mode receiver --targets local-1 --routes alpha/doc,beta/doc --tokens alpha
moon run cmd/main -- daemon --action diff --mode receiver --targets local-1 --left-routes alpha/doc --right-routes beta/doc
moon run cmd/main -- daemon --action demo --mode receiver
```

## Flags

- `--action`: `capabilities | put | sparse | diff | demo`
- `--mode`: `receiver | proxy | passthrough | hybrid`
- `--node-id`: daemon node id
- `--targets`: comma-separated target ids
  - `oci-*` ids create OCI-backed store targets
  - other ids create local artifact CAS targets
- `--oci`: optional explicit OCI capability override (`receiver,proxy,passthrough`)
- `--payload`: input payload string for `put`
- `--lane`: `critical | hot | warm | cold | archive`
- `--path`: slash-separated policy path for tree-rule checks
- `--routes`: comma-separated route paths for sparse indexing demos
- `--tokens`: comma-separated sparse filter tokens
- `--left-routes`: baseline route set for `diff`
- `--right-routes`: incremental route set for `diff`
- `--left-tokens`: baseline token filter for `diff`
- `--right-tokens`: comparison token filter for `diff`

## Mode Semantics

Defaults (can be overridden with `--oci`):

- `receiver`: stores via policy-gated union store
- `proxy`: forwards (no local commit)
- `passthrough`: bypasses storage and returns digest only
- `hybrid`: enables all three capabilities

## Current Runtime Model

The daemon currently uses in-memory stores and an in-memory OCI registry adapter (`storage/oci.mbt`) to validate behavior.

Receiver mode also maintains an in-memory Merkin index tree per daemon node, enabling:

- sparse views (`daemon.sparse_view(tokens)`)
- diff against sparse snapshots (`daemon.diff_from_sparse(...)`)
- diff between token projections (`daemon.diff_views(...)`)

This is intentionally structured so networked OCI transports, persistent ledgers, and persisted tree snapshots can be added without changing CLI shape.
