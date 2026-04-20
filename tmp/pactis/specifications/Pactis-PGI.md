# Pactis-PGI: Pactis Git Interface

- Status: Draft
- Last Updated: 2025-09-25
- Owners: Pactis Core
- Related: Pactis-PSI.md, Pactis-PCI.md, Pactis-VFS.md

## Summary

Pactis-PGI defines the **conversation-integrated Git protocol interface** that extends Git Smart HTTP Protocol with conversation-driven development workflows. PGI enables traditional Git operations (clone, fetch, push) while seamlessly integrating with Pactis's specification conversation system to transform pushes into collaborative discussions.

## Abstract

PGI implements a complete Git Smart HTTP Protocol server that is 100% compatible with standard Git clients, while adding conversation-driven workflow capabilities. When conversation mode is enabled for a repository, push operations can trigger the creation of specification conversations instead of direct commits, enabling team discussion and approval processes before code integration.

## Key Innovation: Conversation-Driven Pushes

Traditional Git workflows allow direct pushes to branches, which can bypass team review and discussion. PGI introduces **conversation-triggered pushes** where:

1. Developer performs normal `git push`
2. PGI intercepts the push and evaluates conversation rules
3. If conversation is required, a SpecRequest is automatically created
4. Push is "rejected" with helpful message pointing to conversation
5. Team discusses and approves changes through conversation
6. Upon approval, changes are integrated into target branch

## Git Smart HTTP Protocol Compliance

### Supported Operations

**Repository Discovery**
```http
GET /:owner/:repo/info/refs?service=git-upload-pack
GET /:owner/:repo/info/refs?service=git-receive-pack
```

**Clone/Fetch Operations**
```http
POST /:owner/:repo/git-upload-pack
Content-Type: application/x-git-upload-pack-request
```

**Push Operations**
```http
POST /:owner/:repo/git-receive-pack
Content-Type: application/x-git-receive-pack-request
```

### Protocol Extensions

PGI extends the Git protocol with conversation-specific capabilities:

**Extended Capabilities**
- `conversation-integration`: Indicates conversation support
- `auto-conversation`: Automatic conversation creation for protected operations
- `conversation-status`: Real-time conversation workflow status

**Capability Advertisement**
```
001e# service=git-receive-pack
0000
0054abc123... refs/heads/main\0report-status delete-refs side-band-64k quiet atomic ofs-delta push-options conversation-integration auto-conversation
0000
```

## Access Control & Security

### Repository Visibility Models

**Public Repositories**
- Clone/fetch: Allow anonymous access
- Push: Require authentication and write permissions

**Private Repositories**
- All operations: Require authentication and appropriate permissions

**Internal Repositories**
- All operations: Require workspace membership

### Authentication Integration

PGI integrates with Pactis authentication (PAI):
- HTTP Basic Auth with personal access tokens
- OAuth2 token-based authentication
- Session-based authentication for web clients
- API token authentication for automated systems

### Permission Validation
```elixir
defp has_git_access?(repository, user, operation) do
  case {repository.visibility, operation} do
    {:public, "git-upload-pack"} -> true
    {:private, _} when is_nil(user) -> false
    {:private, _} -> user_has_repository_access?(user, repository)
    {_, "git-receive-pack"} when is_nil(user) -> false
    {_, "git-receive-pack"} -> user_has_write_access?(user, repository)
    _ -> false
  end
end
```

## Conversation Integration Workflows

### Decision Matrix for Push Operations

PGI evaluates each push operation and decides the appropriate action:

```elixir
defp should_trigger_conversation?(repository, request_body, user) do
  cond do
    not repository.conversation_enabled -> {:ok, :allow_direct_push}
    repository.auto_merge_enabled -> {:ok, :allow_direct_push}
    pushing_to_protected_branch?(request_body) -> {:ok, :trigger_conversation}
    user_has_bypass_permissions?(user, repository) -> {:ok, :allow_direct_push}
    true -> {:ok, :trigger_conversation}
  end
end
```

### Conversation Creation Process

When a push triggers conversation mode:

1. **Parse Push Request**: Extract commits, branches, and file changes
2. **Generate SpecRequest**: Create conversation with push context
3. **Store Push Data**: Temporarily store push for later application
4. **Return Conversation Response**: Inform user about conversation requirement

```elixir
defp create_push_conversation(repository, request_body, user) do
  spec_request_attrs = %{
    id: "push-#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
    workspace_id: repository.workspace_id,
    project: repository.name,
    title: "Push to #{repository.name}",
    metadata: %{
      repository_id: repository.id,
      push_type: "git_push",
      author: user.username || user.name,
      push_data: Base.encode64(request_body),
      target_branch: extract_target_branch(request_body),
      commit_count: count_commits(request_body)
    }
  }

  case Pactis.Spec.SpecRequest.create(spec_request_attrs) do
    {:ok, spec_request} -> {:ok, spec_request.id}
    {:error, reason} -> {:error, reason}
  end
end
```

### Conversation Response Format

When a push is rejected for conversation:

```
unpack ok
ng refs/heads/main Push rejected: Conversation required for this repository

Your changes have been received but require team discussion before merging.
A conversation has been automatically created at:

https://pactis.dev/my-org/my-repo/conversations/push-a1b2c3d4

Please participate in the conversation to get your changes approved.
0000
```

## Repository Operations Integration

### Reference Discovery

PGI provides complete Git reference information while adding conversation context:

```elixir
defp build_receive_pack_refs_response(refs, repository) do
  capabilities = "report-status delete-refs side-band-64k quiet atomic ofs-delta push-options"

  # Add conversation-driven capabilities
  conversation_caps = if repository.conversation_enabled do
    " conversation-integration auto-conversation"
  else
    ""
  end

  full_capabilities = capabilities <> conversation_caps
  # ... build response with enhanced capabilities
end
```

### Pack Processing

PGI handles Git pack files while maintaining conversation workflow integration:

**Upload Pack (Clone/Fetch)**
- Standard Git pack generation
- Efficient delta compression
- Shallow clone support
- Conversation metadata in commit messages (optional)

**Receive Pack (Push)**
- Pack validation and unpacking
- Conversation workflow evaluation
- Conditional pack application
- Event emission for successful pushes

## Storage Backend Integration

### Git Repository Structure

PGI manages Git repositories through Pactis storage adapters:

```elixir
case StorageAdapter.open_repository(repository) do
  {:ok, git_repo} ->
    # Standard Git operations on repository
    refs_dir = Path.join(git_repo.git_dir, "refs")
    collect_refs(refs_dir, "refs")
  {:error, reason} ->
    {:error, reason}
end
```

### Content-Addressable Storage

Integration with Pactis storage system (PST):
- Git objects stored in content-addressable format
- Deduplication across repositories
- Multi-provider backend support (S3, local disk, hybrid)
- Efficient blob and tree storage

## Protocol Implementation Details

### Request/Response Processing

**Info/Refs Endpoint**
```elixir
def info_refs(conn, %{"owner" => owner, "repo" => repo} = params) do
  workspace_id = WorkspaceResolver.get_workspace_id(conn)
  full_name = "#{owner}/#{repo}"
  service = params["service"]

  case get_repository_with_access_check(full_name, workspace_id, conn, service) do
    {:ok, repository} ->
      case service do
        "git-upload-pack" -> handle_upload_pack_refs(conn, repository)
        "git-receive-pack" -> handle_receive_pack_refs(conn, repository)
        _ -> send_error(conn, 400, "Invalid service parameter")
      end
    {:error, reason} -> send_error(conn, reason)
  end
end
```

**Pack Processing**
```elixir
def git_receive_pack(conn, %{"owner" => owner, "repo" => repo}) do
  workspace_id = WorkspaceResolver.get_workspace_id(conn)
  current_user = conn.assigns[:current_user]

  case get_repository_with_access_check(full_name, workspace_id, conn, "git-receive-pack") do
    {:ok, repository} ->
      {:ok, request_body, conn} = Plug.Conn.read_body(conn)

      case process_receive_pack_request(repository, request_body, current_user) do
        {:ok, response} -> send_pack_response(conn, response)
        {:error, :conversation_required} -> send_conversation_response(conn, repository)
        {:error, reason} -> send_error(conn, reason)
      end
  end
end
```

### Protocol Message Formats

PGI implements complete Git Smart HTTP protocol message formatting:

**Ref Line Format**
```elixir
defp format_ref_line(content) do
  # Git protocol: 4-digit hex length + content + newline
  length = byte_size(content) + 5
  length_hex = String.pad_leading(Integer.to_string(length, 16), 4, "0")
  "#{length_hex}#{content}\n"
end
```

**Pack Response Format**
```elixir
defp build_pack_response(operation_result) do
  case operation_result do
    :success -> "unpack ok\nok refs/heads/main\n0000"
    {:conversation_required, conversation_url} ->
      build_conversation_required_response(conversation_url)
    {:error, reason} -> build_error_response(reason)
  end
end
```

## Event Integration

PGI emits events for all Git operations via Pactis-PEI:

**Repository Access Events**
```elixir
Pactis.Events.emit("Git.RepositoryCloned",
  version: "v1",
  actor: %{user_id: user.id, type: "user"},
  resource: "Repository/#{repository.id}",
  payload: %{
    repository_id: repository.id,
    operation: "clone",
    client_info: extract_client_info(conn)
  }
)
```

**Push Operation Events**
```elixir
Pactis.Events.emit("Git.PushReceived",
  version: "v1",
  actor: %{user_id: user.id, type: "user"},
  resource: "Repository/#{repository.id}",
  payload: %{
    repository_id: repository.id,
    branch: target_branch,
    commit_count: count_commits(request_body),
    conversation_triggered: conversation_required?,
    spec_request_id: spec_request_id
  }
)
```

## Performance & Scalability

### Caching Strategies

**Reference Caching**
- Cache Git references for fast discovery
- Invalidate on push operations
- TTL-based cache expiration

**Pack Generation Caching**
- Cache common pack responses
- Delta reuse across similar requests
- Memory-efficient streaming for large repositories

### Resource Management

**Concurrent Operations**
- Request pooling for Git operations
- Memory limits for pack processing
- Timeout handling for long-running operations

**Storage Efficiency**
- Shared object storage across repositories
- Efficient packing algorithms
- Garbage collection for unreferenced objects

## Error Handling & Diagnostics

### Standard Git Errors

PGI provides Git-compatible error responses:

```
error: failed to push some refs to 'https://pactis.dev/org/repo.git'
hint: Updates were rejected because the remote contains work that you do
hint: not have locally. This is usually caused by another repository pushing
```

### Conversation-Specific Errors

Enhanced error messages for conversation workflows:

```
error: push rejected by conversation workflow
hint: Your changes require team review before integration.
hint: A conversation has been created at: https://pactis.dev/org/repo/conversations/push-123
hint: Participate in the discussion to get your changes approved.
```

### Debugging Support

**Diagnostic Headers**
- `X-Pactis-Repository-Id`: Internal repository identifier
- `X-Pactis-Conversation-Required`: Indicates if conversation was triggered
- `X-Pactis-Spec-Request-Id`: Links to created conversation

**Logging Integration**
```elixir
Logger.info("Git operation processed",
  repository_id: repository.id,
  operation: operation,
  user_id: user.id,
  conversation_triggered: conversation_required?,
  processing_time: processing_time_ms
)
```

## Configuration & Deployment

### Repository Configuration

```elixir
%Repository{
  conversation_enabled: true,
  auto_merge_enabled: false,
  protected_branches: ["main", "develop"],
  conversation_rules: %{
    require_conversation: ["main"],
    auto_approve_branches: ["feature/*"],
    bypass_users: ["ci-bot"]
  }
}
```

### Server Configuration

```elixir
config :pactis, PactisWeb.GitController,
  max_pack_size: 100_000_000,  # 100MB
  request_timeout: 300_000,    # 5 minutes
  enable_conversation_mode: true,
  enable_pack_caching: true
```

## Integration Patterns

### With Pactis-PSI (Specification Interface)
- Automatic SpecRequest creation from push operations
- Commit message parsing for conversation context
- Repository linking in conversation metadata

### With Pactis-PCI (Content Interface)
- File-level conversation context
- Change tracking across conversations
- Diff integration with conversation messages

### With Pactis-POI (Observability Interface)
- Complete Git operation tracing
- Performance metrics for repository operations
- User access pattern analytics

## Security Considerations

### Access Control
- Complete integration with Pactis authentication
- Repository-level permission enforcement
- Audit logging for all Git operations

### Data Protection
- Secure storage of Git objects
- Encryption in transit for all operations
- Access logging and compliance

### Attack Prevention
- Rate limiting for Git operations
- Resource exhaustion protection
- Malicious pack detection

## Future Enhancements

### Advanced Git Features
- Large File Storage (LFS) support
- Git signing and verification
- Advanced merge strategies
- Partial clone improvements

### Enhanced Conversation Integration
- Automatic conversation summarization
- AI-powered commit message generation
- Smart branch protection rules
- Integration with external CI/CD systems

### Performance Optimizations
- Protocol v2 support
- Improved delta compression
- Distributed repository caching
- Edge server deployment

## Examples

See `docs/examples/pgi/` for complete examples:
- `basic-git-operations.md` - Standard Git workflow examples
- `conversation-triggered-push.md` - Complete conversation workflow
- `repository-setup.md` - Repository configuration examples
- `troubleshooting.md` - Common issues and solutions

---

*Pactis-PGI v1.0 - Conversation-Integrated Git Protocol Interface*
