# AI Provider Adapter Contract (v0.3-draft)

This document defines a provider-neutral runtime adapter contract for deferred Yata work.

The goal is to let multiple AI backends share one integration surface (`submit`, `status`, `cancel`) without changing compiler/runtime orchestration.

## 1. Actions

Required actions:

1. `submit`
2. `status`
3. `cancel`

Each action is implemented as an executable hook with the same signature:

```text
<hook> <task-json-file> <task-index>
```

## 2. Common response envelope

Hooks should emit JSON on stdout (last line is authoritative):

```json
{
  "kind": "merkin.ai.adapter.response",
  "version": "0.3",
  "contract": "merkin.ai.adapter.v0_3",
  "action": "submit|status|cancel",
  "provider": "dry-run|jules-cli|jules-mcp|...",
  "session_id": "provider session id or empty",
  "done": false,
  "ok": true,
  "state": "submitted|planning|resolved|failed|...",
  "detail": "short diagnostic detail"
}
```

Notes:

- `done` is most meaningful for `status` and `cancel`.
- `ok` indicates whether action completed successfully from the adapter perspective.
- additional fields are allowed and should be ignored by strict-minimal consumers.

## 3. Task/dispatch state expectations

Adapters should update task JSON dispatch metadata so orchestration can continue without reparsing raw logs.

Recommended dispatch keys:

- `.dispatch.provider`
- `.dispatch.session_id`
- `.dispatch.session_url` (optional)
- `.dispatch.state`
- `.dispatch.done` (for status/cancel)
- `.dispatch.ok` (for status/cancel)
- `.dispatch.detail` (for status/cancel)
- `.dispatch.cancel` object for cancel-specific records

## 4. Reference hooks in this repo

- `tools/ai-submit-hook.sh`
- `tools/ai-status-hook.sh`
- `tools/ai-cancel-hook.sh`
- `tools/ai-adapter-validate-v0_3.sh` (envelope validator)

Provider modes currently supported:

- `AI_PROVIDER=dry-run`
- `AI_PROVIDER=jules-cli`
- `AI_PROVIDER=jules-mcp`

## 5. Provider-specific env hooks

For `jules-mcp` bring-your-own wrappers:

- `AI_JULES_MCP_SUBMIT_CMD`
- `AI_JULES_MCP_STATUS_CMD`
- `AI_JULES_MCP_CANCEL_CMD`

These commands run with env context such as:

- `TASK_JSON_FILE`
- `TASK_INDEX`
- `TASK_PROMPT` (submit)
- `TASK_ID` (submit)
- `SESSION_ID` (status/cancel)

Each wrapper must print a JSON object on the last output line.

## 6. Minimal action payloads

### 6.1 Submit

Expected minimum from wrapper output:

```json
{"session_id": "abc123", "state": "submitted"}
```

### 6.2 Status

Expected minimum from wrapper output:

```json
{"done": false, "ok": false, "state": "planning", "detail": "queued"}
```

### 6.3 Cancel

Expected minimum from wrapper output:

```json
{"done": true, "ok": true, "state": "canceled", "detail": "cancel accepted"}
```

## 7. Behavior notes for Jules CLI

Current Jules CLI exposes `remote new/list/pull`.

- `submit`: supported (`jules remote new`)
- `status`: supported (`jules remote list --session` parsing)
- `cancel`: not exposed as a native CLI command currently; adapter reports `cancel_not_supported`

## 8. Compatibility policy

- `v0.3.x` is additive only.
- required response keys in section 2 should remain stable.
- unknown fields in responses and dispatch metadata should be ignored by consumers.
