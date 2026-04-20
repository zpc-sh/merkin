# Pactis Storage System Performance Testing Strategy

**Document Version:** 1.0  
**Date:** December 2024  
**Target Audience:** Engineering Team, QA Team, DevOps  
**Prerequisites:** Understanding of Pactis architecture, Elixir testing, Performance testing concepts

## Overview

This document outlines the comprehensive testing strategy for Pactis Storage System performance optimizations. It defines testing methodologies, tools, processes, and success criteria to ensure performance improvements are validated, sustainable, and regression-free.

## Testing Philosophy

### Core Principles

1. **Performance as Code** - All performance tests are version-controlled and automated
2. **Shift-Left Testing** - Performance testing integrated early in development cycle
3. **Continuous Validation** - Automated performance regression detection
4. **Real-World Simulation** - Tests reflect actual production usage patterns
5. **Measurable Outcomes** - All tests produce quantifiable metrics

### Testing Pyramid for Performance

```
    ┌─────────────────────┐
    │   Load/Stress       │  ← Production-like scenarios
    │   Testing           │    Full system under load
    └─────────────────────┘
  
  ┌───────────────────────────┐
  │   Integration             │  ← Component interactions
  │   Performance Tests       │    End-to-end workflows
  └───────────────────────────┘

┌─────────────────────────────────┐
│   Unit Performance Tests        │  ← Individual algorithms
│   Micro-benchmarks             │    Function-level optimization
└─────────────────────────────────┘
```

## Test Categories

### 1. Unit Performance Tests

**Purpose:** Validate individual function and algorithm performance
**Scope:** Single functions, data structures, algorithms
**Frequency:** Every commit
**Duration:** < 5 minutes total

#### Example Test Structure

```elixir
# test/performance/unit/indexing_performance_test.exs
defmodule Pactis.Performance.IndexingPerformanceTest do
  use ExUnit.Case, async: false
  use Benchee
  
  import Pactis.Test.PerformanceHelpers
  
  alias Pactis.Storage.ContentAddressable.Indexer

  @moduletag :unit_performance

  describe "Redis indexing operations" do
    test "single component indexing performance" do
      component = generate_test_component()
      user = build_test_user()
      metadata = build_test_metadata(component)
      
      # Benchmark both old and new implementations
      Benchee.run(%{
        "sequential_indexing" => fn ->
          Indexer.index_component_original(user, component.hash, metadata)
        end,
        "pipelined_indexing" => fn ->
          Indexer.index_component_optimized(user, component.hash, metadata)
        end
      }, time: 10, memory_time: 2)
    end

    test "batch indexing performance scaling" do
      user = build_test_user()
      
      # Test different batch sizes
      batch_sizes = [10, 50, 100, 500]
      
      results = Enum.map(batch_sizes, fn size ->
        components = generate_test_components(size)
        metadata_pairs = Enum.map(components, fn comp ->
          {comp.hash, build_test_metadata(comp)}
        end)
        
        {time, _result} = :timer.tc(fn ->
          Indexer.index_components_batch(user, metadata_pairs)
        end)
        
        %{
          batch_size: size,
          total_time: time,
          time_per_component: time / size,
          throughput: size / (time / 1_000_000)  # ops per second
        }
      end)
      
      # Verify linear or better scaling
      assert_linear_scaling(results)
      
      # Log results for monitoring
      log_performance_results("batch_indexing_scaling", results)
    end
  end

  describe "similarity calculation performance" do
    test "cached vs uncached similarity calculation" do
      component1 = generate_test_component()
      component2 = generate_test_component()
      
      Benchee.run(%{
        "uncached_similarity" => fn ->
          Pactis.Storage.SimilarityCache.calculate_similarity_original(component1, component2)
        end,
        "cached_similarity_miss" => fn ->
          Pactis.Storage.SimilarityCache.calculate_cached_similarity(component1, component2, force_refresh: true)
        end,
        "cached_similarity_hit" => fn ->
          # Pre-populate cache
          Pactis.Storage.SimilarityCache.calculate_cached_similarity(component1, component2)
          # Now test cached access
          Pactis.Storage.SimilarityCache.calculate_cached_similarity(component1, component2)
        end
      }, time: 10)
    end
  end

  # Helper functions
  defp assert_linear_scaling(results) do
    # Verify that time per component doesn't increase significantly with batch size
    times_per_component = Enum.map(results, & &1.time_per_component)
    max_time = Enum.max(times_per_component)
    min_time = Enum.min(times_per_component)
    
    # Allow up to 50% variation (should be much less with good scaling)
    assert max_time <= min_time * 1.5, "Performance doesn't scale linearly: #{inspect(times_per_component)}"
  end
end
```

### 2. Integration Performance Tests

**Purpose:** Validate performance of component interactions and workflows
**Scope:** Multi-component operations, end-to-end scenarios
**Frequency:** Every merge to main branch
**Duration:** < 15 minutes total

```elixir
# test/performance/integration/storage_workflow_test.exs
defmodule Pactis.Performance.StorageWorkflowTest do
  use ExUnit.Case, async: false
  
  import Pactis.Test.PerformanceHelpers
  
  alias Pactis.Storage.{ContentAddressable, Deduplication}
  alias Pactis.Versioning.MerkleTree

  @moduletag :integration_performance

  describe "end-to-end storage workflows" do
    test "component storage and retrieval workflow" do
      user = build_test_user()
      components = generate_test_components(100)
      
      # Measure complete workflow
      workflow_metrics = measure_workflow("complete_storage_workflow", fn ->
        # Step 1: Store components
        {store_time, store_results} = :timer.tc(fn ->
          ContentAddressable.store_components_batch(user, components)
        end)
        
        # Step 2: Build Merkle tree
        {merkle_time, {:ok, tree}} = :timer.tc(fn ->
          component_map = Enum.with_index(components) 
                        |> Enum.map(fn {comp, i} -> {"comp_#{i}", comp} end)
                        |> Enum.into(%{})
          MerkleTree.build_from_components(component_map, user: user)
        end)
        
        # Step 3: Analyze duplicates
        {dedup_time, {:ok, _duplicates}} = :timer.tc(fn ->
          Deduplication.find_duplicate_blocks(components, user)
        end)
        
        %{
          store_time: store_time,
          merkle_time: merkle_time,
          dedup_time: dedup_time,
          total_time: store_time + merkle_time + dedup_time,
          components_count: length(components)
        }
      end)
      
      # Performance assertions
      assert workflow_metrics.store_time < 5_000_000, "Storage took too long: #{workflow_metrics.store_time / 1000}ms"
      assert workflow_metrics.merkle_time < 2_000_000, "Merkle tree took too long: #{workflow_metrics.merkle_time / 1000}ms"
      assert workflow_metrics.dedup_time < 10_000_000, "Deduplication took too long: #{workflow_metrics.dedup_time / 1000}ms"
      
      # Log for trend analysis
      log_performance_results("storage_workflow", workflow_metrics)
    end

    test "concurrent user operations" do
      # Simulate multiple users operating concurrently
      users = Enum.map(1..5, fn i -> build_test_user("user_#{i}") end)
      components_per_user = 50
      
      {total_time, results} = :timer.tc(fn ->
        users
        |> Task.async_stream(fn user ->
          components = generate_test_components(components_per_user)
          ContentAddressable.store_components_batch(user, components)
        end, max_concurrency: 5, timeout: 30_000)
        |> Enum.to_list()
      end)
      
      # Verify all operations succeeded
      assert Enum.all?(results, &match?({:ok, {:ok, _}}, &1))
      
      total_components = length(users) * components_per_user
      throughput = total_components / (total_time / 1_000_000)  # components per second
      
      # Should maintain reasonable throughput under concurrent load
      assert throughput >= 20, "Concurrent throughput too low: #{throughput} ops/sec"
      
      log_performance_results("concurrent_operations", %{
        users: length(users),
        components_per_user: components_per_user,
        total_time: total_time,
        throughput: throughput
      })
    end
  end
end
```

### 3. Load Testing

**Purpose:** Validate system performance under realistic production loads
**Scope:** Full system with simulated user traffic
**Frequency:** Before major releases, weekly on main branch
**Duration:** 30-60 minutes

#### Load Testing Configuration

```yaml
# test/performance/load/storage_load_test.yml
config:
  target: 'http://localhost:4000'
  phases:
    # Warm-up phase
    - duration: 120
      arrivalRate: 5
      name: "Warm up"
    
    # Ramp-up phase
    - duration: 300
      arrivalRate: 10
      rampTo: 50
      name: "Ramp up"
      
    # Sustained load phase
    - duration: 600
      arrivalRate: 50
      name: "Sustained load"
      
    # Spike test
    - duration: 120
      arrivalRate: 100
      name: "Spike test"
      
    # Cool down
    - duration: 120
      arrivalRate: 10
      name: "Cool down"

  environments:
    staging:
      target: 'https://staging.pactis.dev'
      phases:
        - duration: 1800  # 30 minutes
          arrivalRate: 25
          name: "Staging load test"

scenarios:
  - name: "Component storage operations"
    weight: 60
    flow:
      - post:
          url: "/api/v1/storage/components"
          headers:
            Authorization: "Bearer {{ $randomToken() }}"
          json:
            components: "{{ $generateRandomComponents(10) }}"
          capture:
            - json: "$.data[*].hash"
              as: "componentHashes"
      
      - think: 2
      
      - get:
          url: "/api/v1/storage/components/{{ componentHashes[0] }}"
          headers:
            Authorization: "Bearer {{ $randomToken() }}"

  - name: "Deduplication analysis"
    weight: 20
    flow:
      - post:
          url: "/api/v1/storage/analyze-duplicates"
          headers:
            Authorization: "Bearer {{ $randomToken() }}"
          json:
            workspace_id: "{{ $randomWorkspace() }}"
            component_count: 100

  - name: "Similarity search"
    weight: 15
    flow:
      - post:
          url: "/api/v1/storage/find-similar"
          headers:
            Authorization: "Bearer {{ $randomToken() }}"
          json:
            component: "{{ $generateRandomComponent() }}"
            threshold: 0.8

  - name: "Merkle tree operations"
    weight: 5
    flow:
      - post:
          url: "/api/v1/versioning/merkle-tree"
          headers:
            Authorization: "Bearer {{ $randomToken() }}"
          json:
            components: "{{ $generateRandomComponents(50) }}"
            version: "{{ $randomVersion() }}"

# Custom JavaScript functions for data generation
functions:
  generateRandomComponents: |
    function(count) {
      const components = [];
      for (let i = 0; i < count; i++) {
        components.push({
          jsx_code: `const Component${i} = () => <div>Component ${i}</div>;`,
          styles: { [`component-${i}`]: { padding: '20px' } },
          props_schema: { title: { type: 'string', required: true } },
          dependencies: ['react'],
          framework: 'react'
        });
      }
      return components;
    }
  
  generateRandomComponent: |
    function() {
      const id = Math.floor(Math.random() * 1000);
      return {
        jsx_code: `const Component${id} = () => <div>Random Component</div>;`,
        styles: { [`component-${id}`]: { color: '#333' } },
        framework: 'react'
      };
    }
  
  randomWorkspace: |
    function() {
      const workspaces = ['ws1', 'ws2', 'ws3', 'ws4', 'ws5'];
      return workspaces[Math.floor(Math.random() * workspaces.length)];
    }
  
  randomVersion: |
    function() {
      return `${Math.floor(Math.random() * 5) + 1}.${Math.floor(Math.random() * 10)}.${Math.floor(Math.random() * 10)}`;
    }
```

#### Load Test Execution Script

```bash
#!/bin/bash
# scripts/run_load_tests.sh

set -e

echo "🚀 Starting Pactis Storage Performance Load Tests"

# Setup
export TEST_ENV=load_test
export REDIS_URL=redis://localhost:6379
export DATABASE_URL=postgresql://postgres:postgres@localhost:5432/cdfm_load_test

# Prepare test environment
echo "📋 Setting up test environment..."
mix ecto.create --quiet
mix ecto.migrate --quiet
mix run scripts/seed_load_test_data.exs

# Start application in background
echo "🌟 Starting application..."
MIX_ENV=test mix phx.server &
APP_PID=$!

# Wait for application to be ready
sleep 10

# Verify application is responding
curl -f http://localhost:4000/health || {
  echo "❌ Application failed to start properly"
  kill $APP_PID
  exit 1
}

# Run load tests
echo "⚡ Running load tests..."

# Install Artillery if not present
if ! command -v artillery &> /dev/null; then
  npm install -g artillery
fi

# Run the load test
artillery run test/performance/load/storage_load_test.yml \
  --output load_test_results.json \
  --config test/performance/load/config.json

# Generate HTML report
artillery report load_test_results.json \
  --output load_test_report.html

# Cleanup
echo "🧹 Cleaning up..."
kill $APP_PID

# Analyze results
echo "📊 Analyzing results..."
mix run scripts/analyze_load_test_results.exs load_test_results.json

echo "✅ Load tests completed. Report available at: load_test_report.html"
```

### 4. Stress Testing

**Purpose:** Determine system breaking points and behavior under extreme load
**Scope:** Full system pushed beyond normal operating parameters  
**Frequency:** Before major releases, monthly
**Duration:** 1-2 hours

```elixir
# test/performance/stress/memory_stress_test.exs
defmodule Pactis.Performance.MemoryStressTest do
  use ExUnit.Case, async: false
  
  import Pactis.Test.PerformanceHelpers
  
  @moduletag :stress_test
  @moduletag timeout: 7_200_000  # 2 hours

  describe "memory stress testing" do
    test "massive component batch processing" do
      user = build_test_user()
      
      # Start with reasonable size and progressively increase
      batch_sizes = [1000, 5000, 10000, 25000, 50000]
      
      Enum.each(batch_sizes, fn batch_size ->
        IO.puts("Testing batch size: #{batch_size}")
        
        # Monitor memory before test
        :erlang.garbage_collect()
        memory_before = :erlang.memory(:total)
        
        try do
          components = generate_large_test_components(batch_size)
          
          {time, result} = :timer.tc(fn ->
            ContentAddressable.store_components_batch(user, components, 
              max_concurrency: 20,
              timeout: 300_000  # 5 minutes
            )
          end)
          
          :erlang.garbage_collect()
          memory_after = :erlang.memory(:total)
          memory_delta = memory_after - memory_before
          
          # Log results
          log_performance_results("memory_stress_test", %{
            batch_size: batch_size,
            processing_time: time,
            memory_delta: memory_delta,
            memory_per_component: memory_delta / batch_size,
            success: match?({:ok, _}, result)
          })
          
          # Verify memory doesn't grow unbounded
          memory_per_component = memory_delta / batch_size
          assert memory_per_component < 50_000, 
            "Memory per component too high: #{memory_per_component} bytes"
          
          # Brief pause between tests
          :timer.sleep(5000)
          
        rescue
          error ->
            IO.puts("Batch size #{batch_size} failed: #{inspect(error)}")
            
            # Log failure
            log_performance_results("memory_stress_failure", %{
              batch_size: batch_size,
              error: inspect(error),
              memory_before: memory_before
            })
            
            # Stop testing larger batches if we hit memory limits
            if String.contains?(inspect(error), "memory") do
              IO.puts("Memory limit reached at batch size #{batch_size}")
              break
            end
        end
      end)
    end

    test "concurrent user stress test" do
      # Test with many concurrent users
      user_counts = [10, 25, 50, 100]
      components_per_user = 100
      
      Enum.each(user_counts, fn user_count ->
        IO.puts("Testing #{user_count} concurrent users")
        
        users = Enum.map(1..user_count, fn i -> 
          build_test_user("stress_user_#{i}")
        end)
        
        start_time = System.monotonic_time(:microsecond)
        memory_before = :erlang.memory(:total)
        
        try do
          results = users
          |> Task.async_stream(fn user ->
            components = generate_test_components(components_per_user)
            ContentAddressable.store_components_batch(user, components)
          end, 
          max_concurrency: user_count,
          timeout: 600_000,  # 10 minutes
          on_timeout: :kill_task
          )
          |> Enum.to_list()
          
          end_time = System.monotonic_time(:microsecond)
          memory_after = :erlang.memory(:total)
          
          # Analyze results
          successful = Enum.count(results, &match?({:ok, {:ok, _}}, &1))
          failed = user_count - successful
          
          total_time = end_time - start_time
          total_components = user_count * components_per_user
          throughput = total_components / (total_time / 1_000_000)
          
          log_performance_results("concurrent_stress_test", %{
            user_count: user_count,
            successful_users: successful,
            failed_users: failed,
            total_time: total_time,
            throughput: throughput,
            memory_delta: memory_after - memory_before
          })
          
          # Should handle at least 50 concurrent users
          if user_count <= 50 do
            assert successful >= user_count * 0.9, 
              "Too many failures with #{user_count} users: #{failed} failed"
          end
          
        rescue
          error ->
            IO.puts("Concurrent stress test failed with #{user_count} users: #{inspect(error)}")
            
            if user_count <= 25 do
              # Should handle at least 25 users without crashing
              flunk("System crashed with only #{user_count} users: #{inspect(error)}")
            end
        end
      end)
    end
  end
end
```

## Benchmarking Strategy

### 1. Micro-benchmarks

```elixir
# benchmarks/indexing_benchmark.exs
defmodule Pactis.Benchmarks.IndexingBenchmark do
  @moduledoc """
  Detailed benchmarks for indexing operations.
  Run with: mix run benchmarks/indexing_benchmark.exs
  """

  import Pactis.Test.PerformanceHelpers
  
  alias Pactis.Storage.ContentAddressable.Indexer

  def run do
    user = build_test_user()
    component = generate_test_component()
    metadata = build_test_metadata(component)
    
    IO.puts("🔧 Running Indexing Benchmarks")
    IO.puts("=" |> String.duplicate(50))
    
    Benchee.run(
      %{
        "sequential_redis_ops" => fn ->
          Indexer.index_component_original(user, component.hash, metadata)
        end,
        "pipelined_redis_ops" => fn ->
          Indexer.index_component_optimized(user, component.hash, metadata)
        end
      },
      time: 10,
      memory_time: 2,
      formatters: [
        Benchee.Formatters.Console,
        {Benchee.Formatters.HTML, file: "benchmark_results/indexing.html"},
        {Benchee.Formatters.JSON, file: "benchmark_results/indexing.json"}
      ]
    )
    
    # Batch operations benchmark
    IO.puts("\n🔧 Batch Operations Benchmark")
    
    batch_sizes = [10, 50, 100, 500]
    
    batch_benchmarks = batch_sizes
    |> Enum.map(fn size ->
      components = generate_test_components(size)
      metadata_pairs = Enum.map(components, fn comp ->
        {comp.hash, build_test_metadata(comp)}
      end)
      
      {
        "batch_#{size}",
        fn -> Indexer.index_components_batch(user, metadata_pairs) end
      }
    end)
    |> Enum.into(%{})
    
    Benchee.run(
      batch_benchmarks,
      time: 5,
      formatters: [
        Benchee.Formatters.Console,
        {Benchee.Formatters.HTML, file: "benchmark_results/batch_indexing.html"}
      ]
    )
  end
end

# Auto-run when file is executed directly
if __ENV__.file == Path.absname(__FILE__) do
  Pactis.Benchmarks.IndexingBenchmark.run()
end
```

### 2. Comparative Benchmarks

```elixir
# benchmarks/before_after_benchmark.exs
defmodule Pactis.Benchmarks.BeforeAfterBenchmark do
  @moduledoc """
  Benchmark comparing performance before and after optimizations.
  """

  import Pactis.Test.PerformanceHelpers

  def run_comparison do
    scenarios = [
      {
        "Single Component Storage",
        &benchmark_single_component_storage/0
      },
      {
        "Batch Component Storage", 
        &benchmark_batch_storage/0
      },
      {
        "Similarity Calculation",
        &benchmark_similarity_calculation/0
      },
      {
        "Merkle Tree Construction",
        &benchmark_merkle_tree/0
      }
    ]
    
    results = Enum.map(scenarios, fn {name, benchmark_fn} ->
      IO.puts("🔍 Running #{name} benchmark...")
      result = benchmark_fn.()
      IO.puts("✅ Completed #{name}")
      {name, result}
    end)
    
    # Generate comparison report
    generate_comparison_report(results)
  end

  defp benchmark_single_component_storage do
    user = build_test_user()
    component = generate_test_component()
    
    Benchee.run(
      %{
        "before_optimization" => fn ->
          # Simulate original implementation
          Pactis.Storage.OriginalImplementation.store_component(user, component)
        end,
        "after_optimization" => fn ->
          Pactis.Storage.ContentAddressable.store_component(user, component)
        end
      },
      time: 10,
      print: [fast_warning: false],
      formatters: []
    )
  end

  defp generate_comparison_report(results) do
    report_content = """
    # Performance Optimization Results Report
    
    Generated: #{DateTime.utc_now() |> DateTime.to_string()}
    
    ## Summary
    
    #{generate_summary_table(results)}
    
    ## Detailed Results
    
    #{generate_detailed_results(results)}
    
    ## Recommendations
    
    #{generate_recommendations(results)}
    """
    
    File.write!("performance_optimization_report.md", report_content)
    IO.puts("📊 Comparison report generated: performance_optimization_report.md")
  end
end
```

## Test Data Management

### 1. Test Data Generation

```elixir
# lib/pactis/test/data_factory.ex
defmodule Pactis.Test.DataFactory do
  @moduledoc """
  Factory for generating realistic test data for performance testing.
  """

  @frameworks [:react, :vue, :angular, :svelte]
  @component_templates [
    "button", "input", "modal", "card", "navigation", 
    "form", "table", "chart", "sidebar", "header"
  ]

  def generate_realistic_components(count, opts \\ []) do
    framework_distribution = Keyword.get(opts, :framework_distribution, %{
      react: 0.6,
      vue: 0.2, 
      angular: 0.15,
      svelte: 0.05
    })
    
    size_distribution = Keyword.get(opts, :size_distribution, %{
      small: 0.4,    # < 1KB
      medium: 0.4,   # 1KB - 10KB
      large: 0.15,   # 10KB - 50KB
      xlarge: 0.05   # > 50KB
    })
    
    1..count
    |> Enum.map(fn i ->
      framework = select_by_distribution(framework_distribution)
      size_category = select_by_distribution(size_distribution)
      template = Enum.random(@component_templates)
      
      generate_component_by_specs(i, framework, size_category, template)
    end)
  end

  def generate_component_variations(base_component, variation_count) do
    # Generate components with small variations for testing similarity detection
    1..variation_count
    |> Enum.map(fn i ->
      variation_type = Enum.random([:style_change, :prop_addition, :minor_code_change])
      apply_variation(base_component, variation_type, i)
    end)
  end

  def generate_duplicate_heavy_dataset(component_count, duplication_ratio) do
    # Generate dataset with controlled duplication for testing dedup effectiveness
    unique_count = round(component_count * (1 - duplication_ratio))
    duplicate_count = component_count - unique_count
    
    # Generate unique components
    unique_components = generate_realistic_components(unique_count)
    
    # Create duplicates by randomly selecting and slightly modifying existing components
    duplicate_components = 1..duplicate_count
    |> Enum.map(fn _ ->
      base = Enum.random(unique_components)
      # Apply minimal variation to create near-duplicates
      apply_variation(base, :minimal_change, :rand.uniform(100))
    end)
    
    Enum.shuffle(unique_components ++ duplicate_components)
  end

  # Private implementation functions...
  defp generate_component_by_specs(id, framework, size_category, template) do
    jsx_code = generate_jsx_code(framework, template, size_category, id)
    styles = generate_styles(template, size_category, id)
    props_schema = generate_props_schema(template, framework)
    dependencies = generate_dependencies(framework, template)
    
    %{
      id: "component_#{id}",
      jsx_code: jsx_code,
      styles: styles,
      props_schema: props_schema,
      dependencies: dependencies,
      framework: framework,
      template: template,
      size_category: size_category
    }
  end

  defp generate_jsx_code(framework, template, size_category, id) do
    base_code = get_template_code(framework, template)
    
    case size_category do
      :small -> base_code
      :medium -> add_medium_complexity(base_code, id)
      :large -> add_large_complexity(base_code, id)
      :xlarge -> add_xlarge_complexity(base_code, id)
    end
  end
end
```

### 2. Test Environment Management

```bash
#!/bin/bash
# scripts/setup_performance_test_env.sh

set -e

echo "🔧 Setting up Performance Test Environment"

# Environment variables
export MIX_ENV=test
export PERFORMANCE_TEST_DB=cdfm_performance_test
export REDIS_DB=15  # Use separate Redis DB for tests

# Database setup
echo "📊 Setting up test database..."
dropdb --if-exists $PERFORMANCE_TEST_DB
createdb $PERFORMANCE_TEST_DB
mix ecto.migrate

# Redis setup
echo "🗄️  Setting up Redis test environment..."
redis-cli -n $REDIS_DB FLUSHDB

# Generate test data
echo "🏭 Generating test data..."
mix run scripts/generate_performance_test_data.exs

# Verify setup
echo "✅ Verifying test environment..."
mix run scripts/verify_test_environment.exs

echo "🎉 Performance test environment ready!"
echo "Database: $PERFORMANCE_TEST_DB"
echo "Redis DB: $REDIS_DB"
echo "Test data generated: $(redis-cli -n $REDIS_DB DBSIZE) keys"
```

## Continuous Performance Testing

### 1. CI/CD Integration

```yaml
# .github/workflows/performance-tests.yml
name: Performance Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]
  schedule:
    # Run comprehensive performance tests nightly
    - cron: '0 2 * * *'

jobs:
  unit-performance:
    runs-on: ubuntu-latest
    strategy:
      matrix: