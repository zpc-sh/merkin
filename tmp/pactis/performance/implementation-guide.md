# Pactis Storage System Performance Optimization Implementation Guide

**Document Version:** 1.0  
**Date:** December 2024  
**Target Audience:** Engineering Team  
**Prerequisites:** Elixir/Phoenix experience, Redis knowledge, Performance testing familiarity

## Overview

This implementation guide provides step-by-step instructions for implementing the performance optimizations outlined in the optimization plan. Each section includes detailed code examples, testing procedures, and deployment strategies.

## Pre-Implementation Setup

### 1. Development Environment Setup

```bash
# Clone and setup Pactis project
git clone https://github.com/your-org/pactis.git
cd pactis

# Create performance optimization branch
git checkout -b performance-optimization-phase1

# Install dependencies
mix deps.get
mix deps.compile

# Setup test database
mix ecto.create
mix ecto.migrate
```

### 2. Benchmarking Infrastructure

Create the performance testing infrastructure before implementing optimizations:

```elixir
# Create: test/support/performance_helpers.ex
defmodule Pactis.Test.PerformanceHelpers do
  @moduledoc """
  Helpers for performance testing and benchmarking.
  """

  def benchmark(name, fun) do
    {time, result} = :timer.tc(fun)
    IO.puts("#{name}: #{time / 1000}ms")
    result
  end

  def memory_benchmark(name, fun) do
    :erlang.garbage_collect()
    memory_before = :erlang.memory(:total)
    
    {time, result} = :timer.tc(fun)
    
    :erlang.garbage_collect()
    memory_after = :erlang.memory(:total)
    
    memory_delta = memory_after - memory_before
    
    IO.puts("#{name}:")
    IO.puts("  Time: #{time / 1000}ms")
    IO.puts("  Memory delta: #{memory_delta / 1024}KB")
    
    result
  end

  def generate_test_components(count) do
    1..count
    |> Enum.map(fn i ->
      %{
        jsx_code: """
        import React from 'react';
        
        const Component#{i} = ({ title, onClick }) => {
          return (
            <div className="component-#{i}">
              <h1>{title}</h1>
              <button onClick={onClick}>Click me #{i}</button>
            </div>
          );
        };
        
        export default Component#{i};
        """,
        styles: %{
          "component-#{i}" => %{
            "padding" => "20px",
            "border" => "1px solid #ccc",
            "border-radius" => "8px"
          }
        },
        props_schema: %{
          "title" => %{"type" => "string", "required" => true},
          "onClick" => %{"type" => "function", "required" => false}
        },
        dependencies: ["react"],
        framework: :react
      }
    end)
  end

  def generate_large_test_components(count) do
    1..count
    |> Enum.map(fn i ->
      large_jsx = String.duplicate("const variable#{i} = 'test';\n", 100)
      
      %{
        jsx_code: large_jsx <> """
        import React from 'react';
        
        const LargeComponent#{i} = (props) => {
          // Large component with many variables and functions
          #{String.duplicate("const func#{i}_#{j} = () => console.log('test');\n", 50) |> String.replace("#{j}", "")}
          
          return (
            <div>
              #{String.duplicate("<div key={#{i}}>Item #{i}</div>\n", 20)}
            </div>
          );
        };
        
        export default LargeComponent#{i};
        """,
        styles: generate_large_styles(i),
        props_schema: generate_complex_props_schema(i),
        dependencies: ["react", "lodash", "moment"],
        framework: :react
      }
    end)
  end

  defp generate_large_styles(i) do
    1..20
    |> Enum.map(fn j ->
      {"class-#{i}-#{j}", %{
        "color" => "##{:rand.uniform(16777215) |> Integer.to_string(16)}",
        "padding" => "#{:rand.uniform(20)}px",
        "margin" => "#{:rand.uniform(10)}px"
      }}
    end)
    |> Enum.into(%{})
  end

  defp generate_complex_props_schema(i) do
    1..10
    |> Enum.map(fn j ->
      {"prop#{i}_#{j}", %{
        "type" => Enum.random(["string", "number", "boolean", "object"]),
        "required" => Enum.random([true, false])
      }}
    end)
    |> Enum.into(%{})
  end
end
```

### 3. Baseline Performance Tests

```elixir
# Create: test/performance/baseline_test.exs
defmodule Pactis.Performance.BaselineTest do
  use ExUnit.Case, async: false
  
  import Pactis.Test.PerformanceHelpers
  
  alias Pactis.Storage.ContentAddressable
  alias Pactis.Storage.ContentAddressable.Indexer
  alias Pactis.Storage.Deduplication
  alias Pactis.Versioning.MerkleTree

  @moduletag :performance

  test "baseline: component indexing performance" do
    components = generate_test_components(100)
    user = %{id: "test_user", workspace_id: "test_workspace"}
    
    {time, _} = :timer.tc(fn ->
      Enum.each(components, fn component ->
        {:ok, hash} = ContentAddressable.compute_content_hash(component)
        metadata = %{
          size: :erlang.term_to_binary(component) |> byte_size(),
          framework: component.framework,
          semantic_fingerprint: "test_fingerprint_#{hash}",
          created_at: DateTime.utc_now(),
          complexity: 10
        }
        Indexer.index_component(user, hash, metadata)
      end)
    end)
    
    avg_time_per_component = time / length(components) / 1000
    IO.puts("Baseline indexing: #{avg_time_per_component}ms per component")
    
    # Store baseline for comparison
    File.write!("baseline_indexing.txt", "#{avg_time_per_component}")
  end

  test "baseline: merkle tree construction performance" do
    components = generate_test_components(50)
    |> Enum.with_index()
    |> Enum.map(fn {component, i} -> {"component_#{i}.jsx", component} end)
    |> Enum.into(%{})
    
    user = %{id: "test_user", workspace_id: "test_workspace"}
    
    {time, {:ok, _tree}} = :timer.tc(fn ->
      MerkleTree.build_from_components(components, user: user, version: "1.0.0")
    end)
    
    IO.puts("Baseline Merkle tree construction: #{time / 1000}ms")
    File.write!("baseline_merkle.txt", "#{time / 1000}")
  end

  test "baseline: memory usage during deduplication" do
    components = generate_large_test_components(20)
    user = %{id: "test_user", workspace_id: "test_workspace"}
    
    memory_benchmark("Baseline deduplication analysis", fn ->
      {:ok, _duplicates} = Deduplication.find_duplicate_blocks(components, user)
    end)
  end
end
```

Run baseline tests:
```bash
mix test test/performance/baseline_test.exs --include performance
```

## Phase 1 Implementation: Quick Wins

### 1. Redis Pipelining Implementation

#### Step 1: Update Cache Module

```elixir
# Update: lib/pactis/cache.ex
defmodule Pactis.Cache do
  @moduledoc """
  Redis cache interface with performance optimizations.
  """

  # Add to existing cache module
  @doc """
  Execute multiple Redis commands in a single pipeline for better performance.
  """
  def pipeline(commands) when is_list(commands) do
    case Redix.pipeline(get_conn(), commands) do
      {:ok, results} -> {:ok, results}
      {:error, reason} -> {:error, {:pipeline_failed, reason}}
    end
  end

  @doc """
  Get multiple keys in a single operation.
  """
  def mget(keys) when is_list(keys) do
    case Redix.command(get_conn(), ["MGET" | keys]) do
      {:ok, values} -> {:ok, values}
      {:error, reason} -> {:error, {:mget_failed, reason}}
    end
  end

  @doc """
  Set multiple key-value pairs in a single operation.
  """
  def mset(key_value_pairs) when is_list(key_value_pairs) do
    flat_args = Enum.flat_map(key_value_pairs, fn {k, v} -> [k, encode_value(v)] end)
    
    case Redix.command(get_conn(), ["MSET" | flat_args]) do
      {:ok, "OK"} -> :ok
      {:error, reason} -> {:error, {:mset_failed, reason}}
    end
  end

  # Helper function to encode values consistently
  defp encode_value(value) when is_binary(value), do: value
  defp encode_value(value), do: Jason.encode!(value)
end
```

#### Step 2: Update Indexer with Pipelining

```elixir
# Update: lib/pactis/storage/content_addressable/indexer.ex

defmodule Pactis.Storage.ContentAddressable.Indexer do
  # ... existing code ...

  @doc """
  Optimized component indexing using Redis pipelining.
  """
  def index_component_optimized(user, component_hash, metadata) do
    try do
      # Build all Redis commands for pipeline execution
      pipeline_commands = build_index_pipeline_commands(user, component_hash, metadata)
      
      case Pactis.Cache.pipeline(pipeline_commands) do
        {:ok, results} ->
          # Verify all operations succeeded
          if all_operations_successful?(results) do
            Logger.debug("Indexed component #{component_hash} for user #{user.id} (optimized)")
            :ok
          else
            {:error, {:pipeline_partial_failure, results}}
          end
          
        {:error, reason} ->
          Logger.error("Pipeline indexing failed for #{component_hash}: #{inspect(reason)}")
          # Fallback to individual operations
          fallback_to_individual_indexing(user, component_hash, metadata)
      end

    rescue
      error ->
        Logger.error("Optimized indexing failed for #{component_hash}: #{inspect(error)}")
        {:error, {:indexing_failed, error}}
    end
  end

  defp build_index_pipeline_commands(user, component_hash, metadata) do
    [
      # Primary index: hash -> metadata
      ["SET", "#{@primary_index_key}:#{component_hash}", Jason.encode!(metadata)],
      
      # Framework index: framework -> [hashes]
      ["SADD", "#{@framework_index_key}:#{metadata.framework}", component_hash],
      
      # Similarity index: semantic_fingerprint -> [hashes] 
      ["SADD", "#{@similarity_index_key}:#{metadata.semantic_fingerprint}", component_hash],
      
      # Size index: size_range -> [hashes]
      ["SADD", "#{@size_index_key}:#{get_size_bucket(metadata.size)}", component_hash],
      
      # User index: user_id -> [hashes]
      ["SADD", "#{@user_index_key}:#{user.id}", component_hash],
      
      # Workspace index: workspace_id -> [hashes]
      ["SADD", "#{@workspace_index_key}:#{user.workspace_id}", component_hash],
      
      # Update statistics atomically
      ["HINCRBY", "#{@stats_key}:#{user.workspace_id}", "total_components", 1],
      ["HINCRBY", "#{@stats_key}:#{user.workspace_id}", "total_size", metadata.size || 0],
      ["HINCRBY", "#{@stats_key}:#{user.workspace_id}", "framework_#{metadata.framework}", 1],
      ["HSET", "#{@stats_key}:#{user.workspace_id}", "last_updated", DateTime.utc_now() |> DateTime.to_unix()]
    ]
  end

  defp all_operations_successful?(results) do
    Enum.all?(results, fn result ->
      case result do
        "OK" -> true
        {:ok, _} -> true
        n when is_integer(n) -> true  # SADD returns number of added elements
        _ -> false
      end
    end)
  end

  defp fallback_to_individual_indexing(user, component_hash, metadata) do
    Logger.warn("Falling back to individual Redis operations for #{component_hash}")
    # Call the original implementation as fallback
    index_component_original(user, component_hash, metadata)
  end

  # Batch operations for multiple components
  def index_components_batch(user, component_metadata_pairs, opts \\ []) do
    max_pipeline_size = Keyword.get(opts, :max_pipeline_size, 100)
    
    component_metadata_pairs
    |> Enum.chunk_every(max_pipeline_size)
    |> Enum.map(&index_component_batch(&1, user))
    |> Enum.reduce({:ok, []}, &combine_batch_results/2)
  end

  defp index_component_batch(batch, user) do
    # Build pipeline commands for entire batch
    all_commands = 
      batch
      |> Enum.flat_map(fn {component_hash, metadata} ->
        build_index_pipeline_commands(user, component_hash, metadata)
      end)
    
    case Pactis.Cache.pipeline(all_commands) do
      {:ok, _results} -> {:ok, Enum.map(batch, fn {hash, _} -> hash end)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp combine_batch_results({:ok, batch_results}, {:ok, all_results}) do
    {:ok, all_results ++ batch_results}
  end
  defp combine_batch_results({:error, reason}, _acc), do: {:error, reason}
  defp combine_batch_results(_batch, {:error, reason}), do: {:error, reason}
end
```

#### Step 3: Add Feature Flag Support

```elixir
# Create: lib/pactis/storage/feature_flags.ex
defmodule Pactis.Storage.FeatureFlags do
  @moduledoc """
  Feature flags for storage system optimizations.
  """

  def redis_pipelining_enabled?(workspace_id) do
    case System.get_env("REDIS_PIPELINING_ENABLED") do
      "true" -> true
      "false" -> false
      nil ->
        # Default: enable for specific workspaces for gradual rollout
        enabled_workspaces = Application.get_env(:pactis, :redis_pipelining_workspaces, [])
        workspace_id in enabled_workspaces
    end
  end

  def parallel_storage_enabled?(workspace_id) do
    case System.get_env("PARALLEL_STORAGE_ENABLED") do
      "true" -> true
      "false" -> false
      nil ->
        enabled_workspaces = Application.get_env(:pactis, :parallel_storage_workspaces, [])
        workspace_id in enabled_workspaces
    end
  end

  def similarity_caching_enabled?(workspace_id) do
    case System.get_env("SIMILARITY_CACHING_ENABLED") do
      "true" -> true
      "false" -> false
      nil ->
        # Enable by default - low risk optimization
        true
    end
  end
end
```

#### Step 4: Update Main Interface with Feature Flags

```elixir
# Update: lib/pactis/storage/content_addressable/indexer.ex

def index_component(user, component_hash, metadata) do
  if Pactis.Storage.FeatureFlags.redis_pipelining_enabled?(user.workspace_id) do
    index_component_optimized(user, component_hash, metadata)
  else
    index_component_original(user, component_hash, metadata)
  end
end

# Rename existing implementation for fallback
def index_component_original(user, component_hash, metadata) do
  # ... existing implementation ...
end
```

### 2. Similarity Caching Implementation

#### Step 1: Create Similarity Cache Module

```elixir
# Create: lib/pactis/storage/similarity_cache.ex
defmodule Pactis.Storage.SimilarityCache do
  @moduledoc """
  Caching layer for expensive component similarity calculations.
  """

  alias Pactis.Cache
  alias Pactis.Delta.ComponentDiff

  @cache_prefix "similarity"
  @default_ttl :timer.hours(24)

  @doc """
  Calculate semantic similarity with caching.
  """
  def calculate_cached_similarity(component1, component2, opts \\ []) do
    ttl = Keyword.get(opts, :ttl, @default_ttl)
    force_refresh = Keyword.get(opts, :force_refresh, false)
    
    cache_key = generate_similarity_cache_key(component1, component2)
    
    if force_refresh do
      calculate_and_cache_similarity(component1, component2, cache_key, ttl)
    else
      case Cache.get(cache_key) do
        {:ok, similarity} when similarity != nil ->
          similarity
        _ ->
          calculate_and_cache_similarity(component1, component2, cache_key, ttl)
      end
    end
  end

  @doc """
  Precompute and cache similarities for a batch of components.
  """
  def precompute_similarities_batch(components, opts \\ []) do
    max_concurrency = Keyword.get(opts, :max_concurrency, 10)
    
    # Generate all unique pairs
    component_pairs = generate_component_pairs(components)
    
    # Process pairs in parallel with controlled concurrency
    component_pairs
    |> Task.async_stream(
      fn {comp1, comp2} -> 
        calculate_cached_similarity(comp1, comp2, opts)
      end,
      max_concurrency: max_concurrency,
      timeout: 30_000
    )
    |> Enum.reduce(0, fn
      {:ok, _similarity}, acc -> acc + 1
      _, acc -> acc
    end)
  end

  defp generate_similarity_cache_key(component1, component2) do
    with {:ok, hash1} <- Pactis.Storage.ContentAddressable.compute_content_hash(component1),
         {:ok, hash2} <- Pactis.Storage.ContentAddressable.compute_content_hash(component2) do
      # Ensure consistent ordering for cache key
      {min_hash, max_hash} = if hash1 <= hash2, do: {hash1, hash2}, else: {hash2, hash1}
      "#{@cache_prefix}:#{min_hash}:#{max_hash}"
    else
      _ ->
        # Fallback to content-based hash if content hash computation fails
        content1 = :erlang.term_to_binary(component1) |> :crypto.hash(:sha256) |> Base.encode16(case: :lower)
        content2 = :erlang.term_to_binary(component2) |> :crypto.hash(:sha256) |> Base.encode16(case: :lower)
        {min_hash, max_hash} = if content1 <= content2, do: {content1, content2}, else: {content2, content1}
        "#{@cache_prefix}:#{min_hash}:#{max_hash}"
    end
  end

  defp calculate_and_cache_similarity(component1, component2, cache_key, ttl) do
    similarity = calculate_similarity_impl(component1, component2)
    
    # Cache the result
    Cache.set(cache_key, similarity, ttl: ttl)
    
    similarity
  end

  defp calculate_similarity_impl(component1, component2) do
    # Quick similarity check first to avoid expensive operations
    quick_similarity = calculate_quick_similarity_score(component1, component2)
    
    if quick_similarity < 0.3 do
      # Skip expensive calculation for obviously different components
      quick_similarity
    else
      # Full expensive calculation only for potentially similar components
      delta = ComponentDiff.generate_component_delta(component1, component2)
      calculate_detailed_similarity(delta)
    end
  end

  defp calculate_quick_similarity_score(component1, component2) do
    # Fast heuristics-based similarity
    framework_match = if component1.framework == component2.framework, do: 0.3, else: 0.0
    
    size1 = byte_size(component1.jsx_code || "")
    size2 = byte_size(component2.jsx_code || "")
    size_similarity = if size1 > 0 and size2 > 0 do
      min(size1, size2) / max(size1, size2) * 0.2
    else
      0.0
    end
    
    deps1 = MapSet.new(component1.dependencies || [])
    deps2 = MapSet.new(component2.dependencies || [])
    deps_similarity = if MapSet.size(deps1) > 0 or MapSet.size(deps2) > 0 do
      intersection_size = MapSet.intersection(deps1, deps2) |> MapSet.size()
      union_size = MapSet.union(deps1, deps2) |> MapSet.size()
      intersection_size / union_size * 0.2
    else
      0.0
    end
    
    framework_match + size_similarity + deps_similarity
  end

  defp calculate_detailed_similarity(delta) do
    jsx_similarity = calculate_code_similarity(delta.jsx_delta)
    style_similarity = calculate_style_similarity(delta.style_delta)
    props_similarity = calculate_schema_similarity(delta.props_delta)
    deps_similarity = calculate_deps_similarity(delta.deps_delta)
    
    # Weighted average
    jsx_similarity * 0.4 + style_similarity * 0.2 + props_similarity * 0.2 + deps_similarity * 0.2
  end

  # ... implement similarity calculation helpers ...
  defp calculate_code_similarity(jsx_delta) do
    # Implementation based on unchanged vs changed blocks
    total_blocks = length(jsx_delta.unchanged || []) + length(jsx_delta.added || []) + length(jsx_delta.removed || [])
    if total_blocks > 0 do
      length(jsx_delta.unchanged || []) / total_blocks
    else
      1.0
    end
  end

  defp calculate_style_similarity(style_delta) do
    total_props = map_size(style_delta.unchanged || %{}) + map_size(style_delta.added || %{}) + map_size(style_delta.removed || %{})
    if total_props > 0 do
      map_size(style_delta.unchanged || %{}) / total_props
    else
      1.0
    end
  end

  defp calculate_schema_similarity(props_delta) do
    total_props = map_size(props_delta.unchanged || %{}) + map_size(props_delta.added || %{}) + map_size(props_delta.removed || %{})
    if total_props > 0 do
      map_size(props_delta.unchanged || %{}) / total_props
    else
      1.0
    end
  end

  defp calculate_deps_similarity(deps_delta) do
    total_deps = length(deps_delta.unchanged || []) + length(deps_delta.added || []) + length(deps_delta.removed || [])
    if total_deps > 0 do
      length(deps_delta.unchanged || []) / total_deps
    else
      1.0
    end
  end

  defp generate_component_pairs(components) do
    for {comp1, i} <- Enum.with_index(components),
        {comp2, j} <- Enum.with_index(components),
        i < j,
        do: {comp1, comp2}
  end
end
```

#### Step 2: Update ContentAddressable to Use Similarity Cache

```elixir
# Update: lib/pactis/storage/content_addressable.ex

defmodule Pactis.Storage.ContentAddressable do
  # ... existing code ...
  
  alias Pactis.Storage.SimilarityCache
  alias Pactis.Storage.FeatureFlags

  defp calculate_semantic_similarity(component1, component2) do
    # Use cached similarity if feature is enabled
    if FeatureFlags.similarity_caching_enabled?("default") do
      SimilarityCache.calculate_cached_similarity(component1, component2)
    else
      # Original implementation for fallback
      calculate_semantic_similarity_original(component1, component2)
    end
  end

  defp calculate_semantic_similarity_original(component1, component2) do
    # ... existing implementation ...
  end
end
```

### 3. Parallel folder_api Implementation

#### Step 1: Connection Pool Setup

```elixir
# Add to lib/pactis/application.ex
defmodule Pactis.Application do
  def start(_type, _args) do
    children = [
      # ... existing children ...
      
      # Add connection pool for folder_api
      {Pactis.Storage.FolderApiPool, [
        name: :folder_api_pool,
        size: 20,
        max_overflow: 10,
        worker_module: Pactis.Storage.FolderApiWorker
      ]}
    ]

    opts = [strategy: :one_for_one, name: Pactis.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

#### Step 2: Create Connection Pool Worker

```elixir
# Create: lib/pactis/storage/folder_api_pool.ex
defmodule Pactis.Storage.FolderApiPool do
  @moduledoc """
  Connection pool for folder_api operations.
  """

  def child_spec(opts) do
    pool_opts = [
      name: {:local, Keyword.get(opts, :name, :folder_api_pool)},
      worker_module: Keyword.get(opts, :worker_module, Pactis.Storage.FolderApiWorker),
      size: Keyword.get(opts, :size, 10),
      max_overflow: Keyword.get(opts, :max_overflow, 5),
      strategy: :fifo
    ]

    :poolboy.child_spec(__MODULE__, pool_opts)
  end

  def execute(fun) when is_function(fun, 1) do
    :poolboy.transaction(:folder_api_pool, fun, 30_000)
  end

  def execute_async(fun) when is_function(fun, 1) do
    Task.async(fn -> execute(fun) end)
  end
end

defmodule Pactis.Storage.FolderApiWorker do
  @moduledoc """
  Worker process for folder_api operations.
  """
  
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], [])
  end

  def init([]) do
    # Initialize any connection state here
    {:ok, %{}}
  end

  def handle_call({:store, user, hash, data}, _from, state) do
    result = folder_api_store_impl(user, hash, data)
    {:reply, result, state}
  end

  def handle_call({:get, user, hash}, _from, state) do
    result = folder_api_get_impl(user, hash)
    {:reply, result, state}
  end

  defp folder_api_store_impl(user, hash, data) do
    # Actual folder_api integration
    case Folder.ContentAddressable.store(user, hash, data) do
      {:ok, hash} -> {:ok, hash}
      error -> error
    end
  rescue
    error -> {:error, {:folder_api_unavailable, error}}
  end

  defp folder_api_get_impl(user, hash) do
    case Folder.ContentAddressable.get(user, hash) do
      {:ok, data} -> {:ok, data}
      error -> error
    end
  rescue
    error -> {:error, {:folder_api_unavailable, error}}
  end
end
```

#### Step 3: Update ContentAddressable for Parallel Operations

```elixir
# Update: lib/pactis/storage/content_addressable.ex

defmodule Pactis.Storage.ContentAddressable do
  alias Pactis.Storage.{FolderApiPool, FeatureFlags}

  def store_components_batch(user, components, opts \\ []) do
    if FeatureFlags.parallel_storage_enabled?(user.workspace_id) do
      store_components_batch_parallel(user, components, opts)
    else
      store_components_batch_sequential(user, components, opts)
    end
  end

  defp store_components_batch_parallel(user, components, opts) do
    max_concurrency = Keyword.get(opts, :max_concurrency, 10)
    timeout = Keyword.get(opts, :timeout, 30_000)
    
    # Pre-compute hashes and normalize components
    components_with_hashes = 
      components
      |> Task.async_stream(
        fn component ->
          case normalize_component_data(component) do
            {:ok, normalized} ->
              case compute_content_hash(normalized) do
                {:ok, hash} -> {:ok, {hash, normalized, component}}
                error -> error
              end
            error -> error
          end
        end,
        max_concurrency: max_concurrency,
        timeout: 10_000
      )
      |> Enum.map(fn {:ok, result} -> result end)

    case Enum.find(components_with_hashes, &match?({:error, _}, &1)) do
      {:error, _} = error -> error
      nil ->
        # Group by hash to identify duplicates
        {unique_components, duplicate_info} = group_and_deduplicate(components_with_hashes)
        
        # Process unique components in parallel
        unique_results = process_unique_components_parallel(user, unique_components, opts)
        
        # Handle duplicates
        duplicate_results = handle_duplicates(duplicate_info, unique_results)
        
        {:ok, unique_results ++ duplicate_results}
    end
  end

  defp process_unique_components_parallel(user, unique_components, opts) do
    max_concurrency = Keyword.get(opts, :max_concurrency, 10)
    timeout = Keyword.get(opts, :timeout, 30_000)
    
    unique_components
    |> Task.async_stream(
      fn {:unique, hash, normalized, _original} ->
        # Use connection pool for parallel folder_api calls
        FolderApi