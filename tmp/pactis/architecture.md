# Pactis.dev - Complete Architecture Specification

## Project Overview
Transform the existing Pactis Elixir/Phoenix application to Pactis (Code + Form) - a collaborative component library platform that bridges code structure and design form, enabling developers and designers to build components together.

## Complete Input for Claude Code

```bash
# Pactis Platform Complete Architecture Implementation

## Project Transformation Overview
Rename and restructure the existing application (whether Pactis or Pactis) to Pactis - a component library platform that merges code structure with design form. The platform enables collaborative component building between developers and designers with multi-framework generation capabilities.

**Note**: This handles renaming from either Pactis OR Pactis if you've already started that transition.
```

## Phase 1: Complete Project Rename & Restructuring

### 1. Application-Wide Rename Operations
Execute comprehensive rename across entire codebase (handles both Pactis and Pactis origins):

```bash
# Find and replace in all files - handles multiple possible origins
find . -type f -name "*.ex" -o -name "*.exs" -o -name "*.eex" -o -name "*.heex" | \
  xargs sed -i '' 's/Pactis/Pactis/g; s/pactis/pactis/g; s/Pactis/Pactis/g; s/pactis/pactis/g'

find . -type f -name "*.json" -o -name "*.md" -o -name "*.yml" -o -name "*.yaml" | \
  xargs sed -i '' 's/Pactis/Pactis/g; s/pactis/pactis/g; s/Pactis/Pactis/g; s/pactis/pactis/g'

# Update specific config references
find ./config -type f -name "*.exs" | \
  xargs sed -i '' 's/PactisWeb/PactisWeb/g; s/PactisWeb/PactisWeb/g'

```bash
# File and directory renames - Handle all possible existing names
mv lib/pactis lib/pactis 2>/dev/null || true
mv lib/pactis lib/pactis 2>/dev/null || true
mv lib/cdfm_web lib/cdfm_web 2>/dev/null || true
mv lib/cdfm_web lib/cdfm_web 2>/dev/null || true
mv test/pactis test/pactis 2>/dev/null || true
mv test/pactis test/pactis 2>/dev/null || true
mv test/cdfm_web test/cdfm_web 2>/dev/null || true
mv test/cdfm_web test/cdfm_web 2>/dev/null || true

# Update mix.exs - Handle any existing Pactis references
app: :pactis
mod: {Pactis.Application, []}

# Update config files - Replace both Pactis AND Pactis references
config :pactis, PactisWeb.Endpoint, ...
config :pactis, Pactis.Repo, ...

# Update all module definitions - Handle all possible existing references
Pactis -> Pactis
PactisWeb -> PactisWeb
Pactis -> Pactis (if exists)
PactisWeb -> PactisWeb (if exists)
pactis -> pactis
pactis -> pactis (if exists)
```

### 2. Module Structure Transformation
Transform all existing modules to new namespace:

```elixir
# Core Application
defmodule Pactis do
  use Application
  # Existing application logic
end

defmodule Pactis.Repo do
  use AshPostgres.Repo, otp_app: :pactis
end

# Domain modules
defmodule Pactis.Accounts do
  use Ash.Domain
  # Existing accounts domain
end

defmodule Pactis.Core do
  use Ash.Domain
  # Transform Blueprint -> Component
  # Keep existing functionality, rename concepts
end

# Web modules
defmodule PactisWeb do
  # Existing web functionality
end
```

## Phase 2: Enhanced Database Schema

### 3. New Database Migrations
Create comprehensive schema extensions:

```elixir
# Migration: Add component library features
defmodule Pactis.Repo.Migrations.AddComponentLibraryFeatures do
  use Ecto.Migration

  def change do
    # Component Registry
    create table(:component_registries, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :namespace, :string, null: false
      add :component_name, :string, null: false
      add :latest_version_id, :binary_id
      add :download_count, :integer, default: 0
      add :verification_level, :string, default: "community"
      add :verified, :boolean, default: false
      add :featured, :boolean, default: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:component_registries, [:namespace, :component_name])
    create index(:component_registries, [:verification_level])
    create index(:component_registries, [:download_count])

    # Package Dependencies
    create table(:package_dependencies, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :blueprint_id, references(:blueprints, type: :binary_id, on_delete: :delete_all)
      add :package_manager, :string, null: false # npm, hex, cargo, composer
      add :package_name, :string, null: false
      add :version_requirement, :string, null: false
      add :dev_only, :boolean, default: false
      add :optional, :boolean, default: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:package_dependencies, [:blueprint_id])
    create index(:package_dependencies, [:package_manager])

    # Usage Analytics
    create table(:usage_metrics, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :blueprint_id, references(:blueprints, type: :binary_id, on_delete: :delete_all)
      add :user_id, references(:users, type: :binary_id, on_delete: :nilify_all)
      add :event_type, :string, null: false # download, install, star, fork, view, preview
      add :metadata, :map, default: %{}
      add :user_agent, :string
      add :ip_hash, :string
      add :country, :string
      add :referrer, :string

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create index(:usage_metrics, [:blueprint_id])
    create index(:usage_metrics, [:user_id])
    create index(:usage_metrics, [:event_type])
    create index(:usage_metrics, [:inserted_at])

    # Component Frameworks
    create table(:component_frameworks, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false # react, Svelte, svelte, angular
      add :display_name, :string, null: false
      add :version, :string
      add :generator_module, :string, null: false
      add :file_extensions, {:array, :string}, default: []
      add :package_manager, :string # npm, yarn, pnpm
      add :active, :boolean, default: true

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:component_frameworks, [:name])

    # Component Previews
    create table(:component_previews, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :blueprint_id, references(:blueprints, type: :binary_id, on_delete: :delete_all)
      add :framework_id, references(:component_frameworks, type: :binary_id, on_delete: :delete_all)
      add :preview_html, :text
      add :demo_props, :map, default: %{}
      add :screenshot_url, :string
      add :sandbox_url, :string

      timestamps(type: :utc_datetime_usec)
    end

    create index(:component_previews, [:blueprint_id])
    create index(:component_previews, [:framework_id])

    # Tags (many-to-many with blueprints)
    create table(:tags, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :slug, :string, null: false
      add :color, :string, default: "#6B7280"
      add :usage_count, :integer, default: 0

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:tags, [:slug])
    create index(:tags, [:usage_count])

    create table(:blueprint_tags, primary_key: false) do
      add :blueprint_id, references(:blueprints, type: :binary_id, on_delete: :delete_all)
      add :tag_id, references(:tags, type: :binary_id, on_delete: :delete_all)

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create unique_index(:blueprint_tags, [:blueprint_id, :tag_id])
  end
end

# Migration: Extend Blueprint model
defmodule Pactis.Repo.Migrations.ExtendBlueprintsForComponents do
  use Ecto.Migration

  def change do
    alter table(:blueprints) do
      # Component-specific fields
      add :package_type, :string, default: "component" # component, template, theme, plugin, blueprint
      add :npm_package_name, :string
      add :component_manifest, :map, default: %{}
      add :demo_urls, {:array, :string}, default: []
      add :verification_level, :string, default: "community" # community, verified, official
      add :framework_support, {:array, :string}, default: ["react"] # react, Svelte, svelte, angular
      add :complexity_level, :string, default: "beginner" # beginner, intermediate, advanced
      add :installation_instructions, :text
      add :demo_props_schema, :map, default: %{}
      add :responsive_breakpoints, {:array, :string}, default: ["mobile", "tablet", "desktop"]
      add :accessibility_features, {:array, :string}, default: []
      add :browser_support, {:array, :string}, default: ["chrome", "firefox", "safari", "edge"]
      add :bundle_size_kb, :integer
      add :performance_score, :integer # 1-100
      add :last_tested_at, :utc_datetime_usec
      add :featured_at, :utc_datetime_usec
      add :trending_score, :float, default: 0.0
    end

    create index(:blueprints, [:package_type])
    create index(:blueprints, [:verification_level])
    create index(:blueprints, [:complexity_level])
    create index(:blueprints, [:trending_score])
    create index(:blueprints, [:featured_at])
  end
end
```

## Phase 3: Enhanced Ash Resources

### 4. Updated Core Resources
Transform and extend existing Ash resources:

```elixir
# Enhanced Blueprint resource
defmodule Pactis.Core.Blueprint do
  use Ash.Resource,
    domain: Pactis.Core,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshJsonApi.Resource]

  # Existing attributes plus new ones
  attributes do
    uuid_primary_key :id
    attribute :title, :string, allow_nil?: false
    attribute :description, :text
    attribute :content, :map, default: %{}

    # New component-specific attributes
    attribute :package_type, :atom do
      constraints one_of: [:component, :template, :theme, :plugin, :blueprint]
      default :component
    end

    attribute :npm_package_name, :string
    attribute :component_manifest, :map, default: %{}
    attribute :demo_urls, {:array, :string}, default: []

    attribute :verification_level, :atom do
      constraints one_of: [:community, :verified, :official]
      default :community
    end

    attribute :framework_support, {:array, :atom}, default: [:react]
    attribute :complexity_level, :atom do
      constraints one_of: [:beginner, :intermediate, :advanced]
      default :beginner
    end

    attribute :installation_instructions, :string
    attribute :demo_props_schema, :map, default: %{}
    attribute :responsive_breakpoints, {:array, :string}, default: ["mobile", "tablet", "desktop"]
    attribute :accessibility_features, {:array, :string}, default: []
    attribute :browser_support, {:array, :string}, default: ["chrome", "firefox", "safari", "edge"]
    attribute :bundle_size_kb, :integer
    attribute :performance_score, :integer
    attribute :trending_score, :decimal, default: Decimal.new(0)

    # Timestamps
    attribute :last_tested_at, :utc_datetime_usec
    attribute :featured_at, :utc_datetime_usec
    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    # Existing relationships
    belongs_to :user, Pactis.Accounts.User
    belongs_to :category, Pactis.Core.Category

    # New relationships
    has_many :package_dependencies, Pactis.Core.PackageDependency
    has_many :usage_metrics, Pactis.Core.UsageMetric
    has_many :component_previews, Pactis.Core.ComponentPreview
    many_to_many :tags, Pactis.Core.Tag, through: Pactis.Core.BlueprintTag
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    # Enhanced search action
    read :search do
      argument :query, :string
      argument :framework, :atom
      argument :complexity, :atom
      argument :verification_level, :atom
      argument :package_type, :atom

      filter expr(
        if is_nil(^arg(:query)) do
          true
        else
          fragment("to_tsvector('english', coalesce(?, '') || ' ' || coalesce(?, '')) @@ plainto_tsquery('english', ?)",
            title, description, ^arg(:query))
        end
      )

      filter expr(
        if is_nil(^arg(:framework)) do
          true
        else
          ^arg(:framework) in framework_support
        end
      )

      filter expr(
        if is_nil(^arg(:complexity)) do
          true
        else
          complexity_level == ^arg(:complexity)
        end
      )

      filter expr(
        if is_nil(^arg(:verification_level)) do
          true
        else
          verification_level == ^arg(:verification_level)
        end
      )

      filter expr(
        if is_nil(^arg(:package_type)) do
          true
        else
          package_type == ^arg(:package_type)
        end
      )
    end

    read :trending do
      sort trending_score: :desc, inserted_at: :desc
    end

    read :featured do
      filter expr(not is_nil(featured_at))
      sort featured_at: :desc
    end

    update :increment_downloads do
      change Pactis.Core.Changes.IncrementDownloads
    end
  end
end

# New PackageDependency resource
defmodule Pactis.Core.PackageDependency do
  use Ash.Resource,
    domain: Pactis.Core,
    data_layer: AshPostgres.DataLayer

  attributes do
    uuid_primary_key :id
    attribute :package_manager, :atom, constraints: [one_of: [:npm, :hex, :cargo, :composer]]
    attribute :package_name, :string, allow_nil?: false
    attribute :version_requirement, :string, allow_nil?: false
    attribute :dev_only, :boolean, default: false
    attribute :optional, :boolean, default: false

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :blueprint, Pactis.Core.Blueprint
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end
end

# New UsageMetric resource
defmodule Pactis.Core.UsageMetric do
  use Ash.Resource,
    domain: Pactis.Core,
    data_layer: AshPostgres.DataLayer

  attributes do
    uuid_primary_key :id
    attribute :event_type, :atom, constraints: [one_of: [:download, :install, :star, :fork, :view, :preview]]
    attribute :metadata, :map, default: %{}
    attribute :user_agent, :string
    attribute :ip_hash, :string
    attribute :country, :string
    attribute :referrer, :string

    create_timestamp :inserted_at
  end

  relationships do
    belongs_to :blueprint, Pactis.Core.Blueprint
    belongs_to :user, Pactis.Accounts.User
  end

  actions do
    defaults [:create, :read]
  end
end
```

## Phase 4: Component Generator Framework

### 5. Multi-Framework Generator System
Create comprehensive generator infrastructure:

```elixir
# Base Generator Behavior
defmodule Pactis.Generators.BaseGenerator do
  @callback generate(blueprint :: Pactis.Core.Blueprint.t(), opts :: keyword()) ::
    {:ok, %{files: map(), metadata: map()}} | {:error, String.t()}

  @callback validate_blueprint(blueprint :: Pactis.Core.Blueprint.t()) ::
    {:ok, Pactis.Core.Blueprint.t()} | {:error, String.t()}

  @callback supported_features() :: [atom()]
end

# React Generator
defmodule Pactis.Generators.ReactGenerator do
  @behaviour Pactis.Generators.BaseGenerator

  def generate(blueprint, opts \\ []) do
    with {:ok, validated_blueprint} <- validate_blueprint(blueprint) do
      files = %{
        "package.json" => generate_package_json(validated_blueprint, opts),
        "src/#{component_name(validated_blueprint)}.jsx" => generate_component(validated_blueprint),
        "src/#{component_name(validated_blueprint)}.stories.js" => generate_storybook(validated_blueprint),
        "src/#{component_name(validated_blueprint)}.test.js" => generate_tests(validated_blueprint),
        "README.md" => generate_readme(validated_blueprint),
        "src/index.js" => generate_index(validated_blueprint)
      }

      metadata = %{
        framework: "react",
        bundle_size_estimate: estimate_bundle_size(files),
        dependencies: extract_dependencies(validated_blueprint),
        typescript_support: Keyword.get(opts, :typescript, false)
      }

      {:ok, %{files: files, metadata: metadata}}
    end
  end

  def validate_blueprint(blueprint) do
    # Validate blueprint has required fields for React generation
    {:ok, blueprint}
  end

  def supported_features do
    [:props, :events, :styling, :typescript, :storybook, :testing]
  end

  defp generate_component(blueprint) do
    """
    import React from 'react';
    import PropTypes from 'prop-types';
    #{generate_styles_import(blueprint)}

    const #{component_name(blueprint)} = (#{generate_props_destructure(blueprint)}) => {
      #{generate_component_body(blueprint)}
    };

    #{generate_prop_types(blueprint)}

    export default #{component_name(blueprint)};
    """
  end

  defp generate_package_json(blueprint, opts) do
    Jason.encode!(%{
      name: blueprint.npm_package_name || "@pactis/#{kebab_case(blueprint.title)}",
      version: "1.0.0",
      description: blueprint.description,
      main: "src/index.js",
      dependencies: %{
        "react" => "^18.0.0",
        "prop-types" => "^15.8.0"
      },
      peerDependencies: %{
        "react" => ">=16.8.0",
        "react-dom" => ">=16.8.0"
      },
      keywords: extract_keywords(blueprint),
      author: blueprint.user.name,
      license: "MIT"
    }, pretty: true)
  end
end

# Svelte Generator
defmodule Pactis.Generators.SvelteGenerator do
  @behaviour Pactis.Generators.BaseGenerator

  def generate(blueprint, opts \\ []) do
    with {:ok, validated_blueprint} <- validate_blueprint(blueprint) do
      files = %{
        "package.json" => generate_package_json(validated_blueprint),
        "src/#{component_name(validated_blueprint)}.Svelte" => generate_component(validated_blueprint),
        "src/index.js" => generate_index(validated_blueprint),
        "README.md" => generate_readme(validated_blueprint)
      }

      metadata = %{
        framework: "Svelte",
        Svelte_version: "3.x",
        dependencies: extract_dependencies(validated_blueprint)
      }

      {:ok, %{files: files, metadata: metadata}}
    end
  end

  def validate_blueprint(blueprint), do: {:ok, blueprint}
  def supported_features, do: [:props, :events, :styling, :composition_api]

  defp generate_component(blueprint) do
    """
    <template>
      #{generate_template(blueprint)}
    </template>

    <script>
    import { defineComponent } from 'Svelte'

    export default defineComponent({
      name: '#{component_name(blueprint)}',
      props: #{generate_props_definition(blueprint)},
      setup(props, { emit }) {
        #{generate_composition_logic(blueprint)}

        return {
          #{generate_return_object(blueprint)}
        }
      }
    })
    </script>

    <style scoped>
    #{generate_styles(blueprint)}
    </style>
    """
  end
end

# Generator Registry
defmodule Pactis.Generators.Registry do
  def generators do
    %{
      react: Pactis.Generators.ReactGenerator,
      Svelte: Pactis.Generators.SvelteGenerator,
      svelte: Pactis.Generators.SvelteGenerator,
      angular: Pactis.Generators.AngularGenerator
    }
  end

  def generate_for_framework(blueprint, framework, opts \\ []) do
    case Map.get(generators(), framework) do
      nil -> {:error, "Unsupported framework: #{framework}"}
      generator -> generator.generate(blueprint, opts)
    end
  end

  def generate_all_frameworks(blueprint, opts \\ []) do
    frameworks = Keyword.get(opts, :frameworks, [:react, :Svelte])

    Enum.reduce(frameworks, %{}, fn framework, acc ->
      case generate_for_framework(blueprint, framework, opts) do
        {:ok, result} -> Map.put(acc, framework, result)
        {:error, _} -> acc
      end
    end)
  end
end
```

## Phase 5: Web Interface & LiveViews

### 6. Component Marketplace LiveViews
Create comprehensive UI for component discovery:

```elixir
# Main Marketplace LiveView
defmodule PactisWeb.ComponentLive.Marketplace do
  use PactisWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:search_query, "")
     |> assign(:selected_framework, :all)
     |> assign(:selected_complexity, :all)
     |> assign(:selected_verification, :all)
     |> assign(:selected_package_type, :all)
     |> assign(:view_mode, :grid)
     |> assign(:sort_by, :trending)
     |> load_components()
     |> load_frameworks()
     |> load_categories()}
  end

  def handle_event("search", %{"query" => query}, socket) do
    {:noreply,
     socket
     |> assign(:search_query, query)
     |> load_components()}
  end

  def handle_event("filter", %{"framework" => framework}, socket) do
    {:noreply,
     socket
     |> assign(:selected_framework, String.to_existing_atom(framework))
     |> load_components()}
  end

  def handle_event("preview_component", %{"id" => id}, socket) do
    component = get_component!(id)

    # Track view event
    track_usage_event(component, :view, socket)

    {:noreply,
     socket
     |> assign(:preview_component, component)
     |> push_event("show_preview_modal", %{
       component_id: id,
       preview_html: generate_preview_html(component),
       demo_props: component.demo_props_schema
     })}
  end

  def handle_event("download_component", %{"id" => id, "framework" => framework}, socket) do
    component = get_component!(id)

    case Pactis.Generators.Registry.generate_for_framework(component, String.to_existing_atom(framework)) do
      {:ok, %{files: files, metadata: metadata}} ->
        # Track download event
        track_usage_event(component, :download, socket)

        # Increment download counter
        Pactis.Core.Blueprint.increment_downloads(component)

        {:noreply,
         socket
         |> put_flash(:info, "Component downloaded successfully!")
         |> push_event("download_files", %{
           files: files,
           filename: "#{component.title}-#{framework}.zip",
           metadata: metadata
         })}

      {:error, error} ->
        {:noreply,
         socket
         |> put_flash(:error, "Download failed: #{error}")}
    end
  end

  defp load_components(socket) do
    components = Pactis.Core.Blueprint.search!(
      query: socket.assigns.search_query,
      framework: (if socket.assigns.selected_framework == :all, do: nil, else: socket.assigns.selected_framework),
      complexity: (if socket.assigns.selected_complexity == :all, do: nil, else: socket.assigns.selected_complexity),
      verification_level: (if socket.assigns.selected_verification == :all, do: nil, else: socket.assigns.selected_verification),
      package_type: (if socket.assigns.selected_package_type == :all, do: nil, else: socket.assigns.selected_package_type)
    )

    assign(socket, :components, components)
  end

  defp track_usage_event(component, event_type, socket) do
    attrs = %{
      blueprint_id: component.id,
      user_id: get_current_user_id(socket),
      event_type: event_type,
      metadata: %{
        user_agent: get_connect_info(socket, :user_agent),
        referer: get_connect_info(socket, :peer_data)
      },
      ip_hash: hash_ip(get_connect_info(socket, :peer_data))
    }

    Pactis.Core.UsageMetric.create(attrs)
  end
end
```

## Phase 6: API Endpoints

### 7. Component Discovery API
Create REST API for external integrations:

```elixir
# API Router additions
scope "/api/v1", PactisWeb do
  pipe_through :api

  # Component discovery
  get "/components", ComponentApiController, :index
  get "/components/search", ComponentApiController, :search
  get "/components/:id", ComponentApiController, :show
  get "/components/:id/download/:framework", ComponentApiController, :download

  # Package management
  post "/packages/publish", PackageApiController, :publish
  get "/packages/:namespace/:name", PackageApiController, :show
  get "/packages/:namespace/:name/versions", PackageApiController, :versions

  # Analytics
  post "/metrics/track", MetricsApiController, :track
  get "/components/:id/stats", MetricsApiController, :component_stats

  # Frameworks
  get "/frameworks", FrameworkApiController, :index
end

# Component API Controller
defmodule PactisWeb.ComponentApiController do
  use PactisWeb, :controller

  def index(conn, params) do
    components = Pactis.Core.Blueprint.search!(
      query: params["q"],
      framework: params["framework"],
      complexity: params["complexity"],
      verification_level: params["verification"],
      package_type: params["type"]
    )

    render(conn, :index, components: components)
  end

  def show(conn, %{"id" => id}) do
    component = Pactis.Core.Blueprint.get!(id)
    render(conn, :show, component: component)
  end

  def download(conn, %{"id" => id, "framework" => framework}) do
    component = Pactis.Core.Blueprint.get!(id)

    case Pactis.Generators.Registry.generate_for_framework(component, String.to_atom(framework)) do
      {:ok, %{files: files, metadata: metadata}} ->
        # Track download
        track_api_usage(component, :download, conn)

        # Create ZIP file
        zip_content = create_zip_archive(files)
        filename = "#{component.title}-#{framework}.zip"

        conn
        |> put_resp_content_type("application/zip")
        |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
        |> send_resp(200, zip_content)

      {:error, error} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: error})
    end
  end
end
```

## Phase 7: Component Preview System

### 8. Live Preview Infrastructure
Implement safe component preview rendering:

```elixir
# Component Preview Module
defmodule Pactis.ComponentPreview do
  @doc """
  Generate live preview HTML for a component with given props
  """
  def generate_preview(component, framework, props \\ %{}) do
    case framework do
      :react -> generate_react_preview(component, props)
      :Svelte -> generate_Svelte_preview(component, props)
      _ -> {:error, "Unsupported framework for preview"}
    end
  end

  defp generate_react_preview(component, props) do
    # Generate React component preview
    case Pactis.Generators.ReactGenerator.generate(component) do
      {:ok, %{files: files}} ->
        component_code = files["src/#{component_name(component)}.jsx"]
        preview_html = create_react_preview_html(component_code, props)
        {:ok, preview_html}

      {:error, error} ->
        {:error, error}
    end
  end

  defp create_react_preview_html(component_code, props) do
    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <script crossorigin src="https://unpkg.com/react@18/umd/react.development.js"></script>
      <script crossorigin src="https://unpkg.com/react-dom@18/umd/react-dom.development.js"></script>
      <script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
      <style>
        body { margin: 0; padding: 20px; font-family: system-ui, sans-serif; }
        .preview-container { border: 1px solid #e2e8f0; border-radius: 8px; padding: 20px; }
      </style>
    </head>
    <body>
      <div id="preview-root"></div>
      <script type="text/babel">
        #{component_code}

        const props = #{Jason.encode!(props)};
        const container = document.getElementById('preview-root');
        const root = ReactDOM.createRoot(container);
        root.render(<div className="preview-container">{React.createElement(#{component_name(component)}, props)}</div>);
      </script>
    </body>
    </html>
    """
  end

  def generate_screenshot(component, framework \\ :react) do
    # Generate screenshot of component for thumbnails
    # This would integrate with a service like Puppeteer
    case generate_preview(component, framework) do
      {:ok, preview_html} ->
        screenshot_url = capture_component_screenshot(preview_html, component.id)
        {:ok, screenshot_url}

      {:error, error} ->
        {:error, error}
    end
  end
end
```

## Phase 8: Analytics Dashboard

### 9. Component Analytics & Metrics
Create analytics dashboard for component authors:

```elixir
# Analytics LiveView
defmodule PactisWeb.AnalyticsLive.Dashboard do
  use PactisWeb, :live_view

  def mount(%{"component_id" => component_id}, _session, socket) do
    component = Pactis.Core.Blueprint.get!(component_id)

    {:ok,
     socket
     |> assign(:component, component)
     |> assign(:date_range, :last_30_days)
     |> load_analytics_data()}
  end

  def handle_event("change_date_range", %{"range" => range}, socket) do
    {:noreply,
     socket
     |> assign(:date_range, String.to_atom(range))
     |> load_analytics_data()}
  end

  defp load_analytics_data(socket) do
    component = socket.assigns.component
    date_range = socket.assigns.date_range

    {start_date, end_date} = get_date_range(date_range)

    metrics = Pactis.Core.UsageMetric
    |> Ash.Query.filter(blueprint_id == ^component.id)
    |> Ash.Query.filter(inserted_at >= ^start_date and inserted_at <= ^end_date)
    |> Ash.read!()

    analytics = %{
      total_downloads: count_by_event_type(metrics, :download),
      total_views: count_by_event_type(metrics, :view),
      total_installs: count_by_event_type(metrics, :install),
      daily_stats: group_by_day(metrics),
      framework_breakdown: group_by_framework(metrics),
      country_breakdown: group_by_country(metrics)
    }

    assign(socket, :analytics, analytics)
  end
end
```

## Phase 9: CLI Tools

### 10. Command Line Interface
Create CLI tools for component publishing:

```elixir
# CLI Mix Task
defmodule Mix.Tasks.Cdfm.Publish do
  use Mix.Task

  @shortdoc "Publish a component to Pactis"

  def run(args) do
    {opts, _} = OptionParser.parse!(args,
      strict: [
        path: :string,
        framework: :string,
        token: :string,
        dry_run: :boolean
      ]
    )

    component_path = opts[:path] || "."
    framework = String.to_atom(opts[:framework] || "react")
    api_token = opts[:token] || System.get_env("PACTIS_TOKEN")
    dry_run = opts[:dry_run] || false

    case publish_component(component_path, framework, api_token, dry_run) do
      {:ok, result} ->
        IO.puts("✅ Component published successfully!")
        IO.puts("   URL: #{result.url}")
        IO.puts("   ID: #{result.id}")

      {:error, error} ->
        IO.puts("❌ Failed to publish component: #{error}")
        System.halt(1)
    end
  end

  defp publish_component(path, framework, token, dry_run) do
    # Read component files
    # Validate component structure
    # Upload to Pactis platform
    # Return result
  end
end

# Component scaffold generator
defmodule Mix.Tasks.Cdfm.New do
  use Mix.Task

  @shortdoc "Generate a new Pactis component scaffold"

  def run([name | _]) do
    component_name = Macro.camelize(name)
    component_dir = Macro.underscore(name)

    # Create component directory structure
    File.mkdir_p!(component_dir)
    File.mkdir_p!("#{component_dir}/src")
    File.mkdir_p!("#{component_dir}/stories")
    File.mkdir_p!("#{component_dir}/tests")

    # Generate component files
    generate_component_file(component_dir, component_name)
    generate_package_json(component_dir, component_name)
    generate_readme(component_dir, component_name)
    generate_cdfm_config(component_dir, component_name)

    IO.puts("✅ Generated component scaffold: #{component_dir}")
    IO.puts("   Next steps:")
    IO.puts("   1. cd #{component_dir}")
    IO.puts("   2. Edit src/#{component_name}.jsx")
    IO.puts("   3. Run: mix pactis.publish")
  end
end
```

## Component Publishing

Pactis exposes component publishing via AshTypescript RPC rather than JSON:API. This provides a typed, stable surface for UI clients and automation.

- Endpoint: `POST /rpc/run`
- Domain/Resource/Action: `Pactis.Core` / `Pactis.Core.Blueprint` / `publish_component`
- Input: `{ manifest: map(), bundleB64: string }` (base64-encoded zip/tgz)
- Persistence: The bundle is stored under `priv/storage/components/<sha256>.zip` and metadata is recorded on the created Blueprint (`component_files`, `bundle_size_kb`).

See `docs/RPC_GUIDE.md` for TS and curl examples.

## Implementation Timeline

### Week 1: Foundation (Core Rename & Database)
- [ ] Complete application rename from Pactis to Pactis
- [ ] Run database migrations for new tables
- [ ] Update all module references and configurations
- [ ] Test existing functionality works with new naming

### Week 2: Core Generator Framework
- [ ] Implement BaseGenerator behavior
- [ ] Create React generator with full file output
- [ ] Create Svelte generator with basic support
- [ ] Set up generator registry and framework switching

### Week 3: Marketplace UI
- [ ] Build component marketplace LiveView
- [ ] Implement search and filtering functionality
- [ ] Add component preview modal system
- [ ] Create component detail pages with download functionality

### Week 4: API & Analytics
- [ ] Implement REST API endpoints for component discovery
- [ ] Add usage tracking and analytics
- [ ] Create analytics dashboard for component authors
- [ ] Build CLI tools for component publishing

### Week 5: Polish & Testing
- [ ] Add component verification system
- [ ] Implement trending/featured algorithms
- [ ] Create comprehensive test suite
- [ ] Performance optimization and caching

## Success Metrics (5-Week Goals)

- **Platform Migration**: Complete rename and rebrand to Pactis
- **Component Library**: 50+ components published and discoverable
- **Multi-Framework**: React and Svelte generators producing usable components
- **User Experience**: Full marketplace with search, preview, and download
- **Analytics**: Usage tracking and dashboard for component insights
- **Developer Tools**: CLI tools for easy component publishing
- **Community**: 25+ active component publishers

## Technical Architecture Benefits

1. **Incremental Evolution**: Builds on existing Ash/Phoenix foundation
2. **Pattern Consistency**: Follows established domain and resource patterns
3. **Multi-Framework Ready**: Extensible generator system for any framework
4. **Scalable Infrastructure**: Existing infrastructure handles growth
5. **Developer-Friendly**: Rich tooling and API support
6. **Analytics-Driven**: Built-in usage tracking and insights

This comprehensive architecture transforms your existing Pactis into Pactis - a collaborative platform where code structure meets design form, enabling developers and designers to build and share components across multiple frameworks.
