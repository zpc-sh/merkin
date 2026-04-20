# Pactis Component Generation — AshJsonApi & RPC

Status: Draft

This spec defines the component generation, imprint, and redraft interfaces exposed via AshJsonApi and RPC, including job orchestration and provider/model capabilities.

## Resources

### AI Tickets (Pactis.AI.Generator)
- Type: `ai_tickets`
- Routes:
  - `POST /ai/generator/generate_single_action`
  - `POST /ai/generator/generate_category_action`
  - `POST /ai/generator/generate_library_action`
  - `POST /ai/generator/redraft_action`
- Input fields:
  - generate_single: {category, name, description, provider?, model?, opts?}
  - generate_category: {category, count, provider?, model?, opts?}
  - generate_library: {target_count, provider?, model?, opts?}
  - redraft_action: {source_blueprint_id, prompt, provider?, model?, opts?, subscription_id?}
- Output: Ticket `{id, job_id, kind, status}`

### Capabilities (Pactis.AI.Capabilities)
- Type: `ai_capabilities`
- Routes:
  - `GET /ai/capabilities`
- Output:
  - `{ providers: [string], models: %{provider => [string]}, health: %{provider => %{status, latency_ms, error?}} }`

### Blueprints (Pactis.Blueprints.Blueprint)
- Type: `blueprints`
- Routes:
  - `GET /blueprints` (read)
  - `GET /blueprints/:id` (read)
  - `POST /blueprints/imprint_action` (body: `{source_blueprint_id, name?, slug?}`)
- Ownership & ACL:
  - `owner_user_id`, `owner_org_id`, `visibility` (:public | :internal | :private)
  - Policies TBD (owner-only writes; internal visible to org members)

## Job Status (REST Bridge)
- `GET /api/v1/components/jobs/:id` → `{status, attempt, attempts, result?}`
- Result may contain `{blueprint_id}` or `{blueprint_ids}` or `{stats}`

## Provider/Model Validation
- Server validates `provider` and `model` against config:
  - `config :pactis, :ai_models, %{ anthropic: ["claude-..."], openai: ["gpt-4o"], ... }`

## Usage Tracking
- On success, workers increment `components_created` via `UsageTracker.track_usage_async` when `subscription_id` is provided.

## Notes
- RPC (AshTypescript) also exposes these actions for typed UI clients.
- The legacy REST endpoints remain for transition (imprint, redraft/remix), and will be deprecated once clients adopt AshJsonApi.
