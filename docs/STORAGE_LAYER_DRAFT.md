# Storage Layer Draft (Composable Union + OCI)

This draft introduces a composable storage model with policy-driven replication and no cron dependency.

## Surfaces

- `StoreNode` trait (`storage/storage.mbt`):
  - `node_id`, `role`, `availability`
  - `has_blob`, `get_blob`, `put_blob`
- `ArtifactCasNode`: in-memory adapter over `ArtifactStore`
- `UnionStore`:
  - ordered composition over multiple `StoreNode`s
  - policy-gated read/write
  - idempotent replication via operation keys

## Policy Model

`ReplicationPolicy` (`storage/policy.mbt`) is content-addressed and includes:

- quorum controls: `quorum_write`, `quorum_read`
- target rules: per target id/role/lane/availability/write mode
- backpressure policy: inflight/pending limits
- idempotency policy: deterministic operation-key scope
- OCI policy: repository/media-type/tag mode
- tree rules: prefix/exact path checks with sealed-epoch + replica constraints

## Event-Driven Replication

Replication is triggered by events (`Ingest`, `SealEpoch`, `ReadMiss`, `PeerHandshake`), not cron.

Dispatch flow in `UnionStore::put_blob`:

1. evaluate tree rule gate
2. evaluate target rule gate (role/lane/availability)
3. compute idempotency key
4. short-circuit duplicates
5. apply backpressure gate
6. write + commit ledger state

## OCI Alignment

`OciPolicy` captures how blobs/manifests are published:

- `repository`
- `artifact_media_type`
- `tag_mode` (`DigestOnly`, `EpochTag`, `LatestTag`)

This keeps registry-API compatibility while Merkin keeps its own internal content IDs.

## Current Scope vs Future

Implemented now:
- composable CAS interface
- deterministic policy identity
- idempotency/backpressure/tree checks
- integration tests for union behavior

Future extension points:
- remote network-backed `StoreNode` implementations
- OCI push/pull adapter implementing `StoreNode`
- persistent idempotency ledger and per-target queues
- richer tree-automata compiler from policy DSL
