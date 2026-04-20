# Pactis Framework — Paradigm Tour

**A Revolutionary Standards-Track Protocol Ecosystem for "Negotiated Truth" in Software Development**

This is not just another web application - Pactis defines a complete paradigm shift where software artifacts achieve consensus through cryptographic verification, semantic knowledge graphs, and AI-augmented workflows.

## Table of Contents

1. [The Revolutionary Vision](#the-revolutionary-vision)
2. [17 Formal Interface Specifications](#17-formal-interface-specifications)
3. [Negotiated Truth Protocol](#negotiated-truth-protocol)
4. [AI-Augmented Development Workflow](#ai-augmented-development-workflow)
5. [Enterprise-Grade Infrastructure](#enterprise-grade-infrastructure)
6. [Semantic Implementation: priv/ Directory](#semantic-implementation-priv-directory)
7. [Application Layer Implementation](#application-layer-implementation)
8. [Getting Started with the Paradigm](#getting-started-with-the-paradigm)

---

## The Revolutionary Vision

**Pactis** redefines software development through **"Negotiated Truth"** - a formal framework where:

- **Every artifact** is cryptographically signed and content-addressed
- **AI agents** participate in specification negotiations with formal context
- **Knowledge graphs** capture patterns, decisions, and system relationships
- **Semantic workflows** enable deterministic, verifiable transformations
- **Economic models** meter usage and settle inter-service transactions

This isn't incremental improvement - it's a **paradigm shift** toward **verifiable, AI-collaborative, semantically-aware software development**.

---

## 17 Formal Interface Specifications

Pactis defines a complete **standards-track protocol ecosystem** with 17 formal interfaces:

### Core Framework Specifications

**Pactis** - The foundational framework defining:
- JSON-LD shapes (Blueprint, ArtifactPointer, Generator, Provenance)
- Context policy and validation taxonomy
- Determinism and idempotency guarantees
- ed25519 signatures over canonicalized JSON (URDNA2015)

**Pactis-TVI** (Truth Validation Interface) - Validation API with:
- Syntax → Schema → Policy validation tiers
- Machine-friendly error taxonomy
- Conformance testing framework

**Pactis-GRI** (Generator Registry Interface) - Capabilities and versions registry

**Pactis-API** (Artifact Publication Interface) - Core operations:
- `POST /enroll` - Register sources with context policy
- `POST /generate` - Transform inputs → ArtifactPointer
- `GET /artifacts/{pointer}` - Fetch immutable artifacts (CAS semantics)

**Pactis-VFS** (Virtual File System) - Content-addressed storage access

### AI & Knowledge Management

**Pactis-KEI** (Knowledge Engine Interface) - Powers the **Avici AI system**:
- BuildFrame: aggregate ContextFrames from scope and inputs
- HarvestManifests: ingest service registries and capabilities
- UpsertPattern/Decision: record curated knowledge with provenance
- Integration with SpecAPI and Language Server Protocol

**Pactis-CFP** (Context Frame Protocol) - Formal AI conversation context:
- CognitiveState (indirection levels 0-5, architect mode)
- ServiceRegistry with AI summaries and capabilities
- ActiveContext (projects, patterns, decisions)
- Cross-system correlation (SpecAPI threads, Kyozo sessions)

### Content & Authoring

**Pactis-CAI** (Content Authoring Interface) - Bidirectional content pipeline:
- JSON-LD ↔ Markdown-LD round-trip authoring
- Deterministic projections preserving semantic identity
- Conflict-aware merges with machine-resolvable hints
- Multi-channel publishing (HTML, PDF, docs, sites)

**Pactis-SRI** (Service Registry Interface) - Machine-readable service discovery:
- Canonical JSON-LD service manifests
- Aggregation API across repositories
- Well-known discovery paths (`/.well-known/pactis/service.jsonld`)

### Enterprise Infrastructure

**Pactis-SMI** (Settlement & Metering Interface) - Production billing system:
- JSON-LD billing events with semantic validation
- Tiered rating rules and usage aggregation
- Oban job queues for async processing
- Idempotent payment processing with dunning workflows

**Pactis-TAI** (Test API Interface) - Test execution as semantic artifacts:
- TestSuite, TestCase, TestRun as JSON-LD
- Correlation with SpecAPI and repository commits
- Portable, machine-readable test definitions

### Additional Specifications

**Pactis-LGI** (Language Gateway Interface)
**Pactis-DAI** (Design Automation Interface)
Plus trademark policies, naming rationale, and business protocols

---

## Negotiated Truth Protocol

The **core innovation** of Pactis: achieving consensus on software artifacts through formal semantic processes.

### Cryptographic Verification

**ed25519 Signatures** over canonicalized JSON-LD:
```
signature = ed25519_sign(
  private_key,
  canonicalize_jsonld(artifact, URDNA2015)
)
```

**Content-Addressed Storage**:
- Artifacts referenced by cryptographic hash
- Deterministic generation: same inputs → same pointer
- Immutable: once published, never changes

**Idempotency Keys**:
```
unique_key = hash(source_id, framework_version, generator_version)
```

### Validation Tiers

**Syntax Validation** → **Schema Validation** → **Policy Validation**

Each tier produces machine-readable ValidationReports with structured error taxonomy.

### Provenance & Trust

W3C PROV-O ontology tracking:
- Who generated the artifact
- When and how it was created
- What sources were used
- Verification chain of dependencies

---

## AI-Augmented Development Workflow

### Context Frame Protocol (CFP)

Every AI interaction receives a **formal ContextFrame**:

```jsonld
{
  "@type": "avici:ContextFrame",
  "avici:cognitiveState": {
    "avici:indirection": 3,
    "avici:mode": "architect",
    "avici:avoid": ["implementation_details"]
  },
  "avici:serviceRegistry": [
    {
      "@type": "sri:Service",
      "@id": "urn:pactis:service:specapi",
      "avici:capabilities": ["cross-repo-negotiation"],
      "avici:aiSummary": "Conversation-driven spec requests"
    }
  ],
  "avici:activeContext": {
    "avici:projects": [{"@id": "urn:proj:pactis"}],
    "avici:patterns": [{"@id": "urn:pattern:async-jobs"}],
    "avici:decisions": [{"@id": "urn:decision:use-oban"}]
  }
}
```

### Knowledge Engine (Avici)

**Pattern Mining**: Automatically extract reusable patterns from specification negotiations

**Service Discovery**: Harvest and aggregate service manifests across repositories

**Context Correlation**: Link conversations, code commits, and system changes

**Memory Persistence**: Maintain conversation state via Kyozo sessions

### Language Server Integration

AI agents integrate via **Language Gateway Interface (LGI)** providing:
- IDE-native semantic assistance
- Context-aware code generation
- Real-time specification negotiation
- Pattern suggestion and validation

---

## Enterprise-Grade Infrastructure

### Settlement & Metering (SMI)

**Production billing system** with formal semantic events:

```jsonld
{
  "@type": "pactis:UsageEvent",
  "pactis:subscriptionId": "sub_123",
  "pactis:eventType": "api_call",
  "pactis:quantity": 1,
  "pactis:occurredAt": "2025-09-20T12:34:56Z",
  "pactis:idempotencyKey": "ue_01HZY0GMG4Z6"
}
```

**Tiered Rating Rules**:
```jsonld
{
  "@type": "pactis:RatingRule",
  "pactis:tiers": [
    {"upTo": 1000, "unitPrice": "0.10"},
    {"upTo": 5000, "unitPrice": "0.08"},
    {"unitPrice": "0.05"}
  ]
}
```

**Async Processing**: All billing operations via Oban job queues with:
- Exponential backoff retries
- Dead letter queue handling
- Idempotent processing guarantees
- Real-time telemetry and observability

### Content Authoring (CAI)

**Round-trip editing** between JSON-LD and Markdown-LD:
- **Deterministic projections** preserve semantic identity
- **Conflict resolution** with machine-readable merge hints
- **Multi-channel publishing** to HTML, PDF, documentation sites
- **Version control integration** with provenance tracking

### Test Infrastructure (TAI)

**Tests as semantic artifacts**:
- TestSuite, TestCase, TestRun defined in JSON-LD
- Portable across services and repositories
- Correlated with specifications and commits
- Machine-readable results and artifacts

---

## Semantic Implementation: priv/ Directory

The `priv/` directory is where **Pactis truly shines** as a semantic, content-addressed framework. This isn't just configuration - it's a complete **semantic web implementation** with JSON-LD, formal specifications, and deterministic artifact generation.

### Directory Structure
```
priv/
├── pactis.json                    # Schema.org service manifest
├── service.manifest.jsonld        # Pactis framework service descriptor
├── jsonld/                       # JSON-LD semantic definitions
│   ├── pactis.context.jsonld    # Core vocabulary context
│   ├── blueprints/              # Blueprint definitions as JSON-LD
│   ├── components/              # Component specifications
│   ├── ui/                      # UI component schemas
│   ├── flow_templates.jsonld    # Workflow templates (25KB+)
│   └── flow_execution.jsonld    # Execution patterns (20KB+)
├── repo/                        # Database assets
│   ├── migrations/              # Schema evolution
│   └── seeds.exs               # Rich seed data (787 lines)
└── resource_snapshots/          # Ash resource schema snapshots
    └── repo/                    # Timestamped resource definitions
```

### Service Manifest (`service.manifest.jsonld`)

This file defines Pactis as a **semantic service** with formal API contracts:

```jsonld
{
  "@context": ["/jsonld/pactis.context.jsonld"],
  "@id": "pactis:service/pactis",
  "@type": ["pactis:ServiceDescriptor", "schema:Service"],
  "name": "Pactis Framework",
  "description": "Negotiated truth framework with deterministic, signed, content‑addressed artifacts",
  "api": {
    "openapi": "/api/v1/openapi.json",
    "jsonapi": "/api/json",
    "manifests": [
      {"rel": "service", "href": "/service.jsonld"},
      {"rel": "context", "href": "/jsonld/pactis.context.jsonld"}
    ]
  },
  "branding": {
    "logo": {"contentUrl": "/branding/logo.svg?text=Pactis"},
    "theme": {"contentUrl": "/branding/theme.css"}
  }
}
```

### Business Model (`pactis.json`)

Schema.org-compliant service definition with business metadata:

```json
{
  "@type": "SoftwareApplication",
  "name": "Pactis",
  "alternateName": "Cloud Development & File Management",
  "url": "https://pactis.sh",
  "provider": {
    "@type": "Organization",
    "name": "Zero Point Consciousness",
    "url": "https://zpc.sh"
  },
  "offers": {
    "@type": "Offer",
    "price": "0",
    "priceCurrency": "USD"
  }
}
```

---

## JSON-LD Semantic Framework

Pactis implements a **complete semantic web architecture** using JSON-LD for component definitions, workflow templates, and system interoperability.

### Blueprint Definitions (`priv/jsonld/blueprints/`)

Each component is defined as **semantic JSON-LD** with full metadata:

```jsonld
// terminal-ui-component.jsonld
{
  "@context": {"@vocab": "https://blueprints.dev/vocab/"},
  "@id": "blueprints:terminal-ui-component",
  "@type": "AshResource",
  "name": "Terminal UI Component",
  "resource": {
    "module_name": "TerminalComponent",
    "attributes": [
      {"name": "command", "type": "string", "required": true},
      {"name": "output", "type": "string"},
      {"name": "timestamp", "type": "utc_datetime", "default": "utc_now()"}
    ],
    "actions": [
      {"name": "execute", "type": "action", "description": "Execute a terminal command"},
      {"name": "clear", "type": "action", "description": "Clear terminal history"}
    ],
    "meta": {
      "category": "terminal",
      "complexity": "intermediate",
      "supports_streaming": true
    }
  },
  "stats": {"downloads": 1847, "stars": 156, "forks": 23}
}
```

### Workflow Templates (`flow_templates.jsonld`)

**25KB of workflow definitions** including complete customer service automation:

```jsonld
{
  "@type": "FlowTemplate",
  "@id": "https://pactis.dev/templates/customer-service-automation",
  "name": "Customer Service Automation",
  "category": "customer-service",
  "estimatedSetupTime": "PT30M",
  "requiredServices": ["openai", "pinecone"],
  "estimatedCost": {"monthlyOperation": 45.00, "currency": "USD"},
  "nodes": [
    {
      "id": "input-sensor",
      "type": "sensor",
      "name": "Customer Input",
      "config": {"channels": ["email", "chat", "phone"]}
    }
    // ... complex flow definitions
  ]
}
```

### Context Vocabularies

**Formal semantic vocabularies** defining the component and workflow ontology:

```jsonld
// pactis.context.jsonld
{
  "@context": {
    "@vocab": "https://pactis.dev/schema/",
    "schema": "http://schema.org/",
    "pactis": "https://pactis.dev/schema/",
    "flow": "https://pactis.dev/schema/flow/"
  }
}
```

---

## Database Schema & Migrations

### Auto-Generated Ash Migrations

The initial migration (`20250917075414_initial_migration.exs`) is **53KB** and creates comprehensive schema:

```elixir
def up do
  # Code review system
  create table(:review_comments, primary_key: false) do
    add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
    add :file_path, :text, null: false
    add :line_number, :bigint
    add :body, :text, null: false
    add :code_review_id, :uuid
    add :author_id, :uuid
  end

  # Billing system with usage tracking
  create table(:billing_usage_events, primary_key: false) do
    add :event_type, :text, null: false
    add :quantity, :decimal, null: false, default: "1"
    add :unit_cost_cents, :bigint
    add :total_cost_cents, :bigint
  end

  # Component blueprint system
  create table(:blueprints, primary_key: false) do
    add :name, :text, null: false
    add :slug, :text, null: false
    add :description, :text
    add :resource_definition, :map
    add :readme, :text
    add :tags, {:array, :text}, default: []
    add :downloads_count, :bigint, default: 0
    add :stars_count, :bigint, default: 0
  end
end
```

### Resource Snapshots

**Timestamped schema snapshots** in `/resource_snapshots/repo/` capture the exact state of each Ash resource:

```json
// blueprints/20250917075414.json
{
  "attributes": [
    {"source": "id", "type": "uuid", "primary_key?": true},
    {"source": "name", "type": "text", "allow_nil?": false},
    {"source": "resource_definition", "type": "map"}
  ]
}
```

---

## Seed Data & Fixtures

### Rich Development Data (`seeds.exs` - 787 lines)

**Production-quality seed data** with comprehensive component examples:

```elixir
# 6 realistic users with authentication
users_data = [
  %{
    username: "alexdev", email: "alex@example.com",
    bio: "Full-stack developer passionate about building scalable applications with Elixir and Phoenix",
    github_handle: "alexdev", website_url: "https://alexdev.io"
  },
  %{
    username: "neon_ninja", email: "jen@example.com",
    bio: "Cyberpunk aesthetic enthusiast. Creating neon-inspired UIs that glow in the dark web",
    location: "Tokyo, Japan"
  }
]

# 6 component categories with icons and colors
categories_data = [
  %{name: "Authentication", color: "#3B82F6", icon: "hero-lock-closed"},
  %{name: "UI Components", color: "#8B5CF6", icon: "hero-squares-2x2"}
]

# 5 detailed blueprint examples
blueprints_data = [
  %{
    name: "Terminal UI Component",
    description: "A beautiful terminal interface component with syntax highlighting...",
    resource_definition: %{
      "module_name" => "TerminalComponent",
      "attributes" => [
        %{"name" => "command", "type" => "string", "required" => true},
        %{"name" => "timestamp", "type" => "utc_datetime", "default" => "utc_now()"}
      ],
      "actions" => [
        %{"name" => "execute", "type" => "action", "description" => "Execute a terminal command"}
      ]
    },
    readme: """
    # Terminal UI Component
    ## Features
    - 🎨 Syntax highlighting for multiple languages
    - 📜 Command history with search
    - ⚡ Real-time command execution
    """,
    downloads_count: 1847, stars_count: 156
  }
]
```

### Comprehensive Test Fixtures

**Organizations, collections, and realistic metadata** for development and testing scenarios.

---

## Application Layer Implementation

The system is organized into three main **Ash Domains**, each handling distinct business concerns:

### 1. Pactis.Core Domain (`lib/pactis/core.ex`)

**Primary Resources:**
- `Blueprint` - Design component templates with versioning
- `Repository` - Git-like repository management
- `Collection` - Curated component collections
- `Star`, `Fork`, `Download` - Social interactions
- `Review`, `Issue`, `Comment` - Community feedback
- `PackageDependency` - Component dependencies
- `UsageMetric` - Analytics data

**Key Functions:**
```elixir
Core.list_blueprints(opts \\ [])        # Paginated blueprint listing
Core.get_blueprint!(id)                 # Fetch specific blueprint
Core.get_repository_by_full_name(name)  # GitHub-style repo lookup
```

**JSON:API & TypeScript RPC:**
- Auto-generated OpenAPI specs at `/api/openapi.json`
- TypeScript-typed RPC endpoints for frontend integration
- Optimized query interfaces like `blueprint_cards` and `repo_header`

### 2. Pactis.Accounts Domain (`lib/pactis/accounts.ex`)

**Resources:**
- `User` - Core user management with OAuth support
- `Token`, `ApiToken` - Authentication tokens
- `Organization`, `Membership` - Team management

**Authentication Support:**
- Password-based auth with AshAuthentication
- GitHub OAuth integration
- Google OAuth integration
- API token-based access

### 3. Pactis.Spec Domain (`lib/pactis/spec.ex`)

**Resources:**
- `Workspace` - Project containers
- `SpecRequest` - Specification requirements
- `SpecMessage` - Threaded conversations
- `CodeReview` - Review workflows

**Collaboration Features:**
- Real-time messaging with thread support
- Review approval workflows
- Workspace-scoped project management

---

## UI Components & Patterns

The frontend uses **Phoenix LiveView** for real-time, interactive interfaces with **45 LiveView components** covering the entire user experience.

### Key LiveView Patterns

#### 1. Marketplace & Discovery
```elixir
# lib/pactis_web/live/blueprint_live/index.ex
defmodule PactisWeb.BlueprintLive.Index do
  # Real-time search, filtering, and sorting
  def handle_event("search", %{"search" => %{"query" => query}}, socket)
  def handle_event("filter_by_tag", %{"tag" => tag}, socket)
  def handle_event("sort", %{"field" => field}, socket)

  # Client-side filtering with server-side optimization
  defp filter_by_search(blueprints, search_query)
  defp filter_by_tags(blueprints, selected_tags)
end
```

#### 2. Repository Browsing
```elixir
# Routes in router.ex:188-210
live "/:owner/:repo", RepositoryLive.Show, :show
live "/:owner/:repo/tree/:ref/*path", RepositoryLive.Show, :show_path
live "/:owner/:repo/blob/:ref/*path", RepositoryLive.Show, :show_file
live "/:owner/:repo/commits", RepositoryLive.Commits.Index, :index
```

#### 3. Collaborative Specifications
```elixir
# lib/pactis_web/live/spec_live/
├── conversation.ex        # Main conversation interface
├── components/
│   ├── message_card.ex   # Individual message display
│   ├── message_composer.ex # Message creation
│   └── thread_view.ex    # Threaded discussions
```

### Authentication & Authorization

**Route Protection Patterns:**
```elixir
# Public routes (optional auth)
ash_authentication_live_session :authentication_optional do
  live "/blueprints", BlueprintLive.Index, :index
  live "/users/:username", UserLive.Profile, :profile
end

# Authenticated routes (required auth)
live_session :auth_required,
  on_mount: [{PactisWeb.LiveUserAuth, :live_user_required}] do
  live "/dashboard", DashboardLive.Index, :index
  live "/workspaces", WorkspaceLive.Index, :index
end
```

### TypeScript Integration

The system includes **TypeScript RPC** capabilities:
```typescript
// Generated from Ash resources
post "/rpc/run", AshTypescriptRpcController, :run
post "/rpc/validate", AshTypescriptRpcController, :validate
```

Assets include custom TypeScript helpers:
- `assets/js/ash_rpc.ts` - RPC client utilities
- `assets/js/rpc_helpers.ts` - Helper functions

---

## Integration Flows

### 1. Frontend-Backend Communication

**LiveView Pattern:**
```elixir
# Real-time updates via Phoenix PubSub
def handle_info({FormComponent, {:saved, blueprint}}, socket) do
  {:noreply, stream_insert(socket, :blueprints, blueprint)}
end
```

**RPC Pattern:**
```elixir
# TypeScript-typed RPC calls
typescript_rpc do
  resource Pactis.Blueprints.Blueprint do
    rpc_action :list_blueprints, :read
    typed_query :blueprint_cards, :read do
      ts_result_type_name "BlueprintCardResult"
      fields [:id, :name, :slug, :description, :version, :stars_count]
    end
  end
end
```

### 2. API Pipeline Architecture

**Pipeline Composition:**
```elixir
pipeline :api_authenticated do
  plug :accepts, ["json"]
  plug PactisWeb.Plugs.RateLimit, operation: "api_default"
  plug PactisWeb.Plugs.ApiAuth, required: true
end

pipeline :api_design_tokens_write do
  plug :accepts, ["json"]
  plug PactisWeb.Plugs.RateLimit, operation: "api_write"
  plug PactisWeb.Plugs.ApiAuth, required: true
  plug PactisWeb.Plugs.RequireScope, scopes: ["write:design-tokens"]
end
```

### 3. GitHub-Compatible API

**Repository Operations:**
```elixir
# GitHub-style API endpoints
scope "/api/v1/repos/:owner/:repo" do
  get "/", RepositoryController, :show
  get "/contents/*path", RepositoryContentController, :show
  put "/contents/*path", RepositoryContentController, :create_or_update
  post "/forks", RepositoryController, :fork_repo
end
```

---

## Testing Strategy

The test suite demonstrates comprehensive coverage patterns across all layers:

### 1. Resource Testing
```elixir
# test/pactis/accounts/user_test.exs
describe "password authentication" do
  test "register_with_password creates a user with hashed password"
  test "sign_in_with_password works with valid credentials"
end

describe "OAuth user creation" do
  test "register_with_github creates user from GitHub OAuth data"
  test "register_with_google creates user from Google OAuth data"
end
```

### 2. LiveView Testing
```elixir
# test/pactis_web/live/blueprint_live_test.exs
test "mount and basic rendering"
test "search functionality"
test "tag filtering"
test "sorting operations"
```

### 3. Integration Testing
```elixir
# test/pactis_web/integration/auth_integration_test.exs
test "full authentication flow"
test "API token access patterns"
```

---

## Reusable Patterns

### 1. Domain-Driven Resource Pattern

**Consistent Structure:**
```elixir
defmodule Pactis.SomeDomain do
  use Ash.Domain, extensions: [AshJsonApi.Domain, AshTypescript.Rpc]

  resources do
    resource(Pactis.SomeDomain.Resource)
  end

  typescript_rpc do
    resource Pactis.SomeDomain.Resource do
      rpc_action :list_items, :read
      typed_query :item_summary, :read do
        fields [:id, :name, :updated_at]
      end
    end
  end
end
```

### 2. LiveView State Management

**Search + Filter Pattern:**
```elixir
def mount(_params, _session, socket) do
  {:ok,
   socket
   |> assign(:search_query, "")
   |> assign(:selected_tags, [])
   |> assign(:sort_by, "updated_at")
   |> load_data()}
end

def handle_event("search", %{"search" => %{"query" => query}}, socket) do
  {:noreply, socket |> assign(:search_query, query) |> load_data()}
end
```

### 3. Pipeline Security Pattern

**Incremental Authorization:**
```elixir
# Base auth
pipeline :api_authenticated
# + Billing checks
pipeline :api_authenticated, PactisWeb.Plugs.BillingGate
# + Scope validation
pipeline :api_authenticated, PactisWeb.Plugs.RequireScope, scopes: ["write:design-tokens"]
```

### 4. JSON-LD Semantic Integration

**Specification Framework:**
```elixir
# Context policy and validation
# JSON-LD shapes for Blueprint, ArtifactPointer, Generator
# Deterministic content-addressing with ed25519 signatures
# Error taxonomy with machine-readable codes
```

---

## Getting Started with the Paradigm

### 1. Development Setup
```bash
mix deps.get
mix ecto.setup
mix assets.setup
mix phx.server
```

### 2. Key Endpoints
- **Web Interface**: `http://localhost:4000`
- **API Documentation**: `http://localhost:4000/api/docs`
- **LiveDashboard**: `http://localhost:4000/dev/dashboard`

### 3. API Access
```bash
# Register user
POST /api/v1/auth/register

# Create API token
POST /api/v1/tokens

# Access protected resources
Authorization: Bearer <token>
```

### 4. Testing
```bash
mix test                    # Run all tests
mix test --failed          # Run only failed tests
mix test test/pactis_web/  # Test web layer only
```

---

## Summary

**Pactis** is far more sophisticated than initially apparent - it's a **complete semantic web framework** implementing:

### Semantic Architecture
- **JSON-LD semantic definitions** for all components, workflows, and services
- **Formal vocabularies** with W3C-compliant context definitions
- **Content-addressed storage** with deterministic artifact generation
- **25KB+ workflow templates** for complex automation scenarios

### Data Architecture
- **53KB auto-generated migrations** from Ash resource definitions
- **787-line seed file** with production-quality fixtures
- **Timestamped resource snapshots** for schema versioning
- **Comprehensive billing system** with usage tracking

### Application Architecture
- **Domain-driven design** with 3 main Ash domains managing 33+ resources
- **45 LiveView components** providing real-time collaborative interfaces
- **666-line router** with GitHub-compatible API endpoints
- **TypeScript RPC integration** for type-safe frontend communication

### Semantic Web Implementation
- **Service manifests** with Schema.org compliance
- **Blueprint definitions** as formal JSON-LD specifications
- **Workflow ontologies** for automation and AI integration
- **Provenance tracking** with ed25519 signatures

**The Real Paradigm**: Pactis represents a **fundamental shift** in how software is conceived, developed, and verified. It's not just a framework - it's a **complete protocol ecosystem** defining the future of AI-collaborative, semantically-aware, cryptographically-verified software development.

This implementation proves that the vision is not only possible but **production-ready**, with enterprise billing, formal specifications, AI integration, and comprehensive tooling.

**For Protocol Implementers**: Study the 17 formal specifications in `docs/specifications/` to understand the complete ecosystem. Each interface is precisely defined with JSON-LD shapes, conformance requirements, and integration patterns.

**For Developers**: Start with the semantic APIs (`/service.jsonld`, `/jsonld/pactis.context.jsonld`) to understand machine-readable service discovery, then explore the GitHub-compatible endpoints for familiar integration patterns.

**For AI Researchers**: The Context Frame Protocol (CFP) and Knowledge Engine Interface (KEI) define how AI agents can participate meaningfully in software development with formal semantic context and verifiable knowledge graphs.

**For the Future**: Pactis defines the foundation for software development in an AI-augmented world where human and artificial intelligence collaborate through formal protocols, semantic understanding, and cryptographic verification.