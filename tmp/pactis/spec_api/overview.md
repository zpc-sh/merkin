# Cross-Repository Spec Negotiation API

## Overview

Pactis's Cross-Repository Spec Negotiation API is a groundbreaking innovation that enables distributed services and repositories to coordinate specification changes through structured message exchanges. This system replaces error-prone file system handoffs with a clean HTTP API that provides real-time coordination, semantic interoperability, and audit trails.

## Why This is Revolutionary

Traditional approaches to coordinating changes across multiple repositories rely on:
- Manual coordination through tickets or chat
- File system polling and watching
- Git-based coordination with complex merge strategies
- Ad-hoc notification systems

Pactis's approach provides:
- **Structured Communication**: Typed messages with semantic meaning
- **Real-time Coordination**: Instant notifications via PubSub
- **Semantic Interoperability**: JSON-LD for cross-system understanding
- **Audit Trails**: Complete history of negotiations and decisions
- **Attachment Support**: Include patches, configs, and documentation
- **Workspace Scoping**: Secure, multi-tenant coordination

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Service A     │    │      Pactis       │    │   Service B     │
│   (markdown_ld) │    │   Negotiation   │    │   (vue_gen)     │
│                 │    │      Hub        │    │                 │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│ Creates Spec    │───▶│ SpecRequest     │◀───│ Subscribes to   │
│ Request         │    │ Storage         │    │ Changes         │
│                 │    │                 │    │                 │
│ Sends Proposals │───▶│ Message         │◀───│ Sends Questions │
│                 │    │ Exchange        │    │                 │
│                 │    │                 │    │                 │
│ Receives Events │◀───│ PubSub Events   │───▶│ Receives Events │
│                 │    │                 │    │                 │
│ Exports JSON-LD │◀───│ Canonical       │───▶│ Imports JSON-LD │
│                 │    │ Export          │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Core Concepts

### Spec Requests
The central coordination entity representing a specification change that needs agreement across services.

**Attributes:**
- `id`: Client-supplied unique identifier (workspace-scoped)
- `workspace_id`: Workspace for security and multi-tenancy
- `project`: Source project proposing the change
- `title`: Human-readable description
- `status`: Current state in the negotiation lifecycle
- `metadata`: Extensible key-value data

**Lifecycle States:**
- `proposed` → Initial state when created
- `accepted` → Agreement reached to proceed  
- `in_progress` → Implementation actively happening
- `implemented` → Change complete and deployed
- `rejected` → Change declined
- `blocked` → Blocked on external dependencies

### Spec Messages
Structured communication between services about a spec request.

**Message Types:**
- `comment` - General discussion and clarification
- `question` - Information requests requiring responses
- `proposal` - Specific change suggestions with details
- `decision` - Final decisions and approvals

**Message Structure:**
- `from`: Source identification (`{project, agent}`)
- `body`: Human-readable message content
- `ref`: Optional reference to specific files/sections
- `attachments`: Supporting files (patches, configs, etc.)

### Workspaces
Security and organizational boundary for spec negotiations. All operations are scoped to workspaces with proper authentication and authorization.

## API Endpoints

Base path: `/api/v1/workspaces/:workspace_id/spec`

### Create/Update Spec Request
```http
POST /requests
Authorization: Bearer <token>
Content-Type: application/json

{
  "id": "markdown-ld-v2-migration",
  "project": "markdown_ld", 
  "title": "Migrate to v2 spec format",
  "metadata": {"priority": "high", "deadline": "2025-10-01"}
}
```

### Send Message
```http
POST /requests/markdown-ld-v2-migration/messages
Authorization: Bearer <token>
Idempotency-Key: uuid-here
Content-Type: application/json

{
  "message": {
    "type": "proposal",
    "from": {"project": "markdown_ld", "agent": "spec-bot"},
    "body": "Proposal to update schema version to 2.0 with backward compatibility",
    "ref": {"path": "schemas/markdown.jsonld", "json_pointer": "/version"},
    "attachments": ["migration-guide.md", "schema-diff.patch"]
  },
  "attachments_content": {
    "migration-guide.md": "<base64-encoded-content>",
    "schema-diff.patch": "<base64-encoded-content>"
  }
}
```

### Subscribe to Updates
```http
GET /requests/markdown-ld-v2-migration/messages?since=2025-09-01T15:00:00Z
Authorization: Bearer <token>
```

### Update Status
```http
POST /requests/markdown-ld-v2-migration/status
Authorization: Bearer <token>
Content-Type: application/json

{"status": "accepted"}
```

### Export Canonical JSON-LD
```http
GET /requests/markdown-ld-v2-migration/export.jsonld
Authorization: Bearer <token>
Accept: application/ld+json
```

## Real-time Events

The system publishes events via Phoenix PubSub for real-time coordination:

### Event Topics
- `spec:ws:{workspace_id}:request:{id}:message` - New messages
- `spec:ws:{workspace_id}:request:{id}:status` - Status changes  
- `spec:ws:{workspace_id}:request:{id}:export` - Export ready

### Event Payloads
```elixir
# Message event
{:spec_message, %{
  request_id: "markdown-ld-v2-migration",
  message: %{id: "msg-1", type: :proposal, ...},
  at: ~U[2025-09-05 15:30:00Z]
}}

# Status event  
{:spec_status, %{
  request_id: "markdown-ld-v2-migration",
  status: :accepted,
  previous: :proposed,
  at: ~U[2025-09-05 15:35:00Z]
}}
```

## Security & Authentication

- **Bearer Token Authentication**: Standard OAuth2/JWT tokens via AshAuthentication
- **Workspace Authorization**: Users must have access to the workspace
- **Billing Gates**: API usage tracked and rate-limited per organization
- **Input Validation**: Strict schema validation and sanitization
- **Attachment Security**: Path traversal protection and size limits

## Key Innovations

1. **Semantic Message Exchange**: Structured, typed communication beyond simple notifications
2. **Attachment Support**: Include code patches, configuration files, and documentation  
3. **Real-time Coordination**: Instant notifications enable responsive workflows
4. **JSON-LD Export**: Standard semantic format for tool interoperability
5. **Workspace Security**: Multi-tenant with proper isolation and billing
6. **Audit Trail**: Complete negotiation history with timestamps and attribution
7. **Idempotency**: Reliable message delivery with deduplication

This system enables a new category of distributed development workflows where services can negotiate changes programmatically while maintaining human oversight and approval processes.