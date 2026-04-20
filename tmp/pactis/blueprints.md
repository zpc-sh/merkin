Blueprint Forge: Complete Design Document
Executive Summary
Blueprint Forge is a platform for sharing and managing reusable Ash Framework resource patterns. Through our discussion, we've evolved the design to include a sophisticated multi-format rendering system that can generate Phoenix HTML, Terminal UI, Native apps, and API endpoints from the same Ash resource definitions.
Core Architecture Decisions
1. Multi-Format Blueprint System
Decision: Blueprints support multiple output formats from a single resource definition.
elixirdefmodule Pactis.Blueprints.Blueprint do
  use Ash.Resource

  attributes do
    uuid_primary_key :id
    attribute :name, :string
    attribute :slug, :string
    attribute :description, :string

    # Core Ash resource definition (always present)
    attribute :resource_definition, :map, allow_nil?: false

    # Supported format manifests
    attribute :format_manifests, :map
    attribute :available_formats, {:array, :atom}, default: [:phoenix_html]
    attribute :format_metadata, :map

    # Versioning
    attribute :version, :string, allow_nil?: false
    attribute :version_major, :integer
    attribute :version_minor, :integer
    attribute :version_patch, :integer

    # Stats & metadata
    attribute :downloads_count, :integer, default: 0
    attribute :stars_count, :integer, default: 0
    attribute :quality_score, :decimal
  end
end
Rationale: Like LiveView Native's approach, we embrace platform differences rather than abstracting them away. Each format can be optimal for its platform.
2. Component System Separation
Decision: Components are NOT part of Blueprints. They are a separate concern.
Rationale:

Blueprints = Ash Resources (backend data structures)
Components = UI patterns (frontend presentation)
Mixing them violates separation of concerns

Learning from: Frank Dugan's Pyro/AshPyro kept these separate for good reason - they're fundamentally different things.
3. Available Formats
elixirformats = [
  :phoenix_html,      # Traditional web with LiveView
  :terminal_ui,       # Using Raxol for rich Terminal UIs
  :liveview_native,   # iOS/Android native apps
  :rest_api,          # JSON API
  :graphql_api,       # GraphQL endpoint
  :admin_panel        # Auto-generated admin interface
]
4. Installation Philosophy
Decision: Immutable, versioned installations with clear modification tracking.
elixir# .pactis.lock
%{
  installed: [
    %{
      blueprint: "user_auth",
      version: "1.2.3",
      installed_at: ~U[2024-01-15 10:00:00Z],
      sha256: "abc123...",
      generated_files: [...],
      modified_files: [...],
      templates_snapshot: "priv/blueprints/user_auth_1.2.3.snapshot"
    }
  ]
}
Rationale: Trust is critical for the Elixir community. Never break existing code.
Format Implementations
Phoenix HTML Format
Standard web interface using Phoenix LiveView:

Generates LiveViews, components, and templates
Supports themes and responsive design
Integrates with existing Phoenix apps

Terminal UI Format (Raxol)
Rich terminal interfaces using Raxol framework:

Sub-millisecond event processing
Component-based architecture
Full keyboard navigation
ASCII charts and visualizations

elixirdefmodule Pactis.Formats.Raxol.Generator do
  def generate(blueprint, opts) do
    %{
      app_module: generate_app_module(resource),
      list_view: generate_list_view(resource),
      detail_view: generate_detail_view(resource),
      form_view: generate_form_view(resource)
    }
  end
end
LiveView Native Format
Native iOS/Android apps:

Platform-specific templates
SwiftUI and Jetpack Compose
Shared business logic with web

API Formats
REST and GraphQL APIs:

Auto-generated from Ash resources
OpenAPI/GraphQL schema included
Authentication/authorization built-in

Installation System
CLI Interface
bash# Install specific format
mix pactis.install user_management --format phoenix_html

# Install multiple formats
mix pactis.install user_management --formats phoenix_html,rest_api

# Install all available formats
mix pactis.install user_management --all-formats

# Preview what will be generated
mix pactis.install user_management --preview
Conflict Resolution
elixirdefmodule Pactis.ConflictResolver do
  def check_compatibility(blueprint, project) do
    case analyze_changes() do
      :no_changes -> {:ok, :safe_to_update}
      :minor_modifications -> {:warning, :merge_required, generate_diff()}
      :major_modifications -> {:error, :manual_review_required}
      :file_deleted -> {:skip, :user_opted_out}
    end
  end
end
Quality & Testing Systems
Visual Testing Across Formats
elixirdefmodule Pactis.Testing.VisualRegression do
  def test_component(component, format) do
    case format do
      :html -> capture_browser_screenshot()
      :terminal -> capture_terminal_output()
      :native -> capture_simulator_screenshot()
    end
    |> compare_with_baseline()
  end
end
Accessibility Auditing
elixirdefmodule Pactis.Accessibility do
  def audit_component(component) do
    %{
      html: audit_html(component),      # axe-core
      terminal: audit_terminal(component), # keyboard-only
      native: audit_native(component)    # VoiceOver/TalkBack
    }
  end
end
Performance Profiling
Different metrics for different formats:

HTML: First paint, bundle size, TTI
Terminal: Event processing, render time
Native: Launch time, frame rate, memory

Theme System
Universal semantic tokens that translate across formats:
elixirdefmodule Pactis.Themes do
  defstruct [
    primary: nil,
    secondary: nil,
    danger: nil,
    spacing: %{xs: nil, sm: nil, md: nil, lg: nil},
    typography: %{heading: nil, body: nil, mono: nil}
  ]

  def to_css(theme), do: # CSS variables
  def to_terminal(theme), do: # ANSI colors
  def to_native(theme), do: # Platform themes
end
Component Sharing Model
Tiered System

Official Components - Maintained by core team
Certified Components - Community, verified quality
Community Templates - Starting points, no guarantees

Key Philosophy
"Components are starting points, not solutions"

Fork, don't fix
No versioning obligations
Recognition over responsibility
Templates, not dependencies

Governance & Trust
Distribution Strategy

Publish through Hex.pm for trust
Immutable releases
GPG signed commits
Security audits for certified blueprints

Community Contract

Immutability: Published blueprints never change
Transparency: All code generation is visible
No Lock-in: Generated code is yours
Respect: Never modify without permission
Stability: Breaking changes follow SemVer

Namespace Management
elixir%{
  "ash-project/*" => :official,  # Only Ash team
  "company/*" => :verified,      # Verified orgs
  "community/*" => :open,        # Anyone
  "abandoned/*" => :reclaimable  # 6 months inactive
}
Migration & Evolution
Smart Migration System
elixir mix pactis.migrate user_auth

# Options:
# 1. Keep current version (safe)
# 2. Show differences (manual)
# 3. Interactive migration (assisted)
# 4. Generate alongside (fresh)
Blueprint Lineage Tracking
Track forks, deprecations, and successors:

Show blueprint evolution
Recommend migrations
Maintain community continuity

Implementation Priorities
Phase 1: Core Foundation

Basic Blueprint model with resource definitions
Phoenix HTML format generator
Simple installation system
Basic versioning

Phase 2: Multi-Format

Add Terminal UI format (Raxol)
Add REST API format
Format-specific generators
Conflict resolution

Phase 3: Quality Systems

Visual testing framework
Accessibility auditing
Performance profiling
Theme system

Phase 4: Community Features

Component sharing
Certification process
Governance model
Migration tools

Key Technical Decisions

Use Raxol over Ratatouille for terminal UI (better architecture, performance)
Separate components from blueprints (different concerns)
Embrace format differences (don't abstract away platform specifics)
Immutable releases (trust > features)
Hex.pm integration (leverage existing trust)

Success Metrics

Number of blueprints created
Format adoption rates
Community contributions
Installation success rate
User retention
Breaking change frequency

Risk Mitigation

Dependency conflicts: Clear dependency resolution
Breaking changes: Immutable releases, versioning
Abandonment: Namespace reclamation, forking
Quality issues: Tiered system, certification
Trust: Transparency, governance, security audits

Conclusion
Blueprint Forge positions itself as the definitive platform for Ash Framework patterns by:

Providing multi-format code generation
Maintaining high quality standards
Respecting the Elixir community's values
Building trust through transparency and immutability

The system acknowledges that most shared code is "here's what worked for me" rather than perfect solutions, and designs around this reality with a focus on templates and starting points rather than dependencies.

This design document represents the synthesis of our discussion, incorporating lessons from LiveView Native, Pyro/AshPyro, Raxol, and the realities of open-source component sharing. The multi-format approach with immutable releases provides the flexibility developers need while maintaining the stability the Elixir community expects.
