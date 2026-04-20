# Pactis-PSI: Pactis Specification Interface

- Status: Draft
- Last Updated: 2026-04-02
- Owners: Pactis Core
- Related: Pactis-CCV2.md, Pactis-PGI.md, Pactis-PCI.md, Pactis-PEI.md

## Summary

Pactis-PSI defines the **conversation-driven development interface** that transforms traditional code changes into structured conversations. PSI enables teams to discuss, review, and approve changes through spec requests and threaded messages, integrating with Git workflows and repository operations to create a collaborative development experience.

## Abstract

PSI introduces the concept of "specification conversations" - structured discussions around code changes, feature requests, and development proposals that are tightly integrated with repository operations. Instead of direct pushes to main branches, developers create spec requests that facilitate team discussion, code review, and consensus-building before implementation.

## CCV2 Compatibility (Sabha Profile)

Under Pactis-CCV2, PSI remains the primary request/message interface for human workflows and integration tooling, with this positioning:

1. `SpecRequest` and `SpecMessage` are adapter/logging surfaces for conversational traces.
2. Canonical conversational substrate semantics (Tree/Node/Region/Branch/FoldHandle/Nucleant/Crystal) are defined in Sabha contracts, not in PSI resource shapes.
3. Move semantics (`assert`, `challenge`, `fork`, `fold`, `crystallize`, etc.) may be mirrored into PSI messages for UX and audit continuity.

Reference:

- [Pactis-CCV2.md](./Pactis-CCV2.md)
- [Pactis-Sabha-Schemas.md](./Pactis-Sabha-Schemas.md)
- [Pactis-Sabha-Operations.md](./Pactis-Sabha-Operations.md)

## Key Concepts

### Core Entities

**SpecRequest**: A structured conversation about a proposed change
- Unique identifier within workspace context
- Project association and repository linkage
- Status lifecycle (proposed → accepted → in_progress → implemented)
- Metadata for tracking and categorization

**SpecMessage**: Individual messages within a spec request conversation
- Message types: question, proposal, acceptance, rejection, status_update, review_request, merge_proposal
- Threading support with parent_message_id and thread_id
- Rich content including code references, attachments, and repository context
- Actor attribution and timestamps

**Workspace**: Multi-tenant context for organizing spec requests
- Repository associations
- User permissions and access control
- Workflow automation rules
- Analytics and reporting scope

### Repository Integration

**Repository Context**: Links spec requests to specific repositories
- Branch and commit references
- File path associations
- Code review integration
- Merge proposal workflows

**Code References**: Structured references to repository content
- File paths and line ranges
- Commit SHAs and branch names
- Diff integration for review workflows
- Conversation anchoring to specific code locations

## API Surface

### HTTP Endpoints (SpecAPI)

- Base: `/api/v1/spec`
- Content type: `application/ld+json` (responses include `@context` with `https://pactis.dev/vocab#`)
- AuthN/AuthZ: OAuth2 bearer; scopes `read:spec`, `write:spec`
- Idempotency: `X-Idempotency-Key` for message appends (optional; body `idempotency_key` also accepted)

Routes
- `POST /workspaces/{workspace_id}/requests` — upsert a SpecRequest
- `GET /workspaces/{workspace_id}/requests/{id}` — get a SpecRequest
- `GET /workspaces/{workspace_id}/requests` — list SpecRequests
- `PATCH /workspaces/{workspace_id}/requests/{id}/status` — set status
- `POST /workspaces/{workspace_id}/requests/{id}/messages` — append SpecMessage
- `GET /workspaces/{workspace_id}/requests/{id}/messages` — list SpecMessages

### Core Operations

**Create Spec Request**
```http
POST /workspaces/{workspace_id}/requests
Content-Type: application/json

{
  "id": "feature-user-authentication",
  "title": "Add OAuth2 authentication system",
  "project": "backend-api",
  "repository_id": "repo-123",
  "metadata": {
    "priority": "high",
    "estimated_effort": "large",
    "tags": ["authentication", "security"]
  }
}
```

**Send Message**
```http
POST /workspaces/{workspace_id}/requests/{request_id}/messages
Content-Type: application/json

{
  "id": "msg-456",
  "type": "proposal",
  "body": "I propose we use OAuth2 with PKCE flow for better security",
  "attachments": ["architecture-diagram.png"],
  "repository_context": {
    "repository_id": "repo-123",
    "branch": "feature/oauth2",
    "commit_sha": "abc123"
  },
  "code_ref": {
    "files": ["lib/auth/oauth.ex"],
    "line_range": {"start": 15, "end": 45}
  }
}
```

**Update Spec Status**
```http
PATCH /workspaces/{workspace_id}/requests/{request_id}/status
Content-Type: application/json

{
  "status": "accepted",
  "reason": "Team consensus reached after discussion"
}
```

### Review Workflows

**Create Code Review**
```http
POST /workspaces/{workspace_id}/spec-requests/{request_id}/reviews
Content-Type: application/json

{
  "branch": "feature/oauth2",
  "commit_sha": "abc123",
  "description": "Please review OAuth2 implementation",
  "files": ["lib/auth/oauth.ex", "test/auth/oauth_test.exs"],
  "priority": "normal"
}
```

**Submit Review Decision**
```http
POST /workspaces/{workspace_id}/spec-requests/{request_id}/reviews/{review_id}/decision
Content-Type: application/json

{
  "decision": "approve",
  "comments": "Implementation looks good, minor suggestions in inline comments"
}
```

### Merge Proposals

**Propose Merge**
```http
POST /workspaces/{workspace_id}/spec-requests/{request_id}/merge-proposals
Content-Type: application/json

{
  "source_branch": "feature/oauth2",
  "target_branch": "main",
  "merge_strategy": "merge",
  "description": "Ready to merge OAuth2 implementation"
}
```

## TypeScript RPC Surface

PSI exposes a complete TypeScript RPC interface for frontend integration:

### Generated Types
```typescript
// Auto-generated from Ash resources
interface SpecRequestListItem {
  id: string;
  workspace_id: string;
  project: string;
  title: string;
  status: 'proposed' | 'accepted' | 'rejected' | 'in_progress' | 'implemented' | 'blocked';
  inserted_at: string;
  updated_at: string;
}

interface SpecMessageListItem {
  id: string;
  workspace_id: string;
  request_id: string;
  type: 'question' | 'proposal' | 'acceptance' | 'rejection' | 'status_update' | 'review_request' | 'merge_proposal';
  from: ActorInfo;
  body: string;
  thread_id?: string;
  parent_message_id?: string;
  priority: 'low' | 'normal' | 'high';
  status: string;
  created_at: string;
  edited_at?: string;
}
```

### RPC Actions
```typescript
// Workspace operations
const workspaces = await rpc.listWorkspaces();
const workspace = await rpc.createWorkspace({name: "Product Team"});

// Spec request operations
const requests = await rpc.listRequests({workspace_id: "ws-123"});
const request = await rpc.getRequest({workspace_id: "ws-123", id: "req-456"});
const created = await rpc.upsertRequest({...requestData});
await rpc.setRequestStatus({id: "req-456", status: "accepted"});

// Message operations
const messages = await rpc.listMessagesForRequest({
  workspace_id: "ws-123",
  request_id: "req-456"
});
const message = await rpc.appendMessage({...messageData});
const edited = await rpc.editMessage({id: "msg-789", body: "Updated content"});
await rpc.addMessageReaction({message_id: "msg-789", reaction: "👍"});
```

## Status Lifecycle

### Allowed Transitions
```
proposed → [accepted, rejected]
accepted → [in_progress, blocked]
in_progress → [implemented, blocked]
blocked → [in_progress, rejected]
implemented → [] (terminal)
rejected → [proposed] (re-proposal allowed)
```

### Workflow Automation
PSI supports automated workflow rules that trigger on status changes:
- Auto-assign implementation on acceptance
- Trigger deployment workflows on implementation
- Send notifications on status changes
- Integration with external project management tools

## Message Threading

### Thread Organization
- **Root Messages**: Top-level messages without parent_message_id
- **Reply Threading**: Messages with parent_message_id form reply chains
- **Thread Grouping**: thread_id allows logical grouping beyond parent-child
- **Message Organization**: Frontend can organize by threads for better UX

### Message Types & Workflows

**Question → Response Flow**
```
question (root) → proposal (reply) → acceptance (reply)
```

**Review Request Flow**
```
review_request (root) → approval/rejection (replies) → merge_proposal (new root)
```

**Status Update Flow**
```
status_update (system) → acknowledgment (user replies)
```

## Search & Analytics

### Search Capabilities
```http
GET /workspaces/{workspace_id}/search?q=authentication&include_messages=true
```

Returns structured results:
```json
{
  "spec_requests": [...],
  "messages": [...],
  "total_count": 42
}
```

### Analytics API
```http
GET /workspaces/{workspace_id}/analytics?time_range=last_30_days
```

Provides insights:
```json
{
  "time_range": "last_30_days",
  "spec_requests": {
    "total": 156,
    "by_status": {"proposed": 23, "accepted": 45, "implemented": 67}
  },
  "messages": {
    "total": 892,
    "by_type": {"question": 234, "proposal": 189, "acceptance": 156}
  },
  "repository_integration": {
    "linked_specs": 89,
    "reviews_completed": 67
  }
}
```

## Event Integration

PSI emits structured events via Pactis-PEI:

**Spec Request Events**
- `Spec.RequestCreated`: New spec request initiated
- `Spec.RequestUpdated`: Status or content changes
- `Spec.RequestAccepted`: Team consensus reached

**Message Events**
- `Spec.MessageSent`: New message in conversation
- `Spec.ReviewRequested`: Code review initiated
- `Spec.ReviewCompleted`: Review decision submitted

## Real-Time Collaboration

### PubSub Integration
```elixir
# Subscribe to workspace events
Phoenix.PubSub.subscribe(Pactis.PubSub, "workspace:#{workspace_id}")

# Receive real-time updates
{:spec_request_updated, %{id: "req-123", status: "accepted", ...}}
```

### WebSocket Support
- Live updates for active spec requests
- Real-time message delivery
- Typing indicators and presence
- Collaborative editing sessions

## Security & Permissions

### Access Control
- **Workspace Membership**: Required for all operations
- **Repository Access**: Required for repository-linked specs
- **Review Permissions**: Configurable per repository
- **Merge Permissions**: Role-based merge authority

### Audit Trail
- Complete conversation history preservation
- Actor attribution for all actions
- IP address and user agent tracking
- Compliance-ready audit logs

## Implementation Details

### Ash Resource Integration
```elixir
defmodule Pactis.Spec do
  use Ash.Domain, extensions: [AshTypescript.Rpc]

  resources do
    resource(Pactis.Spec.SpecRequest)
    resource(Pactis.Spec.SpecMessage)
    resource(Pactis.Spec.Workspace)
    resource(Pactis.Spec.CodeReview)
    resource(Pactis.Spec.ReviewApproval)
  end
end
```

### Service Layer
PSI provides a high-level service interface (`Pactis.Spec.SpecService`) that handles:
- Complex multi-step workflows
- Repository integration via Git adapters
- Event emission and workflow triggers
- Permission checking and validation
- Error handling and transaction management

### Background Processing
- **Oban Integration**: Async processing of complex workflows
- **Queue Management**: Dedicated `spec` queue for PSI operations
- **Job Types**: Notification delivery, analytics updates, external integrations
- **Retry Logic**: Resilient handling of transient failures

## Conformance Requirements

### Idempotency
- All write operations support idempotency keys
- Duplicate message prevention via content hashing
- Safe retry behavior for network failures

### Data Consistency
- Atomic updates for multi-resource operations
- Event ordering guarantees within conversations
- Conflict resolution for concurrent edits

### Performance
- Pagination support for large conversations
- Efficient querying with proper indexing
- Caching strategies for frequently accessed data

## Integration Patterns

### Git Integration (via Pactis-PGI)
- Push operations can trigger spec request creation
- Branch protection rules enforce conversation workflows
- Merge operations integrate with spec request approval

### Content Management (via Pactis-PCI)
- File changes automatically link to spec requests
- Code references enable precise conversation anchoring
- Diff visualization within conversation context

### Observability (via Pactis-POI)
- Complete conversation tracing with correlation IDs
- Performance metrics for conversation workflows
- User engagement analytics and insights

## Error Handling

### Validation Errors
```json
{
  "error": "validation_error",
  "message": "Missing required field: title",
  "field": "title",
  "code": "FIELD_REQUIRED"
}
```

### Permission Errors
```json
{
  "error": "permission_denied",
  "message": "Insufficient permissions for repository access",
  "required_permission": "repository.read",
  "code": "ACCESS_DENIED"
}
```

### Workflow Errors
```json
{
  "error": "invalid_transition",
  "message": "Cannot transition from implemented to in_progress",
  "current_status": "implemented",
  "attempted_status": "in_progress",
  "code": "INVALID_STATUS_TRANSITION"
}
```

## Future Enhancements

### AI Integration
- Automated code review suggestions
- Smart conversation summarization
- Intelligent workflow recommendations
- Natural language query interface

### Advanced Analytics
- Team collaboration metrics
- Code quality correlation analysis
- Predictive workflow optimization
- Cross-project insight generation

### External Integrations
- Slack/Teams notification bots
- Jira/Linear workflow sync
- GitHub/GitLab import/export
- Calendar and meeting integration

## Examples

See `docs/examples/psi/` for complete examples:
- `basic-spec-request.md` - Simple feature proposal workflow
- `code-review-flow.md` - Complete review and merge process
- `complex-conversation.md` - Multi-threaded discussion with branching
- `api-integration.md` - TypeScript client usage patterns

---

*Pactis-PSI v1.0 - Conversation-Driven Development Interface*
