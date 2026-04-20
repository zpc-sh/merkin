# GitHub-esque Component Library Platform Architecture Specification

## 1. Current State Analysis

### Tech Stack & Patterns
- **Framework**: Phoenix 1.8+ with LiveView 1.1+
- **Database**: PostgreSQL with Ash Framework (3.0+) for domain modeling
- **Frontend**: TailwindCSS + DaisyUI components, HeroIcons
- **Authentication**: Ash Authentication (4.0+)
- **Storage**: Local filesystem + S3-compatible (ExAws)
- **Background Jobs**: Custom implementation with Redis cache
- **Asset Pipeline**: esbuild + Tailwind

### Existing Domain Models
- **Accounts Domain**: User, Organization, Membership
- **Core Domain**: Blueprint (primary entity), Category, Star, Fork, Download, Collection, Comment, Issue, Review
- **Advanced Features**: Semantic versioning, JSON-LD support, multi-format generation, collaborative features

### Current Capabilities
- Blueprint creation/management with sophisticated versioning
- Multi-format code generation (Phoenix HTML, Terminal UI, Admin Panel, REST API)
- Fork/star/download tracking
- Collections and categorization
- Installation preview and command generation
- File storage abstraction for components

## 2. Architecture Evolution Plan

### Component Library Platform Extensions

#### A. Component Package System
Extend the existing Blueprint model to support component packages:

```elixir
# Enhanced Blueprint attributes
attribute :package_type, :atom do
  constraints one_of: [:blueprint, :component, :theme, :template, :plugin]
  default :blueprint
end

attribute :npm_package_name, :string do
  description "NPM package identifier for JS components"
end

attribute :component_manifest, :map do
  description "Component-specific metadata (props, events, styling)"
end

attribute :demo_urls, {:array, :string} do
  description "Live demo and playground URLs"
end
```

#### B. Multi-Language Support Infrastructure
```elixir
# New Language Support domain
defmodule BlueprintForge.Languages do
  resources do
    resource(BlueprintForge.Languages.Language)
    resource(BlueprintForge.Languages.ComponentAdapter)
    resource(BlueprintForge.Languages.TranslationRule)
  end
end

# Language-specific generators
defmodule BlueprintForge.Formats.ReactGenerator do
  use BlueprintForge.Formats.BaseGenerator
  # Convert Ash blueprints to React components
end
```

## 3. Database Schema Extensions

### New Tables/Models

#### Component Registry
```elixir
defmodule BlueprintForge.Core.ComponentRegistry do
  attributes do
    uuid_primary_key :id
    attribute :namespace, :string, allow_nil?: false
    attribute :component_name, :string, allow_nil?: false
    attribute :latest_version_id, :uuid
    attribute :download_count, :integer, default: 0
    attribute :verified, :boolean, default: false
  end

  relationships do
    has_many :versions, BlueprintForge.Core.Blueprint
  end
end
```

#### Package Dependencies
```elixir
defmodule BlueprintForge.Core.PackageDependency do
  attributes do
    uuid_primary_key :id
    attribute :package_manager, :atom # :npm, :hex, :cargo, :composer
    attribute :package_name, :string, allow_nil?: false
    attribute :version_requirement, :string, allow_nil?: false
    attribute :dev_only, :boolean, default: false
  end

  relationships do
    belongs_to :blueprint, BlueprintForge.Core.Blueprint
  end
end
```

#### Usage Analytics
```elixir
defmodule BlueprintForge.Core.UsageMetric do
  attributes do
    uuid_primary_key :id
    attribute :event_type, :atom # :download, :install, :star, :fork, :view
    attribute :metadata, :map, default: %{}
    attribute :user_agent, :string
    attribute :ip_hash, :string
    create_timestamp :recorded_at
  end

  relationships do
    belongs_to :blueprint, BlueprintForge.Core.Blueprint
    belongs_to :user, BlueprintForge.Accounts.User
  end
end
```

## 4. API Extensions

### REST API Endpoints (following existing patterns)
```elixir
# In router.ex
scope "/api/v1", BlueprintForgeWeb do
  pipe_through :api

  # Component discovery
  get "/components", ComponentApiController, :index
  get "/components/search", ComponentApiController, :search
  get "/components/:namespace/:name", ComponentApiController, :show
  get "/components/:namespace/:name/versions", ComponentApiController, :versions

  # Package management
  post "/packages/publish", PackageApiController, :publish
  get "/packages/:name/metadata", PackageApiController, :metadata
  get "/packages/:name/:version/download", PackageApiController, :download

  # Analytics
  post "/metrics/track", MetricsApiController, :track
  get "/components/:id/stats", MetricsApiController, :component_stats
end
```

### LiveView Extensions
```elixir
# Component marketplace browser
live "/marketplace", ComponentLive.Marketplace, :index
live "/marketplace/:category", ComponentLive.Marketplace, :category
live "/marketplace/:namespace/:name", ComponentLive.Show, :show

# Package management dashboard
live "/dashboard/packages", PackageLive.Dashboard, :index
live "/dashboard/packages/:id/analytics", PackageLive.Analytics, :show

# Component playground/sandbox
live "/playground", PlaygroundLive.Index, :index
live "/playground/:namespace/:name", PlaygroundLive.Component, :show
```

## 5. Frontend Component Architecture

### Enhanced LiveView Components

#### Component Browser
```elixir
defmodule BlueprintForgeWeb.ComponentLive.Browser do
  use BlueprintForgeWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:search_filters, %{language: nil, category: nil, verified: false})
     |> assign(:view_mode, :grid)
     |> load_components()}
  end

  # Real-time component preview
  def handle_event("preview_component", %{"id" => id}, socket) do
    component = get_component!(id)
    
    {:noreply,
     socket
     |> assign(:preview_component, component)
     |> push_event("render_preview", %{
       component_id: id,
       demo_data: component.demo_data
     })}
  end
end
```

#### Interactive Code Playground
```elixir
defmodule BlueprintForgeWeb.PlaygroundLive do
  use BlueprintForgeWeb, :live_view

  # Live code editor with syntax highlighting
  def handle_event("code_change", %{"code" => code}, socket) do
    case compile_component(code) do
      {:ok, compiled} ->
        {:noreply,
         socket
         |> assign(:compiled_code, compiled)
         |> push_event("update_preview", %{html: compiled.html})}

      {:error, errors} ->
        {:noreply,
         socket
         |> assign(:compilation_errors, errors)}
    end
  end
end
```

### Component Documentation System
```elixir
defmodule BlueprintForgeWeb.DocsLive do
  # Auto-generated documentation from component metadata
  # Interactive prop explorer
  # Usage examples with live previews
end
```

## 6. Integration Points

### Authentication & Authorization
```elixir
# Extend existing user model
defmodule BlueprintForge.Accounts.User do
  # Add package publishing permissions
  attribute :publisher_verified, :boolean, default: false
  attribute :max_packages, :integer, default: 10
  attribute :api_tokens, {:array, :string}, default: []

  # Package management relationships
  has_many :published_packages, BlueprintForge.Core.Blueprint,
    foreign_key: :publisher_id
end
```

### Mem Storage (CAS + Manifests)

Pactis includes a lightweight content-addressable storage with Docker-like manifests for preview/apply flows.

- Layout:
  - `priv/mem/blobs/sha256/<hex>`: CAS blobs addressed by `sha256:<hex>`.
  - `priv/mem/manifests/<hex>.json`: Stored manifest JSON by digest.
  - `priv/mem/index/<workspace>/<name>/<ref>.txt`: Ref index mapping to manifest digest.
- Manifest:
  - Media type: `application/vnd.pactis.mem.manifest.v1+json`.
  - Fields: `schemaVersion`, `mediaType`, `config`, `layers`.
  - Config media type: `application/vnd.pactis.mem.config.v1+json`.
  - Diff layer media type: `application/vnd.pactis.diff.v1+patch`.
- API:
  - `GET /api/v1/workspaces/:workspace_id/mem/manifests/:ref/*name` → `{ digest, manifest }`.
  - `GET /api/v1/workspaces/:workspace_id/mem/blobs/:digest` → raw bytes.
- Producer:
  - `Pactis.Ops.ChangeRunJob` writes diff/config blobs, builds a manifest, and tags `name=ops/changes/<change_id>`, `ref=preview`.
- Safety:
  - Default to preview; applying writes only under `lib/`, `assets/`, `priv/templates/`.
  - Only apply on explicit user action; previews are read-only in target repo.

### File Storage Integration
```elixir
defmodule BlueprintForge.PackageStorage do
  # Extend existing file storage for package assets
  def store_package_assets(package_id, files) do
    # Use existing BlueprintForge.FileStorage infrastructure
    # Store component files, demos, documentation
  end

  def generate_cdn_urls(package_id) do
    # Integration with existing S3/CDN setup
  end
end
```

### Background Jobs Enhancement
```elixir
defmodule BlueprintForge.BackgroundJobs.PackageJobs do
  # Extend existing background job system
  def schedule_package_analysis(package_id) do
    # Security scanning
    # Dependency analysis
    # Performance metrics
  end
end
```

## 7. Implementation Roadmap

### Phase 1: Core Component System (4-6 weeks)
1. **Database migrations** for new component-specific tables
2. **Extend Blueprint model** with component package fields
3. **Basic component browser** LiveView implementation
4. **Package upload/management** interface

### Phase 2: Multi-Language Support (6-8 weeks)
1. **Generator framework** for React/Vue/Svelte components
2. **Language adapters** and translation rules
3. **Package manager integrations** (npm, yarn)
4. **CLI tools** for package publishing

### Phase 3: Discovery & Analytics (4-6 weeks)
1. **Advanced search** with semantic filtering
2. **Usage analytics** dashboard
3. **Recommendation engine** for related components
4. **Verification system** for trusted publishers

### Phase 4: Developer Experience (6-8 weeks)
1. **Interactive playground** with live editing
2. **Component documentation** auto-generation
3. **Testing framework** integration
4. **CI/CD pipelines** for automated publishing

### Phase 5: Ecosystem & Monetization (8-10 weeks)
1. **Marketplace features** (paid components, subscriptions)
2. **Team collaboration** tools
3. **Enterprise features** (private registries, SSO)
4. **API rate limiting** and usage tiers

## Key Advantages of This Approach

1. **Incremental Evolution**: Builds on existing solid foundation
2. **Pattern Consistency**: Follows established Ash/Phoenix patterns
3. **Multi-Framework**: Not limited to Elixir ecosystem
4. **Enterprise Ready**: Scalable architecture with existing infrastructure
5. **Developer Focused**: Rich tooling and documentation support

This architecture specification leverages your existing sophisticated blueprint system while expanding it into a comprehensive component library platform that rivals GitHub's package ecosystem.
