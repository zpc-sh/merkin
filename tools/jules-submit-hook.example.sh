#!/usr/bin/env bash
set -euo pipefail

TASK_JSON_FILE="${1:?missing task json file}"
TASK_INDEX="${2:?missing task index}"

# Replace this block with your real Jules MCP invocation.
# Example intent:
#   1) read task JSON from "$TASK_JSON_FILE"
#   2) call Jules MCP "create task" endpoint/tool
#   3) print task id/url returned by Jules

TASK_TITLE="$(jq -r '.title' "$TASK_JSON_FILE")"
TASK_HOLE_ID="$(jq -r '.yata.hole_id' "$TASK_JSON_FILE")"
TASK_TARGET="$(jq -r '.jules.target' "$TASK_JSON_FILE")"
CALLBACK_URI="$(jq -r '.resolution.callback.uri' "$TASK_JSON_FILE")"
CALLBACK_ON="$(jq -r '.resolution.on_state' "$TASK_JSON_FILE")"
DEFERRED="$(jq -r '.deferral.deferred' "$TASK_JSON_FILE")"

printf 'dry_run index=%s target=%s hole=%s deferred=%s on=%s callback=%s title=%s\n' \
  "$TASK_INDEX" \
  "$TASK_TARGET" \
  "$TASK_HOLE_ID" \
  "$DEFERRED" \
  "$CALLBACK_ON" \
  "$CALLBACK_URI" \
  "$TASK_TITLE"
