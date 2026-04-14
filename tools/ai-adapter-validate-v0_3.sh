#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Validate AI adapter response envelopes (v0.3).

Usage:
  tools/ai-adapter-validate-v0_3.sh [options]

Options:
  --action <submit|status|cancel>  Expected action value
  --file <path>                    Read response from file (default: stdin)
  --last-line                      Validate last non-empty line only (default)
  --full                           Validate full input as a JSON object
  -h, --help                       Show this help

Exit:
  0 when valid; non-zero when invalid.
USAGE
}

EXPECTED_ACTION=""
INPUT_FILE=""
LAST_LINE=true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --action)
      EXPECTED_ACTION="$2"
      shift 2
      ;;
    --file)
      INPUT_FILE="$2"
      shift 2
      ;;
    --last-line)
      LAST_LINE=true
      shift
      ;;
    --full)
      LAST_LINE=false
      shift
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

if [[ -n "$EXPECTED_ACTION" ]]; then
  case "$EXPECTED_ACTION" in
    submit|status|cancel) ;;
    *)
      printf 'Expected --action submit|status|cancel, got: %s\n' "$EXPECTED_ACTION" >&2
      exit 1
      ;;
  esac
fi

if [[ -n "$INPUT_FILE" ]]; then
  if [[ ! -f "$INPUT_FILE" ]]; then
    printf 'Input file not found: %s\n' "$INPUT_FILE" >&2
    exit 1
  fi
  raw="$(cat "$INPUT_FILE")"
else
  raw="$(cat)"
fi

if [[ "$LAST_LINE" == "true" ]]; then
  payload="$(printf '%s\n' "$raw" | awk 'NF {line=$0} END {print line}')"
else
  payload="$raw"
fi

if [[ -z "$payload" ]]; then
  printf 'No JSON payload found\n' >&2
  exit 1
fi

if ! jq -e . >/dev/null 2>&1 <<<"$payload"; then
  printf 'Payload is not valid JSON\n' >&2
  exit 1
fi

jq_check='(
  (.kind == "merkin.ai.adapter.response") and
  (.version == "0.3") and
  (.contract == "merkin.ai.adapter.v0_3") and
  (.action | type == "string") and
  (.provider | type == "string") and
  (.session_id | type == "string") and
  (.done | type == "boolean") and
  (.ok | type == "boolean") and
  (.state | type == "string") and
  (.detail | type == "string")
)'

if ! jq -e "$jq_check" >/dev/null <<<"$payload"; then
  printf 'Payload failed required envelope checks\n' >&2
  exit 1
fi

if [[ -n "$EXPECTED_ACTION" ]]; then
  got_action="$(jq -r '.action' <<<"$payload")"
  if [[ "$got_action" != "$EXPECTED_ACTION" ]]; then
    printf 'Action mismatch: expected=%s got=%s\n' "$EXPECTED_ACTION" "$got_action" >&2
    exit 1
  fi
fi

jq -nc --arg action "$(jq -r '.action' <<<"$payload")" --arg provider "$(jq -r '.provider' <<<"$payload")" '{valid:true, action:$action, provider:$provider}'
