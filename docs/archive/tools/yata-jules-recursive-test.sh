#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Recursive integration test harness:
1) run moon-build -> Yata -> Jules pipeline
2) submit real Jules tasks
3) optionally poll Jules task status
4) rerun in rounds until error_groups reaches 0 or max rounds

Usage:
  tools/yata-jules-recursive-test.sh --submit-hook <path> [options]

Options:
  --submit-hook <path>         Executable submit hook (required)
  --status-hook <path>         Executable status hook for task polling
  --cancel-hook <path>         Executable cancel hook for timed-out tasks
  --cancel-on-timeout <bool>   cancel unresolved tasks when poll times out
                               (default: false)
  --base-out-dir <dir>         Base output dir (default: _build/yata/moon-build/recursive)
  --max-rounds <uint>          Max recursive rounds (default: 3)
  --sleep-secs <uint>          Poll interval when status hook is set (default: 15)
  --round-timeout-secs <uint>  Per-round poll timeout (default: 1800)

Pipeline pass-through:
  --defer-enabled <bool>       default: true
  --callback-target <name>     default: gemini-jules
  --callback-channel <id>      default: mcp
  --callback-uri <uri>         default: app://jules/tasks/update
  --callback-on <state>        default: resolved
  --git-report <mode>          default: auto
  --git-remote <name>          default: origin
  --git-ref-limit <uint>       default: 20

Status hook contract:
  <status-hook> <task-json-file> <task-index>
  Must print one JSON object on stdout (last line is parsed), shape:
    {"done": true|false, "ok": true|false, "state": "<text>", "detail": "<text>"}
EOF
}

summary_value() {
  local key="$1"
  local file="$2"
  awk -F= -v target="$key" '$1 == target { print substr($0, index($0, "=") + 1) }' "$file" | tail -n 1
}

is_uint() {
  [[ "$1" =~ ^[0-9]+$ ]]
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE_OUT_DIR="$ROOT_DIR/_build/yata/moon-build/recursive"
SUBMIT_HOOK=""
STATUS_HOOK=""
CANCEL_HOOK=""
CANCEL_ON_TIMEOUT=false
MAX_ROUNDS=3
SLEEP_SECS=15
ROUND_TIMEOUT_SECS=1800

DEFER_ENABLED=true
CALLBACK_TARGET="gemini-jules"
CALLBACK_CHANNEL="mcp"
CALLBACK_URI="app://jules/tasks/update"
CALLBACK_ON="resolved"
GIT_REPORT_MODE="auto"
GIT_REMOTE="origin"
GIT_REF_LIMIT=20

while [[ $# -gt 0 ]]; do
  case "$1" in
    --submit-hook)
      SUBMIT_HOOK="$2"
      shift 2
      ;;
    --status-hook)
      STATUS_HOOK="$2"
      shift 2
      ;;
    --cancel-hook)
      CANCEL_HOOK="$2"
      shift 2
      ;;
    --cancel-on-timeout)
      CANCEL_ON_TIMEOUT="$2"
      shift 2
      ;;
    --base-out-dir)
      BASE_OUT_DIR="$2"
      shift 2
      ;;
    --max-rounds)
      MAX_ROUNDS="$2"
      shift 2
      ;;
    --sleep-secs)
      SLEEP_SECS="$2"
      shift 2
      ;;
    --round-timeout-secs)
      ROUND_TIMEOUT_SECS="$2"
      shift 2
      ;;
    --defer-enabled)
      DEFER_ENABLED="$2"
      shift 2
      ;;
    --callback-target)
      CALLBACK_TARGET="$2"
      shift 2
      ;;
    --callback-channel)
      CALLBACK_CHANNEL="$2"
      shift 2
      ;;
    --callback-uri)
      CALLBACK_URI="$2"
      shift 2
      ;;
    --callback-on)
      CALLBACK_ON="$2"
      shift 2
      ;;
    --git-report)
      GIT_REPORT_MODE="$2"
      shift 2
      ;;
    --git-remote)
      GIT_REMOTE="$2"
      shift 2
      ;;
    --git-ref-limit)
      GIT_REF_LIMIT="$2"
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

if [[ -z "$SUBMIT_HOOK" ]]; then
  printf 'Missing required --submit-hook\n' >&2
  exit 1
fi

if [[ ! -x "$SUBMIT_HOOK" ]]; then
  printf 'Submit hook is not executable: %s\n' "$SUBMIT_HOOK" >&2
  exit 1
fi

if [[ -n "$STATUS_HOOK" && ! -x "$STATUS_HOOK" ]]; then
  printf 'Status hook is not executable: %s\n' "$STATUS_HOOK" >&2
  exit 1
fi

if [[ -n "$CANCEL_HOOK" && ! -x "$CANCEL_HOOK" ]]; then
  printf 'Cancel hook is not executable: %s\n' "$CANCEL_HOOK" >&2
  exit 1
fi

for n in "$MAX_ROUNDS" "$SLEEP_SECS" "$ROUND_TIMEOUT_SECS" "$GIT_REF_LIMIT"; do
  if ! is_uint "$n"; then
    printf 'Expected unsigned integer, got: %s\n' "$n" >&2
    exit 1
  fi
done

if [[ "$DEFER_ENABLED" != "true" && "$DEFER_ENABLED" != "false" ]]; then
  printf 'Expected --defer-enabled true|false, got: %s\n' "$DEFER_ENABLED" >&2
  exit 1
fi

if [[ "$CANCEL_ON_TIMEOUT" != "true" && "$CANCEL_ON_TIMEOUT" != "false" ]]; then
  printf 'Expected --cancel-on-timeout true|false, got: %s\n' "$CANCEL_ON_TIMEOUT" >&2
  exit 1
fi

mkdir -p "$BASE_OUT_DIR"
ROUNDS_FILE="$BASE_OUT_DIR/rounds.ndjson"
: > "$ROUNDS_FILE"

poll_round_status() {
  local round="$1"
  local round_dir="$2"
  local submit_results_file="$3"

  local total
  total="$(wc -l < "$submit_results_file" | tr -d ' ')"
  if [[ "$total" == "0" ]]; then
    return 0
  fi

  local start_ts now_ts deadline done_count hook_fail_count
  start_ts="$(date +%s)"
  deadline=$((start_ts + ROUND_TIMEOUT_SECS))

  local poll_file last_file
  poll_file="$round_dir/status_poll.ndjson"
  last_file="$round_dir/status_last.ndjson"
  : > "$poll_file"

  while true; do
    done_count=0
    hook_fail_count=0
    : > "$last_file"

    while IFS= read -r result_line; do
      [[ -z "$result_line" ]] && continue

      local task_index task_file hook_out hook_rc raw_json parsed_json done ok state detail
      task_index="$(jq -r '.task_index' <<<"$result_line")"
      task_file="$(jq -r '.task_file' <<<"$result_line")"

      set +e
      hook_out="$("$STATUS_HOOK" "$task_file" "$task_index" 2>&1)"
      hook_rc=$?
      set -e

      raw_json="$(printf '%s\n' "$hook_out" | tail -n 1)"
      if jq -e . >/dev/null 2>&1 <<<"$raw_json"; then
        parsed_json="$raw_json"
      else
        parsed_json='{}'
      fi

      done="$(jq -r '.done // false' <<<"$parsed_json")"
      ok="$(jq -r '.ok // false' <<<"$parsed_json")"
      state="$(jq -r '.state // ""' <<<"$parsed_json")"
      detail="$(jq -r '.detail // ""' <<<"$parsed_json")"

      if [[ "$done" == "true" ]]; then
        done_count=$((done_count + 1))
      fi
      if [[ "$hook_rc" -ne 0 ]]; then
        hook_fail_count=$((hook_fail_count + 1))
      fi

      jq -nc \
        --argjson round "$round" \
        --argjson task_index "$task_index" \
        --arg task_file "$task_file" \
        --argjson hook_ok "$([[ "$hook_rc" -eq 0 ]] && echo true || echo false)" \
        --argjson done "$done" \
        --argjson ok "$ok" \
        --arg state "$state" \
        --arg detail "$detail" \
        --arg raw_output "$hook_out" \
        '{
          round: $round,
          task_index: $task_index,
          task_file: $task_file,
          hook_ok: $hook_ok,
          done: $done,
          ok: $ok,
          state: $state,
          detail: $detail,
          raw_output: $raw_output
        }' >> "$last_file"
    done < "$submit_results_file"

    cat "$last_file" >> "$poll_file"

    if [[ "$done_count" -ge "$total" ]]; then
      return 0
    fi

    now_ts="$(date +%s)"
    if [[ "$now_ts" -ge "$deadline" ]]; then
      return 1
    fi

    sleep "$SLEEP_SECS"
  done
}

cancel_round_pending() {
  local round="$1"
  local round_dir="$2"
  local submit_results_file="$3"
  local status_last_file="$4"

  local cancel_results_file
  cancel_results_file="$round_dir/cancel_results.ndjson"
  : > "$cancel_results_file"

  local cancel_attempted cancel_done_ok cancel_failed
  cancel_attempted=0
  cancel_done_ok=0
  cancel_failed=0

  while IFS= read -r result_line; do
    [[ -z "$result_line" ]] && continue

    local task_index task_file done
    task_index="$(jq -r '.task_index' <<<"$result_line")"
    task_file="$(jq -r '.task_file' <<<"$result_line")"
    done=false
    if [[ -f "$status_last_file" ]]; then
      done="$(jq -r --argjson idx "$task_index" 'select(.task_index == $idx) | .done' "$status_last_file" | tail -n 1)"
      if [[ -z "$done" ]]; then
        done=false
      fi
    fi

    if [[ "$done" == "true" ]]; then
      continue
    fi

    cancel_attempted=$((cancel_attempted + 1))

    local hook_out hook_rc raw_json parsed_json done_after ok state detail
    set +e
    hook_out="$("$CANCEL_HOOK" "$task_file" "$task_index" 2>&1)"
    hook_rc=$?
    set -e

    raw_json="$(printf '%s\n' "$hook_out" | tail -n 1)"
    if jq -e . >/dev/null 2>&1 <<<"$raw_json"; then
      parsed_json="$raw_json"
    else
      parsed_json='{}'
    fi

    done_after="$(jq -r '.done // false' <<<"$parsed_json")"
    ok="$(jq -r '.ok // false' <<<"$parsed_json")"
    state="$(jq -r '.state // ""' <<<"$parsed_json")"
    detail="$(jq -r '.detail // ""' <<<"$parsed_json")"

    if [[ "$done_after" == "true" && "$ok" == "true" ]]; then
      cancel_done_ok=$((cancel_done_ok + 1))
    fi
    if [[ "$hook_rc" -ne 0 || "$ok" != "true" ]]; then
      cancel_failed=$((cancel_failed + 1))
    fi

    jq -nc \
      --argjson round "$round" \
      --argjson task_index "$task_index" \
      --arg task_file "$task_file" \
      --argjson hook_ok "$([[ "$hook_rc" -eq 0 ]] && echo true || echo false)" \
      --argjson done "$done_after" \
      --argjson ok "$ok" \
      --arg state "$state" \
      --arg detail "$detail" \
      --arg raw_output "$hook_out" \
      '{
        round: $round,
        task_index: $task_index,
        task_file: $task_file,
        hook_ok: $hook_ok,
        done: $done,
        ok: $ok,
        state: $state,
        detail: $detail,
        raw_output: $raw_output
      }' >> "$cancel_results_file"
  done < "$submit_results_file"

  printf '%s %s %s\n' "$cancel_attempted" "$cancel_done_ok" "$cancel_failed"
}

final_error_groups=""
converged=false
round=1
while [[ "$round" -le "$MAX_ROUNDS" ]]; do
  round_dir="$BASE_OUT_DIR/round-$round"
  mkdir -p "$round_dir"

  printf 'round=%s start\n' "$round"

  "$ROOT_DIR/tools/moon-build-yata-jules.sh" \
    --out-dir "$round_dir" \
    --defer-enabled "$DEFER_ENABLED" \
    --callback-target "$CALLBACK_TARGET" \
    --callback-channel "$CALLBACK_CHANNEL" \
    --callback-uri "$CALLBACK_URI" \
    --callback-on "$CALLBACK_ON" \
    --git-report "$GIT_REPORT_MODE" \
    --git-remote "$GIT_REMOTE" \
    --git-ref-limit "$GIT_REF_LIMIT" \
    --submit-hook "$SUBMIT_HOOK"

  summary_file="$round_dir/summary.txt"
  error_groups="$(summary_value "error_groups" "$summary_file")"
  submitted_count="$(summary_value "submitted_count" "$summary_file")"
  failed_submissions="$(summary_value "failed_submissions" "$summary_file")"
  final_error_groups="$error_groups"

  status_timeout=false
  cancel_triggered=false
  cancel_attempted=0
  cancel_done_ok=0
  cancel_failed=0
  if [[ -n "$STATUS_HOOK" ]]; then
    submit_results_file="$(summary_value "submit_results" "$summary_file")"
    if [[ -n "$submit_results_file" && -f "$submit_results_file" ]]; then
      if ! poll_round_status "$round" "$round_dir" "$submit_results_file"; then
        status_timeout=true
        if [[ "$CANCEL_ON_TIMEOUT" == "true" && -n "$CANCEL_HOOK" ]]; then
          cancel_triggered=true
          status_last_file="$round_dir/status_last.ndjson"
          cancel_counts="$(cancel_round_pending "$round" "$round_dir" "$submit_results_file" "$status_last_file")"
          cancel_attempted="$(awk '{print $1}' <<<"$cancel_counts")"
          cancel_done_ok="$(awk '{print $2}' <<<"$cancel_counts")"
          cancel_failed="$(awk '{print $3}' <<<"$cancel_counts")"
        fi
      fi
    fi
  fi

  jq -nc \
    --argjson round "$round" \
    --arg round_dir "$round_dir" \
    --argjson error_groups "${error_groups:-0}" \
    --argjson submitted_count "${submitted_count:-0}" \
    --argjson failed_submissions "${failed_submissions:-0}" \
    --argjson status_timeout "$status_timeout" \
    --argjson cancel_triggered "$cancel_triggered" \
    --argjson cancel_attempted "$cancel_attempted" \
    --argjson cancel_done_ok "$cancel_done_ok" \
    --argjson cancel_failed "$cancel_failed" \
    '{
      round: $round,
      round_dir: $round_dir,
      error_groups: $error_groups,
      submitted_count: $submitted_count,
      failed_submissions: $failed_submissions,
      status_timeout: $status_timeout,
      cancel_triggered: $cancel_triggered,
      cancel_attempted: $cancel_attempted,
      cancel_done_ok: $cancel_done_ok,
      cancel_failed: $cancel_failed
    }' >> "$ROUNDS_FILE"

  printf 'round=%s error_groups=%s submitted=%s failed_submissions=%s status_timeout=%s cancel_triggered=%s cancel_attempted=%s cancel_done_ok=%s cancel_failed=%s\n' \
    "$round" \
    "${error_groups:-0}" \
    "${submitted_count:-0}" \
    "${failed_submissions:-0}" \
    "$status_timeout" \
    "$cancel_triggered" \
    "$cancel_attempted" \
    "$cancel_done_ok" \
    "$cancel_failed"

  if [[ "${error_groups:-0}" == "0" ]]; then
    converged=true
    break
  fi

  round=$((round + 1))
done

if [[ "$converged" == "true" ]]; then
  printf 'recursive_test=pass rounds=%s final_error_groups=%s rounds_file=%s\n' \
    "$round" \
    "${final_error_groups:-0}" \
    "$ROUNDS_FILE"
  exit 0
fi

printf 'recursive_test=fail rounds=%s final_error_groups=%s rounds_file=%s\n' \
  "$MAX_ROUNDS" \
  "${final_error_groups:-0}" \
  "$ROUNDS_FILE"
exit 1
