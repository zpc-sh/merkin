#!/usr/bin/env bash
set -euo pipefail

TASK_JSON_FILE="${1:?missing task json file}"
TASK_INDEX="${2:?missing task index}"

task_id="$(jq -r '.task_id // ""' "$TASK_JSON_FILE")"
session_id="$(jq -r '.dispatch.session_id // ""' "$TASK_JSON_FILE")"

jq -nc \
  --arg task_id "$task_id" \
  --argjson task_index "$TASK_INDEX" \
  --arg session_id "$session_id" \
  --arg state "canceled" \
  --arg detail "example cancel hook accepted cancellation request" \
  '{
    kind: "merkin.ai.adapter.response",
    version: "0.3",
    contract: "merkin.ai.adapter.v0_3",
    action: "cancel",
    provider: "example",
    task_id: $task_id,
    task_index: $task_index,
    session_id: $session_id,
    done: true,
    ok: true,
    state: $state,
    detail: $detail
  }'
