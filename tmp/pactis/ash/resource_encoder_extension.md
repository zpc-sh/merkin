# ash_resource_blueprint — Resource Blueprint Extension

Configure how a resource is encoded to a JSON‑LD blueprint via a simple DSL.

Usage

```elixir
defmodule MyApp.Accounts.User do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshResourceBlueprint.Extension]

  resource_blueprint do
    jsonld_context %{ "@vocab" => "https://pactis.dev/vocab#", "schema" => "https://schema.org/" }
    include [:attributes, :relationships, :actions]
    # exclude [:validations, :calculations]
  end
end
```

The extension only persists configuration. Pactis.ResourceEncoder reads these
options at runtime to produce the encoded document. If no options are specified,
Pactis defaults are used.

Sections
- jsonld_context: map to override the JSON‑LD `@context`
- include: list of sections to keep (attributes, relationships, actions, validations,
  calculations, aggregates, preparations, changes, meta)
- exclude: list of sections to omit (ignored when `include` is present)

Compatibility
- The legacy DSL `resource_encoder` (Pactis.ResourceEncoder.Extension) still works
  but is deprecated; this extension is preferred.

Publishing
- For Hex, extract to a standalone repo `ash_resource_blueprint` while keeping code vendored here.
