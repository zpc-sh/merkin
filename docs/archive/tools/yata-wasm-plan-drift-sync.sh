#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Emit finger.plan.wasm drift surface from sparse Merkin tree and two peer repos.

Usage:
  tools/yata-wasm-plan-drift-sync.sh [options]

Options:
  --out-dir <dir>        Output directory
                         (default: _build/yata/wasm-plan/latest)
  --routes <csv>         Sparse seed routes
                         (default: alpha/doc,beta/doc)
  --tokens <csv>         Sparse filter tokens
                         (default: alpha)
  --peer-a-path <path>   First peer repo path
                         (default: ../mu)
  --peer-a-name <name>   First peer name label
                         (default: mu)
  --peer-b-path <path>   Second peer repo path
                         (default: ../lang/muyata)
  --peer-b-name <name>   Second peer name label
                         (default: muyata)
  --seal <bool>          Pre-seal synthetic sparse tree before plan emission
                         (default: true)
  -h, --help             Show this help
EOF
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT_DIR/_build/yata/wasm-plan/latest"
ROUTES="alpha/doc,beta/doc"
TOKENS="alpha"
PEER_A_PATH="$ROOT_DIR/../mu"
PEER_A_NAME="mu"
PEER_B_PATH="$ROOT_DIR/../lang/muyata"
PEER_B_NAME="muyata"
SEAL="true"

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
    --peer-a-path)
      PEER_A_PATH="$2"
      shift 2
      ;;
    --peer-a-name)
      PEER_A_NAME="$2"
      shift 2
      ;;
    --peer-b-path)
      PEER_B_PATH="$2"
      shift 2
      ;;
    --peer-b-name)
      PEER_B_NAME="$2"
      shift 2
      ;;
    --seal)
      SEAL="$2"
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

mkdir -p "$OUT_DIR"

raw_output_file="$OUT_DIR/finger.plan.wasm.raw.txt"
plan_file="$OUT_DIR/finger.plan.wasm"
summary_file="$OUT_DIR/summary.txt"

peer_a_head="$(git_head_or_unknown "$PEER_A_PATH")"
peer_b_head="$(git_head_or_unknown "$PEER_B_PATH")"
drift_peers="${PEER_A_NAME}:${peer_a_head},${PEER_B_NAME}:${peer_b_head}"

branch_raw="$(git -C "$ROOT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || printf 'unknown')"
branch_raw_hex="$(printf '%s' "$branch_raw" | od -An -tx1 | tr -d ' \n')"
if command -v perl >/dev/null 2>&1; then
  branch_clean="$(printf '%s' "$branch_raw" | perl -CSD -pe 's/\x{200B}|\x{200C}|\x{FEFF}//g')"
else
  branch_clean="$branch_raw"
fi

(
  cd "$ROOT_DIR"
  moon run cmd/main -- daemon yata wasm-plan \
    --routes "$ROUTES" \
    --tokens "$TOKENS" \
    --drift-peers "$drift_peers" \
    --seal "$SEAL" >"$raw_output_file"
)

awk 'BEGIN { emit = 0 } /^kind: merkin.yata.plan$/ { emit = 1 } emit { print }' \
  "$raw_output_file" >"$plan_file"

if [[ ! -s "$plan_file" ]]; then
  printf 'Failed to extract finger.plan.wasm from %s\n' "$raw_output_file" >&2
  exit 1
fi

drift_commitment="$(awk -F= '/^drift_commitment=/{print $2; exit}' "$raw_output_file")"
if [[ -z "$drift_commitment" ]]; then
  printf 'Failed to extract drift_commitment from %s\n' "$raw_output_file" >&2
  exit 1
fi

generated_at_utc="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
{
  printf 'finger_plan_wasm_sync\n'
  printf 'generated_at_utc=%s\n' "$generated_at_utc"
  printf 'routes=%s\n' "$ROUTES"
  printf 'tokens=%s\n' "$TOKENS"
  printf 'seal=%s\n' "$SEAL"
  printf 'drift_commitment=%s\n' "$drift_commitment"
  printf 'peer_a_name=%s\n' "$PEER_A_NAME"
  printf 'peer_a_path=%s\n' "$PEER_A_PATH"
  printf 'peer_a_head=%s\n' "$peer_a_head"
  printf 'peer_b_name=%s\n' "$PEER_B_NAME"
  printf 'peer_b_path=%s\n' "$PEER_B_PATH"
  printf 'peer_b_head=%s\n' "$peer_b_head"
  printf 'merkin_branch_raw=%s\n' "$branch_raw"
  printf 'merkin_branch_clean=%s\n' "$branch_clean"
  printf 'merkin_branch_raw_hex=%s\n' "$branch_raw_hex"
  printf 'raw_output=%s\n' "$raw_output_file"
  printf 'plan_file=%s\n' "$plan_file"
} >"$summary_file"

printf 'finger_plan_wasm=%s\n' "$plan_file"
printf 'summary=%s\n' "$summary_file"
printf 'drift_commitment=%s\n' "$drift_commitment"
