# CLI Spec (Minimal)

Binary: `pactis`

Global options
- `--base <URL>`: API base (default: `https://pactis.dev` or `http://localhost:4000` in dev)
- `--token <STR>`: overrides `PACTIS_TOKEN`
- `-v/--verbose`: increase output
- `--json`: machine-readable output

Commands
- `pack <path> [--framework svelte] [--out <bundle.tgz>] [--include <glob>]... [--exclude <glob>]...`
  - Walk `path`, filter, hash, and produce a streaming archive + manifest
- `validate <path> [--framework svelte]`
  - Local structure checks (files present, sizes, metadata)
- `publish <path> --framework svelte [--dry-run] [--token <STR>] [--tag <k=v>]...`
  - Pack and publish; if `--dry-run`, only produce manifest and stats
- `diff <old_path> <new_path> [--framework svelte]`
  - File-level diff summary; future: rolling-hash chunk plan
- `keys doctor`
  - Validate AI provider key availability using FILE/env conventions
 - `workspace describe --workspace <id>`
   - Fetch workspace descriptor JSON-LD (links to services/LGI/SpecAPI)
 - `services list --workspace <id>`
   - List running services for a workspace
 - `repo service --owner <org> --repo <name>`
   - Fetch repo ServiceDescriptor via SDI discovery

Exit codes
- 0: success
- 2: validation failed
- 3: publish failed
- 4: usage error

Environment
- `PACTIS_TOKEN`: bearer token for authenticated operations
- `PACTIS_BASE_URL`: default API base override
  
Secrets Resolution
- The CLI follows Pactis’ ephemeral secrets contract:
  - If `*_API_KEY_FILE` env vars are set (e.g., `OPENAI_API_KEY_FILE`), read keys from those files.
  - Otherwise, look under `--secrets-dir` if provided, or `SECRETSDIR`/`~/.sshs/<project>` for files named `openai_api_key`, `anthropic_api_key`, etc.
  - As a last resort, fall back to `*_API_KEY` env vars.
  - PROCSI-based retrieval may be added later; the CLI should keep transport pluggable.

Flags
- `--secrets-dir <path>`: explicit directory with secret files (overrides `SECRETSDIR`).
