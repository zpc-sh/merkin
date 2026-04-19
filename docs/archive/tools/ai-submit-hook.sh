#!/usr/bin/env bash
set -euo pipefail

TASK_JSON_FILE="${1:?missing task json file}"
TASK_INDEX="${2:?missing task index}"

AI_PROVIDER="${AI_PROVIDER:-dry-run}"
AI_JULES_REPO="${AI_JULES_REPO:-}"
AI_JULES_MCP_SUBMIT_CMD="${AI_JULES_MCP_SUBMIT_CMD:-}"
ADAPTER_CONTRACT="merkin.ai.adapter.v0_3"

now_utc() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

json_last_line() {
  local raw="$1"
  printf '%s\n' "$raw" | tail -n 1
}

write_dispatch() {
  local provider="$1"
  local session_id="$2"
  local session_url="$3"
  local state="$4"
  local raw_output="$5"

  local tmp
  tmp="$(mktemp)"
  jq \
    --arg provider "$provider" \
    --arg session_id "$session_id" \
    --arg session_url "$session_url" \
    --arg state "$state" \
    --arg submitted_at "$(now_utc)" \
    --arg submit_output "$raw_output" \
    '.dispatch = {
      provider: $provider,
      session_id: $session_id,
      session_url: $session_url,
      state: $state,
      submitted_at: $submitted_at,
      submit_output: $submit_output
    }' \
    "$TASK_JSON_FILE" > "$tmp"
  mv "$tmp" "$TASK_JSON_FILE"
}

task_prompt="$(jq -r '.jules.prompt // .title' "$TASK_JSON_FILE")"
task_id="$(jq -r '.task_id // ""' "$TASK_JSON_FILE")"

case "$AI_PROVIDER" in
  dry-run)
    session_id="dryrun-$(printf '%s-%s' "$TASK_INDEX" "$task_id" | sha256sum | awk '{print substr($1,1,12)}')"
    session_url=""
    state="submitted"
    output="dry_run provider=dry-run index=${TASK_INDEX} task_id=${task_id}"
    write_dispatch "$AI_PROVIDER" "$session_id" "$session_url" "$state" "$output"
    jq -nc \
      --arg provider "$AI_PROVIDER" \
      --arg session_id "$session_id" \
      --arg session_url "$session_url" \
      --arg state "$state" \
      --arg output "$output" \
      --arg contract "$ADAPTER_CONTRACT" \
      '{
        kind: "merkin.ai.adapter.response",
        version: "0.3",
        contract: $contract,
        action: "submit",
        provider: $provider,
        ok: true,
        done: false,
        state: $state,
        detail: $output,
        session_id: $session_id,
        session_url: $session_url,
        output: $output
      }'
    ;;

  jules-cli)
    cmd=(jules remote new --session "$task_prompt")
    if [[ -n "$AI_JULES_REPO" ]]; then
      cmd+=(--repo "$AI_JULES_REPO")
    fi

    set +e
    output="$("${cmd[@]}" 2>&1)"
    rc=$?
    set -e
    if [[ "$rc" -ne 0 ]]; then
      printf '%s\n' "$output" >&2
      exit "$rc"
    fi

    session_id="$(printf '%s\n' "$output" | sed -n 's/^ID:[[:space:]]*//p' | head -n 1)"
    session_url="$(printf '%s\n' "$output" | sed -n 's/^URL:[[:space:]]*//p' | head -n 1)"
    if [[ -z "$session_id" ]]; then
      printf 'Failed to parse Jules session ID from output:\n%s\n' "$output" >&2
      exit 1
    fi

    write_dispatch "$AI_PROVIDER" "$session_id" "$session_url" "submitted" "$output"
    jq -nc \
      --arg provider "$AI_PROVIDER" \
      --arg session_id "$session_id" \
      --arg session_url "$session_url" \
      --arg state "submitted" \
      --arg output "$output" \
      --arg contract "$ADAPTER_CONTRACT" \
      '{
        kind: "merkin.ai.adapter.response",
        version: "0.3",
        contract: $contract,
        action: "submit",
        provider: $provider,
        ok: true,
        done: false,
        state: $state,
        detail: $output,
        session_id: $session_id,
        session_url: $session_url,
        output: $output
      }'
    ;;

  jules-mcp)
    if [[ -z "$AI_JULES_MCP_SUBMIT_CMD" ]]; then
      printf 'AI_PROVIDER=jules-mcp requires AI_JULES_MCP_SUBMIT_CMD\n' >&2
      exit 1
    fi

    set +e
    output="$(
      TASK_JSON_FILE="$TASK_JSON_FILE" \
      TASK_INDEX="$TASK_INDEX" \
      TASK_PROMPT="$task_prompt" \
      TASK_ID="$task_id" \
      bash -lc "$AI_JULES_MCP_SUBMIT_CMD" 2>&1
    )"
    rc=$?
    set -e
    if [[ "$rc" -ne 0 ]]; then
      printf '%s\n' "$output" >&2
      exit "$rc"
    fi

    last="$(json_last_line "$output")"
    if ! jq -e . >/dev/null 2>&1 <<<"$last"; then
      printf 'AI_JULES_MCP_SUBMIT_CMD must emit JSON on the last line. Got:\n%s\n' "$last" >&2
      exit 1
    fi

    session_id="$(jq -r '.session_id // .id // ""' <<<"$last")"
    session_url="$(jq -r '.session_url // .url // ""' <<<"$last")"
    state="$(jq -r '.state // "submitted"' <<<"$last")"
    if [[ -z "$session_id" ]]; then
      printf 'Could not read session_id from MCP submit JSON:\n%s\n' "$last" >&2
      exit 1
    fi

    write_dispatch "$AI_PROVIDER" "$session_id" "$session_url" "$state" "$output"
    jq -nc \
      --arg provider "$AI_PROVIDER" \
      --arg session_id "$session_id" \
      --arg session_url "$session_url" \
      --arg state "$state" \
      --arg output "$output" \
      --arg contract "$ADAPTER_CONTRACT" \
      '{
        kind: "merkin.ai.adapter.response",
        version: "0.3",
        contract: $contract,
        action: "submit",
        provider: $provider,
        ok: true,
        done: false,
        state: $state,
        detail: $output,
        session_id: $session_id,
        session_url: $session_url,
        output: $output
      }'
    ;;

  *)
    printf 'Unknown AI_PROVIDER: %s\n' "$AI_PROVIDER" >&2
    exit 1
    ;;
esac
