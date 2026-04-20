Ephemeral Secrets for CLI and Agents (SSHS Model)

See the normative spec: [Pactis‑SSHS](../specifications/Pactis-SSHS.md)

Summary
- Use age-encrypted secrets in `secrets.enc/`, decrypt into an ephemeral dir (or RAM disk), and point tools to files via `*_API_KEY_FILE` or `SECRETSDIR`.

Workflow
1) Encrypt keys once (add more recipients with multiple `-r`):

    RECIP="$(ssh-add -L | head -n1)"
    printf '%s' "sk-openai-..." | age -r "$RECIP" -o secrets.enc/openai_api_key.age
    printf '%s' "sk-anthropic-..." | age -r "$RECIP" -o secrets.enc/anthropic_api_key.age

2) Start a gated secrets session:

    ./secrets-shell
    # mounts an ephemeral dir, sets SECRETSDIR, creates ~/.sshs/<project>

3) Run tools without exposing raw env:

    OPENAI_API_KEY_FILE="$SECRETSDIR/openai_api_key" \
    ANTHROPIC_API_KEY_FILE="$SECRETSDIR/anthropic_api_key" \
    pactis publish ./component --framework svelte

CLI Integration
- The `pactis` CLI should accept `--secrets-dir` and will resolve keys in this order:
  1. `*_API_KEY_FILE`
  2. files under `--secrets-dir` or `SECRETSDIR`/`~/.sshs/<project>`
  3. `*_API_KEY`

Notes
- macOS: Prefer RAM disk for zero residuals; Linux: use `tmpfs`.
- On APFS, secure-deletion is best-effort; RAM disk avoids this.
