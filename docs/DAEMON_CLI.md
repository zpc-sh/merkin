# Daemon CLI and OCI Facilities

`cmd/main` now exposes a daemon-oriented CLI with configurable OCI behavior.

For broader library/module orientation, see `docs/DOCUMENTATION_INDEX.md` and `docs/LIBRARY_API_GUIDE.md`.

## Command Style

The CLI now supports a Docker-like categorical style:

```bash
moon run cmd/main -- daemon <category> <command> [flags]
```

Legacy form is still supported:

```bash
moon run cmd/main -- daemon --action <action> [flags]
```

## Commands

```bash
moon run cmd/main -- daemon help
moon run cmd/main -- daemon oci capabilities --mode hybrid --targets local-1,oci-1
moon run cmd/main -- daemon oci put --mode receiver --targets local-1,oci-1 --payload hello --lane hot --path ingest/oci
moon run cmd/main -- daemon tree sparse --mode receiver --targets local-1 --routes alpha/doc,beta/doc --tokens alpha
moon run cmd/main -- daemon tree diff --mode receiver --targets local-1 --left-routes alpha/doc --right-routes beta/doc
moon run cmd/main -- daemon conv turn --hall saba --topic debate --content "Opening statement" --overlay chatgpt --actor-role ai
moon run cmd/main -- daemon conv replay --hall saba --topic debate --seed-non-replayable true --enforce-length true
moon run cmd/main -- daemon conv embed --file-ref docs/sample.bin --embedding-action flip-aot --embedding-count 3
moon run cmd/main -- daemon conv embed-purge --purge-after-turns 1 --current-turn-seq 2
moon run cmd/main -- daemon yata topology --yata-branch-factor 5 --yata-max-children 3
moon run cmd/main -- daemon yata wasm-plan --routes alpha/doc,beta/doc --tokens alpha --drift-peers mu:abc,muyata:def
moon run cmd/main -- daemon yata triad-contract --routes alpha/doc,beta/doc --tokens alpha --drift-peers mu:abc,lang:def --merkin-head aaa --mu-head bbb --lang-head ccc
moon run cmd/main -- daemon adapter validate --action status --file /tmp/adapter.json

# Legacy
moon run cmd/main -- daemon --action capabilities --mode hybrid --targets local-1,oci-1
moon run cmd/main -- daemon --action put --mode receiver --targets local-1,oci-1 --payload hello --lane hot --path ingest/oci
moon run cmd/main -- daemon --action sparse --mode receiver --targets local-1 --routes alpha/doc,beta/doc --tokens alpha
moon run cmd/main -- daemon --action diff --mode receiver --targets local-1 --left-routes alpha/doc --right-routes beta/doc
moon run cmd/main -- daemon --action conv-turn --hall saba --topic debate --content "Opening statement" --overlay chatgpt --actor-role ai
moon run cmd/main -- daemon --action conv-replay --hall saba --topic debate --seed-non-replayable true --enforce-length true
moon run cmd/main -- daemon --action conv-embed --file-ref docs/sample.bin --embedding-action flip-aot --embedding-count 3
moon run cmd/main -- daemon --action conv-embed-purge --purge-after-turns 1 --current-turn-seq 2
moon run cmd/main -- daemon --action yata-topology --yata-branch-factor 5 --yata-max-children 3 --yata-detached-depth 2
moon run cmd/main -- daemon --action demo --mode receiver
```

## Categories and Commands

- `oci`: `capabilities | put`
- `tree`: `sparse | diff`
- `conv`: `turn | replay | embed | embed-purge`
- `yata`: `topology | wasm-plan | triad-contract`
- `cognitive`: `compile | distributed | measure` (legacy bridge-only, de-scoped from active roadmap)
- `adapter`: `validate`

## Flags

- `--action`: legacy daemon action selector; also used by `adapter validate` bridge as adapter action `submit|status|cancel`
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
- `--hall`: hall name for conversational actions
- `--policy-profile`: policy profile for conversational actions
- `--topic`: thread topic for conversational actions
- `--track`: `program | git` track for conversational actions
- `--overlay`: overlay id for conversational actions
- `--actor-role`: `ai | human | system`
- `--content`: turn content for conversational actions
- `--idempotency-key`: optional idempotency key for `conv-turn`
- `--input-min`, `--input-max`, `--output-min`, `--output-max`: length envelope bounds
- `--from-seq`, `--to-seq`: replay window for `conv-replay`
- `--enforce-length`: enforce non-replayable turn failures on replay
- `--seed-non-replayable`: create one intentionally non-replayable turn before replay
- `--file-ref`: file reference for embedding metadata
- `--file-type`: file type label for embedding metadata
- `--mime-type`: mime type for embedding metadata
- `--embedding-found`: `true | false`
- `--embedding-count`: unsigned finding count
- `--embedding-action`: `observe | flip-aot | purge`
- `--embedding-ephemeral`: `true | false`
- `--purge-after-turns`: purge window measured in turn age
- `--embedding-note`: optional embedding metadata note
- `--current-turn-seq`: turn sequence horizon for purge execution
- `--yata-branch-factor`: synthetic child count attached to one root for topology diagnostics
- `--yata-detached-depth`: synthetic detached chain length for topology diagnostics
- `--yata-max-children`: threshold used by overbranch hotspot detection
- `--yata-max-depth`: traversal depth bound for detached-hole detection
- `--drift-peers`: two peer refs for drift coordination in `yata wasm-plan` and `yata triad-contract` (`<peer-a>,<peer-b>`)
- `--seal`: `true | false` pre-seal synthetic sparse tree before `yata wasm-plan` or `yata triad-contract`
- `--merkin-head`: Merkin git head pin for `yata triad-contract`
- `--mu-head`: Mu git head pin for `yata triad-contract`
- `--lang-head`: lang git head pin for `yata triad-contract`
- `--merkin-branch`: raw Merkin branch string for byte-level ghost audit in `yata triad-contract`
- `--mu-branch`: raw Mu branch string for byte-level ghost audit in `yata triad-contract`
- `--lang-branch`: raw lang branch string for byte-level ghost audit in `yata triad-contract`
- `--wasm-exports`: comma-separated Merkin wasm export list for ABI checks in `yata triad-contract`
- `--generated-at-utc`: RFC3339 generation timestamp for `yata triad-contract`
- `--contract-version`: contract schema version label for `yata triad-contract`
- `--emit-distributed`: `true | false` for `cognitive compile` bridge
- `--distributed-out-dir`: output dir for distributed planner bridge
- `--distributed-cluster-name`: cluster name for distributed planner bridge
- `--distributed-shards`: shard count for distributed bridge commands
- `--distributed-replicas`: replica factor for distributed bridge commands
- `--distributed-max-inflight-per-shard`: inflight budget for distributed bridge commands
- `--distributed-regions`: regions csv for distributed bridge commands
- `--summary-file`: summary path for `cognitive distributed` and `cognitive measure` bridge commands
- `--compiler-out-dir`: compiler output dir for `cognitive distributed`
- `--coord-minutes-per-hole`: additive offload assumption for `cognitive measure`
- `--automation-overhead-minutes`: additive offload assumption for `cognitive measure`
- `--fix-minutes-low`: lower bound manual fix effort assumption for `cognitive measure`
- `--fix-minutes-high`: upper bound manual fix effort assumption for `cognitive measure`
- `--active-delegation-coverage`: delegation coverage override `[0..1]` for `cognitive measure`
- `--file`: file input for `adapter validate`
- `--last-line`: validate only last non-empty line for `adapter validate`
- `--full`: validate full payload as one JSON object for `adapter validate`

## Bridge Commands

`adapter` category currently runs as a bridge emitter from `cmd/main`:

- they print `status=bridge_only`
- they emit `bridge_command=...` for the shell tool to execute

`cognitive` bridge commands are retained for compatibility only and are not part of the active implementation roadmap.
Use `tools/moon-build-yata-jules.sh` for the active compiler-diagnostics workflow.

Cross-repo drift helper for `finger.plan.wasm`:

- `tools/yata-wasm-plan-drift-sync.sh`
- `make wasm-plan-drift`
- `daemon yata wasm-plan` now emits compact plan wire + paired `merkin.boundary.stigmergy` boundary wire + FSM attention gradient summary fields from the same peer scan

Cross-repo triad contract helper for Merkin + Mu + lang:

- `tools/yata-triad-contract-sync.sh`
- `make triad-contract-sync`

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

Conversational actions use the in-memory host scaffold in `daemon/conversation.mbt` and are intended as a bridge to the Pactis/Saba API contracts in `docs/PACTIS_CONVERSATIONAL_API_SPEC.md` and `docs/PACTIS_CONVERSATIONAL_OPENAPI.yaml`.

## CLI/TUI readiness for first release

You do **not** need to design a full separate client to start using the system:

- The CLI is already scriptable and covers daemon OCI flows, sparse/diff tree inspection, conversational turn/replay, embedding metadata workflows, and Yata topology diagnostics.
- The new `yata-topology` action exposes balancing and detached-chain checks directly from `cmd/main`, so operators can run release gates from shell/CI without a UI.
- A TUI can be added later as a thin presentation layer over these same CLI/API surfaces.

Practical recommendation:

1. Keep release gates in CLI + CI first (stable, automatable).
2. Add a TUI only for operator ergonomics once workflows stabilize.
