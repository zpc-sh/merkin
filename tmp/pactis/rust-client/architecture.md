# Architecture (Proposal)

Crates
- pactis_cli (binary): User-facing CLI, thin layer over library
- pactis_client (library): Packaging, HTTP, auth, and models

Module Tree (pactis_client)
- auth
  - token.rs: `TokenSource` trait, `EnvTokenSource` using `PACTIS_TOKEN`
- http
  - client.rs: `HttpClient` (reqwest), base URL, retries, backoff
  - endpoints.rs: publish, validate, status, repo SDI discovery, workspace discovery
- packaging
  - discover.rs: fast file discovery respecting .gitignore (ignore crate)
  - hash.rs: blake3/sha256 hashing, parallel (rayon)
  - archive.rs: streaming zip/tar generation (async-compression)
  - filter.rs: size/type filters, include/exclude globs
  - manifest.rs: `Bundle` manifest (files, sizes, hashes, metadata)
- diff
  - chunk.rs: rolling hash window (planning)
  - delta.rs: binary delta format (planning)
- model
  - types.rs: `FileEntry`, `ComponentMetadata`, `Bundle`, `PublishResult`
  - lgi.rs: `ModelInfo`, `WorkspaceDescriptor`, `ServiceDescriptor` (JSON-LD helpers)
- telemetry
  - log.rs: structured logs; optional metrics
- errors.rs: unified error type

CLI (pactis_cli)
- main.rs: clap-based subcommands
- commands/
  - pack.rs: create `Bundle` from path
  - publish.rs: publish bundle or path; reads `PACTIS_TOKEN`
  - validate.rs: local checks (structure, size, forbidden files)
  - diff.rs: compute file-level diff or rolling-hash plan (future)
  - keys_doctor.rs: check FILE/env secrets and provider reachability
  - services.rs: list workspace services; fetch service.jsonld (repo/workspace)
  - workspace.rs: fetch workspace.jsonld descriptor

Performance Notes
- Use `ignore` crate for batched, parallel file walking
- Hash with `blake3` (fast, parallel) + optional `sha256` when required server-side
- Stream archives to limit peak memory; avoid buffering entire bundles
- Consider mmap for very large files (feature-gated)
- Async reqwest with retries, jittered exponential backoff

Security
- Secrets resolution module supports SSHS ([spec](../specifications/Pactis-SSHS.md)):
  - Honors `*_API_KEY_FILE` first, then `*_API_KEY`, then optional managed identity/PROCSI
  - `--secrets-dir` sets FILE envs implicitly (e.g., OPENAI_API_KEY_FILE)
  - Never write secrets to disk; avoid logging secret paths
- Zero-copy where possible; avoid logging sensitive paths/contents
- Validate path traversal when packaging (normalize, stay within root)

Compatibility
- Primary target: Linux/macOS (x86_64, aarch64)
- Windows support is desirable, not required for v0
