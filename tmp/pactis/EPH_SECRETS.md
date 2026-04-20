I like your plan. Here’s a concrete, macOS-native, no-daemon approach that uses Secretive (SSH keys in Secure Enclave) + age-plugin-ssh to encrypt secrets at rest, and exposes them as plain files only for the duration of a session. Agents can just read the mounted dir; when you exit, it’s gone.

Key ideas

Store per-project secrets as age-encrypted files, using your Secretive SSH public key as the recipient.
On “enter project,” decrypt into a temp directory (or RAM disk) owned by your user with 0700 perms.
Export SECRETSDIR pointing there; agents read files like $SECRETSDIR/openai_api_key.
When the session ends, the subshell exits and cleanup deletes the directory/mount.
Secretive can require user presence; your Apple Watch/Touch ID approvals gate decryption.
Prereqs

Secretive installed and configured as your ssh-agent.
Homebrew: brew install age age-plugin-ssh jq
Confirm your Secretive public key is visible: ssh-add -L Pick the line for the project key (ssh-ed25519 … Secretive).
Repository layout (example)

secrets.enc/ holds encrypted files committed to git. secrets.enc/openai_api_key.age secrets.enc/anthropic_api_key.age secrets.enc/...
Nothing decrypted is ever committed.
Add secrets (one-time per secret)

Choose your Secretive public key (RECIP). For example: RECIP="$(ssh-add -L | head -n1)"
Add a secret: printf '%s' "sk-your-openai-key" | age -r "$RECIP" -o secrets.enc/openai_api_key.age printf '%s' "sk-anthropic..." | age -r "$RECIP" -o secrets.enc/anthropic_api_key.age
You can repeat with multiple recipients (e.g., teammate keys) by passing multiple -r flags.
Session script: decrypt to a temp dir and spawn a subshell
Save as secrets-shell (chmod +x secrets-shell). This version uses a secure temp dir; below I also include a RAM-disk variant.

#!/usr/bin/env bash
set -euo pipefail

PROJECT="${PROJECT:-zpc}"
ENC_DIR="${ENC_DIR:-secrets.enc}"

if ! command -v age >/dev/null || ! command -v age-plugin-ssh >/dev/null; then
echo "Install age and age-plugin-ssh (brew install age age-plugin-ssh)" >&2
exit 1
fi

if ! ssh-add -L >/dev/null 2>&1; then
echo "No ssh-agent keys available. Ensure Secretive is configured." >&2
exit 1
fi

if [ ! -d "$ENC_DIR" ]; then
echo "Encrypted dir not found: $ENC_DIR" >&2
exit 1
fi

MOUNT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/$PROJECT.secrets.XXXXXX")"
chmod 700 "$MOUNT_DIR"

cleanup() {

Best-effort wipe then delete

if command -v gnu_shred >/dev/null; then SHRED=gnu_shred
elif command -v shred >/dev/null; then SHRED=shred
else SHRED=""
fi
if [ -n "$SHRED" ]; then
find "$MOUNT_DIR" -type f -maxdepth 1 -print0 | xargs -0 -I{} $SHRED -u -n1 -z "{}" || true
else
find "$MOUNT_DIR" -type f -maxdepth 1 -exec bash -c '> "$1"' _ {} ; || true
rm -f "$MOUNT_DIR"/* || true
fi
rmdir "$MOUNT_DIR" 2>/dev/null || rm -rf "$MOUNT_DIR"
}
trap cleanup EXIT

Decrypt every *.age into flat files named without the .age suffix

shopt -s nullglob
for enc in "$ENC_DIR"/*.age; do
name="$(basename "$enc" .age)"
age -d "$enc" > "$MOUNT_DIR/$name"
chmod 600 "$MOUNT_DIR/$name"
done

export SECRETSDIR="$MOUNT_DIR"

echo "Secrets mounted at: $SECRETSDIR"
echo "Files: $(printf '%s ' "$SECRETSDIR"/* 2>/dev/null || true)"
echo "Starting subshell. Exit to tear down."
exec "${SHELL:-/bin/zsh}" -l

Optional: RAM disk variant (macOS only)

Keeps decrypted files off disk entirely; removes even the small forensic footprint in /tmp.
Replace the temp dir block with:

Create a 16 MB RAM disk (adjust SIZE_MB)

SIZE_MB="${SIZE_MB:-16}"
SECTORS=$((SIZE_MB * 2048))
DEV=$(hdiutil attach -nomount "ram://$SECTORS")
diskutil erasevolume APFS "Secrets-$PROJECT" "$DEV" >/dev/null
MOUNT_DIR="/Volumes/Secrets-$PROJECT"
chmod 700 "$MOUNT_DIR"
cleanup() {
hdiutil detach "$DEV" -force >/dev/null 2>&1 || true
}
trap cleanup EXIT

Agent consumption patterns

File-based convention (recommended): agents look for SECRETSDIR and read well-known filenames. OPENAI: $SECRETSDIR/openai_api_key Anthropic: $SECRETSDIR/anthropic_api_key Gemini: $SECRETSDIR/gemini_api_key
Env shim for tools that only read env: OPENAI_API_KEY="$(cat "$SECRETSDIR/openai_api_key")" codex ... Add a thin wrapper script codexzpc: #!/usr/bin/env bash set -euo pipefail : "${SECRETSDIR:?Set by secrets-shell}" OPENAI_API_KEY="$(<"$SECRETSDIR/openai_api_key")" codex --config preferred_auth_method='openai_api_key' "$@"
Nice-to-have change for @openai/codex

Add support for OPENAI_API_KEY_FILE. Many tools follow the *_FILE convention (Docker-style). Pseudocode: const key = process.env.OPENAI_API_KEY || (process.env.OPENAI_API_KEY_FILE && fs.readFileSync(process.env.OPENAI_API_KEY_FILE, "utf8").trim()); Then your wrapper just sets OPENAI_API_KEY_FILE="$SECRETSDIR/openai_api_key" and no env secret is exposed.
Direnv integration

Don’t export real keys in .envrc.
Instead, provide a helper to launch the secrets shell:
.envrc (example)
use node # or your normal setup layout secrets() { echo "Run: ./secrets-shell to start a gated secret session" }
Or create a project script bin/dev that calls ./secrets-shell then starts your usual dev processes from that subshell.
Security notes and trade-offs

Your Apple Watch/Touch ID gating comes from Secretive: if your key requires user presence, the first age decryption will prompt; once your keychain/agent is unlocked, subsequent decrypts in that session won’t re-prompt until it re-locks.
Once decrypted, any process under your user can read files in SECRETSDIR. This is by design (you want agents to read them). Keep perms 0700 on dir, 0600 on files.
RAM disk avoids writing secrets to disk. If you use TMPDIR, deletion on exit is best-effort but adequate for most dev scenarios.
Compared to a local header-injecting proxy: the proxy avoids exposing raw keys to agents entirely, at the cost of a tiny process. Your “mounted secrets” approach deliberately exposes raw keys; that’s fine if that’s your policy.
End-to-end example with codex

Encrypt the key: RECIP="$(ssh-add -L | head -n1)" printf '%s' "sk-project-ZPC..." | age -r "$RECIP" -o secrets.enc/openai_api_key.age
Enter the project: ./secrets-shell
Approve with Apple Watch/Touch ID if prompted
Run codex: OPENAI_API_KEY="$(<"$SECRETSDIR/openai_api_key")" codex --config preferred_auth_method='openai_api_key'
Pick a supported model like gpt-4o or gpt-4o-mini in codex; “gpt5” isn’t a public model.
