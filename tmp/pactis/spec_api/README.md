# Pactis Spec API Documentation

This directory contains comprehensive documentation for Pactis's Cross-Repository Spec Negotiation API - a revolutionary system enabling distributed services to coordinate specification changes through structured message exchanges.

## Documentation Overview

### 📋 [Overview](./overview.md)
Complete introduction to the Cross-Repository Spec Negotiation API, including:
- Why this innovation is revolutionary
- Architecture and core concepts
- Key benefits and use cases
- Security and authentication

### 🔄 [Protocol](./protocol.md) 
Detailed protocol specifications covering:
- Message flow patterns and sequence diagrams
- State transition rules
- Communication patterns (broadcast, pull-based, export-based)
- Error handling and recovery mechanisms

### 🛠️ [Implementation Guide](./implementation.md)
Practical integration guide with:
- Quick start examples
- Client libraries and SDK usage
- CI/CD pipeline integration
- Webhook handling
- Testing strategies and best practices

### 📊 [JSON-LD Schemas](./schemas.md)
Semantic structure and interoperability documentation:
- Core vocabulary and context definitions
- Complete schema definitions for all message types
- Integration with external vocabularies (Schema.org, Dublin Core)
- SPARQL query examples

### 💡 [Examples & Best Practices](./examples.md)
Real-world scenarios and implementation patterns:
- API version migration coordination
- Database schema evolution workflows
- Configuration management automation
- Error recovery patterns
- Monitoring and observability

### 📚 Wiki (Curated)
Community-authored SpecAPI notes and patterns:
- See: [WIKI_INDEX](./WIKI_INDEX.md)

## Quick Reference

### API Base URL
```
/api/v1/workspaces/:workspace_id/spec
```

### Core Endpoints
- `POST /requests` - Create/update spec requests
- `POST /requests/:id/messages` - Send messages
- `GET /requests/:id/messages` - Retrieve messages
- `POST /requests/:id/status` - Update request status
- `GET /requests/:id/export.jsonld` - Export as JSON-LD
- `POST /requests/:id/checkpoints` - Create a checkpoint (manifest snapshot)
- `PUT /requests/:id/restore/:checkpoint` - Request restore to a checkpoint

### Canonical JSON-LD Specs
- Spec API (source of truth): `priv/jsonld/resources/Spec/spec_api.jsonld`  
  Served at: `GET /api/specs/spec-api.jsonld` (content-type: `application/ld+json`)
- Method Spec Registry (extension): `priv/jsonld/resources/Spec/method_registry.jsonld`  
  Served at: `GET /api/specs/method-registry.jsonld` (content-type: `application/ld+json`)

## Source of Truth & Versioning

- Authoritative specs are the JSON-LD files under `priv/jsonld/resources/Spec/*`. Code and prose should align to these.
- Each document includes `@id`, `version`, `lastUpdated`, and `changeLog` for traceability.
- Propose changes by editing these JSON-LD files in a PR. Keep `changeLog` concise and bump `version` appropriately.
- Public, read-only endpoints serve these exact files for external consumers and validation.

### Message Types
- `comment` - General discussion
- `question` - Information requests
- `proposal` - Change suggestions
- `decision` - Approvals/rejections

### Request Status Flow
```
proposed → accepted → in_progress → implemented
    ↓         ↓            ↓
 rejected   blocked     blocked
```

## Getting Started

1. **Authentication**: Obtain a workspace-scoped Bearer token
2. **Create Request**: Initialize a spec negotiation
3. **Exchange Messages**: Send proposals, questions, and decisions
4. **Monitor Events**: Subscribe to real-time updates via PubSub
5. **Export Results**: Generate JSON-LD for archival/integration

## Key Innovations

✅ **Structured Communication** - Typed messages with semantic meaning  
✅ **Real-time Coordination** - Instant notifications via Phoenix PubSub  
✅ **Semantic Interoperability** - JSON-LD enables tool ecosystem integration  
✅ **Attachment Support** - Include patches, configs, documentation  
✅ **Workspace Security** - Multi-tenant with proper authentication  
✅ **Audit Trails** - Complete negotiation history  
✅ **Idempotency** - Reliable message delivery with deduplication  

## Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  Service A  │    │    Pactis     │    │  Service B  │
│             │───▶│ Negotiation │◀───│             │
│             │    │     Hub     │    │             │
└─────────────┘    └─────────────┘    └─────────────┘
```

This system enables a new category of distributed development workflows where services can negotiate changes programmatically while maintaining human oversight and approval processes.

---

For detailed implementation examples and advanced usage patterns, explore the individual documentation files in this directory.
# Spec API Overview

This is the canonical HTTP surface for PSI (Spec Interface) operations.

- Base path: `/api/v1/spec`
- Content type: `application/ld+json` (responses include `@context` with `https://pactis.dev/vocab#`)
- Auth: OAuth2 bearer token
- Scopes: `read:spec`, `write:spec`
- Idempotency: Use `X-Idempotency-Key` for message appends (optional; body `idempotency_key` also accepted)

## Routes

- `POST /workspaces/{workspace_id}/requests` — upsert a SpecRequest (write:spec)
- `GET /workspaces/{workspace_id}/requests/{id}` — get a SpecRequest (read:spec)
- `GET /workspaces/{workspace_id}/requests` — list SpecRequests (read:spec)
- `PATCH /workspaces/{workspace_id}/requests/{id}/status` — set status (write:spec)
- `POST /workspaces/{workspace_id}/requests/{id}/messages` — append SpecMessage (write:spec)
- `GET /workspaces/{workspace_id}/requests/{id}/messages` — list SpecMessages (read:spec)

## Quick Start (curl)

Upsert a request
```bash
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"id":"feat-auth","project":"backend","title":"Add OAuth2"}' \
  http://localhost:4000/api/v1/spec/workspaces/$WORKSPACE_ID/requests
```

Append a message (idempotent)
```bash
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "X-Idempotency-Key: msg-123" \
  -d '{"type":"proposal","body":"Use OAuth2 with PKCE"}' \
  http://localhost:4000/api/v1/spec/workspaces/$WORKSPACE_ID/requests/feat-auth/messages
```

List messages
```bash
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:4000/api/v1/spec/workspaces/$WORKSPACE_ID/requests/feat-auth/messages
```

Status update
```bash
curl -X PATCH \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"status":"accepted"}' \
  http://localhost:4000/api/v1/spec/workspaces/$WORKSPACE_ID/requests/feat-auth/status
```

## Tenancy & Access

- GitHub-style tenancy: single DB; all operations are scoped by `workspace_id`.
- Access: user must be a member of the workspace’s organization.
- The server enforces access with a workspace access plug and validates that message repo context belongs to the same workspace.

See `/api/v1/spec/docs` for live OpenAPI UI.
