#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
status_file="$repo_root/.well-known/sat-smt-offload-status.json"

vendored_z3="$repo_root/tools/solver/z3-4.13.0-x64-glibc-2.35/bin/z3"
if [ -z "${Z3PATH:-}" ]; then
  if [ -x "$vendored_z3" ]; then
    export Z3PATH="$vendored_z3"
  else
    export Z3PATH="$(command -v z3)"
  fi
fi

args=("$@")
if [ "${#args[@]}" -eq 0 ]; then
  args=(storage)
fi

solver_version="$($Z3PATH --version 2>/dev/null || echo 'unknown')"

echo "sat_smt_offloaded=true"
echo "solve_kind=smt"
echo "solve_report_offloaded_to=mu.local.z3"
echo "solver_path=$Z3PATH"
echo "solver_version=$solver_version"

tmp_output="$(mktemp)"
set +e
moon prove "${args[@]}" -v >"$tmp_output" 2>&1
prove_exit=$?
set -e

if [ $prove_exit -eq 0 ]; then
  cat > "$status_file" <<JSON
{
  "kind": "merkin.sat_smt.offload.status",
  "sat_smt_offloaded": true,
  "solve_kind": "smt",
  "solve_report_offloaded_to": "mu.local.z3",
  "solver_path": "${Z3PATH}",
  "solver_version": "${solver_version}",
  "moon_prove": "passed"
}
JSON
  cat "$tmp_output"
  rm -f "$tmp_output"
  exit 0
fi

if rg -q "no configured provers are available" "$tmp_output"; then
  cat > "$status_file" <<JSON
{
  "kind": "merkin.sat_smt.offload.status",
  "sat_smt_offloaded": true,
  "solve_kind": "smt",
  "solve_report_offloaded_to": "mu.local.z3",
  "solver_path": "${Z3PATH}",
  "solver_version": "${solver_version}",
  "moon_prove": "failed",
  "reason": "why3_harness has no configured provers available"
}
JSON
  echo "moon_prove_status=failed"
  echo "reason=why3_harness has no configured provers available"
fi

cat "$tmp_output"
rm -f "$tmp_output"
exit $prove_exit
