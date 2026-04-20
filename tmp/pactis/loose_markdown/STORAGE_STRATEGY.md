# Pactis Storage Strategy

## Overview

Pactis implements a multi-tiered storage architecture designed to handle the diverse data needs of a high-performance code generation platform with live preview capabilities, multi-agent interactions, and semantic processing.

## Storage Architecture

### Tier 1: PostgreSQL (Primary Persistent Storage)
**Status**: ✅ Implemented  
**Purpose**: Core application data, user accounts, blueprint metadata

**Handles**:
- User accounts, organizations, and memberships
- Blueprint definitions and metadata
- Reviews, comments, and issues
- Collections and categorizations
- Version history and semantic versioning
- JSON-LD context and semantic data

**Key Features**:
- AshPostgres integration with Ash framework
- Complex JSON storage for blueprint definitions
- Full ACID compliance for critical data
- Advanced indexing for semantic search
- UUID-based primary keys

### Tier 2: Redis (Session & Cache Storage)
**Status**: ✅ Implemented  
**Purpose**: High-speed session management and caching

**Handles**:
- Live preview sessions (TTL: 1 hour)
- Multi-agent conversation state (TTL: 2 hours)
- Blueprint caching for frequently accessed data (TTL: 30 minutes)
- User workspace/playground state (TTL: 24 hours)
- WebSocket session metadata (TTL: 4 hours)

**Key Features**:
- Automatic TTL-based cleanup
- JSON serialization for complex data structures
- High-performance key-value operations
- Session state persistence across requests

### Tier 3: File Storage (Static Assets & Generated Code)
**Status**: ✅ Implemented  
**Purpose**: File-based storage with multiple adapter support

**Adapters**:
- **Local**: Development environment (`priv/storage/`)
- **S3**: Production environment (AWS S3 or compatible)

**Handles**:
- Generated code archives and downloads
- Blueprint export packages
- Live preview artifacts (with automatic cleanup)
- User-uploaded assets
- Build outputs and temporary files

**Key Features**:
- Environment-specific configuration
- Automatic file cleanup for temporary assets
- Content-type detection and proper headers
- Secure path handling to prevent traversal attacks

### Tier 4: Background Jobs (Maintenance & Cleanup)
**Status**: ✅ Implemented  
**Purpose**: Automated maintenance and health monitoring

**Functions**:
- Cleanup expired live preview sessions (hourly)
- Cleanup expired file storage artifacts (hourly)
- System health checks (every 5 minutes)
- Cache optimization and maintenance
- Performance monitoring and alerts

## Configuration

### Development Environment

```elixir
# config/dev.exs
config :pactis, :redis,
  host: "localhost",
  port: 6379,
  database: 0

config :pactis, :file_storage,
  adapter: :local,
  local_path: "priv/storage/dev"
```

### Production Environment

```elixir
# config/prod.exs
config :pactis, :redis,
  host: System.get_env("REDIS_HOST") || "localhost",
  port: String.to_integer(System.get_env("REDIS_PORT") || "6379"),
  database: String.to_integer(System.get_env("REDIS_DATABASE") || "0")

config :pactis, :file_storage,
  adapter: :s3,
  bucket: System.get_env("S3_BUCKET"),
  region: System.get_env("AWS_REGION") || "us-east-1"
```

## Usage Examples

### Live Preview Storage

```elixir
# Store generated code for live preview
session_id = "preview_123"
generated_code = %{
  "lib/my_app/user.ex" => "defmodule MyApp.User do...",
  "test/my_app/user_test.exs" => "defmodule MyApp.UserTest do..."
}

{:ok, session_id} = Pactis.Cache.store_live_preview(session_id, generated_code)

# Retrieve later
{:ok, data} = Pactis.Cache.get_live_preview(session_id)
```

### Multi-Agent State Management

```elixir
# Store agent conversation state
agent_state = %{
  agents: ["architect", "generator", "reviewer"],
  conversation_history: [...],
  current_context: %{blueprint_id: "bp_123"}
}

{:ok, session_id} = Pactis.Cache.store_agent_state(session_id, agent_state)

# Append to conversation
new_message = %{agent: "reviewer", message: "Code looks good!", timestamp: ...}
{:ok, _} = Pactis.Cache.append_to_agent_conversation(session_id, new_message)
```

### File Storage Operations

```elixir
# Store generated code archive
code_files = %{
  "lib/user.ex" => "defmodule User do...",
  "mix.exs" => "defmodule MyApp.MixProject do..."
}

{:ok, key} = Pactis.FileStorage.store_generated_code(
  blueprint_id, "1.0.0", code_files, "phoenix"
)

# Store blueprint export
{:ok, export_key} = Pactis.FileStorage.store_blueprint_export(
  blueprint_id, blueprint_data
)
```

### Background Job Monitoring

```elixir
# Check system status
{:ok, status} = Pactis.BackgroundJobs.status()

# Force cleanup if needed
{:ok, results} = Pactis.BackgroundJobs.force_cleanup()

# Run health check
:ok = Pactis.StorageTest.health_check()
```

## Performance Characteristics

### Redis Cache
- **Latency**: Sub-millisecond for simple operations
- **Throughput**: 100,000+ operations/second
- **Memory**: Efficient with automatic expiration
- **Scalability**: Horizontal scaling with Redis Cluster

### File Storage
- **Local**: Limited by disk I/O, suitable for development
- **S3**: Highly scalable, CDN-ready, global distribution
- **Throughput**: Depends on adapter and network conditions

### PostgreSQL
- **ACID Compliance**: Full transaction support
- **JSON Performance**: Efficient with proper indexing
- **Scalability**: Vertical scaling, read replicas for scaling reads

## Security Considerations

### File Storage Security
- Path traversal protection in local adapter
- Secure presigned URLs for S3 access
- Content-type validation and sanitization
- Environment-specific access controls

### Redis Security
- Database isolation by environment
- No sensitive data stored (all session/cache data)
- Automatic expiration prevents data accumulation
- Network security via VPC/firewall rules

### Database Security
- Encrypted connections (SSL/TLS)
- Role-based access control
- Parameterized queries prevent injection
- Regular security updates and patches

## Monitoring & Observability

### Health Checks
- Automated system health monitoring
- Redis connectivity and memory usage
- File storage accessibility and space
- Database connection and performance

### Metrics
- Cache hit/miss ratios
- File storage usage and cleanup rates
- Background job execution times
- Database query performance

### Alerting
- Storage system failures
- Unusual cleanup volumes
- Performance degradation
- Capacity warnings

## Backup & Recovery

### PostgreSQL
- Regular automated backups
- Point-in-time recovery capability
- Backup encryption and offsite storage

### Redis
- Persistence configuration (RDB + AOF)
- Backup of critical session data
- Quick recovery from snapshots

### File Storage
- S3 versioning and cross-region replication
- Local storage backup strategies
- Disaster recovery procedures

## Scaling Strategy

### Current Capacity
- Suitable for thousands of concurrent users
- Efficient memory usage with TTL-based cleanup
- Optimized for development and small-scale production

### Future Scaling Options
1. **Redis Cluster**: Horizontal scaling for cache layer
2. **S3/CDN**: Global content distribution
3. **Database Sharding**: Horizontal PostgreSQL scaling
4. **Microservices**: Service-specific storage optimization

## Testing & Validation

### Automated Testing
```elixir
# Run comprehensive storage tests
Pactis.StorageTest.run_all_tests()

# Quick health check
Pactis.StorageTest.health_check()
```

### Test Coverage
- ✅ Redis cache operations
- ✅ File storage CRUD operations
- ✅ Agent state management
- ✅ Blueprint caching
- ✅ Background job functionality
- ✅ Health monitoring

## Migration Strategy

### From Current Setup
1. **Phase 1**: Add Redis for sessions (✅ Complete)
2. **Phase 2**: Implement file storage system (✅ Complete)
3. **Phase 3**: Add background jobs (✅ Complete)
4. **Phase 4**: Optimize and monitor

### Future Enhancements
- Search engine integration (Elasticsearch)
- Real-time collaboration features
- Advanced caching strategies
- Performance optimization with metrics

## Dependencies

### Required Services
- PostgreSQL 13+ (primary database)
- Redis 6+ (cache and sessions)
- AWS S3 or compatible (production file storage)

### Elixir Dependencies
- `redix` - Redis client
- `ex_aws` + `ex_aws_s3` - AWS integration
- `jason` - JSON encoding/decoding
- `hackney` - HTTP client for S3

## Conclusion

The Pactis storage strategy provides a robust, scalable foundation for:
- High-performance live preview functionality
- Efficient multi-agent state management  
- Reliable blueprint storage and versioning
- Automatic cleanup and maintenance
- Production-ready scalability

This multi-tiered approach ensures optimal performance for each data type while maintaining simplicity in development and operations.