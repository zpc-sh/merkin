# Pactis Storage System Performance Optimization Rollback Procedures

**Document Version:** 1.0  
**Date:** December 2024  
**Owner:** Engineering Team  
**Emergency Contact:** DevOps Team  
**Last Updated:** December 2024

## Overview

This document provides comprehensive rollback procedures for Pactis Storage System performance optimizations. It includes decision criteria for when to rollback, step-by-step procedures, monitoring guidelines, and recovery verification processes.

## Rollback Decision Matrix

### Critical Rollback Triggers

**Immediate Rollback Required:**
- Error rate > 5% for any storage operation
- System-wide availability < 95%
- Data corruption or consistency issues detected
- Complete system failure or crash loops
- Memory usage > 2GB sustained for > 5 minutes
- Response time > 10x baseline for > 2 minutes

**Consider Rollback:**
- Error rate 1-5% sustained for > 10 minutes
- Performance degradation > 50% from baseline
- User complaints about system slowness
- Monitoring alerts firing continuously
- Resource utilization > 90% sustained

**Monitor but Continue:**
- Minor performance variations < 20%
- Isolated errors affecting < 0.1% of requests
- Temporary resource spikes < 2 minutes
- Non-critical feature issues

## Pre-Rollback Checklist

### 1. Immediate Assessment (2 minutes)

- [ ] **Verify the Issue**
  ```bash
  # Check system health
  curl -f https://api.pactis.dev/health
  
  # Check error rates
  curl -s "http://prometheus:9090/api/v1/query?query=rate(cdfm_storage_errors_total[5m])"
  
  # Check response times
  curl -s "http://prometheus:9090/api/v1/query?query=histogram_quantile(0.95,rate(cdfm_storage_duration_seconds_bucket[5m]))"
  ```

- [ ] **Identify Affected Features**
  - Component storage operations
  - Similarity search
  - Merkle tree operations
  - Deduplication analysis
  - User-facing features

- [ ] **Check Recent Deployments**
  ```bash
  # Check recent deployments
  kubectl get deployments -o wide
  kubectl describe deployment pactis-app
  ```

### 2. Communication (2 minutes)

- [ ] **Alert Stakeholders**
  - Post in #incidents Slack channel
  - Notify product team if user-facing
  - Update status page if external impact
  - Assign incident commander

- [ ] **Document Incident**
  - Create incident ticket
  - Record start time and symptoms
  - Note affected users/workspaces
  - Track rollback decision rationale

## Rollback Procedures by Feature

### 1. Redis Pipelining Rollback

**Impact:** Reverts to sequential Redis operations  
**Expected Downtime:** 30 seconds  
**Risk Level:** Low

#### Step 1: Disable Feature Flag (30 seconds)
```bash
# Connect to production environment
kubectl exec -it deployment/pactis-app -- iex -S mix

# Disable Redis pipelining globally
iex> Application.put_env(:pactis, :redis_pipelining_workspaces, [])
iex> :ok

# Or disable for specific workspace only
iex> current_workspaces = Application.get_env(:pactis, :redis_pipelining_workspaces, [])
iex> updated_workspaces = List.delete(current_workspaces, "problematic_workspace_id")
iex> Application.put_env(:pactis, :redis_pipelining_workspaces, updated_workspaces)
```

#### Step 2: Force Configuration Reload
```bash
# Trigger configuration reload without restart
kubectl exec -it deployment/pactis-app -- iex -S mix -e "Pactis.Storage.FeatureFlags.reload_config()"
```

#### Step 3: Verify Rollback
```bash
# Test indexing operation
curl -X POST https://api.pactis.dev/api/v1/storage/test-indexing \
  -H "Authorization: Bearer $TEST_TOKEN" \
  -d '{"test": true}'

# Check metrics show sequential operations
curl -s "http://prometheus:9090/api/v1/query?query=cdfm_storage_indexing_duration_seconds{optimization_enabled=\"false\"}"
```

### 2. Similarity Caching Rollback

**Impact:** Reverts to uncached similarity calculations  
**Expected Downtime:** None (graceful degradation)  
**Risk Level:** Very Low

#### Step 1: Disable Caching (immediate)
```bash
# Set environment variable to disable caching
kubectl set env deployment/pactis-app SIMILARITY_CACHING_ENABLED=false

# Or disable via runtime configuration
kubectl exec -it deployment/pactis-app -- iex -S mix
iex> Application.put_env(:pactis, :similarity_caching_enabled, false)
```

#### Step 2: Clear Existing Cache (optional)
```bash
# Clear similarity cache if needed
kubectl exec -it deployment/pactis-app -- iex -S mix
iex> Pactis.Cache.del_pattern("similarity:*")
```

#### Step 3: Monitor Performance Impact
```bash
# Watch for increased similarity calculation times
kubectl logs -f deployment/pactis-app | grep "similarity_calculation"

# Monitor response times
watch "curl -s 'http://prometheus:9090/api/v1/query?query=histogram_quantile(0.95,rate(cdfm_storage_similarity_duration_seconds_bucket[5m]))'"
```

### 3. Parallel Storage Rollback

**Impact:** Reverts to sequential folder_api operations  
**Expected Downtime:** 1-2 minutes  
**Risk Level:** Medium

#### Step 1: Disable Parallel Processing
```bash
# Disable parallel storage globally
kubectl set env deployment/pactis-app PARALLEL_STORAGE_ENABLED=false

# Or disable for specific workspaces
kubectl exec -it deployment/pactis-app -- iex -S mix
iex> Application.put_env(:pactis, :parallel_storage_workspaces, [])
```

#### Step 2: Wait for In-Flight Operations
```bash
# Monitor active tasks
kubectl exec -it deployment/pactis-app -- iex -S mix
iex> Task.Supervisor.children(Pactis.TaskSupervisor) |> length()

# Wait for count to drop to normal levels (< 10)
# This may take 1-2 minutes for large batch operations to complete
```

#### Step 3: Restart Connection Pool (if needed)
```bash
# If connection pool issues, restart the pool
kubectl exec -it deployment/pactis-app -- iex -S mix
iex> Supervisor.terminate_child(Pactis.Supervisor, Pactis.Storage.FolderApiPool)
iex> Supervisor.restart_child(Pactis.Supervisor, Pactis.Storage.FolderApiPool)
```

### 4. Merkle Tree Optimization Rollback

**Impact:** Reverts to non-memoized tree construction  
**Expected Downtime:** None  
**Risk Level:** Low

#### Step 1: Disable Memoization
```bash
# Disable Merkle tree optimizations
kubectl exec -it deployment/pactis-app -- iex -S mix
iex> Application.put_env(:pactis, :merkle_tree_memoization_enabled, false)
```

#### Step 2: Clear Memory Caches
```bash
# Force garbage collection to clear memoization caches
kubectl exec -it deployment/pactis-app -- iex -S mix
iex> :erlang.garbage_collect()
iex> Pactis.Versioning.MerkleTree.clear_memo_cache()
```

### 5. Block Deduplication Rollback

**Impact:** Reverts to memory-intensive analysis  
**Expected Downtime:** None  
**Risk Level:** Low

#### Step 1: Disable Streaming Analysis
```bash
# Revert to original deduplication algorithm
kubectl exec -it deployment/pactis-app -- iex -S mix
iex> Application.put_env(:pactis, :streaming_deduplication_enabled, false)
```

#### Step 2: Cancel In-Progress Jobs
```bash
# Cancel any large deduplication jobs
kubectl exec -it deployment/pactis-app -- iex -S mix
iex> Oban.cancel_all_jobs(Pactis.Storage.Jobs.DeduplicationJob)
```

## Complete System Rollback

### Emergency Full Rollback (5 minutes)

**Use when:** Multiple optimizations failing, system instability  
**Impact:** Full revert to pre-optimization state  
**Downtime:** 3-5 minutes

#### Step 1: Deploy Previous Version (2 minutes)
```bash
# Get previous stable version
PREVIOUS_VERSION=$(kubectl rollout history deployment/pactis-app --revision=2 | grep "Revision 2" | awk '{print $3}')

# Rollback deployment
kubectl rollout undo deployment/pactis-app --to-revision=2

# Wait for rollout completion
kubectl rollout status deployment/pactis-app --timeout=300s
```

#### Step 2: Verify Database Compatibility (1 minute)
```bash
# Check if database migration rollback needed
kubectl exec -it deployment/pactis-app -- mix ecto.migrations

# Rollback migrations if needed (rare, only if schema changes)
# kubectl exec -it deployment/pactis-app -- mix ecto.rollback --step=1
```

#### Step 3: Clear All Optimization Caches (30 seconds)
```bash
# Clear Redis caches
kubectl exec -it deployment/pactis-app -- iex -S mix
iex> Pactis.Cache.flushdb()
```

#### Step 4: Restart All Services (90 seconds)
```bash
# Rolling restart to ensure clean state
kubectl rollout restart deployment/pactis-app
kubectl rollout restart deployment/pactis-worker

# Wait for services to be ready
kubectl wait --for=condition=available --timeout=300s deployment/pactis-app
kubectl wait --for=condition=available --timeout=300s deployment/pactis-worker
```

## Post-Rollback Verification

### 1. System Health Checks (5 minutes)

```bash
# Verify system is responding
curl -f https://api.pactis.dev/health

# Check error rates are normal
curl -s "http://prometheus:9090/api/v1/query?query=rate(cdfm_storage_errors_total[5m])" | jq '.data.result[0].value[1]'

# Verify response times are acceptable
curl -s "http://prometheus:9090/api/v1/query?query=histogram_quantile(0.95,rate(cdfm_http_request_duration_seconds_bucket[5m]))" | jq '.data.result[0].value[1]'

# Check memory usage is stable
curl -s "http://prometheus:9090/api/v1/query?query=container_memory_usage_bytes{pod=~\"pactis-app.*\"}" | jq '.data.result[0].value[1]'
```

### 2. Functional Testing (10 minutes)

```bash
# Test critical user journeys
./scripts/smoke_tests.sh

# Test storage operations
curl -X POST https://api.pactis.dev/api/v1/storage/components \
  -H "Authorization: Bearer $TEST_TOKEN" \
  -H "Content-Type: application/json" \
  -d @test_component.json

# Test similarity search
curl -X POST https://api.pactis.dev/api/v1/storage/find-similar \
  -H "Authorization: Bearer $TEST_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"component": {"jsx_code": "test"}, "threshold": 0.8}'

# Test deduplication
curl -X POST https://api.pactis.dev/api/v1/storage/analyze-duplicates \
  -H "Authorization: Bearer $TEST_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"workspace_id": "test-workspace"}'
```

### 3. Performance Baseline Verification (15 minutes)

```bash
# Run performance verification script
./scripts/verify_performance_baseline.sh

# Expected results:
# - Component indexing < 50ms p95
# - Similarity search < 500ms p95
# - Memory usage < 1GB peak
# - Error rate < 1%
```

## Monitoring During Rollback

### Critical Metrics to Watch

```bash
# Error rate (should decrease immediately)
watch -n 10 "curl -s 'http://prometheus:9090/api/v1/query?query=rate(cdfm_storage_errors_total[1m])'"

# Response time (should stabilize within 5 minutes)
watch -n 30 "curl -s 'http://prometheus:9090/api/v1/query?query=histogram_quantile(0.95,rate(cdfm_http_request_duration_seconds_bucket[5m]))'"

# Memory usage (should stabilize within 10 minutes)
watch -n 30 "curl -s 'http://prometheus:9090/api/v1/query?query=container_memory_usage_bytes{pod=~\"pactis-app.*\"}'"

# Active connections (should return to normal)
watch -n 20 "curl -s 'http://prometheus:9090/api/v1/query?query=redis_connected_clients'"
```

### Alert Suppression During Rollback

```bash
# Suppress non-critical alerts during rollback
curl -X POST http://alertmanager:9093/api/v1/silences \
  -H "Content-Type: application/json" \
  -d '{
    "matchers": [
      {"name": "alertname", "value": "PerformanceRegression", "isRegex": false}
    ],
    "startsAt": "'$(date -u +%Y-%m-%dT%H:%M:%S.000Z)'",
    "endsAt": "'$(date -u -d '+1 hour' +%Y-%m-%dT%H:%M:%S.000Z)'",
    "createdBy": "rollback-procedure",
    "comment": "Suppressing during performance optimization rollback"
  }'
```

## Communication During Rollback

### Internal Communication Template

```
🚨 INCIDENT UPDATE: Pactis Storage Performance Rollback

Status: IN PROGRESS
Started: [TIME]
ETA: [TIME + 15 minutes]

ISSUE:
- Performance optimization causing [SPECIFIC_ISSUE]
- Impact: [USER_IMPACT]
- Decision: Rolling back to stable version

ACTIONS TAKEN:
- [ ] Feature flags disabled
- [ ] Caches cleared  
- [ ] Services restarted
- [ ] Verification in progress

NEXT STEPS:
- Complete verification testing
- Monitor system stability
- Post-incident analysis

Point of Contact: [INCIDENT_COMMANDER]
```

### User Communication Template

```
We're currently experiencing elevated response times in our component storage system. 
We've identified the issue and are implementing a fix. 

Expected resolution: Within 15 minutes
Impact: Component operations may be slower than normal
Workaround: None required, system remains functional

We'll update this status as we have more information.
```

## Post-Rollback Actions

### 1. Immediate Actions (30 minutes)

- [ ] **Update Status Page**
  - Mark incident as resolved
  - Provide timeline and resolution summary
  - Thank users for patience

- [ ] **Internal Notification**
  - Announce successful rollback in #incidents
  - Provide brief summary of issue and resolution
  - Schedule post-incident review

- [ ] **System Monitoring**
  - Continue monitoring for 2 hours post-rollback
  - Verify all metrics remain stable
  - Ensure no secondary issues arise

### 2. Documentation Updates (1 hour)

- [ ] **Incident Report**
  - Document timeline of events
  - Record rollback procedures used
  - Note any issues with rollback process
  - Identify rollback procedure improvements

- [ ] **Runbook Updates**
  - Update rollback procedures based on learnings
  - Add any missing steps discovered
  - Update timing estimates if needed

### 3. Analysis and Prevention (24 hours)

- [ ] **Root Cause Analysis**
  - Investigate why optimization failed
  - Identify gaps in testing or monitoring
  - Document lessons learned

- [ ] **Process Improvements**
  - Update deployment procedures
  - Enhance monitoring and alerting
  - Improve testing coverage

- [ ] **Re-deployment Planning**
  - Plan fix for identified issues
  - Schedule re-deployment with additional safeguards
  - Define success criteria for retry

## Emergency Contacts

### Primary Contacts
- **Incident Commander:** DevOps Team Lead
- **Engineering Lead:** Performance Team Lead  
- **Product Owner:** Product Manager
- **Communications:** Customer Success Manager

### Escalation Chain
1. **Level 1:** Engineering Team (0-15 minutes)
2. **Level 2:** Engineering Manager (15-30 minutes)  
3. **Level 3:** CTO (30+ minutes or major outage)
4. **Level 4:** CEO (customer-impacting outage > 2 hours)

### Contact Information
```
Engineering Team: #engineering-alerts (Slack)
DevOps Team: #devops-incidents (Slack)
Emergency Phone: [EMERGENCY_NUMBER]
PagerDuty: [PAGERDUTY_SERVICE_KEY]
```

## Testing Rollback Procedures

### Monthly Rollback Drill

Execute rollback procedures in staging environment monthly to:
- Verify procedures are accurate and complete
- Train team members on rollback process
- Identify and fix gaps in documentation
- Measure actual rollback times

### Rollback Simulation Script

```bash
#!/bin/bash
# scripts/rollback_drill.sh

echo "🔄 Starting Pactis Rollback Drill"

# Simulate performance issue
echo "📊 Injecting performance degradation..."
kubectl apply -f test/rollback/performance_degradation_sim.yaml

# Wait for issue to be detected
echo "⏱️  Waiting for issue detection..."
sleep 30

# Execute rollback procedures
echo "🔄 Executing rollback..."
./scripts/rollback_performance_optimizations.sh --dry-run=false --env=staging

# Verify rollback success
echo "✅ Verifying rollback..."
./scripts/verify_rollback_success.sh

# Cleanup
echo "🧹 Cleaning up..."
kubectl delete -f test/rollback/performance_degradation_sim.yaml

echo "🎉 Rollback drill completed successfully!"
```

## Appendix

### A. Quick Reference Commands

```bash
# Emergency rollback (all optimizations)
kubectl set env deployment/pactis-app \
  REDIS_PIPELINING_ENABLED=false \
  SIMILARITY_CACHING_ENABLED=false \
  PARALLEL_STORAGE_ENABLED=false

# Check system health
curl -f https://api.pactis.dev/health && echo "✅ System healthy" || echo "❌ System unhealthy"

# View recent errors
kubectl logs deployment/pactis-app --since=10m | grep ERROR

# Monitor key metrics
watch "curl -s 'http://prometheus:9090/api/v1/query?query=up{job=\"pactis-app\"}'"
```

### B. Performance Baseline Values

| Metric | Baseline | Acceptable | Critical |
|--------|----------|------------|----------|
| Component Indexing P95 | 35ms | 50ms | 100ms |
| Similarity Search P95 | 200ms | 500ms | 1000ms |
| Memory Usage Peak | 300MB | 500MB | 1GB |
| Error Rate | 0.01% | 0.1% | 1% |
| API Response P95 | 150ms | 300ms | 1000ms |

### C. Common Issues and Solutions

**Issue:** Redis connection timeout during rollback  
**Solution:** Restart Redis connection pool, increase timeout values

**Issue:** Partial feature flag updates  
**Solution:** Use deployment restart to ensure consistent configuration

**Issue:** Cache inconsistency after rollback  
**Solution:** Clear all caches and allow warm-up period

**Issue:** Long-running jobs blocking rollback  
**Solution:** Cancel active jobs, implement job interruption handling

---

**Document History:**
- v1.0: Initial rollback procedures
- Last Review: December 2024
- Next Review: March 2025