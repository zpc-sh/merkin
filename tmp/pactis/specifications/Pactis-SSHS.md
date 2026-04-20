# Pactis‑SSHS: Secure Secrets via SSH Keys (Ephemeral Mount)

Status: Draft

## Summary
Pactis‑SSHS defines a minimal, agent‑friendly contract for supplying provider credentials to applications and agents without long‑lived environment variables or external daemons. Secrets are decrypted into a per‑session directory or RAM disk and referenced via file paths.

## Normative Contract
- SECRETSDIR: A per‑session directory containing one file per secret.
  - Permissions: directory 0700; files 0600.
  - Filenames (recommended): `openai_api_key`, `anthropic_api_key`, `xai_api_key`, `gemini_api_key`, `mistral_api_key`, `ai21_api_key`.
- *_API_KEY_FILE: Environment variables may point to secret files.
- Resolution order (normative):
  1. `*_API_KEY_FILE`
  2. `*_API_KEY`
  3. Provider‑managed identity (if applicable)
  4. PROCSI (Kerberos‑backed) fallback
  5. error
- ~/.sshs/<project>: Optional symlink to the ephemeral mount for agents that do not inherit environment variables.
- TTL: Sessions SHOULD auto‑teardown in 30–60 minutes or at exit (RAM disk detach or deletion). 

## Provisioning Reference
- Encryption at rest: age + age‑plugin‑ssh; use Secretive (macOS) or ssh‑agent (Linux/WSL) for key material.
- Decrypt on session start into:
  - macOS RAM disk: `/Volumes/Secrets-<project>.noindex` (Spotlight indexing disabled)
  - Linux tmpfs: `/run/user/$UID/sshs-<project>`
- Provide a symlink: `~/.sshs/<project>` → the ephemeral directory.
- Do not commit decrypted files; only commit `secrets.enc/*.age`.

## Client Conventions
- Agents/tools SHOULD support `*_API_KEY_FILE` and read the file contents.
- If both FILE and env are missing, agents SHOULD check `SECRETSDIR/<expected_name>`.
- Agents MUST NOT log secrets; paths may be logged if necessary.
- Applications SHOULD prefer FILE → ENV → managed identity → PROCSI.

## Observability & Health
- Reporting endpoint (workspace): `POST /api/v1/workspaces/{workspace_id}/ops/lgi/secrets/report`
  - Emits `LGI.Secrets.MountChecked` events.
- Health endpoint (workspace): `GET /api/v1/workspaces/{workspace_id}/lgi/secrets/health`
  - Returns latest `LGI.Secrets.MountChecked`.
- Periodic emission: A monitor MAY emit secrets mount health every 60s.

## Security Notes
- APFS secure deletion is best‑effort; prefer RAM disk on macOS.
- Keep directory/file permissions strict (0700/0600).
- Avoid printing or echoing file contents; pass paths to libraries/SDKs.
- Redact secrets in logs and events; never persist plaintext secrets.

## Example (Shell)
```
# Start a gated session (example)
./secrets-shell  # mounts and exports SECRETSDIR; symlink ~/.sshs/<project>

# Use FILE envs for providers
export OPENAI_API_KEY_FILE="$SECRETSDIR/openai_api_key"
export ANTHROPIC_API_KEY_FILE="$SECRETSDIR/anthropic_api_key"

# Run an agent or CLI
pactis publish ./component --framework svelte
```

## Integration (Providers)
- Pactis providers check `*_API_KEY_FILE` first, then env, then PROCSI.
- PROCSI fallback checks `*_API_KEY_FILE` before raw env.

## Related
- How‑to: [Ephemeral Secrets for CLI and Agents](../howto/secrets_ephemeral_cli.md)
- Discovery: [AI Discovery](../AI_DISCOVERY.md)
- Ethics: `GET /api/v1/lgi/heart`
