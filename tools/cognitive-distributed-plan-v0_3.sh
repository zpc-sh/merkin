#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Distributed planner for Cognitive Semantic Compiler (v0.3):
- consumes cognitive IR + FSM worklist
- emits deterministic shard assignments and queue topology
- remains planning/markup-only unless upstream compiler mode is active

Usage:
  tools/cognitive-distributed-plan-v0_3.sh [options]

Options:
  --compiler-out-dir <dir>       Directory containing cognitive compiler outputs
                                 (default: _build/cognitive/v0.3/latest)
  --summary-file <path>          Explicit cognitive summary.txt path
                                 (default: <compiler-out-dir>/summary.txt)
  --out-dir <dir>                Output directory
                                 (default: <compiler-out-dir>/distributed)
  --cluster-name <name>          Cluster name (default: merkin-cognitive-v0_3)
  --mode <mode>                  Override mode: markup|active (default: from summary)
  --shards <uint>                Number of logical shards (default: 16)
  --replicas <uint>              Base replica factor per assignment (default: 2)
  --max-inflight-per-shard <n>   Soft budget per shard (default: 64)
  --regions <csv>                Comma-separated regions
                                 (default: us-west1,us-east1)
  -h, --help                     Show this help

Outputs:
  cognitive_distributed_manifest.v0_3.json
  cognitive_distributed_assignments.v0_3.ndjson
  cognitive_distributed_queue_plan.v0_3.ndjson
  cognitive_distributed_capacity.v0_3.json
  summary.txt
USAGE
}

summary_value() {
  local key="$1"
  local file="$2"
  awk -F= -v target="$key" '$1 == target { print substr($0, index($0, "=") + 1) }' "$file" | tail -n 1
}

is_uint() {
  [[ "$1" =~ ^[0-9]+$ ]]
}

resolve_path() {
  local input="$1"
  local base1="$2"
  local base2="$3"
  if [[ -z "$input" ]]; then
    return 1
  fi
  if [[ "$input" = /* ]]; then
    if [[ -f "$input" ]]; then
      printf '%s\n' "$input"
      return 0
    fi
    return 1
  fi
  if [[ -f "$base1/$input" ]]; then
    printf '%s\n' "$base1/$input"
    return 0
  fi
  if [[ -f "$base2/$input" ]]; then
    printf '%s\n' "$base2/$input"
    return 0
  fi
  if [[ -f "$input" ]]; then
    printf '%s\n' "$input"
    return 0
  fi
  return 1
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPILER_OUT_DIR="$ROOT_DIR/_build/cognitive/v0.3/latest"
SUMMARY_FILE=""
OUT_DIR=""
CLUSTER_NAME="merkin-cognitive-v0_3"
MODE_OVERRIDE=""
SHARDS=16
REPLICAS=2
MAX_INFLIGHT_PER_SHARD=64
REGIONS_CSV="us-west1,us-east1"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --compiler-out-dir)
      COMPILER_OUT_DIR="$2"
      shift 2
      ;;
    --summary-file)
      SUMMARY_FILE="$2"
      shift 2
      ;;
    --out-dir)
      OUT_DIR="$2"
      shift 2
      ;;
    --cluster-name)
      CLUSTER_NAME="$2"
      shift 2
      ;;
    --mode)
      MODE_OVERRIDE="$2"
      shift 2
      ;;
    --shards)
      SHARDS="$2"
      shift 2
      ;;
    --replicas)
      REPLICAS="$2"
      shift 2
      ;;
    --max-inflight-per-shard)
      MAX_INFLIGHT_PER_SHARD="$2"
      shift 2
      ;;
    --regions)
      REGIONS_CSV="$2"
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

if [[ -z "$SUMMARY_FILE" ]]; then
  SUMMARY_FILE="$COMPILER_OUT_DIR/summary.txt"
fi

if [[ ! -f "$SUMMARY_FILE" ]]; then
  printf 'Missing compiler summary: %s\n' "$SUMMARY_FILE" >&2
  exit 1
fi

if [[ -z "$OUT_DIR" ]]; then
  OUT_DIR="$COMPILER_OUT_DIR/distributed"
fi

if ! is_uint "$SHARDS" || [[ "$SHARDS" -eq 0 ]]; then
  printf 'Expected --shards to be a positive unsigned integer, got: %s\n' "$SHARDS" >&2
  exit 1
fi
if ! is_uint "$REPLICAS" || [[ "$REPLICAS" -eq 0 ]]; then
  printf 'Expected --replicas to be a positive unsigned integer, got: %s\n' "$REPLICAS" >&2
  exit 1
fi
if ! is_uint "$MAX_INFLIGHT_PER_SHARD" || [[ "$MAX_INFLIGHT_PER_SHARD" -eq 0 ]]; then
  printf 'Expected --max-inflight-per-shard to be a positive unsigned integer, got: %s\n' "$MAX_INFLIGHT_PER_SHARD" >&2
  exit 1
fi

mode_from_summary="$(summary_value "mode" "$SUMMARY_FILE")"
COMPILER_MODE="$mode_from_summary"
if [[ -z "$COMPILER_MODE" ]]; then
  COMPILER_MODE="markup"
fi
if [[ -n "$MODE_OVERRIDE" ]]; then
  COMPILER_MODE="$MODE_OVERRIDE"
fi
if [[ "$COMPILER_MODE" != "markup" && "$COMPILER_MODE" != "active" ]]; then
  printf 'Expected mode markup|active, got: %s\n' "$COMPILER_MODE" >&2
  exit 1
fi

summary_dir="$(cd "$(dirname "$SUMMARY_FILE")" && pwd)"
ir_field="$(summary_value "ir_file" "$SUMMARY_FILE")"
worklist_field="$(summary_value "worklist_file" "$SUMMARY_FILE")"

IR_FILE="$(resolve_path "$ir_field" "$ROOT_DIR" "$summary_dir" || true)"
WORKLIST_FILE="$(resolve_path "$worklist_field" "$ROOT_DIR" "$summary_dir" || true)"

if [[ -z "$IR_FILE" || ! -f "$IR_FILE" ]]; then
  printf 'Unable to resolve IR file from summary: %s\n' "$ir_field" >&2
  exit 1
fi
if [[ -z "$WORKLIST_FILE" || ! -f "$WORKLIST_FILE" ]]; then
  printf 'Unable to resolve worklist file from summary: %s\n' "$worklist_field" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

MANIFEST_FILE="$OUT_DIR/cognitive_distributed_manifest.v0_3.json"
ASSIGNMENTS_FILE="$OUT_DIR/cognitive_distributed_assignments.v0_3.ndjson"
QUEUE_PLAN_FILE="$OUT_DIR/cognitive_distributed_queue_plan.v0_3.ndjson"
CAPACITY_FILE="$OUT_DIR/cognitive_distributed_capacity.v0_3.json"
SUMMARY_OUT_FILE="$OUT_DIR/summary.txt"

jq -c \
  --arg cluster "$CLUSTER_NAME" \
  --arg mode "$COMPILER_MODE" \
  --argjson shards "$SHARDS" \
  --argjson replicas "$REPLICAS" \
  --slurpfile wl "$WORKLIST_FILE" \
  '
  def strhash:
    explode | reduce .[] as $b (0; ((. * 131) + $b) % 2147483647);
  def lane_for($q):
    if $q == "prepare" then "contract-prep"
    elif $q == "delegate" then "delegate-control"
    elif $q == "poll" then "resolve-poll"
    elif $q == "verify" then "resolve-verify"
    elif $q == "repair" then "repair-loop"
    else "misc" end;
  ($wl // [] | reduce .[] as $w ({}; .[$w.hole_id] = $w)) as $wm
  | . as $i
  | ($wm[$i.hole_id] // {
      queue: (if $mode == "markup" then "prepare" else "delegate" end),
      next_fsm: "delegate",
      reason: "fallback-missing-workitem"
    }) as $w
  | ($i.hole_id | strhash) as $h
  | ($h % $shards) as $s
  | ($w.queue // "prepare") as $q
  | {
      kind: "merkin.cognitive.distributed.shard.assignment",
      version: "0.3",
      cluster: $cluster,
      mode: $mode,
      hole_id: $i.hole_id,
      anchor: $i.anchor,
      route: ($i.merkin.route // []),
      queue: $q,
      next_fsm: ($w.next_fsm // "delegate"),
      reason: ($w.reason // ""),
      lane: lane_for($q),
      shard: {
        id: ("shard-" + (($s + 1) | tostring)),
        index: $s,
        total: $shards,
        hash: $h
      },
      replica_count: (if $q == "repair" or $q == "verify" then ($replicas + 1) else $replicas end),
      replica_set: [range(0; (if $q == "repair" or $q == "verify" then ($replicas + 1) else $replicas end)) | ("r" + ((. + 1) | tostring))],
      provider: ($w.provider // $i.fsm.delegate.provider),
      callback: ($i.callbacks.callback // null),
      deferral: ($i.deferral // null),
      embedding: {
        policy: "micro-local",
        expected_tokens: (
          if $q == "prepare" then 256
          elif $q == "delegate" then 128
          elif $q == "poll" then 64
          elif $q == "verify" then 96
          else 192
          end
        )
      }
    }
  ' "$IR_FILE" > "$ASSIGNMENTS_FILE"

jq -s -c '
  group_by(.shard.id + "|" + .lane + "|" + .queue)
  | map({
      kind: "merkin.cognitive.distributed.queue.assignment",
      version: "0.3",
      shard: .[0].shard.id,
      lane: .[0].lane,
      queue: .[0].queue,
      item_count: length,
      max_replica_count: (map(.replica_count) | max),
      providers: (map(.provider) | map(select(. != null)) | unique)
    })
  | .[]
' "$ASSIGNMENTS_FILE" > "$QUEUE_PLAN_FILE"

regions_json="$(jq -n --arg csv "$REGIONS_CSV" '$csv | split(",") | map(gsub("^ +| +$"; "")) | map(select(length > 0))')"

jq -n \
  --arg cluster "$CLUSTER_NAME" \
  --arg mode "$COMPILER_MODE" \
  --arg summary "$SUMMARY_FILE" \
  --arg ir "$IR_FILE" \
  --arg worklist "$WORKLIST_FILE" \
  --argjson shards "$SHARDS" \
  --argjson replicas "$REPLICAS" \
  --argjson max_inflight "$MAX_INFLIGHT_PER_SHARD" \
  --argjson regions "$regions_json" \
  --slurpfile assignments "$ASSIGNMENTS_FILE" \
  --slurpfile queueplan "$QUEUE_PLAN_FILE" \
  '
  ($assignments // []) as $a
  | ($queueplan // []) as $q
  | ($a | length) as $n
  | ($a | group_by(.shard.id) | map({id: .[0].shard.id, count: length}) | sort_by(.id)) as $shard_load
  | {
      kind: "merkin.cognitive.distributed.manifest",
      version: "0.3",
      cluster: $cluster,
      mode: $mode,
      planning_only: ($mode == "markup"),
      control_plane: {
        summary_file: $summary,
        ir_file: $ir,
        worklist_file: $worklist,
        queue_plan_file: "cognitive_distributed_queue_plan.v0_3.ndjson"
      },
      data_plane: {
        shards: $shards,
        replica_factor: $replicas,
        max_inflight_per_shard: $max_inflight,
        regions: $regions,
        total_assignments: $n,
        shard_load: $shard_load
      },
      roles: [
        "observer-gateway",
        "contractor",
        "scheduler",
        "delegate-router",
        "resolve-poller",
        "embed-hot",
        "lookahead-warm"
      ],
      queue_counts: (
        $q
        | group_by(.queue)
        | map({key: .[0].queue, value: (map(.item_count) | add)})
        | from_entries
      ),
      lane_counts: (
        $q
        | group_by(.lane)
        | map({key: .[0].lane, value: (map(.item_count) | add)})
        | from_entries
      )
    }
  ' > "$MANIFEST_FILE"

jq -n \
  --arg cluster "$CLUSTER_NAME" \
  --arg mode "$COMPILER_MODE" \
  --argjson shards "$SHARDS" \
  --argjson max_inflight "$MAX_INFLIGHT_PER_SHARD" \
  --slurpfile assignments "$ASSIGNMENTS_FILE" \
  '
  ($assignments // []) as $a
  | ($a | length) as $total
  | ($a | group_by(.shard.id) | map(length)) as $loads
  | ($loads | if length == 0 then 0 else max end) as $max_load
  | ($loads | if length == 0 then 0 else min end) as $min_load
  | ($loads | if length == 0 then 0 else (add / length) end) as $avg_load
  | {
      kind: "merkin.cognitive.distributed.capacity",
      version: "0.3",
      cluster: $cluster,
      mode: $mode,
      shards: $shards,
      total_items: $total,
      load: {
        min_per_shard: $min_load,
        avg_per_shard: $avg_load,
        max_per_shard: $max_load,
        saturation_ratio: (if $max_inflight == 0 then 0 else ($max_load / $max_inflight) end)
      },
      recommendations: {
        worker_pools: [
          {
            role: "prepare-contract",
            suggested_workers: (if $mode == "markup" then 2 else 1 end)
          },
          {
            role: "delegate-router",
            suggested_workers: (if $mode == "markup" then 1 else 2 end)
          },
          {
            role: "resolve-poller",
            suggested_workers: (if $mode == "markup" then 1 else 3 end)
          },
          {
            role: "embed-hot",
            suggested_workers: 2
          }
        ]
      }
    }
  ' > "$CAPACITY_FILE"

assignment_count="$(jq -s 'length' "$ASSIGNMENTS_FILE")"
queue_count="$(jq -s 'length' "$QUEUE_PLAN_FILE")"
prepare_count="$(jq -s 'map(select(.queue == "prepare")) | length' "$ASSIGNMENTS_FILE")"
poll_count="$(jq -s 'map(select(.queue == "poll")) | length' "$ASSIGNMENTS_FILE")"

{
  printf 'kind=merkin.cognitive.distributed.planner\n'
  printf 'version=0.3\n'
  printf 'cluster=%s\n' "$CLUSTER_NAME"
  printf 'mode=%s\n' "$COMPILER_MODE"
  printf 'summary_file=%s\n' "$SUMMARY_FILE"
  printf 'ir_file=%s\n' "$IR_FILE"
  printf 'worklist_file=%s\n' "$WORKLIST_FILE"
  printf 'manifest_file=%s\n' "$MANIFEST_FILE"
  printf 'assignments_file=%s\n' "$ASSIGNMENTS_FILE"
  printf 'queue_plan_file=%s\n' "$QUEUE_PLAN_FILE"
  printf 'capacity_file=%s\n' "$CAPACITY_FILE"
  printf 'shards=%s\n' "$SHARDS"
  printf 'replicas=%s\n' "$REPLICAS"
  printf 'max_inflight_per_shard=%s\n' "$MAX_INFLIGHT_PER_SHARD"
  printf 'assignment_count=%s\n' "$assignment_count"
  printf 'queue_plan_count=%s\n' "$queue_count"
  printf 'prepare_count=%s\n' "$prepare_count"
  printf 'poll_count=%s\n' "$poll_count"
} > "$SUMMARY_OUT_FILE"

cat "$SUMMARY_OUT_FILE"
