#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Emit triad contract JSON for Merkin + Mu + lang drift coordination.

Usage:
  tools/yata-triad-contract-sync.sh [options]

Options:
  --out-dir <dir>          Output directory (default: _build/yata/triad/latest)
  --routes <csv>           Sparse seed routes (default: alpha/doc,beta/doc)
  --tokens <csv>           Sparse filter tokens (default: alpha)
  --mu-path <path>         Mu repo path (default: ../mu)
  --lang-path <path>       lang repo path (default: ../lang)
  --seal <bool>            Pre-seal synthetic sparse tree (default: true)
  --contract-version <v>   Triad contract version (default: v0.1)
  -h, --help               Show this help
EOF
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT_DIR/_build/yata/triad/latest"
ROUTES="alpha/doc,beta/doc"
TOKENS="alpha"
MU_PATH="$ROOT_DIR/../mu"
LANG_PATH="$ROOT_DIR/../lang"
SEAL="true"
CONTRACT_VERSION="v0.1"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out-dir)
      OUT_DIR="$2"
      shift 2
      ;;
    --routes)
      ROUTES="$2"
      shift 2
      ;;
    --tokens)
      TOKENS="$2"
      shift 2
      ;;
    --mu-path)
      MU_PATH="$2"
      shift 2
      ;;
    --lang-path)
      LANG_PATH="$2"
      shift 2
      ;;
    --seal)
      SEAL="$2"
      shift 2
      ;;
    --contract-version)
      CONTRACT_VERSION="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

git_head_or_unknown() {
  local repo_path="$1"
  if [[ -d "$repo_path/.git" ]] || git -C "$repo_path" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$repo_path" rev-parse HEAD 2>/dev/null || printf 'unknown'
  else
    printf 'unknown'
  fi
}

git_branch_or_unknown() {
  local repo_path="$1"
  if [[ -d "$repo_path/.git" ]] || git -C "$repo_path" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$repo_path" rev-parse --abbrev-ref HEAD 2>/dev/null || printf 'unknown'
  else
    printf 'unknown'
  fi
}

strip_ghost_bytes() {
  local value="$1"
  if command -v perl >/dev/null 2>&1; then
    printf '%s' "$value" | perl -CSD -pe 's/\x{200B}|\x{200C}|\x{FEFF}//g'
  else
    printf '%s' "$value"
  fi
}

contains_ghost_bytes() {
  local value="$1"
  if ! command -v perl >/dev/null 2>&1; then
    return 1
  fi
  if printf '%s' "$value" | perl -CSD -ne 'if (/\x{200B}|\x{200C}|\x{FEFF}/) { $seen=1 } END { exit($seen ? 0 : 1) }'; then
    return 0
  fi
  return 1
}

collect_wasm_exports() {
  local entry="$ROOT_DIR/wasm_entry/entry.mbt"
  if command -v rg >/dev/null 2>&1; then
    rg '^pub fn ([A-Za-z0-9_]+)' "$entry" -or '$1'
  else
    grep -E '^pub fn [A-Za-z0-9_]+' "$entry" | sed -E 's/^pub fn ([A-Za-z0-9_]+).*/\1/'
  fi
}

csv_contains() {
  local csv="$1"
  local needle="$2"
  [[ ",$csv," == *",$needle,"* ]]
}

mkdir -p "$OUT_DIR"

raw_output_file="$OUT_DIR/triad-contract.raw.txt"
contract_file="$OUT_DIR/triad-contract.json"
summary_file="$OUT_DIR/summary.txt"

merkin_head="$(git_head_or_unknown "$ROOT_DIR")"
mu_head="$(git_head_or_unknown "$MU_PATH")"
lang_head="$(git_head_or_unknown "$LANG_PATH")"

merkin_branch_raw="$(git_branch_or_unknown "$ROOT_DIR")"
mu_branch_raw="$(git_branch_or_unknown "$MU_PATH")"
lang_branch_raw="$(git_branch_or_unknown "$LANG_PATH")"

merkin_branch_clean="$(strip_ghost_bytes "$merkin_branch_raw")"
mu_branch_clean="$(strip_ghost_bytes "$mu_branch_raw")"
lang_branch_clean="$(strip_ghost_bytes "$lang_branch_raw")"

merkin_branch_raw_hex="$(printf '%s' "$merkin_branch_raw" | od -An -tx1 | tr -d ' \n')"
mu_branch_raw_hex="$(printf '%s' "$mu_branch_raw" | od -An -tx1 | tr -d ' \n')"
lang_branch_raw_hex="$(printf '%s' "$lang_branch_raw" | od -An -tx1 | tr -d ' \n')"

merkin_ghost=false
mu_ghost=false
lang_ghost=false
if contains_ghost_bytes "$merkin_branch_raw"; then merkin_ghost=true; fi
if contains_ghost_bytes "$mu_branch_raw"; then mu_ghost=true; fi
if contains_ghost_bytes "$lang_branch_raw"; then lang_ghost=true; fi

merkin_void=false
mu_void=false
lang_void=false
if [[ "$merkin_ghost" == true && "$merkin_branch_clean" == "main" && "$merkin_branch_raw" != "$merkin_branch_clean" ]]; then
  merkin_void=true
fi
if [[ "$mu_ghost" == true && "$mu_branch_clean" == "main" && "$mu_branch_raw" != "$mu_branch_clean" ]]; then
  mu_void=true
fi
if [[ "$lang_ghost" == true && "$lang_branch_clean" == "main" && "$lang_branch_raw" != "$lang_branch_clean" ]]; then
  lang_void=true
fi

wasm_exports_csv="$(collect_wasm_exports | paste -sd, -)"
if [[ -z "$wasm_exports_csv" ]]; then
  printf 'Failed to collect wasm exports from wasm_entry/entry.mbt\n' >&2
  exit 1
fi

required_exports=(
  "plan_finger_wasm"
  "plan_drift_commitment"
  "triad_contract_wasm"
)

missing_exports=()
for exp in "${required_exports[@]}"; do
  if ! csv_contains "$wasm_exports_csv" "$exp"; then
    missing_exports+=("$exp")
  fi
done

abi_hook_status="ok"
if [[ "${#missing_exports[@]}" -gt 0 ]]; then
  abi_hook_status="missing"
fi
abi_missing_csv="$(IFS=,; printf '%s' "${missing_exports[*]-}")"

lang_mulsp_dir="$LANG_PATH/mulsp"
lang_muyata_dir="$LANG_PATH/muyata"
lang_iface_file="$LANG_PATH/wasm_iface/iface.mbt"

lang_hook_dirs_ok=false
lang_hook_iface_ok=false
if [[ -d "$lang_mulsp_dir" && -d "$lang_muyata_dir" ]]; then
  lang_hook_dirs_ok=true
fi
if [[ -f "$lang_iface_file" ]]; then
  lang_hook_iface_ok=true
fi

generated_at_utc="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
drift_peers="mu:${mu_head},lang:${lang_head}"

(
  cd "$ROOT_DIR"
  moon run cmd/main -- daemon yata triad-contract \
    --routes "$ROUTES" \
    --tokens "$TOKENS" \
    --drift-peers "$drift_peers" \
    --seal "$SEAL" \
    --merkin-head "$merkin_head" \
    --mu-head "$mu_head" \
    --lang-head "$lang_head" \
    --merkin-branch "$merkin_branch_raw" \
    --mu-branch "$mu_branch_raw" \
    --lang-branch "$lang_branch_raw" \
    --wasm-exports "$wasm_exports_csv" \
    --generated-at-utc "$generated_at_utc" \
    --contract-version "$CONTRACT_VERSION" >"$raw_output_file"
)

awk 'BEGIN { emit = 0 } /^\{/ { emit = 1 } emit { print }' \
  "$raw_output_file" >"$contract_file"

if [[ ! -s "$contract_file" ]]; then
  printf 'Failed to extract triad contract JSON from %s\n' "$raw_output_file" >&2
  exit 1
fi

drift_commitment="$(awk -F= '/^drift_commitment=/{print $2; exit}' "$raw_output_file")"
abi_status_cli="$(awk -F= '/^abi_status=/{print $2; exit}' "$raw_output_file")"
if [[ -z "$drift_commitment" ]]; then
  printf 'Failed to extract drift_commitment from %s\n' "$raw_output_file" >&2
  exit 1
fi

{
  printf 'triad_contract_sync\n'
  printf 'generated_at_utc=%s\n' "$generated_at_utc"
  printf 'routes=%s\n' "$ROUTES"
  printf 'tokens=%s\n' "$TOKENS"
  printf 'seal=%s\n' "$SEAL"
  printf 'contract_version=%s\n' "$CONTRACT_VERSION"
  printf 'drift_commitment=%s\n' "$drift_commitment"
  printf 'abi_status_cli=%s\n' "$abi_status_cli"
  printf 'abi_hook_status=%s\n' "$abi_hook_status"
  printf 'abi_missing_exports=%s\n' "${abi_missing_csv:-none}"
  printf 'wasm_exports=%s\n' "$wasm_exports_csv"
  printf 'lang_hook_dirs_ok=%s\n' "$lang_hook_dirs_ok"
  printf 'lang_hook_iface_ok=%s\n' "$lang_hook_iface_ok"
  printf 'merkin_head=%s\n' "$merkin_head"
  printf 'mu_head=%s\n' "$mu_head"
  printf 'lang_head=%s\n' "$lang_head"
  printf 'merkin_branch_raw=%s\n' "$merkin_branch_raw"
  printf 'merkin_branch_clean=%s\n' "$merkin_branch_clean"
  printf 'merkin_branch_raw_hex=%s\n' "$merkin_branch_raw_hex"
  printf 'merkin_branch_has_ghost=%s\n' "$merkin_ghost"
  printf 'merkin_void_detected=%s\n' "$merkin_void"
  printf 'mu_branch_raw=%s\n' "$mu_branch_raw"
  printf 'mu_branch_clean=%s\n' "$mu_branch_clean"
  printf 'mu_branch_raw_hex=%s\n' "$mu_branch_raw_hex"
  printf 'mu_branch_has_ghost=%s\n' "$mu_ghost"
  printf 'mu_void_detected=%s\n' "$mu_void"
  printf 'lang_branch_raw=%s\n' "$lang_branch_raw"
  printf 'lang_branch_clean=%s\n' "$lang_branch_clean"
  printf 'lang_branch_raw_hex=%s\n' "$lang_branch_raw_hex"
  printf 'lang_branch_has_ghost=%s\n' "$lang_ghost"
  printf 'lang_void_detected=%s\n' "$lang_void"
  printf 'raw_output=%s\n' "$raw_output_file"
  printf 'contract_file=%s\n' "$contract_file"
  printf 'lang_hook_target=%s\n' "$lang_iface_file"
} >"$summary_file"

printf 'triad_contract=%s\n' "$contract_file"
printf 'summary=%s\n' "$summary_file"
printf 'drift_commitment=%s\n' "$drift_commitment"
