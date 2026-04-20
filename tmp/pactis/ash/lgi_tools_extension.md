# Ash LGI Tools Extension

Declare LGI-compatible tools at the resource level. Tools map to resource actions
and are exposed via the LGI tools registry and execution endpoints.

Usage

```elixir
defmodule MyApp.Repositories.Repository do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshLgiTools.Extension]

  tools do
    tool :repo_transfer do
      action :transfer_ownership
      idempotency true
      auth_scopes [:repo_admin]
      description "Transfer repository to a user or organization"
      tags [:repository]

      input_schema %{
        type: "object",
        required: ["target_owner_type"],
        properties: %{
          "target_owner_type" => %{enum: ["organization", "user"]},
          "target_org_id" => %{type: ["string", "null"]},
          "target_user_id" => %{type: ["string", "null"]}
        }
      }

      output_schema %{
        type: "object",
        properties: %{"status" => %{enum: ["ok"]}}
      }
    end
  end
end
```

Runtime
- The extension is config-only. The LGI layer reads the tools registry and:
  - Serves `GET /api/v1/lgi/tools` (catalog)
  - Executes tools via `POST /api/v1/lgi/execute` by dispatching to resource actions
- Eventing/idempotency/trace are enforced at the LGI boundary.

Notes
- Keep schemas small and focused; large shapes can be referenced via `$ref` to your JSON Schema files.
- Use `auth_scopes` and `visibility` to help clients discover and respect access controls.
- Idempotency should be true for state-changing operations that support it.

