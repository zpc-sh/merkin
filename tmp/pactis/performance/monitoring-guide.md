# Pactis Storage System Performance Monitoring Guide

**Document Version:** 1.0
**Date:** December 2024
**Target Audience:** DevOps, SRE, Engineering Teams
**Prerequisites:** Elixir telemetry, Prometheus/Grafana, Application monitoring experience

## Overview

This guide provides comprehensive monitoring and alerting strategies for the Pactis Storage System performance optimizations. It covers telemetry implementation, dashboard setup, alert configuration, and troubleshooting procedures to ensure optimal system performance and quick issue resolution.

## Monitoring Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  Pactis Application                       │
│  ┌─────────────────┐    ┌─────────────────┐            │
│  │   Telemetry     │    │   Custom        │            │
│  │   Events        │    │   Metrics       │            │
│  └─────────────────┘    └─────────────────┘            │
└─────────────┬───────────────────┬───────────────────────┘
              │                   │
              ▼                   ▼
┌─────────────────┐    ┌─────────────────┐
│   Prometheus    │    │   Application   │
│   Metrics       │    │   Logs          │
└─────────────────┘    └─────────────────┘
              │                   │
              ▼                   ▼
┌─────────────────────────────────────────────────────────┐
│              Grafana Dashboards                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │Performance  │  │ System      │  │ Business    │    │
│  │Metrics      │  │ Health      │  │ KPIs        │    │
│  └─────────────┘  └─────────────┘  └─────────────┘    │
└─────────────────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────┐
│            Alerting (PagerDuty/Slack)                  │
└─────────────────────────────────────────────────────────┘
```

## Telemetry Implementation

### 1. Core Telemetry Setup

```elixir
# lib/pactis/telemetry.ex
defmodule Pactis.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      {:telemetry_poller, measurements: periodic_measurements(), period: :timer.seconds(10)},
      {TelemetryMetricsPrometheus, metrics: metrics()},
      {Pactis.Telemetry.StorageMetrics, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # Storage Performance Metrics
      last_value("pactis.storage.components.count",
        description: "Number of components stored",
        tags: [:workspace_id, :framework]
      ),

      summary("pactis.storage.indexing.duration",
        description: "Component indexing duration",
        tags: [:optimization_enabled, :workspace_id],
        unit: {:native, :microsecond}
      ),

      summary("pactis.storage.similarity.duration",
        description: "Similarity calculation duration",
        tags: [:cache_hit, :workspace_id],
        unit: {:native, :microsecond}
      ),

      summary("pactis.storage.merkle.build_duration",
        description: "Merkle tree construction duration",
        tags: [:component_count_bucket, :workspace_id],
        unit: {:native, :microsecond}
      ),

      summary("pactis.storage.deduplication.duration",
        description: "Block deduplication analysis duration",
        tags: [:component_count_bucket, :workspace_id],
        unit: {:native, :microsecond}
      ),

      # Memory Usage Metrics
      last_value("pactis.storage.memory.usage",
        description: "Storage operations memory usage",
        tags: [:operation_type, :workspace_id],
        unit: :byte
      ),

      # Cache Performance Metrics
      counter("pactis.cache.operations.total",
        description: "Cache operations count",
        tags: [:operation, :result, :cache_type]
      ),

      summary("pactis.cache.operation.duration",
        description: "Cache operation duration",
        tags: [:operation, :cache_type],
        unit: {:native, :microsecond}
      ),

      last_value("pactis.cache.hit_rate",
        description: "Cache hit rate percentage",
        tags: [:cache_type]
      ),

      # External API Metrics
      summary("pactis.folder_api.request.duration",
        description: "Folder API request duration",
        tags: [:operation, :result],
        unit: {:native, :microsecond}
      ),

      counter("pactis.folder_api.requests.total",
        description: "Folder API requests count",
        tags: [:operation, :result]
      ),

      # Business Metrics
      counter("pactis.storage.optimization.savings",
        description: "Storage savings from optimizations",
        tags: [:optimization_type, :workspace_id],
        unit: :byte
      ),

      counter("pactis.storage.conflicts.resolved",
        description: "Number of conflicts resolved",
        tags: [:resolution_strategy, :workspace_id]
      ),

      # Error Metrics
      counter("pactis.storage.errors.total",
        description: "Storage operation errors",
        tags: [:operation, :error_type, :workspace_id]
      ),

      # System Resource Metrics
      last_value("vm.memory.total", unit: :byte),
      last_value("vm.system_counts.process_count"),
      last_value("vm.system_counts.port_count"),

      # Database Metrics
      summary("pactis.repo.query.total_time",
        description: "Database query duration",
        tags: [:source],
        unit: {:native, :microsecond}
      )
    ]
  end

  defp periodic_measurements do
    [
      {Pactis.Telemetry.StorageMetrics, :dispatch_storage_metrics, []},
      {Pactis.Telemetry.CacheMetrics, :dispatch_cache_metrics, []},
      {:erlang, :memory, []},
      {:erlang, :system_info, [:process_count, :port_count]}
    ]
  end
end
```

### 2. Storage-Specific Metrics Collection

```elixir
# lib/pactis/telemetry/storage_metrics.ex
defmodule Pactis.Telemetry.StorageMetrics do
  use GenServer
  require Logger

  alias Pactis.Storage.ContentAddressable.Indexer
  alias Pactis.Cache

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    # Attach telemetry handlers
    events = [
      [:pactis, :storage, :indexing, :start],
      [:pactis, :storage, :indexing, :stop],
      [:pactis, :storage, :similarity, :start],
      [:pactis, :storage, :similarity, :stop],
      [:pactis, :storage, :merkle, :start],
      [:pactis, :storage, :merkle, :stop],
      [:pactis, :storage, :deduplication, :start],
      [:pactis, :storage, :deduplication, :stop],
      [:pactis, :folder_api, :request, :start],
      [:pactis, :folder_api, :request, :stop]
    ]

    :telemetry.attach_many("pactis-storage-metrics", events, &handle_event/4, nil)

    {:ok, %{}}
  end

  # Telemetry event handlers
  def handle_event([:pactis, :storage, operation, :stop], measurements, metadata, _config) do
    duration = measurements.duration
    optimization_enabled = Map.get(metadata, :optimization_enabled, false)
    workspace_id = Map.get(metadata, :workspace_id, "unknown")

    :telemetry.execute(
      [:pactis, :storage, operation, :duration],
      %{duration: duration},
      %{optimization_enabled: optimization_enabled, workspace_id: workspace_id}
    )
  end

  def handle_event([:pactis, :folder_api, :request, :stop], measurements, metadata, _config) do
    duration = measurements.duration

    operation = Map.get(metadata, :operation, "unknown")
    result = Map.get(metadata, :result, "unknown")

    :telemetry.execute(
      [:pactis, :folder_api, :request, :duration],
      %{duration: duration},
      %{operation: operation, result: result}
    )
  end

  # Periodic metrics collection
  def dispatch_storage_metrics do
    # Collect workspace statistics
    workspaces = get_active_workspaces()
    
    Enum.each(workspaces, fn workspace_id ->
      case Indexer.get_workspace_stats(workspace_id) do
        {:ok, stats} ->
          :telemetry.execute(
            [:pactis, :storage, :components, :count],
            %{count: stats.total_components},
            %{workspace_id: workspace_id}
          )

          :telemetry.execute(
            [:pactis, :storage, :optimization, :savings],
            %{savings: stats.storage_savings_bytes || 0},
            %{optimization_type: "deduplication", workspace_id: workspace_id}
          )

        _ ->
          :ok
      end
    end)
  end

  defp get_active_workspaces do
    # Get list of active workspaces from your application
    # This is a placeholder implementation
    ["workspace_1", "workspace_2", "workspace_3"]
  end
end
```

### 3. Performance Instrumentation Helpers

```elixir
# lib/pactis/telemetry/performance.ex
defmodule Pactis.Telemetry.Performance do
  @moduledoc """
  Helpers for instrumenting performance-critical code paths.
  """

  @doc """
  Instrument a function with telemetry events and memory tracking.
  """
  defmacro instrument(event_name, metadata \\ %{}, do: block) do
    quote do
      metadata = Map.merge(unquote(metadata), %{
        optimization_enabled: Pactis.Storage.FeatureFlags.optimization_enabled?()
      })

      start_memory = :erlang.memory(:total)
      
      result = :telemetry.span(
        [:pactis, :storage, unquote(event_name)],
        metadata,
        fn -> 
          {unquote(block), metadata}
        end
      )

      end_memory = :erlang.memory(:total)
      memory_delta = end_memory - start_memory

      if memory_delta > 0 do
        :telemetry.execute(
          [:pactis, :storage, :memory, :usage],
          %{memory_delta: memory_delta},
          Map.merge(metadata, %{operation_type: unquote(event_name)})
        )
      end

      result
    end
  end

  @doc """
  Track cache operations with hit/miss rates.
  """
  def track_cache_operation(cache_type, operation, fun) do
    start_time = System.monotonic_time(:microsecond)
    
    result = fun.()
    
    duration = System.monotonic_time(:microsecond) - start_time
    cache_result = case result do
      {:ok, nil} -> "miss"
      {:ok, _} -> "hit"
      _ -> "error"
    end

    :telemetry.execute(
      [:pactis, :cache, :operation, :duration],
      %{duration: duration},
      %{operation: operation, cache_type: cache_type}
    )

    :telemetry.execute(
      [:pactis, :cache, :operations, :total],
      %{count: 1},
      %{operation: operation, result: cache_result, cache_type: cache_type}
    )

    result
  end
end
```

## Key Performance Indicators (KPIs)

### 1. Primary Performance Metrics

| Metric | Target | Critical Threshold | Description |
|--------|--------|-------------------|-------------|
| Component Indexing P95 | < 10ms | > 50ms | Time to index a single component |
| Batch Storage Throughput | > 100 ops/sec | < 20 ops/sec | Components stored per second |
| Similarity Search P95 | < 100ms | > 500ms | Time to find similar components |
| Memory Usage Peak | < 500MB | > 1GB | Peak memory during large operations |
| Cache Hit Rate | > 85% | < 70% | Percentage of cache hits |
| Error Rate | < 0.1% | > 1% | Percentage of failed operations |

### 2. Business Impact Metrics

| Metric | Target | Critical Threshold | Description |
|--------|--------|-------------------|-------------|
| Storage Savings Ratio | > 30% | < 10% | Percentage of storage saved by deduplication |
| User Perceived Latency | < 200ms | > 1000ms | End-to-end operation time |
| System Availability | > 99.9% | < 99% | Uptime percentage |
| Cost per Operation | < $0.001 | > $0.01 | Infrastructure cost per storage operation |

## Dashboard Configuration

### 1. Performance Overview Dashboard

```json
{
  "dashboard": {
    "title": "Pactis Storage Performance",
    "panels": [
      {
        "title": "Operation Latencies",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(cdfm_storage_indexing_duration_seconds_bucket[5m]))",
            "legendFormat": "Indexing P95"
          },
          {
            "expr": "histogram_quantile(0.95, rate(cdfm_storage_similarity_duration_seconds_bucket[5m]))",
            "legendFormat": "Similarity P95"
          }
        ]
      },
      {
        "title": "Throughput",
        "type": "graph", 
        "targets": [
          {
            "expr": "rate(cdfm_storage_components_total[1m])",
            "legendFormat": "Components/sec"
          }
        ]
      },
      {
        "title": "Memory Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "cdfm_storage_memory_usage_bytes",
            "legendFormat": "Storage Memory"
          }
        ]
      },
      {
        "title": "Cache Performance",
        "type": "stat",
        "targets": [
          {
            "expr": "rate(cdfm_cache_operations_total{result=\"hit\"}[5m]) / rate(cdfm_cache_operations_total[5m]) * 100",
            "legendFormat": "Hit Rate %"
          }
        ]
      }
    ]
  }
}
```

### 2. System Health Dashboard

```json
{
  "dashboard": {
    "title": "Pactis Storage System Health",
    "panels": [
      {
        "title": "Error Rates",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(cdfm_storage_errors_total[5m])",
            "legendFormat": "Errors/sec - {{error_type}}"
          }
        ]
      },
      {
        "title": "Folder API Health",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(cdfm_folder_api_request_duration_seconds_bucket[5m]))",
            "legendFormat": "API Latency P95"
          },
          {
            "expr": "rate(cdfm_folder_api_requests_total{result!=\"success\"}[5m])",
            "legendFormat": "API Errors/sec"
          }
        ]
      },
      {
        "title": "Resource Utilization",
        "type": "graph",
        "targets": [
          {
            "expr": "vm_memory_total_bytes",
            "legendFormat": "Total Memory"
          },
          {
            "expr": "vm_system_counts_process_count",
            "legendFormat": "Process Count"
          }
        ]
      }
    ]
  }
}
```

## Alerting Rules

### 1. Critical Alerts

```yaml
# alerts/storage_critical.yml
groups:
  - name: cdfm_storage_critical
    rules:
      - alert: StorageIndexingLatencyHigh
        expr: histogram_quantile(0.95, rate(cdfm_storage_indexing_duration_seconds_bucket[5m])) > 0.05
        for: 2m
        labels:
          severity: critical
          team: storage
        annotations:
          summary: "Storage indexing latency is critically high"
          description: "95th percentile indexing latency is {{ $value }}s, above 50ms threshold"
          runbook_url: "https://docs.pactis.dev/runbooks/storage-latency"

      - alert: StorageBatchThroughputLow
        expr: rate(cdfm_storage_components_total[1m]) < 20
        for: 5m
        labels:
          severity: critical
          team: storage
        annotations:
          summary: "Storage batch throughput critically low"
          description: "Current throughput is {{ $value }} ops/sec, below 20 ops/sec threshold"

      - alert: StorageErrorRateHigh
        expr: rate(cdfm_storage_errors_total[5m]) / rate(cdfm_storage_operations_total[5m]) > 0.01
        for: 1m
        labels:
          severity: critical
          team: storage
        annotations:
          summary: "Storage error rate is critically high"
          description: "Error rate is {{ $value | humanizePercentage }}, above 1% threshold"

      - alert: FolderAPIDown
        expr: up{job="folder_api"} == 0
        for: 30s
        labels:
          severity: critical
          team: storage
        annotations:
          summary: "Folder API is down"
          description: "Folder API service is unreachable"
```

### 2. Warning Alerts

```yaml
# alerts/storage_warnings.yml
groups:
  - name: cdfm_storage_warnings
    rules:
      - alert: CacheHitRateLow
        expr: rate(cdfm_cache_operations_total{result="hit"}[5m]) / rate(cdfm_cache_operations_total[5m]) < 0.7
        for: 10m
        labels:
          severity: warning
          team: storage
        annotations:
          summary: "Cache hit rate is low"
          description: "Cache hit rate is {{ $value | humanizePercentage }}, below 70% threshold"

      - alert: MemoryUsageHigh
        expr: cdfm_storage_memory_usage_bytes > 500000000  # 500MB
        for: 5m
        labels:
          severity: warning
          team: storage
        annotations:
          summary: "Storage memory usage is high"
          description: "Memory usage is {{ $value | humanizeBytes }}, above 500MB threshold"

      - alert: SimilaritySearchSlow
        expr: histogram_quantile(0.95, rate(cdfm_storage_similarity_duration_seconds_bucket[5m])) > 0.5
        for: 5m
        labels:
          severity: warning
          team: storage
        annotations:
          summary: "Similarity search is slow"
          description: "95th percentile similarity search time is {{ $value }}s"
```

## Performance Regression Detection

### 1. Automated Regression Testing

```elixir
# test/performance/regression_test.exs
defmodule Pactis.Performance.RegressionTest do
  use ExUnit.Case, async: false
  
  import Pactis.Test.PerformanceHelpers

  @moduletag :regression

  setup do
    # Load baseline metrics
    indexing_baseline = read_baseline("baseline_indexing.txt")
    merkle_baseline = read_baseline("baseline_merkle.txt")
    
    {:ok, %{indexing_baseline: indexing_baseline, merkle_baseline: merkle_baseline}}
  end

  test "indexing performance regression", %{indexing_baseline: baseline} do
    components = generate_test_components(100)
    user = build_test_user()
    
    {time, _} = :timer.tc(fn ->
      Enum.each(components, fn component ->
        {:ok, hash} = ContentAddressable.compute_content_hash(component)
        metadata = build_test_metadata(component, hash)
        Indexer.index_component(user, hash, metadata)
      end)
    end)
    
    avg_time = time / length(components) / 1000  # Convert to ms
    
    # Alert if performance degraded by more than 20%
    regression_threshold = baseline * 1.2
    
    if avg_time > regression_threshold do
      Logger.error("Performance regression detected! Current: #{avg_time}ms, Baseline: #{baseline}ms")
      
      # Send alert to monitoring system
      send_performance_alert(:indexing_regression, %{
        current: avg_time,
        baseline: baseline,
        degradation_percent: (avg_time - baseline) / baseline * 100
      })
      
      flunk("Indexing performance regressed by #{((avg_time - baseline) / baseline * 100) |> Float.round(1)}%")
    end
  end

  test "memory usage regression" do
    components = generate_large_test_components(50)
    user = build_test_user()
    
    :erlang.garbage_collect()
    memory_before = :erlang.memory(:total)
    
    {:ok, _} = Deduplication.find_duplicate_blocks(components, user)
    
    :erlang.garbage_collect()
    memory_after = :erlang.memory(:total)
    
    memory_delta = memory_after - memory_before
    max_allowed_memory = 100_000_000  # 100MB
    
    if memory_delta > max_allowed_memory do
      Logger.error("Memory usage regression! Used: #{memory_delta} bytes")
      
      send_performance_alert(:memory_regression, %{
        memory_used: memory_delta,
        max_allowed: max_allowed_memory
      })
      
      flunk("Memory usage exceeded threshold: #{memory_delta} bytes")
    end
  end

  defp read_baseline(filename) do
    case File.read(filename) do
      {:ok, content} -> String.to_float(String.trim(content))
      _ -> 0.0  # Default if baseline doesn't exist
    end
  end

  defp send_performance_alert(type, data) do
    # Integration with your alerting system
    Phoenix.PubSub.broadcast(Pactis.PubSub, "performance:alerts", {type, data})
  end
end
```

### 2. Continuous Performance Monitoring

```elixir
# lib/pactis/performance/monitor.ex
defmodule Pactis.Performance.Monitor do
  use GenServer
  require Logger

  @check_interval :timer.minutes(5)
  @performance_thresholds %{
    indexing_p95: 10_000,      # 10ms in microseconds
    similarity_p95: 100_000,   # 100ms in microseconds  
    memory_peak: 500_000_000,  # 500MB in bytes
    cache_hit_rate: 0.85       # 85%
  }

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    schedule_check()
    {:ok, %{last_metrics: %{}}}
  end

  def handle_info(:check_performance, state) do
    current_metrics = collect_current_metrics()
    
    # Check for regressions
    regressions = detect_regressions(current_metrics, state.last_metrics)
    
    # Send alerts for any regressions found
    Enum.each(regressions, &send_regression_alert/1)
    
    schedule_check()
    {:noreply, %{state | last_metrics: current_metrics}}
  end

  defp collect_current_metrics do
    %{
      indexing_p95: get_prometheus_metric("cdfm_storage_indexing_duration_seconds", 0.95),
      similarity_p95: get_prometheus_metric("cdfm_storage_similarity_duration_seconds", 0.95),
      memory_peak: get_prometheus_metric("cdfm_storage_memory_usage_bytes"),
      cache_hit_rate: calculate_cache_hit_rate(),
      timestamp: DateTime.utc_now()
    }
  end

  defp detect_regressions(current, previous) do
    regressions = []
    
    # Check each metric against threshold and trend
    regressions = check_metric_regression(current, previous, :indexing_p95, @performance_thresholds.indexing_p95, regressions)
    regressions = check_metric_regression(current, previous, :similarity_p95, @performance_thresholds.similarity_p95, regressions)
    regressions = check_metric_regression(current, previous, :memory_peak, @performance_thresholds.memory_peak, regressions)
    
    # Cache hit rate regression (lower is worse)
    if current.cache_hit_rate < @performance_thresholds.cache_hit_rate do
      [{:cache_hit_rate_low, current.cache_hit_rate, @performance_thresholds.cache_hit_rate} | regressions]
    else
      regressions
    end
  end

  defp check_metric_regression(current, previous, metric, threshold, regressions) do
    current_value = Map.get(current, metric, 0)
    previous_value = Map.get(previous, metric, 0)
    
    cond do
      current_value > threshold ->
        [{:threshold_exceeded, metric, current_value, threshold} | regressions]
      
      previous_value > 0 and current_value > previous_value * 1.2 ->
        [{:trend_regression, metric, current_value, previous_value} | regressions]
      
      true ->
        regressions
    end
  end

  defp schedule_check do
    Process.send_after(self(), :check_performance, @check_interval)
  end
end
```

## Troubleshooting Guide

### 1. High Latency Issues

**Symptoms:**
- Component indexing > 50ms P95
- Similarity search > 500ms P95
- User complaints about slow performance

**Investigation Steps:**
1. Check Redis pipeline optimization status:
   ```bash
   # Check if pipelining is enabled
   curl -s "http://localhost:9090/api/v1/query?query=cdfm_storage_indexing_duration_seconds{optimization_enabled=\"true\"}"
   ```

2. Verify cache hit rates:
   ```bash
   # Check cache performance
   curl -s "http://localhost:9090/api/v1/query?query=rate(cdfm_cache_operations_total{result=\"hit\"}[5m])/rate(cdfm_cache_operations_total[5m])"
   ```

3. Monitor external API latency:
   ```bash
   # Check folder_api response times
   curl -s "http://localhost:9090/api/v1/query?query=histogram_quantile(0.95,rate(cdfm_folder_api_request_duration_seconds_bucket[5m]))"
   ```

**Resolution Actions:**
- Enable Redis pipelining if disabled
- Increase cache TTL for stable data
- Scale up folder_api connections
- Check network latency to external services

### 2. Memory Issues

**Symptoms:**
- Memory usage > 1GB during operations
- Out of memory errors
- Frequent garbage collection

**Investigation Steps:**
1. Identify memory-intensive operations:
   ```elixir
   # In IEx, monitor memory usage
   :observer.start()
   
   # Check current memory by type
   :erlang.memory()
   ```

2. Check for memory leaks in specific operations:
   ```bash
   # Memory usage trends
   curl -s "http://localhost:9090/api/v1/query?query=cdfm_storage_memory_usage_bytes"
   ```

**Resolution Actions:**
- Enable streaming processing for large datasets
- Implement batch size limits
- Add memory circuit breakers
- Tune garbage collection parameters

### 3. Cache Performance Issues

**Symptoms:**
- Cache hit rate < 70%
- Frequent cache misses for similar queries
- High cache operation latency

**Investigation Steps:**
1. Analyze cache key distribution:
   ```elixir
   # Check cache key patterns
   {:ok, keys} = Redix.command(Pactis.Cache.get_conn(), ["KEYS", "similarity:*"])
   length(keys)
   ```

2. Monitor cache eviction rates:
   ```bash
   # Redis INFO command
   redis-cli INFO stats | grep evicted
   ```

**Resolution Actions:**
- Optimize cache key generation
- Increase cache memory allocation
- Implement cache warming strategies
- Review TTL settings

## Performance Testing in CI/CD

### 1. Automated Performance Tests

```yaml
# .github/workflows/performance.yml
name: Performance Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  performance:
    runs-on: ubuntu-latest
    
    services:
      redis:
        image: redis:7-alpine
        ports:
          - 6379:6379
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        ports:
          - 5432:5432

    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Elixir
        uses: erlef/setup-beam@v1
        with:
          elixir-version: '1.15'
          otp-version: '26'
          
      - name: Install dependencies
        run: mix deps.get
        
      - name: Setup database
        run: |
          mix ecto.create
          mix ecto.migrate
          
      - name: Run baseline performance tests
        run: mix test test/performance/baseline_test.exs --include performance
        
      - name: Run performance regression tests
        run: mix test test/performance/regression_test.exs --include regression
        
      - name: Generate performance report
        run: |
          mix run scripts/generate_performance_report.exs
          
      - name: Upload performance artifacts
        uses: actions/upload-artifact@v3
        with:
          name: performance-report
          path: performance_report.html
```

### 2. Load Testing Integration

```yaml
# load_testing/artillery_config.yml
config:
  target: 'http://localhost:4000'
  phases:
    - duration