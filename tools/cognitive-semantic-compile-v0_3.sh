#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Prototype cognitive semantic compiler (v0.3):
- runs moon-build -> Yata pipeline (optional)
- compiles artifacts into CognitiveSemanticIR entries
- emits FSM registry + worklist queues

Usage:
  tools/cognitive-semantic-compile-v0_3.sh [options]

Options:
  --mode <mode>              Compiler mode: markup|active (default: markup)
                             markup: prepare/annotate only (no dispatch promotion)
                             active: includes dispatch/status-derived state
  --active                   Shortcut for --mode active
  --out-dir <dir>             Output directory (default: _build/cognitive/v0.3/latest)
  --pipeline-out-dir <dir>    Pipeline artifact dir (default: <out-dir>/pipeline)
  --skip-pipeline             Reuse existing pipeline outputs in --pipeline-out-dir
  --emit-distributed          Also emit distributed planner artifacts
  --distributed-out-dir <dir> Distributed planner output dir (default: <out-dir>/distributed)
  --distributed-cluster-name  Cluster name for distributed planner
                             (default: merkin-cognitive-v0_3)
  --distributed-shards <n>    Shard count passed to distributed planner (default: 16)
  --distributed-replicas <n>  Replica factor passed to distributed planner (default: 2)
  --distributed-max-inflight-per-shard <n>
                             Max inflight per shard passed to planner (default: 64)
  --distributed-regions <csv> Regions csv passed to planner
                             (default: us-west1,us-east1)
  --submit-hook <path>        Optional submit hook passed to moon-build pipeline
  --defer-enabled <bool>      Passed through (default: true)
  --callback-target <name>    Passed through (default: gemini-jules)
  --callback-channel <id>     Passed through (default: mcp)
  --callback-uri <uri>        Passed through (default: app://jules/tasks/update)
  --callback-on <state>       Passed through (default: resolved)
  --git-report <mode>         Passed through (default: auto)
  --git-remote <name>         Passed through (default: origin)
  --git-ref-limit <uint>      Passed through (default: 20)
  -h, --help                  Show this help

Outputs:
  cognitive_fsm_registry.v0_3.json
  cognitive_ir.v0_3.ndjson
  cognitive_fsm_worklist.v0_3.ndjson
  summary.txt
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
OUT_DIR="$ROOT_DIR/_build/cognitive/v0.3/latest"
PIPELINE_OUT_DIR=""
RUN_PIPELINE=true
COMPILER_MODE="markup"
SUBMIT_HOOK=""
EMIT_DISTRIBUTED=false
DISTRIBUTED_OUT_DIR=""
DISTRIBUTED_CLUSTER_NAME="merkin-cognitive-v0_3"
DISTRIBUTED_SHARDS=16
DISTRIBUTED_REPLICAS=2
DISTRIBUTED_MAX_INFLIGHT_PER_SHARD=64
DISTRIBUTED_REGIONS="us-west1,us-east1"
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
    --mode)
      COMPILER_MODE="$2"
      shift 2
      ;;
    --active)
      COMPILER_MODE="active"
      shift
      ;;
    --out-dir)
      OUT_DIR="$2"
      shift 2
      ;;
    --pipeline-out-dir)
      PIPELINE_OUT_DIR="$2"
      shift 2
      ;;
    --skip-pipeline)
      RUN_PIPELINE=false
      shift
      ;;
    --emit-distributed)
      EMIT_DISTRIBUTED=true
      shift
      ;;
    --distributed-out-dir)
      DISTRIBUTED_OUT_DIR="$2"
      shift 2
      ;;
    --distributed-cluster-name)
      DISTRIBUTED_CLUSTER_NAME="$2"
      shift 2
      ;;
    --distributed-shards)
      DISTRIBUTED_SHARDS="$2"
      shift 2
      ;;
    --distributed-replicas)
      DISTRIBUTED_REPLICAS="$2"
      shift 2
      ;;
    --distributed-max-inflight-per-shard)
      DISTRIBUTED_MAX_INFLIGHT_PER_SHARD="$2"
      shift 2
      ;;
    --distributed-regions)
      DISTRIBUTED_REGIONS="$2"
      shift 2
      ;;
    --submit-hook)
      SUBMIT_HOOK="$2"
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

if [[ "$DEFER_ENABLED" != "true" && "$DEFER_ENABLED" != "false" ]]; then
  printf 'Expected --defer-enabled true|false, got: %s\n' "$DEFER_ENABLED" >&2
  exit 1
fi

if [[ "$COMPILER_MODE" != "markup" && "$COMPILER_MODE" != "active" ]]; then
  printf 'Expected --mode markup|active, got: %s\n' "$COMPILER_MODE" >&2
  exit 1
fi

if ! is_uint "$GIT_REF_LIMIT"; then
  printf 'Expected --git-ref-limit to be an unsigned integer, got: %s\n' "$GIT_REF_LIMIT" >&2
  exit 1
fi

for n in "$DISTRIBUTED_SHARDS" "$DISTRIBUTED_REPLICAS" "$DISTRIBUTED_MAX_INFLIGHT_PER_SHARD"; do
  if ! is_uint "$n"; then
    printf 'Expected distributed planner numeric options to be unsigned integers, got: %s\n' "$n" >&2
    exit 1
  fi
done
if [[ "$DISTRIBUTED_SHARDS" -eq 0 || "$DISTRIBUTED_REPLICAS" -eq 0 || "$DISTRIBUTED_MAX_INFLIGHT_PER_SHARD" -eq 0 ]]; then
  printf 'Distributed planner numeric options must be > 0\n' >&2
  exit 1
fi

if [[ -z "$PIPELINE_OUT_DIR" ]]; then
  PIPELINE_OUT_DIR="$OUT_DIR/pipeline"
fi
if [[ -z "$DISTRIBUTED_OUT_DIR" ]]; then
  DISTRIBUTED_OUT_DIR="$OUT_DIR/distributed"
fi

mkdir -p "$OUT_DIR"

REGISTRY_FILE="$OUT_DIR/cognitive_fsm_registry.v0_3.json"
IR_FILE="$OUT_DIR/cognitive_ir.v0_3.ndjson"
WORKLIST_FILE="$OUT_DIR/cognitive_fsm_worklist.v0_3.ndjson"
SUMMARY_FILE="$OUT_DIR/summary.txt"

if [[ "$RUN_PIPELINE" == "true" ]]; then
  cmd=(
    "$ROOT_DIR/tools/moon-build-yata-jules.sh"
    --out-dir "$PIPELINE_OUT_DIR"
    --defer-enabled "$DEFER_ENABLED"
    --callback-target "$CALLBACK_TARGET"
    --callback-channel "$CALLBACK_CHANNEL"
    --callback-uri "$CALLBACK_URI"
    --callback-on "$CALLBACK_ON"
    --git-report "$GIT_REPORT_MODE"
    --git-remote "$GIT_REMOTE"
    --git-ref-limit "$GIT_REF_LIMIT"
  )
  if [[ "$COMPILER_MODE" == "active" && -n "$SUBMIT_HOOK" ]]; then
    cmd+=(--submit-hook "$SUBMIT_HOOK")
  fi
  "${cmd[@]}"
fi

pipeline_summary="$PIPELINE_OUT_DIR/summary.txt"
if [[ ! -f "$pipeline_summary" ]]; then
  printf 'Missing pipeline summary: %s\n' "$pipeline_summary" >&2
  exit 1
fi

tasks_file="$(summary_value "tasks_file" "$pipeline_summary")"
plan_file="$(summary_value "plan_file" "$pipeline_summary")"
callbacks_file="$(summary_value "callbacks_file" "$pipeline_summary")"
submit_results_file="$(summary_value "submit_results" "$pipeline_summary")"

if [[ -z "$tasks_file" || ! -f "$tasks_file" ]]; then
  printf 'Missing tasks_file from pipeline summary\n' >&2
  exit 1
fi

tasks_source_file="$tasks_file"
if [[ "$COMPILER_MODE" == "active" && -n "$submit_results_file" && -f "$submit_results_file" ]]; then
  promoted_file="$OUT_DIR/tasks_with_dispatch.v0_3.ndjson"
  : > "$promoted_file"
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    task_file="$(jq -r '.task_file // ""' <<<"$line")"
    if [[ -n "$task_file" && -f "$task_file" ]]; then
      cat "$task_file" >> "$promoted_file"
      printf '\n' >> "$promoted_file"
    fi
  done < "$submit_results_file"
  promoted_count="$(grep -c '^{' "$promoted_file" || true)"
  if [[ "$promoted_count" -gt 0 ]]; then
    tasks_source_file="$promoted_file"
  fi
fi

jq -n '{
  kind: "merkin.cognitive.fsm.registry",
  version: "0.3",
  mode: $mode,
  machines: [
    { id: "observer", role: "observe", states: ["Idle","Observed","Rejected"] },
    { id: "contract", role: "contract", states: ["Unbounded","BoundedImmediate","BoundedDeferred"] },
    { id: "delegate", role: "delegate", states: ["Prepared","Queued","Dispatched","RateLimited","ProviderError"] },
    { id: "resolve", role: "resolve", states: ["Awaiting","Verified","Resolved","Failed","Reopened"] },
    { id: "embed", role: "embed", states: ["Staged","Materialized","Purged"] },
    { id: "lookahead", role: "lookahead", states: ["Projected","Warm","Invalidated"] }
  ]
}' --arg mode "$COMPILER_MODE" > "$REGISTRY_FILE"

jq -c \
  --arg mode "$COMPILER_MODE" \
  --arg plan_file "$plan_file" \
  --arg callbacks_file "$callbacks_file" \
  --arg pipeline_summary "$pipeline_summary" \
  '{
    kind: "merkin.cognitive.ir.entry",
    version: "0.3",
    mode: $mode,
    track: "program",
    hole_id: .yata.hole_id,
    anchor: .yata.anchor,
    source: {
      task_id: .task_id,
      pipeline_summary: $pipeline_summary,
      plan_file: $plan_file,
      callbacks_file: $callbacks_file
    },
    diagnostic: .diagnostic,
    callbacks: .resolution,
    deferral: .deferral,
    git: (.git // null),
    merkin: {
      route: (.diagnostic.path | split("/")),
      probabilistic: true
    },
    fsm: {
      observer: {
        role: "observe",
        state: "Observed"
      },
      contract: {
        role: "contract",
        state: (if .deferral.deferred then "BoundedDeferred" else "BoundedImmediate" end),
        conf_floor: .yata.confidence_floor
      },
      delegate: {
        role: "delegate",
        state: (
          if $mode == "markup" then "Prepared"
          elif (.dispatch.session_id // "") != "" then "Dispatched"
          else "Queued"
          end
        ),
        execution_enabled: ($mode == "active"),
        intent: (
          if $mode == "markup" then "prepare-for-deferral"
          else "execute-provider-delegation"
          end
        ),
        provider: (.dispatch.provider // .resolution.callback.target)
      },
      resolve: {
        role: "resolve",
        state: (
          if $mode == "markup" then "Awaiting"
          elif .dispatch.done == true and .dispatch.ok == true then "Resolved"
          elif .dispatch.done == true then "Failed"
          elif (.dispatch.state // "") != "" then .dispatch.state
          else "Awaiting"
          end
        )
      },
      embed: {
        role: "embed",
        state: "Staged",
        policy: {
          ephemeral: true,
          strategy: "micro-local",
          purge_after_turns: 2
        }
      },
      lookahead: {
        role: "lookahead",
        state: "Projected",
        hint: ["neighbors","dependents","likely-fix-paths"]
      }
    }
  }' "$tasks_source_file" > "$IR_FILE"

jq -c '{
  kind: "merkin.cognitive.fsm.workitem",
  version: "0.3",
  mode: .mode,
  hole_id: .hole_id,
  anchor: .anchor,
  queue: (
    if .mode == "markup" then "prepare"
    elif .fsm.resolve.state == "Resolved" then "verify"
    elif .fsm.resolve.state == "Failed" then "repair"
    elif .fsm.delegate.state == "Queued" then "delegate"
    else "poll"
    end
  ),
  next_fsm: (
    if .mode == "markup" then "delegate"
    elif .fsm.resolve.state == "Resolved" then "lookahead"
    elif .fsm.resolve.state == "Failed" then "contract"
    elif .fsm.delegate.state == "Queued" then "delegate"
    else "resolve"
    end
  ),
  provider: .fsm.delegate.provider,
  reason: (
    if .mode == "markup" then "markup-only-prep-for-deferral"
    elif .fsm.resolve.state == "Resolved" then "resolved-needs-lookahead"
    elif .fsm.resolve.state == "Failed" then "resolution-failed-rebound-contract"
    elif .fsm.delegate.state == "Queued" then "not-dispatched"
    else "awaiting-provider-resolution"
    end
  )
}' "$IR_FILE" > "$WORKLIST_FILE"

ir_count="$(jq -s 'length' "$IR_FILE")"
resolved_count="$(jq -s 'map(select(.fsm.resolve.state == "Resolved")) | length' "$IR_FILE")"
prepared_count="$(jq -s 'map(select(.fsm.delegate.state == "Prepared")) | length' "$IR_FILE")"
queued_count="$(jq -s 'map(select(.fsm.delegate.state == "Queued")) | length' "$IR_FILE")"
prepare_queue_count="$(jq -s 'map(select(.queue == "prepare")) | length' "$WORKLIST_FILE")"
delegate_queue_count="$(jq -s 'map(select(.queue == "delegate")) | length' "$WORKLIST_FILE")"
poll_count="$(jq -s 'map(select(.queue == "poll")) | length' "$WORKLIST_FILE")"

{
  printf 'kind=merkin.cognitive.semantic.compiler\n'
  printf 'version=0.3\n'
  printf 'mode=%s\n' "$COMPILER_MODE"
  printf 'pipeline_summary=%s\n' "$pipeline_summary"
  printf 'tasks_file=%s\n' "$tasks_file"
  printf 'tasks_source_file=%s\n' "$tasks_source_file"
  printf 'plan_file=%s\n' "$plan_file"
  printf 'callbacks_file=%s\n' "$callbacks_file"
  printf 'registry_file=%s\n' "$REGISTRY_FILE"
  printf 'ir_file=%s\n' "$IR_FILE"
  printf 'worklist_file=%s\n' "$WORKLIST_FILE"
  printf 'ir_count=%s\n' "$ir_count"
  printf 'resolved_count=%s\n' "$resolved_count"
  printf 'prepared_count=%s\n' "$prepared_count"
  printf 'queued_count=%s\n' "$queued_count"
  printf 'prepare_queue_count=%s\n' "$prepare_queue_count"
  printf 'delegate_queue_count=%s\n' "$delegate_queue_count"
  printf 'poll_count=%s\n' "$poll_count"
} > "$SUMMARY_FILE"

if [[ "$EMIT_DISTRIBUTED" == "true" ]]; then
  planner_cmd=(
    "$ROOT_DIR/tools/cognitive-distributed-plan-v0_3.sh"
    --summary-file "$SUMMARY_FILE"
    --out-dir "$DISTRIBUTED_OUT_DIR"
    --cluster-name "$DISTRIBUTED_CLUSTER_NAME"
    --mode "$COMPILER_MODE"
    --shards "$DISTRIBUTED_SHARDS"
    --replicas "$DISTRIBUTED_REPLICAS"
    --max-inflight-per-shard "$DISTRIBUTED_MAX_INFLIGHT_PER_SHARD"
    --regions "$DISTRIBUTED_REGIONS"
  )
  "${planner_cmd[@]}" >/dev/null

  distributed_summary_file="$DISTRIBUTED_OUT_DIR/summary.txt"
  {
    printf 'emit_distributed=true\n'
    printf 'distributed_summary_file=%s\n' "$distributed_summary_file"
    printf 'distributed_manifest_file=%s\n' "$(summary_value "manifest_file" "$distributed_summary_file")"
    printf 'distributed_assignments_file=%s\n' "$(summary_value "assignments_file" "$distributed_summary_file")"
    printf 'distributed_queue_plan_file=%s\n' "$(summary_value "queue_plan_file" "$distributed_summary_file")"
    printf 'distributed_capacity_file=%s\n' "$(summary_value "capacity_file" "$distributed_summary_file")"
    printf 'distributed_shards=%s\n' "$DISTRIBUTED_SHARDS"
    printf 'distributed_replicas=%s\n' "$DISTRIBUTED_REPLICAS"
    printf 'distributed_max_inflight_per_shard=%s\n' "$DISTRIBUTED_MAX_INFLIGHT_PER_SHARD"
    printf 'distributed_regions=%s\n' "$DISTRIBUTED_REGIONS"
  } >> "$SUMMARY_FILE"
else
  printf 'emit_distributed=false\n' >> "$SUMMARY_FILE"
fi

cat "$SUMMARY_FILE"
