#!/usr/bin/env bash
set -euo pipefail

TASK_JSON_FILE="${1:?missing task json file}"
TASK_INDEX="${2:?missing task index}"

AI_PROVIDER="${AI_PROVIDER:-}"
AI_JULES_MCP_CANCEL_CMD="${AI_JULES_MCP_CANCEL_CMD:-}"
ADAPTER_CONTRACT="merkin.ai.adapter.v0_3"

now_utc() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

emit_response() {
  local provider="$1"
  local session_id="$2"
  local done="$3"
  local ok="$4"
  local state="$5"
  local detail="$6"
  jq -nc \
    --arg contract "$ADAPTER_CONTRACT" \
    --arg provider "$provider" \
    --arg session_id "$session_id" \
    --argjson done "$done" \
    --argjson ok "$ok" \
    --arg state "$state" \
    --arg detail "$detail" \
    '{
      kind: "merkin.ai.adapter.response",
      version: "0.3",
      contract: $contract,
      action: "cancel",
      provider: $provider,
      session_id: $session_id,
      done: $done,
      ok: $ok,
      state: $state,
      detail: $detail
    }'
}

update_dispatch_cancel() {
  local state="$1"
  local done="$2"
  local ok="$3"
  local detail="$4"
  local output="$5"

  local tmp
  tmp="$(mktemp)"
  jq \
    --arg state "$state" \
    --argjson done "$done" \
    --argjson ok "$ok" \
    --arg detail "$detail" \
    --arg output "$output" \
    --arg requested_at "$(now_utc)" \
    '.dispatch = ((.dispatch // {}) + {
      state: $state,
      cancel: {
        requested_at: $requested_at,
        done: $done,
        ok: $ok,
        state: $state,
        detail: $detail,
        output: $output
      }
    })' \
    "$TASK_JSON_FILE" > "$tmp"
  mv "$tmp" "$TASK_JSON_FILE"
}

if [[ -z "$AI_PROVIDER" ]]; then
  AI_PROVIDER="$(jq -r '.dispatch.provider // "dry-run"' "$TASK_JSON_FILE")"
fi

session_id="$(jq -r '.dispatch.session_id // ""' "$TASK_JSON_FILE")"

case "$AI_PROVIDER" in
  dry-run)
    state="canceled"
    detail="dry-run provider treats cancel as complete"
    update_dispatch_cancel "$state" true true "$detail" "$detail"
    emit_response "$AI_PROVIDER" "$session_id" true true "$state" "$detail"
    ;;

  jules-cli)
    if [[ -z "$session_id" ]]; then
      state="missing_session_id"
      detail="dispatch.session_id is missing"
      update_dispatch_cancel "$state" false false "$detail" "$detail"
      emit_response "$AI_PROVIDER" "$session_id" false false "$state" "$detail"
      exit 0
    fi

    # Jules CLI currently exposes remote new/list/pull, no cancel command.
    state="cancel_not_supported"
    detail="jules-cli has no remote cancel command; leave session for manual handling"
    update_dispatch_cancel "$state" false false "$detail" "$detail"
    emit_response "$AI_PROVIDER" "$session_id" false false "$state" "$detail"
    ;;

  jules-mcp)
    if [[ -z "$session_id" ]]; then
      state="missing_session_id"
      detail="dispatch.session_id is missing"
      update_dispatch_cancel "$state" false false "$detail" "$detail"
      emit_response "$AI_PROVIDER" "$session_id" false false "$state" "$detail"
      exit 0
    fi
    if [[ -z "$AI_JULES_MCP_CANCEL_CMD" ]]; then
      state="missing_mcp_cancel_cmd"
      detail="AI_JULES_MCP_CANCEL_CMD is required for jules-mcp cancel"
      update_dispatch_cancel "$state" false false "$detail" "$detail"
      emit_response "$AI_PROVIDER" "$session_id" false false "$state" "$detail"
      exit 0
    fi

    set +e
    output="$(
      TASK_JSON_FILE="$TASK_JSON_FILE" \
      TASK_INDEX="$TASK_INDEX" \
      SESSION_ID="$session_id" \
      bash -lc "$AI_JULES_MCP_CANCEL_CMD" 2>&1
    )"
    rc=$?
    set -e
    if [[ "$rc" -ne 0 ]]; then
      state="mcp_cancel_cmd_failed"
      detail="$output"
      update_dispatch_cancel "$state" false false "$detail" "$output"
      emit_response "$AI_PROVIDER" "$session_id" false false "$state" "$detail"
      exit 0
    fi

    last="$(printf '%s\n' "$output" | tail -n 1)"
    if ! jq -e . >/dev/null 2>&1 <<<"$last"; then
      state="mcp_cancel_bad_json"
      detail="$last"
      update_dispatch_cancel "$state" false false "$detail" "$output"
      emit_response "$AI_PROVIDER" "$session_id" false false "$state" "$detail"
      exit 0
    fi

    done="$(jq -r '.done // true' <<<"$last")"
    ok="$(jq -r '.ok // true' <<<"$last")"
    state="$(jq -r '.state // "canceled"' <<<"$last")"
    detail="$(jq -r '.detail // ""' <<<"$last")"
    update_dispatch_cancel "$state" "$done" "$ok" "$detail" "$output"
    emit_response "$AI_PROVIDER" "$session_id" "$done" "$ok" "$state" "$detail"
    ;;

  *)
    state="unknown_provider"
    detail="Unknown AI_PROVIDER=$AI_PROVIDER"
    update_dispatch_cancel "$state" false false "$detail" "$detail"
    emit_response "$AI_PROVIDER" "$session_id" false false "$state" "$detail"
    ;;
esac
