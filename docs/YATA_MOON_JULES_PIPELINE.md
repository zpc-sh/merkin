# Moon Build -> Yata -> Gemini Jules Pipeline

This pipeline turns `moon build` compiler diagnostics into:

1. open Yata holes (`.plan`) for replay/audit
2. one Jules-ready task per grouped compiler bug
3. per-hole deferral/resolution callback metadata

It is designed so we can dogfood Yata for real maintenance work without first fixing all compiler errors in this repo.

## Why this primitive

- `moon build --output-json` gives structured diagnostics.
- Yata gives deterministic IDs and replayable hole state.
- Jules handoff becomes a mechanical transformation, not manual triage.

## Command

```bash
tools/moon-build-yata-jules.sh
```

Optional submit hook for your Jules MCP adapter:

```bash
tools/moon-build-yata-jules.sh --submit-hook tools/jules-submit-hook.example.sh
```

Unified provider hooks (recommended):

```bash
AI_PROVIDER=jules-cli \
tools/moon-build-yata-jules.sh --submit-hook tools/ai-submit-hook.sh
```

Recursive integration test loop (real Jules flow):

```bash
tools/yata-jules-recursive-test.sh \
  --submit-hook tools/ai-submit-hook.sh \
  --status-hook tools/ai-status-hook.sh \
  --cancel-hook tools/ai-cancel-hook.sh \
  --cancel-on-timeout true \
  --max-rounds 3
```

The cognitive compiler/FSM/distributed planner commands are intentionally
de-scoped from the active workflow. This pipeline now focuses on:

- `moon build` diagnostics capture
- Yata `.plan` emission
- Jules task generation and callback orchestration

Override callback metadata (no hook required):

```bash
tools/moon-build-yata-jules.sh \
  --defer-enabled true \
  --callback-target gemini-jules \
  --callback-channel mcp \
  --callback-uri app://jules/tasks/update \
  --callback-on resolved
```

Control git provenance envelope emission:

```bash
tools/moon-build-yata-jules.sh \
  --git-report auto \
  --git-remote origin \
  --git-ref-limit 20
```

## Outputs

Default output dir: `_build/yata/moon-build/latest`

- `moon_build.raw.log`: complete `moon build` output
- `moon_diagnostics.jsonl`: raw diagnostic JSON lines
- `moon_errors.jsonl`: error-level diagnostics only
- `moon_errors_grouped.json`: grouped error families
- `jules_tasks.ndjson`: one task object per grouped bug
- `yata_resolution_callbacks.ndjson`: one callback contract per hole/task
- `moon_build.yata.plan`: Yata `.plan` with one open hole per grouped bug
- `summary.txt`: counts and artifact paths
- `submit_results.ndjson`: hook execution results (only with `--submit-hook`)

## Grouping behavior

Diagnostics are grouped by:

- `error_code`
- `path`
- first line of `message`

This avoids opening one task per duplicated location spam while preserving all locations inside each task payload.

## Yata mapping

Each grouped bug is mapped to a Yata entry:

- `hole_id`: `sha256:<hash(error_code|path|headline)>`
- `anchor`: `<path>:<line:col>` from first grouped location
- `state`: `open`
- `ready`: `true` (no dependencies)
- `candidate_count`: `0`
- `selected`: `none`
- `provenance`: `moon-build`

`.plan` also emits `self_report_*` metadata with `peer=gemini-jules` by default.

When git metadata is available, `.plan` also emits `git_report_*` headers (branch/remote/merge-base/head/commit-count/refs) so deferred Yata holes are replayable against VCS context.

## Deferral + callback metadata

Each emitted task now includes:

- `deferral`:
  - `deferred` (`true|false`)
  - `strategy` (`metadata-only`)
  - `status` (`deferred|immediate`)
- `resolution`:
  - `on_state` (`sealed|resolved` etc.)
  - `callback.contract_id`
  - `callback.target`
  - `callback.channel`
  - `callback.uri`

This metadata is also emitted into `yata_resolution_callbacks.ndjson` so another system can process resolution routing directly by `hole_id` without parsing task prompts.

Each task also carries optional `git` metadata (or `null` when unavailable) mirroring the `.plan` git envelope.

For branch hygiene, the pipeline also:

- parses branch names at byte-level (`branch_raw_hex`)
- strips `U+200B`, `U+200C`, `U+FEFF` into canonical `branch`
- marks `void_detected=true` when a ghosted branch canonicalizes to `main`

## Hook contract for Jules MCP

`--submit-hook` expects an executable with signature:

```text
<hook> <task-json-file> <task-index>
```

The hook receives one task JSON file at a time and should create the corresponding Jules task through your MCP bridge.

Non-zero hook exits are recorded in `submit_results.ndjson` but do not destroy generated Yata/task artifacts.

`tools/yata-jules-recursive-test.sh` adds a `--status-hook` contract:

```text
<status-hook> <task-json-file> <task-index>
```

Status hook must emit one JSON object:

```json
{"done": true, "ok": true, "state": "resolved", "detail": "optional"}
```

The recursive runner will poll status, then rerun the pipeline in rounds until `error_groups=0` or `--max-rounds` is reached.

## Unified provider hooks

- submit hook: `tools/ai-submit-hook.sh`
- status hook: `tools/ai-status-hook.sh`
- cancel hook: `tools/ai-cancel-hook.sh`
- response validator: `tools/ai-adapter-validate-v0_3.sh`

Validate hook output envelope quickly:

```bash
AI_PROVIDER=dry-run tools/ai-submit-hook.sh /tmp/task.json 1 \
  | tools/ai-adapter-validate-v0_3.sh --action submit
```

Provider selection:

- `AI_PROVIDER=jules-cli` (real Jules CLI submission + status via `jules remote list --session`)
- `AI_PROVIDER=jules-mcp` (bring-your-own command wrappers via env below)
- `AI_PROVIDER=dry-run` (no remote side effects)

Optional env for `jules-cli`:

- `AI_JULES_REPO=<owner/repo>` to force target repo

Required env for `jules-mcp` mode:

- `AI_JULES_MCP_SUBMIT_CMD` (shell command; last line must be JSON with at least `session_id`)
- `AI_JULES_MCP_STATUS_CMD` (shell command; last line must be JSON like `{"done":...,"ok":...,"state":"...","detail":"..."}`)
- `AI_JULES_MCP_CANCEL_CMD` (shell command; last line must be JSON like `{"done":...,"ok":...,"state":"...","detail":"..."}`)

The `v0.3` cognitive compiler documents are kept for historical reference only and are not part of the active implementation roadmap.

For provider-neutral adapter response/dispatch contract (`submit/status/cancel`), see `docs/AI_PROVIDER_ADAPTER_CONTRACT_v0.3.md`.

For a curated Mu language compiler/runtime handoff bundle, see:

- `docs/MU_LANG_COMPILER_HANDOFF.md`
