# Roadmap (Draft)

MVP (v0.1)
- pack: file discovery, filters, hashing, streaming archive
- publish: HTTP upload, dry-run mode, retries
- validate: local checks for structure and size limits
- auth: env token (`PACTIS_TOKEN`), optional `--token`

v0.2
- diff: file-level diff summary
- progress bars and rich TTY output
- JSON output for machine consumption

v0.3
- incremental diffs: rolling-hash chunking and delta upload (server support required)
- resumable uploads (multipart + checkpointing)
- cross-platform builds & release automation

Future
- workspace-aware operations (namespaces, orgs)
- signed manifests; SBOM export
- WASM packaging utilities for embedding in other tools
