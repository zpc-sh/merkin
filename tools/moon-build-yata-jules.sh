#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Capture Moon compiler diagnostics and emit:
1) grouped compiler-bug tasks for Gemini Jules
2) a Yata `.plan` snapshot representing those tasks as open holes

Usage:
  tools/moon-build-yata-jules.sh [options]

Options:
  --out-dir <dir>          Output directory (default: _build/yata/moon-build/latest)
  --generator <name>       `.plan` generator tag (default: moon-build-yata-jules)
  --note <text>            `.plan` note (default: moon-build-compiler-bugs)
  --overlay <name>         self_report overlay (default: merkin)
  --peer <name>            self_report peer/Jules identity (default: gemini-jules)
  --authority <name>       self_report authority (default: local host name)
  --anchor <text>          self_report anchor hint (default: build/moon)
  --view <text>            self_report view hint (default: overlay)
  --conf-floor <uint>      confidence floor for emitted open holes (default: 70)
  --defer-enabled <bool>   mark tasks as deferred metadata (default: true)
  --callback-target <name> resolution callback target identity (default: gemini-jules)
  --callback-channel <id>  resolution callback channel (default: mcp)
  --callback-uri <uri>     resolution callback endpoint hint
                           (default: app://jules/tasks/update)
  --callback-on <state>    callback trigger state (default: resolved)
                           examples: sealed, resolved
  --git-report <mode>      git metadata envelope mode: auto|off (default: auto)
  --git-remote <name>      preferred remote for git metadata (default: origin)
  --git-ref-limit <uint>   max refs to emit in git_report_refs (default: 20)
  --submit-hook <path>     Executable called once per task:
                           <hook> <task-json-file> <task-index>
  -h, --help               Show this help

Outputs:
  moon_build.raw.log
  moon_diagnostics.jsonl
  moon_errors.jsonl
  moon_errors_grouped.json
  jules_tasks.ndjson
  yata_resolution_callbacks.ndjson
  moon_build.yata.plan
  summary.txt
  submit_results.ndjson (only when --submit-hook is provided)
EOF
}

to_rel_path() {
  local absolute_path="$1"
  if [[ "$absolute_path" == "$ROOT_DIR/"* ]]; then
    printf '%s' "${absolute_path#"$ROOT_DIR/"}"
  else
    printf '%s' "$absolute_path"
  fi
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT_DIR/_build/yata/moon-build/latest"
GENERATOR="moon-build-yata-jules"
NOTE="moon-build-compiler-bugs"
OVERLAY="merkin"
PEER="gemini-jules"
AUTHORITY="$(hostname 2>/dev/null || printf 'local-host')"
ANCHOR_HINT="build/moon"
VIEW_HINT="overlay"
CONF_FLOOR=70
DEFER_ENABLED=true
CALLBACK_TARGET="gemini-jules"
CALLBACK_CHANNEL="mcp"
CALLBACK_URI="app://jules/tasks/update"
CALLBACK_ON="resolved"
GIT_REPORT_MODE="auto"
GIT_REMOTE="origin"
GIT_REF_LIMIT=20
SUBMIT_HOOK=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out-dir)
      OUT_DIR="$2"
      shift 2
      ;;
    --generator)
      GENERATOR="$2"
      shift 2
      ;;
    --note)
      NOTE="$2"
      shift 2
      ;;
    --overlay)
      OVERLAY="$2"
      shift 2
      ;;
    --peer)
      PEER="$2"
      shift 2
      ;;
    --authority)
      AUTHORITY="$2"
      shift 2
      ;;
    --anchor)
      ANCHOR_HINT="$2"
      shift 2
      ;;
    --view)
      VIEW_HINT="$2"
      shift 2
      ;;
    --conf-floor)
      CONF_FLOOR="$2"
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
    --submit-hook)
      SUBMIT_HOOK="$2"
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

if ! [[ "$CONF_FLOOR" =~ ^[0-9]+$ ]]; then
  printf 'Expected --conf-floor to be an unsigned integer, got: %s\n' "$CONF_FLOOR" >&2
  exit 1
fi

if [[ "$DEFER_ENABLED" != "true" && "$DEFER_ENABLED" != "false" ]]; then
  printf 'Expected --defer-enabled to be true|false, got: %s\n' "$DEFER_ENABLED" >&2
  exit 1
fi

if [[ "$GIT_REPORT_MODE" != "auto" && "$GIT_REPORT_MODE" != "off" ]]; then
  printf 'Expected --git-report to be auto|off, got: %s\n' "$GIT_REPORT_MODE" >&2
  exit 1
fi

if ! [[ "$GIT_REF_LIMIT" =~ ^[0-9]+$ ]]; then
  printf 'Expected --git-ref-limit to be an unsigned integer, got: %s\n' "$GIT_REF_LIMIT" >&2
  exit 1
fi

if [[ -n "$SUBMIT_HOOK" && ! -x "$SUBMIT_HOOK" ]]; then
  printf 'Submit hook is not executable: %s\n' "$SUBMIT_HOOK" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

RAW_LOG_FILE="$OUT_DIR/moon_build.raw.log"
DIAGNOSTICS_FILE="$OUT_DIR/moon_diagnostics.jsonl"
ERRORS_FILE="$OUT_DIR/moon_errors.jsonl"
GROUPED_FILE="$OUT_DIR/moon_errors_grouped.json"
TASKS_FILE="$OUT_DIR/jules_tasks.ndjson"
CALLBACKS_FILE="$OUT_DIR/yata_resolution_callbacks.ndjson"
PLAN_FILE="$OUT_DIR/moon_build.yata.plan"
SUMMARY_FILE="$OUT_DIR/summary.txt"
SUBMIT_RESULTS_FILE="$OUT_DIR/submit_results.ndjson"

git_report_enabled=false
git_branch=""
git_branch_raw=""
git_branch_raw_hex=""
git_branch_has_ghosts=false
git_void_detected=false
git_remote="$GIT_REMOTE"
git_merge_base=""
git_head=""
git_commit_count=0
git_refs=""

if [[ "$GIT_REPORT_MODE" == "auto" ]]; then
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git_branch_raw="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
    git_branch_raw_hex="$(printf '%s' "$git_branch_raw" | od -An -tx1 | tr -d ' \n')"
    if command -v perl >/dev/null 2>&1; then
      git_branch="$(printf '%s' "$git_branch_raw" | perl -CSD -pe 's/\x{200B}|\x{200C}|\x{FEFF}//g')"
    else
      git_branch="$git_branch_raw"
    fi
    if [[ "$git_branch" != "$git_branch_raw" ]]; then
      git_branch_has_ghosts=true
      if [[ "$git_branch" == "main" ]]; then
        git_void_detected=true
      fi
    fi
    git_head="$(git rev-parse HEAD 2>/dev/null || true)"

    upstream_ref="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)"
    if [[ -n "$upstream_ref" ]]; then
      git_remote="${upstream_ref%%/*}"
      git_merge_base="$(git merge-base HEAD "$upstream_ref" 2>/dev/null || true)"
    else
      remote_head_ref="${git_remote}/${git_branch}"
      if git show-ref --verify --quiet "refs/remotes/${remote_head_ref}"; then
        git_merge_base="$(git merge-base HEAD "$remote_head_ref" 2>/dev/null || true)"
      fi
    fi

    if [[ -n "$git_merge_base" ]]; then
      git_commit_count="$(git rev-list --count "${git_merge_base}..HEAD" 2>/dev/null || printf '0')"
    elif [[ -n "$git_head" ]]; then
      git_commit_count="$(git rev-list --count HEAD 2>/dev/null || printf '0')"
    fi

    if [[ "$GIT_REF_LIMIT" -gt 0 ]]; then
      git_refs="$(git log --pretty=format:%H -n "$GIT_REF_LIMIT" 2>/dev/null | paste -sd, - || true)"
    fi

    if [[ -n "$git_branch" ]]; then
      git_report_enabled=true
    fi
  fi
fi

set +e
moon build --output-json 2>&1 | tee "$RAW_LOG_FILE"
MOON_EXIT=${PIPESTATUS[0]}
set -e

grep -E '^\{"\$message_type":"diagnostic"' "$RAW_LOG_FILE" > "$DIAGNOSTICS_FILE" || true
jq -c 'select(.["$message_type"] == "diagnostic" and .level == "error")' "$DIAGNOSTICS_FILE" > "$ERRORS_FILE" || true

jq -s '
  map({
    error_code: (.error_code | tostring),
    path: (if .path == "" then "unknown" else .path end),
    loc: (if .loc == "" then "0:0-0:0" else .loc end),
    message: (.message // ""),
    headline: ((.message // "") | split("\n")[0]),
    key: ((.error_code | tostring)
      + "|" + (if .path == "" then "unknown" else .path end)
      + "|" + (((.message // "") | split("\n")[0]))
    ),
  })
  | sort_by(.key, .loc)
  | group_by(.key)
  | map({
      error_code: .[0].error_code,
      path: .[0].path,
      headline: .[0].headline,
      message: .[0].message,
      occurrences: length,
      locations: [.[].loc],
    })
' "$ERRORS_FILE" > "$GROUPED_FILE"

: > "$TASKS_FILE"
while IFS= read -r grouped; do
  [[ -z "$grouped" ]] && continue

  error_code="$(jq -r '.error_code' <<<"$grouped")"
  absolute_path="$(jq -r '.path' <<<"$grouped")"
  relative_path="$(to_rel_path "$absolute_path")"
  headline="$(jq -r '.headline' <<<"$grouped")"
  message="$(jq -r '.message' <<<"$grouped")"
  occurrences="$(jq -r '.occurrences' <<<"$grouped")"
  first_loc="$(jq -r '.locations[0]' <<<"$grouped")"
  anchor="${relative_path}:${first_loc%%-*}"
  signature="${error_code}|${relative_path}|${headline}"
  hole_hash="$(printf '%s' "$signature" | sha256sum | awk '{print $1}')"
  hole_id="sha256:${hole_hash}"
  task_id="moon-${hole_hash:0:12}"
  title="[moon:${error_code}] ${headline}"
  prompt="$(printf '%s\n%s\n%s\n%s\n%s\n%s\n%s\n' \
    "Fix the MoonBit compiler error family below." \
    "File: ${relative_path}" \
    "Representative location: ${first_loc}" \
    "Occurrences in this run: ${occurrences}" \
    "Compiler message:" \
    "${message}" \
    "When done, include exact edits and the verification command output."
  )"

  jq -nc \
    --arg task_id "$task_id" \
    --arg title "$title" \
    --arg error_code "$error_code" \
    --arg path "$relative_path" \
    --arg loc "$first_loc" \
    --arg message "$message" \
    --argjson occurrences "$occurrences" \
    --argjson locations "$(jq -c '.locations' <<<"$grouped")" \
    --arg hole_id "$hole_id" \
    --arg anchor "$anchor" \
    --argjson conf_floor "$CONF_FLOOR" \
    --argjson deferred "$DEFER_ENABLED" \
    --arg callback_target "$CALLBACK_TARGET" \
    --arg callback_channel "$CALLBACK_CHANNEL" \
    --arg callback_uri "$CALLBACK_URI" \
    --arg callback_on "$CALLBACK_ON" \
    --arg contract_id "callback:${CALLBACK_CHANNEL}:${CALLBACK_TARGET}" \
    --argjson git_report_enabled "$git_report_enabled" \
    --arg git_branch "$git_branch" \
    --arg git_branch_raw "$git_branch_raw" \
    --arg git_branch_raw_hex "$git_branch_raw_hex" \
    --argjson git_branch_has_ghosts "$git_branch_has_ghosts" \
    --argjson git_void_detected "$git_void_detected" \
    --arg git_remote "$git_remote" \
    --arg git_merge_base "$git_merge_base" \
    --arg git_head "$git_head" \
    --argjson git_commit_count "$git_commit_count" \
    --arg git_refs "$git_refs" \
    --arg peer "$PEER" \
    --arg prompt "$prompt" \
    '{
      task_id: $task_id,
      title: $title,
      type: "compiler_bug",
      diagnostic: {
        error_code: $error_code,
        path: $path,
        loc: $loc,
        message: $message,
        occurrences: $occurrences,
        locations: $locations
      },
      yata: {
        hole_id: $hole_id,
        anchor: $anchor,
        state: "open",
        ready: true,
        deferred: $deferred,
        candidate_count: 0,
        confidence_floor: $conf_floor,
        selected_candidate: null,
        provenance: ["moon-build"]
      },
      deferral: {
        deferred: $deferred,
        strategy: "metadata-only",
        status: (if $deferred then "deferred" else "immediate" end)
      },
      resolution: {
        on_state: $callback_on,
        callback: {
          contract_id: $contract_id,
          target: $callback_target,
          channel: $callback_channel,
          uri: $callback_uri
        }
      },
      git: (
        if $git_report_enabled then {
          branch: $git_branch,
          branch_raw: $git_branch_raw,
          branch_raw_hex: $git_branch_raw_hex,
          branch_has_ghosts: $git_branch_has_ghosts,
          void_detected: $git_void_detected,
          remote: $git_remote,
          merge_base: $git_merge_base,
          head: $git_head,
          commit_count: $git_commit_count,
          refs: $git_refs
        } else null end
      ),
      jules: {
        target: $peer,
        prompt: $prompt
      }
    }' >> "$TASKS_FILE"
done < <(jq -c '.[]' "$GROUPED_FILE")

entry_count="$(jq -s 'length' "$TASKS_FILE")"
material_hash="sha256:$(sha256sum "$TASKS_FILE" | awk '{print $1}')"

if [[ -s "$TASKS_FILE" ]]; then
  jq -c '{
    hole_id: .yata.hole_id,
    anchor: .yata.anchor,
    state: .yata.state,
    task_id: .task_id,
    deferral: .deferral,
    resolution: .resolution
  }' "$TASKS_FILE" > "$CALLBACKS_FILE"
else
  : > "$CALLBACKS_FILE"
fi

{
  printf 'kind: merkin.yata.plan\n'
  printf 'track=program\n'
  printf 'mode=full\n'
  printf 'generator=%s\n' "$GENERATOR"
  printf 'note=%s\n' "$NOTE"
  printf 'material_hash=%s\n' "$material_hash"
  printf 'entries=%s\n' "$entry_count"
  printf 'self_report=1\n'
  printf 'self_report_overlay=%s\n' "$OVERLAY"
  printf 'self_report_peer=%s\n' "$PEER"
  printf 'self_report_authority=%s\n' "$AUTHORITY"
  printf 'self_report_anchor=%s\n' "$ANCHOR_HINT"
  printf 'self_report_gap=1\n'
  printf 'self_report_view=%s\n' "$VIEW_HINT"
  if [[ "$git_report_enabled" == "true" ]]; then
    printf 'git_report=1\n'
    printf 'git_report_branch=%s\n' "$git_branch"
    printf 'git_report_remote=%s\n' "$git_remote"
    printf 'git_report_merge_base=%s\n' "$git_merge_base"
    printf 'git_report_head=%s\n' "$git_head"
    printf 'git_report_commit_count=%s\n' "$git_commit_count"
    printf 'git_report_refs=%s\n' "$git_refs"
  fi
  if [[ -s "$TASKS_FILE" ]]; then
    jq -r '[
      "-",
      .yata.hole_id,
      .yata.anchor,
      .yata.state,
      ("ready=" + (.yata.ready | tostring)),
      ("candidates=" + (.yata.candidate_count | tostring)),
      ("conf_floor=" + (.yata.confidence_floor | tostring)),
      ("selected=" + (if .yata.selected_candidate == null then "none" else .yata.selected_candidate end)),
      ("provenance=" + (.yata.provenance | length | tostring))
    ] | join(" ")' "$TASKS_FILE"
  fi
} > "$PLAN_FILE"

submitted_count=0
failed_submissions=0
if [[ -n "$SUBMIT_HOOK" && -s "$TASKS_FILE" ]]; then
  : > "$SUBMIT_RESULTS_FILE"
  task_index=0
  while IFS= read -r task_json; do
    task_index=$((task_index + 1))
    task_file="$OUT_DIR/task_${task_index}.json"
    printf '%s\n' "$task_json" > "$task_file"

    set +e
    hook_output="$("$SUBMIT_HOOK" "$task_file" "$task_index" 2>&1)"
    hook_status=$?
    set -e

    ok=false
    if [[ $hook_status -eq 0 ]]; then
      ok=true
      submitted_count=$((submitted_count + 1))
    else
      failed_submissions=$((failed_submissions + 1))
    fi

    jq -nc \
      --argjson task_index "$task_index" \
      --arg task_file "$task_file" \
      --arg hook "$SUBMIT_HOOK" \
      --arg output "$hook_output" \
      --argjson ok "$ok" \
      '{
        task_index: $task_index,
        task_file: $task_file,
        hook: $hook,
        ok: $ok,
        output: $output
      }' >> "$SUBMIT_RESULTS_FILE"
  done < "$TASKS_FILE"
fi

{
  printf 'moon_exit=%s\n' "$MOON_EXIT"
  printf 'diagnostics_total=%s\n' "$(wc -l < "$DIAGNOSTICS_FILE" | tr -d ' ')"
  printf 'errors_total=%s\n' "$(wc -l < "$ERRORS_FILE" | tr -d ' ')"
  printf 'error_groups=%s\n' "$entry_count"
  printf 'tasks_file=%s\n' "$TASKS_FILE"
  printf 'callbacks_file=%s\n' "$CALLBACKS_FILE"
  printf 'plan_file=%s\n' "$PLAN_FILE"
  printf 'defer_enabled=%s\n' "$DEFER_ENABLED"
  printf 'callback_target=%s\n' "$CALLBACK_TARGET"
  printf 'callback_channel=%s\n' "$CALLBACK_CHANNEL"
  printf 'callback_uri=%s\n' "$CALLBACK_URI"
  printf 'callback_on=%s\n' "$CALLBACK_ON"
  printf 'git_report_mode=%s\n' "$GIT_REPORT_MODE"
  printf 'git_report_enabled=%s\n' "$git_report_enabled"
  printf 'git_branch=%s\n' "$git_branch"
  printf 'git_branch_raw=%s\n' "$git_branch_raw"
  printf 'git_branch_raw_hex=%s\n' "$git_branch_raw_hex"
  printf 'git_branch_has_ghosts=%s\n' "$git_branch_has_ghosts"
  printf 'git_void_detected=%s\n' "$git_void_detected"
  printf 'git_remote=%s\n' "$git_remote"
  printf 'git_head=%s\n' "$git_head"
  printf 'git_merge_base=%s\n' "$git_merge_base"
  printf 'git_commit_count=%s\n' "$git_commit_count"
  printf 'git_ref_limit=%s\n' "$GIT_REF_LIMIT"
  if [[ -n "$SUBMIT_HOOK" ]]; then
    printf 'submit_hook=%s\n' "$SUBMIT_HOOK"
    printf 'submitted_count=%s\n' "$submitted_count"
    printf 'failed_submissions=%s\n' "$failed_submissions"
    printf 'submit_results=%s\n' "$SUBMIT_RESULTS_FILE"
  fi
} > "$SUMMARY_FILE"

cat "$SUMMARY_FILE"
