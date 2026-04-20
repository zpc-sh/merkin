# Pactis AI Component Generation Pipeline

This document describes the public API for the Pactis generative UI component pipeline and how agents can invoke it.

## Endpoints

- `POST /api/v1/ai/generate/single`
  - Body:
    ```json
    {
      "category": "forms",
      "name": "LoginForm",
      "description": "Secure login with validation",
      "options": {"frameworks": ["phoenix", "svelte"], "dry_run": false}
    }
    ```
  - Response: `{ "status": "ok", "result": { ...generated component... } }`
  - curl:
    ```bash
    curl -X POST \
      -H "Authorization: Bearer $PACTIS_TOKEN" \
      -H "Content-Type: application/json" \
      -d '{"category":"forms","name":"LoginForm","description":"Secure login","options":{"frameworks":["phoenix"],"dry_run":false}}' \
      http://localhost:4000/api/v1/ai/generate/single
    ```

- `POST /api/v1/ai/generate/category`
  - Body:
    ```json
    { "category": "tables", "count": 10, "options": {"quality_threshold": 75} }
    ```
  - Response: `{ "status": "ok", "results": [ ... ] }`
  - curl:
    ```bash
    curl -X POST \
      -H "Authorization: Bearer $PACTIS_TOKEN" \
      -H "Content-Type: application/json" \
      -d '{"category":"tables","count":10,"options":{"quality_threshold":75}}' \
      http://localhost:4000/api/v1/ai/generate/category
    ```

- `POST /api/v1/ai/generate/library`
  - Body:
    ```json
    { "target_count": 100, "options": {"distribution": {"forms": 30, "tables": 20}, "dry_run": true} }
    ```
  - Response: `{ "status": "ok", "report": { "dry_run": true, "plan": { ... }, "estimate": { ... } } }`
  - curl:
    ```bash
    curl -X POST \
      -H "Authorization: Bearer $PACTIS_TOKEN" \
      -H "Content-Type: application/json" \
      -d '{"target_count":100,"options":{"distribution":{"forms":30,"tables":20},"dry_run":true}}' \
      http://localhost:4000/api/v1/ai/generate/library
    ```

- `GET /api/v1/ai/generate/stats`
  - Returns aggregate stats about components, providers, usage, cache and quality.
  - curl:
    ```bash
    curl -H "Authorization: Bearer $PACTIS_TOKEN" http://localhost:4000/api/v1/ai/generate/stats
    ```

- `GET /api/v1/ai/generate/validate`
  - Runs validation across generated components; returns counts and issues.
  - curl:
    ```bash
    curl -H "Authorization: Bearer $PACTIS_TOKEN" http://localhost:4000/api/v1/ai/generate/validate
    ```

## Authentication
- Requires API token; pass as `Authorization: Bearer <token>`.
- Scopes:
  - write:components — required for generate endpoints (single/category/library)
  - read:components — required for read-only endpoints (stats/validate)
- Provider API keys should use SSHS (`SECRETSDIR` + `*_API_KEY_FILE`).

## Notes
- Endpoints call into the orchestrator `Pactis.AI.ComponentGenerator`.
- For dry runs, use `options.dry_run: true` to get a plan and cost estimate without storing artifacts.
- Quality thresholds can be set via `options.quality_threshold` (default 70).

See also: `docs/AI_DISCOVERY.md` and `docs/wiki/specapi_for_ai.md`.
