# Mem Storage and Preview Manifests

This document explains Pactis's lightweight content-addressable storage (CAS) for change previews and how to retrieve manifests and blobs.

## Overview
- CAS store for raw bytes (blobs) addressed by `sha256:<hex>`.
- Docker/OCI‑style manifest that references a config blob and one or more layer blobs.
- Manifests are referenced via logical refs: `(<workspace>, <name>, <ref>)`.

## Storage Layout
- Blobs: `priv/mem/blobs/sha256/<hex>`
- Manifests (by digest): `priv/mem/manifests/<hex>.json`
- Ref index: `priv/mem/index/<workspace>/<name>/<ref>.txt` → `sha256:<hex>`

## Manifest Schema
- Manifest media type: `application/vnd.pactis.mem.manifest.v1+json`
- Config media type: `application/vnd.pactis.mem.config.v1+json`
- Diff layer media type: `application/vnd.pactis.diff.v1+patch`
- Fields:
  - `schemaVersion`, `mediaType`
  - `config`: `{ mediaType, size, digest }`
  - `layers`: list of `{ mediaType, size, digest, annotations }`

## Producer Flow (ChangeRunJob)
1. Write preview diff to disk, then blob it via `Pactis.Mem.put_blob!/1`.
2. Build minimal config JSON and blob it.
3. Build manifest referencing config + diff layer.
4. Store manifest and write ref index for `name=ops/changes/<change_id>`, `ref=preview`.
5. Persist `manifest_digest`, `manifest_name`, `manifest_ref` in `change.result`.

## HTTP API
- Get manifest by ref
  - `GET /api/v1/workspaces/:workspace_id/mem/manifests/:ref/*name`
  - Response: `{ "digest": "sha256:...", "manifest": { ... } }`
- Get blob by digest
  - `GET /api/v1/workspaces/:workspace_id/mem/blobs/:digest`
  - Response: raw bytes (`application/octet-stream`)

Examples
```bash
# Manifest (latest preview for a change)
curl -s \
  http://localhost:4000/api/v1/workspaces/ws1/mem/manifests/preview/ops/changes/<change_id> | jq

# Download the diff layer
curl -s \
  http://localhost:4000/api/v1/workspaces/ws1/mem/blobs/sha256:<hex> -o diff.patch
```

## Mix Task (Seed Preview)
Queue a preview Change/Run and optionally wait for completion.

```bash
mix pactis.ops.seed_preview WORKSPACE_ID \
  [--target_repo REPO] [--target_branch BRANCH] [--target_path PATH] [--blueprint_id UUID] \
  [--wait] [--timeout SECONDS] [--print-blob] [--json]
```

Common flows
```bash
# Queue only (machine-readable)
mix pactis.ops.seed_preview ws1 --json

# Queue and wait (human-readable)
mix pactis.ops.seed_preview ws1 --wait --print-blob

# Queue and wait (machine-readable)
mix pactis.ops.seed_preview ws1 --wait --timeout 120 --json
```

JSON output (when `--json`)
- queued: `{ workspace_id, change_id, run_id, status: "queued" }`
- succeeded: `{ ..., status: "succeeded", manifest_url, manifest_digest, diff_blob_url }`
- failed/timeout/error emit a single structured line.

## Safety & Cleanup
- Safety rules
  - Default to preview; do not write in place during preview.
  - Only apply on explicit user action.
  - Apply writes only under: `lib/`, `assets/`, `priv/templates/`.
- Cleanup
  - Background job periodically prunes `priv/ops_artifacts` and `priv/jsonld/specs` by TTL.
  - CAS content is currently retained; add a TTL policy later if needed.

## Notes
- SSE hints for streaming status/artifacts are not yet implemented in this path.
- Manifests are updated in place for `ref=preview` to always point to the latest run.
