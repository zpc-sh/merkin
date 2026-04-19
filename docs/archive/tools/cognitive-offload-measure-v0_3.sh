#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Estimate coordination/fix effort offload from cognitive compiler outputs (v0.3).

Usage:
  tools/cognitive-offload-measure-v0_3.sh [options]

Options:
  --summary-file <path>               Cognitive compiler summary.txt
                                      (default: _build/cognitive/v0.3/latest/summary.txt)
  --out-file <path>                   Output JSON path
                                      (default: <summary-dir>/offload_measurement.v0_3.json)
  --coord-minutes-per-hole <n>        Manual triage+handoff minutes per hole (default: 7)
  --automation-overhead-minutes <n>   Fixed automation overhead minutes per run (default: 10)
  --fix-minutes-low <n>               Lower bound manual fix+verify minutes per hole (default: 12)
  --fix-minutes-high <n>              Upper bound manual fix+verify minutes per hole (default: 30)
  --active-delegation-coverage <n>    Override active delegation coverage [0..1]
                                      (default: inferred from summary mode/queues)
  -h, --help                          Show this help
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

is_decimal_0_1() {
  [[ "$1" =~ ^(0(\.[0-9]+)?|1(\.0+)?)$ ]]
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUMMARY_FILE="$ROOT_DIR/_build/cognitive/v0.3/latest/summary.txt"
OUT_FILE=""
COORD_MIN_PER_HOLE=7
AUTOMATION_OVERHEAD_MIN=10
FIX_MINUTES_LOW=12
FIX_MINUTES_HIGH=30
COVERAGE_OVERRIDE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --summary-file)
      SUMMARY_FILE="$2"
      shift 2
      ;;
    --out-file)
      OUT_FILE="$2"
      shift 2
      ;;
    --coord-minutes-per-hole)
      COORD_MIN_PER_HOLE="$2"
      shift 2
      ;;
    --automation-overhead-minutes)
      AUTOMATION_OVERHEAD_MIN="$2"
      shift 2
      ;;
    --fix-minutes-low)
      FIX_MINUTES_LOW="$2"
      shift 2
      ;;
    --fix-minutes-high)
      FIX_MINUTES_HIGH="$2"
      shift 2
      ;;
    --active-delegation-coverage)
      COVERAGE_OVERRIDE="$2"
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

if [[ ! -f "$SUMMARY_FILE" ]]; then
  printf 'Summary file not found: %s\n' "$SUMMARY_FILE" >&2
  exit 1
fi

for n in "$COORD_MIN_PER_HOLE" "$AUTOMATION_OVERHEAD_MIN" "$FIX_MINUTES_LOW" "$FIX_MINUTES_HIGH"; do
  if ! is_uint "$n"; then
    printf 'Expected unsigned integer numeric options, got: %s\n' "$n" >&2
    exit 1
  fi
done
if [[ "$FIX_MINUTES_LOW" -gt "$FIX_MINUTES_HIGH" ]]; then
  printf 'Expected --fix-minutes-low <= --fix-minutes-high\n' >&2
  exit 1
fi
if [[ -n "$COVERAGE_OVERRIDE" ]] && ! is_decimal_0_1 "$COVERAGE_OVERRIDE"; then
  printf 'Expected --active-delegation-coverage in [0,1], got: %s\n' "$COVERAGE_OVERRIDE" >&2
  exit 1
fi

summary_dir="$(cd "$(dirname "$SUMMARY_FILE")" && pwd)"
if [[ -z "$OUT_FILE" ]]; then
  OUT_FILE="$summary_dir/offload_measurement.v0_3.json"
fi

mode="$(summary_value "mode" "$SUMMARY_FILE")"
if [[ -z "$mode" ]]; then
  mode="markup"
fi

ir_count="$(summary_value "ir_count" "$SUMMARY_FILE")"
resolved_count="$(summary_value "resolved_count" "$SUMMARY_FILE")"
prepare_queue_count="$(summary_value "prepare_queue_count" "$SUMMARY_FILE")"
delegate_queue_count="$(summary_value "delegate_queue_count" "$SUMMARY_FILE")"
poll_count="$(summary_value "poll_count" "$SUMMARY_FILE")"

for k in ir_count resolved_count prepare_queue_count delegate_queue_count poll_count; do
  v="${!k}"
  if [[ -z "$v" ]]; then
    v=0
  fi
  if ! is_uint "$v"; then
    printf 'Expected %s to be unsigned integer in summary, got: %s\n' "$k" "$v" >&2
    exit 1
  fi
  printf -v "$k" '%s' "$v"
done

if [[ -n "$COVERAGE_OVERRIDE" ]]; then
  coverage="$COVERAGE_OVERRIDE"
else
  if [[ "$mode" == "active" ]]; then
    coverage="1"
  else
    coverage="0"
  fi
fi

distributed_summary_file="$(summary_value "distributed_summary_file" "$SUMMARY_FILE")"
distributed_assignment_count=0
if [[ -n "$distributed_summary_file" ]]; then
  if [[ "$distributed_summary_file" != /* ]]; then
    if [[ -f "$ROOT_DIR/$distributed_summary_file" ]]; then
      distributed_summary_file="$ROOT_DIR/$distributed_summary_file"
    elif [[ -f "$summary_dir/$distributed_summary_file" ]]; then
      distributed_summary_file="$summary_dir/$distributed_summary_file"
    fi
  fi
  if [[ -f "$distributed_summary_file" ]]; then
    distributed_assignment_count="$(summary_value "assignment_count" "$distributed_summary_file")"
    if [[ -z "$distributed_assignment_count" || ! "$distributed_assignment_count" =~ ^[0-9]+$ ]]; then
      distributed_assignment_count=0
    fi
  fi
fi

jq -n \
  --arg summary_file "$SUMMARY_FILE" \
  --arg out_file "$OUT_FILE" \
  --arg mode "$mode" \
  --argjson holes_total "$ir_count" \
  --argjson holes_resolved "$resolved_count" \
  --argjson prepare_queue "$prepare_queue_count" \
  --argjson delegate_queue "$delegate_queue_count" \
  --argjson poll_queue "$poll_count" \
  --argjson coord_min_per_hole "$COORD_MIN_PER_HOLE" \
  --argjson automation_overhead_min "$AUTOMATION_OVERHEAD_MIN" \
  --argjson fix_min_low "$FIX_MINUTES_LOW" \
  --argjson fix_min_high "$FIX_MINUTES_HIGH" \
  --argjson coverage "$coverage" \
  --argjson distributed_assignment_count "$distributed_assignment_count" \
  '
  .kind = "merkin.cognitive.offload.measurement"
  | .version = "0.3"
  | .summary_file = $summary_file
  | .out_file = $out_file
  | .mode = $mode
  | .typed_hole_algebra = {
      H_total: $holes_total,
      H_resolved: $holes_resolved,
      H_open: ($holes_total - $holes_resolved),
      H_active: ($prepare_queue + $delegate_queue + $poll_queue),
      additive_identity_holds: (($holes_total - $holes_resolved + $holes_resolved) == $holes_total)
    }
  | .lane_mass = {
      prepare: $prepare_queue,
      delegate: $delegate_queue,
      poll: $poll_queue,
      distributed_assignments: $distributed_assignment_count
    }
  | .offload_estimate = {
      assumptions: {
        coord_minutes_per_hole: $coord_min_per_hole,
        automation_overhead_minutes: $automation_overhead_min,
        fix_minutes_low_per_hole: $fix_min_low,
        fix_minutes_high_per_hole: $fix_min_high,
        active_delegation_coverage: $coverage
      },
      coordination: {
        manual_minutes: ($holes_total * $coord_min_per_hole),
        automated_minutes: ($automation_overhead_min + ($holes_total * 0.3)),
        saved_minutes: (($holes_total * $coord_min_per_hole) - ($automation_overhead_min + ($holes_total * 0.3)))
      },
      fix_work_potential: {
        manual_minutes_low: ($holes_total * $fix_min_low),
        manual_minutes_high: ($holes_total * $fix_min_high),
        delegated_minutes_low: (($holes_total * $fix_min_low) * $coverage),
        delegated_minutes_high: (($holes_total * $fix_min_high) * $coverage)
      }
    }
  ' > "$OUT_FILE"

jq -nc \
  --argjson obj "$(cat "$OUT_FILE")" \
  '{
    kind: $obj.kind,
    version: $obj.version,
    mode: $obj.mode,
    holes_total: $obj.typed_hole_algebra.H_total,
    holes_resolved: $obj.typed_hole_algebra.H_resolved,
    coordination_saved_minutes: $obj.offload_estimate.coordination.saved_minutes,
    delegated_fix_minutes_low: $obj.offload_estimate.fix_work_potential.delegated_minutes_low,
    delegated_fix_minutes_high: $obj.offload_estimate.fix_work_potential.delegated_minutes_high,
    out_file: $obj.out_file
  }'
