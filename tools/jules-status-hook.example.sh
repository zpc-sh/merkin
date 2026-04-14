#!/usr/bin/env bash
set -euo pipefail

TASK_JSON_FILE="${1:?missing task json file}"
TASK_INDEX="${2:?missing task index}"

# Replace with your real Jules MCP status lookup.
# Must emit one JSON object (last line is parsed by recursive harness).

TASK_ID="$(jq -r '.task_id' "$TASK_JSON_FILE")"
HOLE_ID="$(jq -r '.yata.hole_id' "$TASK_JSON_FILE")"

jq -nc \
  --arg task_id "$TASK_ID" \
  --arg hole_id "$HOLE_ID" \
  --argjson index "$TASK_INDEX" \
  '{
    done: true,
    ok: true,
    state: "resolved",
    detail: ("dry-run status for task_index=" + ($index|tostring) + " task_id=" + $task_id + " hole_id=" + $hole_id)
  }'
