# Pactis RPC Guide (ash_typescript)

This guide shows how Pactis uses `ash_typescript` to expose a typed, framework‑agnostic RPC surface for UI clients (React, Svelte, etc.), including validation and Zod schemas.

## 1) Declare RPC on Domains

Enable the extension and declare actions and typed queries:

```elixir
defmodule Pactis.Core do
  use Ash.Domain, extensions: [AshJsonApi.Domain, AshTypescript.Rpc]

  typescript_rpc do
    resource Pactis.Blueprints.Blueprint do
      rpc_action :list_blueprints, :read
      typed_query :blueprint_cards, :read do
        ts_result_type_name "BlueprintCardResult"
        ts_fields_const_name "blueprintCardFields"
        fields [:id, :name, :slug, :version, :stars_count, :downloads_count]
      end
    end
  end
end
```

We’ve added RPC blocks to Core, Accounts, DesignTokens, and Spec.

## 2) Routes and Controller

Routes are mounted under authenticated API:

```
POST /rpc/run
POST /rpc/validate
```

Controller delegates to `AshTypescript.Rpc` to parse/execute/format requests.

## 3) Generate the TypeScript Client

Run locally to create `assets/js/ash_rpc.ts`:

```
mix ash_typescript.codegen --output assets/js/ash_rpc.ts
```

Configured in `config/config.exs`:

- `run_endpoint`: `/rpc/run`
- `validate_endpoint`: `/rpc/validate`
- `input_field_formatter` / `output_field_formatter`: `:camel_case`
- `generate_zod_schemas`: `true`
- `generate_validation_functions`: `true`

## 4) Using From UI

React example (see `assets/js/examples/react_rpc_example.tsx`):

```tsx
import { withAuthHeaders } from "../rpc_helpers";
import { listBlueprints, blueprintCardFields } from "../ash_rpc";

const headers = withAuthHeaders({}, () => localStorage.getItem("api_token"));
const result = await listBlueprints({ fields: blueprintCardFields, headers });
```

Svelte store example (see `assets/js/examples/svelte_rpc_example.ts`):

```ts
import { createBlueprintsStore } from "../examples/svelte_rpc_example";
const store = createBlueprintsStore(() => localStorage.getItem("api_token"));
```

Design Tokens form with Zod (React and Svelte examples provided under `assets/js/examples/`).

### Publish Component via RPC

Generate the client, then call the typed action:

```ts
import { publishComponent } from "../ash_rpc";

// Manifest describes the component; at minimum provide name, version, framework
const manifest = {
  name: "Card",
  version: "1.0.0",
  framework: "svelte",
  description: "Simple Card component",
};

// Read your zip/tgz bundle and base64-encode it
const bundleBytes = await (await fetch("/path/to/Card.zip")).arrayBuffer();
const bundleB64 = btoa(String.fromCharCode(...new Uint8Array(bundleBytes)));

const headers = { Authorization: `Bearer ${token}` };
const result = await publishComponent({ manifest, bundleB64 }, { headers });
// result contains the created Blueprint; component_files includes bundle metadata
```

Curl JSON example (direct RPC call)

```
curl -X POST "$PACTIS_BASE_URL/rpc/run" \
  -H "Authorization: Bearer $PACTIS_TOKEN" \
  -H "Content-Type: application/json" \
  -d @- <<'JSON'
{
  "domain": "Pactis.Core",
  "resource": "Pactis.Blueprints.Blueprint",
  "action": "publish_component",
  "input": {
    "manifest": {
      "name": "Card",
      "version": "1.0.0",
      "framework": "svelte",
      "description": "Simple Card component"
    },
    "bundleB64": "<base64-zip>"
  }
}
JSON
```

## 5) Validation

- `validate_*` functions mirror Ash validation (using `AshPhoenix.Form` under the hood).
- If Zod is enabled, schemas are generated for embedded types and form inputs.

## 6) Auth Considerations

- Endpoints are under `:api_authenticated`. Client requests must include an API token (`Authorization: Bearer <token>`).
- For browser UIs without API tokens, you can:
  - issue a user token after login and store in memory/localStorage;
  - or (alternate) move the RPC routes to `:api_optional_auth` and rely on Ash policies for authorization;
  - or (server-side) keep LV using direct Ash reads/changes.

## 7) Channels (optional)

- `ash_typescript` can generate Phoenix Channel RPC functions. We’ve disabled this initially. Enable by setting `generate_phx_channel_rpc_actions: true` in config and integrate with `UserSocket`.

## 8) Typed Queries

- Define a `typed_query` with a fields tree to generate both the TS result type and a reusable fields constant.
- Use the constant for refetching to keep payloads minimal and types consistent.

## 9) Troubleshooting Codegen

- If `mix ash_typescript.codegen` logs warnings but doesn’t write the file in your environment, run it locally outside of sandboxing.
- Ensure `zod` is available in your frontend build if Zod schemas are enabled.
