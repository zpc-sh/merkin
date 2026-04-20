# Ash Resource Encoder/Decoder Implementation

## Purpose
Create a system to serialize Ash resources into structured data (for Blueprint storage) and deserialize them back into Igniter generation commands.

## Core Architecture

### 1. ResourceEncoder Module
Location: `lib/pactis/resource_encoder.ex`

```elixir
defmodule Pactis.ResourceEncoder do
  @moduledoc """
  Encodes Ash resources into Blueprint-storable format and decodes back to generation commands
  """

  def encode_resource(resource_module) do
    %{
      module_name: inspect(resource_module),
      table_name: get_table_name(resource_module),
      attributes: encode_attributes(resource_module),
      relationships: encode_relationships(resource_module),
      actions: encode_actions(resource_module),
      validations: encode_validations(resource_module),
      meta: encode_meta(resource_module)
    }
  end

  def decode_to_igniter_commands(encoded_data, target_domain) do
    # Returns list of Igniter commands to recreate the resource
  end
end
```

### 2. Attribute Encoding
Capture all the info needed to recreate `--attribute` flags:

```elixir
defp encode_attributes(resource_module) do
  resource_module
  |> Ash.Resource.Info.attributes()
  |> Enum.map(fn attr ->
    %{
      name: attr.name,
      type: attr.type,
      required: !attr.allow_nil?,
      default: attr.default,
      constraints: attr.constraints,
      # Include everything needed for --attribute flags
    }
  end)
end
```

### 3. Relationship Encoding
Capture belongs_to, has_many, many_to_many relationships:

```elixir
defp encode_relationships(resource_module) do
  resource_module
  |> Ash.Resource.Info.relationships()
  |> Enum.map(fn rel ->
    %{
      name: rel.name,
      type: rel.type, # :belongs_to, :has_many, etc
      destination: inspect(rel.destination),
      required: rel.required?,
      # Additional relationship metadata
    }
  end)
end
```

### 4. Action Encoding
Capture custom actions beyond basic CRUD:

```elixir
defp encode_actions(resource_module) do
  resource_module
  |> Ash.Resource.Info.actions()
  |> Enum.reject(&(&1.name in [:create, :read, :update, :destroy])) # Skip default actions
  |> Enum.map(fn action ->
    %{
      name: action.name,
      type: action.type,
      arguments: encode_arguments(action.arguments),
      changes: encode_changes(action.changes),
      # Other action metadata
    }
  end)
end
```

## Integration with Blueprint Resource

### Blueprint Schema Updates
The `resource_definition:map` field will store the encoded resource data:

```elixir
# In Blueprint resource
attribute :resource_definition, :map do
  description "Encoded Ash resource definition"
  constraints [
    required_keys: [:module_name, :attributes, :relationships]
  ]
end
```

### Blueprint Creation Flow
```elixir
# When creating a blueprint from existing resource
def create_blueprint_from_resource(resource_module, user_id) do
  encoded_definition = ResourceEncoder.encode_resource(resource_module)

  Blueprint
  |> Ash.Changeset.for_create(:create, %{
    name: extract_resource_name(resource_module),
    resource_definition: encoded_definition,
    # other blueprint fields
  })
  |> Ash.create!()
end
```

### Blueprint Installation Flow
```elixir
# When installing blueprint in user's project
def install_blueprint(blueprint, target_domain) do
  commands = ResourceEncoder.decode_to_igniter_commands(
    blueprint.resource_definition,
    target_domain
  )

  # Execute Igniter commands to recreate resource
  Enum.reduce(commands, igniter, fn command, acc ->
    apply_igniter_command(acc, command)
  end)
end
```

## Command Generation Strategy

### Igniter Command Types
The decoder should generate these types of commands:

1. **Resource Generation**
   ```elixir
   ["ash.gen.resource", resource_name, table_name | attribute_flags]
   ```

2. **Relationship Addition**
   ```elixir
   # Custom Igniter code to add relationships to existing resource
   ```

3. **Action Addition**
   ```elixir
   # Custom Igniter code to add custom actions
   ```

4. **Domain Registration**
   ```elixir
   # Add resource to domain module
   ```

## Error Handling & Validation

### Encoding Validation
- Ensure all required fields are captured
- Handle complex types (arrays, maps, custom types)
- Validate constraint encoding

### Decoding Validation
- Verify target domain exists
- Check for naming conflicts
- Validate Elixir module naming conventions

## Testing Strategy

### Test Resources
Create simple test resources to validate encoding/decoding:

```elixir
# test/support/test_resources.ex
defmodule TestUser do
  use Ash.Resource
  # Simple resource for testing
end

defmodule TestDocument do
  use Ash.Resource
  # Complex resource with relationships
end
```

### Test Cases
1. **Round-trip encoding** - encode then decode should recreate equivalent resource
2. **Attribute preservation** - all attribute metadata preserved
3. **Relationship handling** - belongs_to, has_many, many_to_many work correctly
4. **Action preservation** - custom actions recreated properly
5. **Edge cases** - complex constraints, custom types, etc.

## Implementation Notes

### Constraint Handling
Some Ash constraints might be complex objects that need special encoding:

```elixir
defp encode_constraints(constraints) do
  # Handle different constraint types
  # Some might need custom serialization
end
```

### Module Name Resolution
When decoding, need to resolve destination modules properly:

```elixir
defp resolve_destination_module(encoded_destination, target_domain) do
  # Convert "User" to "MyApp.Accounts.User" based on target domain
end
```

### Version Compatibility
Consider encoding the Ash version used:

```elixir
defp encode_meta(resource_module) do
  %{
    ash_version: Application.spec(:ash, :vsn),
    encoded_at: DateTime.utc_now(),
    # Other metadata
  }
end
```

## Usage Examples

### Creating Blueprint from Existing Resource
```elixir
# In pactis project
encoded = ResourceEncoder.encode_resource(Pactis.Core.Document)
Blueprint.create!(%{
  name: "document",
  resource_definition: encoded,
  # ...
})
```

### Installing Blueprint in Dash Project
```elixir
# In dash project via mix task
blueprint = fetch_blueprint("document")
ResourceEncoder.decode_to_igniter_commands(
  blueprint.resource_definition,
  "Dash.Core"
)
# Generates: mix ash.gen.resource Dash.Core.Document documents --attribute filename:string:required ...
```

## File Structure
```
lib/pactis/
├── resource_encoder.ex           # Main encoder/decoder
├── resource_encoder/
│   ├── attribute_encoder.ex      # Attribute-specific encoding
│   ├── relationship_encoder.ex   # Relationship encoding
│   ├── action_encoder.ex         # Action encoding
│   └── igniter_generator.ex      # Igniter command generation
└── blueprint.ex                  # Updated Blueprint resource
```

This gives Claude Code everything needed to implement the complete resource encoding/decoding system for the blueprint registry!
