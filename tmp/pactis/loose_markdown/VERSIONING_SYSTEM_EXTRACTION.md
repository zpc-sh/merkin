# Pactis JSON-LD Versioning System - Complete Documentation

## Executive Summary

The Pactis repository implements a unique versioning system that embeds semantic versioning metadata directly into documents using JSON-LD (JSON for Linking Data). Unlike traditional version control systems that track changes externally, this system creates self-contained, semantically-rich documents that carry their complete version history and relationships.

## Architecture Overview

### Core Design Philosophy

1. **Self-Contained Documents**: Each document contains its complete version metadata, relationships, and semantic context
2. **Semantic Versioning**: Uses JSON-LD to provide machine-readable version relationships
3. **No External Dependencies**: Documents are portable and don't require external version control
4. **Rich Metadata**: Versions include quality metrics, compatibility information, and semantic relationships

### Key Components

```
┌─────────────────────────────────────────────┐
│           JSON-LD Versioning Core           │
├─────────────────────────────────────────────┤
│  • Version Context Creation                 │
│  • Relationship Management                  │
│  • Semantic Validation                      │
│  • Fork/Merge Support                       │
└─────────────────────────────────────────────┘
                    │
        ┌───────────┴───────────┐
        ▼                       ▼
┌──────────────┐       ┌──────────────────┐
│ Diff Engine  │       │ Metadata Manager │
├──────────────┤       ├──────────────────┤
│ • Unified    │       │ • Context Expand │
│ • Side-by-   │       │ • Enrichment     │
│   Side       │       │ • Synchronization│
│ • Word-level │       │ • Validation     │
│ • HTML       │       └──────────────────┘
└──────────────┘

```

## Core Modules Analysis

### 1. Pactis.Versioning (`lib/pactis/versioning/versioning.ex`)

**Purpose**: Core JSON-LD versioning functionality

**Key Functions**:
- `create_version_context/2` - Creates JSON-LD context for a version
- `create_relationship/3` - Establishes version relationships (supersedes, extends, replaces)
- `add_quality_metrics/2` - Adds quality/test coverage metadata
- `compare_versions/2` - Compares two versions and determines relationships
- `create_fork_context/3` - Creates fork relationships in JSON-LD

**Dependencies**: None (pure Elixir)

**JSON-LD Context Structure**:
```elixir
%{
  "@context" => %{
    "@vocab" => "https://pactis.dev/vocab/",
    "version" => "http://schema.org/version",
    "supersedes" => "http://schema.org/supersedes",
    "replaces" => "http://schema.org/replaces",
    "extends" => "http://schema.org/isBasedOn",
    "compatibleWith" => "http://schema.org/compatibleWith",
    "qualityScore" => "https://pactis.dev/vocab/qualityScore",
    "testCoverage" => "https://pactis.dev/vocab/testCoverage"
  },
  "@type" => "Blueprint",
  "@id" => "https://pactis.dev/blueprint/#{name}/#{version}",
  "version" => "1.2.0"
}
```

### 2. Diff Engine Implementations

The system includes THREE different diff algorithms:

#### A. **DiffGenerator** (`lib/pactis/conflict_resolver/diff_generator.ex`)

**Diff Types**:
1. **Unified Diff** - Traditional Git-style diff
2. **Side-by-Side Diff** - Visual comparison with color support
3. **Word-Level Diff** - Granular word changes within lines
4. **HTML Diff** - Web-friendly diff output
5. **Compact Summary** - Logging-friendly change summary

**Key Algorithm**:
```elixir
# Simple line-based comparison
defp calculate_changes(existing_lines, new_lines) do
  existing_set = MapSet.new(existing_lines)
  new_set = MapSet.new(new_lines)
  
  removed_lines = MapSet.difference(existing_set, new_set)
  added_lines = MapSet.difference(new_set, existing_set)
  common_lines = MapSet.intersection(existing_set, new_set)
  
  # Returns categorized changes
end
```

#### B. **FileAnalyzer** (`lib/pactis/conflict_resolver/file_analyzer.ex`)

**Smart Diff Features**:
- AST-based Elixir code analysis
- Pattern detection for user customizations
- Safe change detection (additive only)
- Modification scoring system

**Unique Algorithms**:
```elixir
# AST-based safe change detection
defp analyze_ast_changes(existing_ast, new_ast) do
  existing_defs = extract_definitions(existing_ast)
  new_defs = extract_definitions(new_ast)
  
  # Check if existing definitions are preserved
  Enum.all?(existing_defs, fn {name, arity} ->
    Map.has_key?(new_defs, {name, arity})
  end)
end

# Jaccard similarity for text comparison
defp calculate_similarity(existing_content, new_content) do
  existing_words = String.split(existing_content) |> MapSet.new()
  new_words = String.split(new_content) |> MapSet.new()
  
  intersection_size = MapSet.intersection(existing_words, new_words) |> MapSet.size()
  union_size = MapSet.union(existing_words, new_words) |> MapSet.size()
  
  intersection_size / union_size
end
```

#### C. **ConflictResolver** (`lib/pactis/conflict_resolver.ex`)

**Merge Strategies**:
- Safe merge (automatic for non-conflicting changes)
- Interactive resolution (user-guided)
- Backup & replace
- Skip conflicting files

### 3. Metadata Manager (`lib/pactis/core/metadata_manager.ex`)

**Purpose**: Manages JSON-LD context expansion, validation, and synchronization

**Key Features**:
- **Context Expansion**: Resolves vocabulary references and expands term definitions
- **Semantic Enrichment**: Infers types and suggests properties based on content
- **Format Synchronization**: Keeps JSON-LD metadata consistent across formats
- **Metadata Snapshots**: Creates versioned snapshots for history tracking

**Context Expansion Algorithm**:
```elixir
defp expand_term_definitions(context) do
  vocab = Map.get(context, "@vocab", "")
  
  Enum.reduce(context, %{}, fn {key, value}, acc ->
    cond do
      # Simple term, expand with @vocab
      is_binary(value) and not String.contains?(value, ":") ->
        expanded_def = %{
          "@id" => vocab <> value,
          "@type" => "@id"
        }
        Map.put(acc, key, expanded_def)
      
      # Complex term definition
      is_map(value) ->
        expanded_value = expand_term_id(value, vocab)
        Map.put(acc, key, expanded_value)
    end
  end)
end
```

## Version Operations

### 1. Creating a New Version

```elixir
# Create version context with JSON-LD
version_context = Pactis.Versioning.create_version_context("2.0.0", blueprint)

# Add quality metrics
enriched = Pactis.Versioning.add_quality_metrics(version_context, %{
  score: 0.95,
  test_coverage: 0.85,
  accessibility_compliance: true
})

# Establish relationship to previous version
final_context = Pactis.Versioning.create_relationship(
  enriched,
  "https://pactis.dev/blueprint/example/1.0.0",
  :supersedes
)
```

### 2. Comparing Versions

```elixir
result = Pactis.Versioning.compare_versions(context1, context2)
# Returns:
%{
  compatibility: :newer | :older | :compatible | :extends_other | :unrelated,
  relationships: %{
    context1: %{supersedes: "...", extends: "..."},
    context2: %{...}
  }
}
```

### 3. Creating a Fork

```elixir
fork_context = Pactis.Versioning.create_fork_context(
  base_context,
  "1.0.0-fork",
  %{name: "my-fork", author: "user"}
)
# Automatically sets up "extends" and "forkedFrom" relationships
```

## Storage Architecture

### Physical Storage

The system uses a pluggable storage adapter pattern:

```elixir
Pactis.FileStorage
├── LocalAdapter (development)
│   └── priv/storage/
│       ├── generated/
│       ├── exports/
│       ├── preview/
│       └── assets/
└── S3Adapter (production)
```

### Version Storage Pattern

Versions are stored as:
1. **Blueprint Records** - Main version data in PostgreSQL with JSON-LD context
2. **File Snapshots** - Physical files with embedded metadata
3. **Resource Snapshots** - JSON exports at specific timestamps

```elixir
# Blueprint storage structure
%Pactis.Core.Blueprint{
  jsonld_context: %{...},      # Full JSON-LD context
  semantic_type: "Blueprint",   # JSON-LD @type
  version: "1.2.0",
  version_major: 1,
  version_minor: 2,
  version_patch: 0,
  parent_blueprint_id: uuid,    # For forks
  resource_definition: %{       # Contains @context and @type
    "@context" => %{...},
    "@type" => "Resource",
    ...
  }
}
```

## Working Example

### Complete Versioned Document

```json
{
  "@context": {
    "@vocab": "https://pactis.dev/vocab/",
    "schema": "https://schema.org/",
    "version": "schema:version",
    "supersedes": "schema:supersedes",
    "qualityScore": "pactis:qualityScore",
    "testCoverage": "pactis:testCoverage"
  },
  "@type": "Blueprint",
  "@id": "https://pactis.dev/blueprint/user-auth/2.0.0",
  "version": "2.0.0",
  "supersedes": "https://pactis.dev/blueprint/user-auth/1.5.0",
  "name": "User Authentication Blueprint",
  "description": "Complete user authentication system",
  "qualityScore": 0.95,
  "testCoverage": 0.87,
  "resource_definition": {
    "@type": "AshResource",
    "attributes": [
      {"name": "email", "type": "string", "@type": "schema:EmailAddress"},
      {"name": "password_hash", "type": "string"}
    ]
  },
  "changelog": [
    {
      "version": "2.0.0",
      "changes": ["Added OAuth support", "Improved security"],
      "breaking": false
    },
    {
      "version": "1.5.0",
      "changes": ["Added 2FA"],
      "breaking": false
    }
  ]
}
```

### After Edit (New Version)

```json
{
  "@context": {
    "@vocab": "https://pactis.dev/vocab/",
    "schema": "https://schema.org/",
    "version": "schema:version",
    "supersedes": "schema:supersedes",
    "replaces": "schema:replaces"
  },
  "@type": "Blueprint",
  "@id": "https://pactis.dev/blueprint/user-auth/2.1.0",
  "version": "2.1.0",
  "supersedes": "https://pactis.dev/blueprint/user-auth/2.0.0",
  "name": "User Authentication Blueprint",
  "description": "Complete user authentication system with biometrics",
  "qualityScore": 0.97,
  "testCoverage": 0.90,
  "resource_definition": {
    "@type": "AshResource",
    "attributes": [
      {"name": "email", "type": "string", "@type": "schema:EmailAddress"},
      {"name": "password_hash", "type": "string"},
      {"name": "biometric_data", "type": "binary", "@new": true}
    ]
  },
  "changelog": [
    {
      "version": "2.1.0",
      "changes": ["Added biometric authentication"],
      "breaking": false
    },
    {
      "version": "2.0.0",
      "changes": ["Added OAuth support", "Improved security"],
      "breaking": false
    },
    {
      "version": "1.5.0",
      "changes": ["Added 2FA"],
      "breaking": false
    }
  ]
}
```

## Implementation Guide for Elixir/Phoenix

### Step 1: Core Modules Setup

```elixir
# 1. Create versioning module
defmodule MyApp.Versioning do
  @default_context %{
    "@vocab" => "https://myapp.com/vocab/",
    "version" => "http://schema.org/version",
    "supersedes" => "http://schema.org/supersedes"
  }
  
  def create_version_context(version, document) do
    %{
      "@context" => @default_context,
      "@type" => "Document",
      "@id" => generate_id(document, version),
      "version" => version
    }
  end
end

# 2. Create diff engine
defmodule MyApp.DiffEngine do
  def generate_diff(old, new) do
    # Implement your preferred diff algorithm
  end
end

# 3. Create metadata manager
defmodule MyApp.MetadataManager do
  def expand_context(context) do
    # Expand JSON-LD context
  end
  
  def create_snapshot(document) do
    %{
      document_id: document.id,
      timestamp: DateTime.utc_now(),
      context: document.jsonld_context,
      checksum: hash_document(document)
    }
  end
end
```

### Step 2: Database Schema

```elixir
defmodule MyApp.Repo.Migrations.CreateVersionedDocuments do
  use Ecto.Migration
  
  def change do
    create table(:documents) do
      add :name, :string, null: false
      add :version, :string, null: false
      add :jsonld_context, :map, default: %{}
      add :semantic_type, :string
      add :parent_id, references(:documents, type: :uuid)
      add :content, :text
      add :metadata, :map
      
      timestamps()
    end
    
    create index(:documents, [:name, :version], unique: true)
    create index(:documents, [:parent_id])
  end
end
```

### Step 3: Version Storage Service

```elixir
defmodule MyApp.VersionStorage do
  def store_version(document, content) do
    # 1. Create version context
    context = MyApp.Versioning.create_version_context(
      document.version,
      document
    )
    
    # 2. Calculate diff from previous
    previous = get_previous_version(document)
    diff = if previous do
      MyApp.DiffEngine.generate_diff(previous.content, content)
    end
    
    # 3. Store with embedded metadata
    %Document{
      jsonld_context: context,
      content: content,
      diff: diff,
      parent_id: previous && previous.id
    }
    |> Repo.insert()
  end
  
  def retrieve_version(name, version) do
    Repo.get_by(Document, name: name, version: version)
  end
  
  def reconstruct_at_version(name, version) do
    # Could reconstruct from diffs if storing deltas
  end
end
```

### Step 4: API Design

```elixir
defmodule MyAppWeb.VersionController do
  def create(conn, %{"document" => doc_params}) do
    with {:ok, document} <- MyApp.VersionStorage.store_version(doc_params) do
      json(conn, %{
        "@context" => document.jsonld_context,
        "@id" => document.jsonld_context["@id"],
        "version" => document.version
      })
    end
  end
  
  def show(conn, %{"name" => name, "version" => version}) do
    document = MyApp.VersionStorage.retrieve_version(name, version)
    
    json(conn, %{
      "@context" => document.jsonld_context,
      "content" => document.content,
      "version_info" => %{
        "current" => version,
        "previous" => get_previous_version_id(document),
        "next" => get_next_version_id(document)
      }
    })
  end
  
  def diff(conn, %{"from" => from_v, "to" => to_v}) do
    diff = MyApp.VersionStorage.generate_diff(from_v, to_v)
    json(conn, %{"diff" => diff})
  end
end
```

## Key Differentiators from Traditional VCS

1. **Embedded Metadata**: Version information lives within the document, not in external `.git` directories
2. **Semantic Relationships**: Uses RDF/JSON-LD vocabularies for machine-readable version relationships
3. **Self-Describing**: Documents carry their complete context and can be understood in isolation
4. **Quality Metrics**: Versions include test coverage, accessibility scores, and other quality indicators
5. **Format Agnostic**: Works with any document format that can embed JSON-LD
6. **No Binary Diffs**: Focuses on semantic document changes rather than byte-level differences

## Use Cases for AI Prompt Versioning

This system is ideal for versioning AI prompts because:

1. **Semantic Context**: Each prompt version carries its performance metrics, model compatibility, and relationships
2. **Self-Contained**: Prompts are portable with their complete history
3. **Quality Tracking**: Embed success rates, user ratings, and A/B test results
4. **Relationship Mapping**: Track which prompts extend or replace others
5. **No External Dependencies**: Prompts can be shared/stored anywhere while maintaining version info

### Example Prompt with Versioning

```json
{
  "@context": {
    "@vocab": "https://prompts.ai/vocab/",
    "version": "http://schema.org/version",
    "performance": "prompts:performanceMetric",
    "model": "prompts:targetModel"
  },
  "@type": "AIPrompt",
  "@id": "https://prompts.ai/writing-assistant/2.3.0",
  "version": "2.3.0",
  "supersedes": "https://prompts.ai/writing-assistant/2.2.0",
  "content": "You are a helpful writing assistant...",
  "model": ["gpt-4", "claude-3"],
  "performance": {
    "successRate": 0.89,
    "avgResponseTime": 1.2,
    "userRating": 4.7
  },
  "testResults": {
    "coverage": 0.95,
    "edgeCases": ["handled", "handled", "partial"]
  }
}
```

## Summary

The Pactis versioning system represents a paradigm shift from traditional version control. Instead of tracking changes externally, it embeds rich semantic metadata directly into documents using JSON-LD. This creates self-contained, portable documents that carry their complete version history, quality metrics, and relationships. The system's three diff algorithms provide flexibility for different comparison needs, while the metadata manager ensures semantic consistency across formats. This approach is particularly well-suited for versioning structured documents like AI prompts, where tracking performance metrics and model compatibility is as important as tracking content changes.