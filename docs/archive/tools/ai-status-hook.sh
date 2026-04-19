#!/usr/bin/env bash
set -euo pipefail

TASK_JSON_FILE="${1:?missing task json file}"
TASK_INDEX="${2:?missing task index}"

AI_PROVIDER="${AI_PROVIDER:-}"
AI_JULES_MCP_STATUS_CMD="${AI_JULES_MCP_STATUS_CMD:-}"
ADAPTER_CONTRACT="merkin.ai.adapter.v0_3"

now_utc() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

update_dispatch_state() {
  local state="$1"
  local done="$2"
  local ok="$3"
  local detail="$4"

  local tmp
  tmp="$(mktemp)"
  jq \
    --arg state "$state" \
    --argjson done "$done" \
    --argjson ok "$ok" \
    --arg detail "$detail" \
    --arg checked_at "$(now_utc)" \
    '.dispatch = ((.dispatch // {}) + {
      state: $state,
      done: $done,
      ok: $ok,
      detail: $detail,
      checked_at: $checked_at
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
    update_dispatch_state "resolved" true true "dry-run provider always resolves"
    jq -nc \
      --arg contract "$ADAPTER_CONTRACT" \
      --arg provider "$AI_PROVIDER" \
      --arg session_id "$session_id" \
      --arg state "resolved" \
      --arg detail "dry-run provider always resolves" \
      '{
        kind:"merkin.ai.adapter.response",
        version:"0.3",
        contract:$contract,
        action:"status",
        provider:$provider,
        session_id:$session_id,
        done:true,
        ok:true,
        state:$state,
        detail:$detail
      }'
    ;;

  jules-cli)
    if [[ -z "$session_id" ]]; then
      update_dispatch_state "missing_session_id" false false "dispatch.session_id is missing"
      jq -nc \
        --arg contract "$ADAPTER_CONTRACT" \
        --arg provider "$AI_PROVIDER" \
        '{
          kind:"merkin.ai.adapter.response",
          version:"0.3",
          contract:$contract,
          action:"status",
          provider:$provider,
          session_id:"",
          done:false,
          ok:false,
          state:"missing_session_id",
          detail:"dispatch.session_id is missing"
        }'
      exit 0
    fi

    set +e
    list_out="$(jules remote list --session 2>&1)"
    rc=$?
    set -e
    if [[ "$rc" -ne 0 ]]; then
      update_dispatch_state "status_query_failed" false false "$list_out"
      jq -nc \
        --arg contract "$ADAPTER_CONTRACT" \
        --arg provider "$AI_PROVIDER" \
        --arg session_id "$session_id" \
        --arg detail "$list_out" \
        '{
          kind:"merkin.ai.adapter.response",
          version:"0.3",
          contract:$contract,
          action:"status",
          provider:$provider,
          session_id:$session_id,
          done:false,
          ok:false,
          state:"status_query_failed",
          detail:$detail
        }'
      exit 0
    fi

    line="$(printf '%s\n' "$list_out" | awk -v sid="$session_id" '$1 == sid {print; exit}')"
    if [[ -z "$line" ]]; then
      update_dispatch_state "not_found" false false "session not found in jules remote list"
      jq -nc \
        --arg contract "$ADAPTER_CONTRACT" \
        --arg provider "$AI_PROVIDER" \
        --arg session_id "$session_id" \
        '{
          kind:"merkin.ai.adapter.response",
          version:"0.3",
          contract:$contract,
          action:"status",
          provider:$provider,
          session_id:$session_id,
          done:false,
          ok:false,
          state:"not_found",
          detail:"session not found in jules remote list"
        }'
      exit 0
    fi

    status=""
    for candidate in "In Progress" "Planning" "Completed" "Failed" "Awaiting User Feedback" "Awaiting User F"; do
      if [[ "$line" == *"$candidate"* ]]; then
        status="$candidate"
        break
      fi
    done
    if [[ -z "$status" ]]; then
      status="$(printf '%s\n' "$line" | awk -F'  +' '{print $NF}')"
    fi
    if [[ -z "$status" ]]; then
      status="unknown"
    fi
    state="$status"
    done=false
    ok=false
    case "$status" in
      Completed*)
        done=true
        ok=true
        ;;
      Failed*)
        done=true
        ok=false
        ;;
      Awaiting*)
        done=true
        ok=false
        ;;
      In\ Progress*|Planning*)
        done=false
        ok=false
        ;;
      *)
        done=false
        ok=false
        ;;
    esac

    update_dispatch_state "$state" "$done" "$ok" "session=$session_id status=$status"
    jq -nc \
      --arg contract "$ADAPTER_CONTRACT" \
      --arg provider "$AI_PROVIDER" \
      --arg session_id "$session_id" \
      --argjson done "$done" \
      --argjson ok "$ok" \
      --arg state "$state" \
      --arg detail "session=$session_id status=$status" \
      '{
        kind:"merkin.ai.adapter.response",
        version:"0.3",
        contract:$contract,
        action:"status",
        provider:$provider,
        session_id:$session_id,
        done:$done,
        ok:$ok,
        state:$state,
        detail:$detail
      }'
    ;;

  jules-mcp)
    if [[ -z "$AI_JULES_MCP_STATUS_CMD" ]]; then
      update_dispatch_state "missing_mcp_status_cmd" false false "AI_JULES_MCP_STATUS_CMD is required for jules-mcp"
      jq -nc \
        --arg contract "$ADAPTER_CONTRACT" \
        --arg provider "$AI_PROVIDER" \
        --arg session_id "$session_id" \
        '{
          kind:"merkin.ai.adapter.response",
          version:"0.3",
          contract:$contract,
          action:"status",
          provider:$provider,
          session_id:$session_id,
          done:false,
          ok:false,
          state:"missing_mcp_status_cmd",
          detail:"AI_JULES_MCP_STATUS_CMD is required for jules-mcp"
        }'
      exit 0
    fi

    set +e
    output="$(
      TASK_JSON_FILE="$TASK_JSON_FILE" \
      TASK_INDEX="$TASK_INDEX" \
      SESSION_ID="$session_id" \
      bash -lc "$AI_JULES_MCP_STATUS_CMD" 2>&1
    )"
    rc=$?
    set -e
    if [[ "$rc" -ne 0 ]]; then
      update_dispatch_state "mcp_status_cmd_failed" false false "$output"
      jq -nc \
        --arg contract "$ADAPTER_CONTRACT" \
        --arg provider "$AI_PROVIDER" \
        --arg session_id "$session_id" \
        --arg detail "$output" \
        '{
          kind:"merkin.ai.adapter.response",
          version:"0.3",
          contract:$contract,
          action:"status",
          provider:$provider,
          session_id:$session_id,
          done:false,
          ok:false,
          state:"mcp_status_cmd_failed",
          detail:$detail
        }'
      exit 0
    fi

    last="$(printf '%s\n' "$output" | tail -n 1)"
    if ! jq -e . >/dev/null 2>&1 <<<"$last"; then
      update_dispatch_state "mcp_status_bad_json" false false "$last"
      jq -nc \
        --arg contract "$ADAPTER_CONTRACT" \
        --arg provider "$AI_PROVIDER" \
        --arg session_id "$session_id" \
        --arg detail "$last" \
        '{
          kind:"merkin.ai.adapter.response",
          version:"0.3",
          contract:$contract,
          action:"status",
          provider:$provider,
          session_id:$session_id,
          done:false,
          ok:false,
          state:"mcp_status_bad_json",
          detail:$detail
        }'
      exit 0
    fi

    done="$(jq -r '.done // false' <<<"$last")"
    ok="$(jq -r '.ok // false' <<<"$last")"
    state="$(jq -r '.state // "unknown"' <<<"$last")"
    detail="$(jq -r '.detail // ""' <<<"$last")"
    update_dispatch_state "$state" "$done" "$ok" "$detail"
    jq -nc \
      --arg contract "$ADAPTER_CONTRACT" \
      --arg provider "$AI_PROVIDER" \
      --arg session_id "$session_id" \
      --argjson done "$done" \
      --argjson ok "$ok" \
      --arg state "$state" \
      --arg detail "$detail" \
      '{
        kind:"merkin.ai.adapter.response",
        version:"0.3",
        contract:$contract,
        action:"status",
        provider:$provider,
        session_id:$session_id,
        done:$done,
        ok:$ok,
        state:$state,
        detail:$detail
      }'
    ;;

  *)
    update_dispatch_state "unknown_provider" false false "Unknown AI_PROVIDER=$AI_PROVIDER"
    jq -nc \
      --arg contract "$ADAPTER_CONTRACT" \
      --arg provider "$AI_PROVIDER" \
      --arg session_id "$session_id" \
      --arg detail "Unknown AI_PROVIDER=$AI_PROVIDER" \
      '{
        kind:"merkin.ai.adapter.response",
        version:"0.3",
        contract:$contract,
        action:"status",
        provider:$provider,
        session_id:$session_id,
        done:false,
        ok:false,
        state:"unknown_provider",
        detail:$detail
      }'
    ;;
esac
