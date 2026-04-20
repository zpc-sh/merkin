# Pactis-PCI: Pactis Content Interface

- Status: Draft
- Last Updated: 2025-09-25
- Owners: Pactis Core
- Related: Pactis-PSI.md, Pactis-PGI.md, Pactis-CAI.md, Pactis-VFS.md

## Summary

Pactis-PCI defines the **repository content management interface** that provides GitHub-compatible file and directory operations with conversation-driven enhancements. PCI enables programmatic access to repository content while seamlessly integrating file changes with Pactis's specification conversation system.

## Abstract

PCI implements a complete GitHub-compatible Contents API that allows clients to read, create, update, and delete files in repositories through RESTful HTTP operations. Unlike traditional file APIs, PCI enhances every file operation with conversation context, enabling file changes to trigger specification discussions and maintaining rich metadata about how content evolves through collaborative processes.

## Key Innovation: Conversation-Enhanced File Operations

Traditional file APIs treat content changes as isolated operations. PCI introduces **conversation-contextual file management** where:

1. File modifications automatically link to SpecRequests
2. Change metadata includes conversation references
3. File history preserves collaborative context
4. Content responses include conversation status
5. Batch operations maintain conversation consistency

## GitHub API Compatibility

PCI maintains full compatibility with GitHub's Contents API while adding conversation enhancements:

### Supported Endpoints

**Repository Content Operations**
```http
GET /repos/:owner/:repo/contents/:path     # Get file or directory content
PUT /repos/:owner/:repo/contents/:path     # Create or update file
DELETE /repos/:owner/:repo/contents/:path  # Delete file
```

**Query Parameters**
- `ref`: Branch, tag, or commit SHA (defaults to HEAD)
- `conversation_context`: Include conversation metadata in response

### Response Format Extensions

Standard GitHub response enhanced with Pactis conversation context:

```json
{
  "type": "file",
  "name": "README.md",
  "path": "README.md",
  "sha": "abc123...",
  "size": 1024,
  "url": "https://pactis.dev/api/v1/repos/owner/repo/contents/README.md",
  "html_url": "https://pactis.dev/owner/repo/blob/main/README.md",
  "git_url": "https://pactis.dev/api/v1/repos/owner/repo/git/blobs/abc123",
  "download_url": "https://pactis.dev/owner/repo/raw/main/README.md",
  "content": "SGVsbG8gV29ybGQ=",
  "encoding": "base64",

  // Pactis-specific enhancements
  "conversation_context": {
    "has_active_conversations": false,
    "last_modified_via_conversation": true,
    "conversation_count": 3,
    "last_conversation_id": "spec-readme-update-v2"
  },
  "last_conversation_url": "https://pactis.dev/owner/repo/conversations/spec-readme-update-v2",
  "_links": {
    "self": "https://pactis.dev/api/v1/repos/owner/repo/contents/README.md",
    "git": "https://pactis.dev/api/v1/repos/owner/repo/git/blobs/abc123",
    "html": "https://pactis.dev/owner/repo/blob/main/README.md",
    "conversations": "https://pactis.dev/owner/repo/conversations?path=README.md"
  }
}
```

## File Operations with Conversation Integration

### Create or Update File

**Standard GitHub API**
```http
PUT /repos/owner/repo/contents/lib/auth.ex
Content-Type: application/json

{
  "message": "Add OAuth2 authentication",
  "content": "ZGVmbW9kdWxlIEF1dGggZG8K...",
  "sha": "abc123..." // Required for updates
}
```

**Enhanced Pactis Response**
```json
{
  "content": {
    // Standard file response with conversation context
  },
  "commit": {
    "sha": "def456...",
    "message": "Add OAuth2 authentication",
    "author": {
      "name": "Jane Developer",
      "email": "jane@example.com",
      "date": "2025-01-15T10:30:00Z"
    },

    // Pactis conversation enhancement
    "conversation_url": "https://pactis.dev/spec/auth-implementation-proposal",
    "conversation_context": {
      "file_change": true,
      "path": "lib/auth.ex",
      "action": "create",
      "user_id": "user-123",
      "branch": "main",
      "spec_request_id": "auth-implementation-proposal"
    }
  }
}
```

### Delete File

**Request with Conversation Context**
```http
DELETE /repos/owner/repo/contents/deprecated/old_auth.ex
Content-Type: application/json

{
  "message": "Remove deprecated authentication module",
  "sha": "abc123...",
  "conversation_context": {
    "spec_request_id": "cleanup-deprecated-modules",
    "cleanup_phase": "authentication"
  }
}
```

### Batch File Operations

PCI extends GitHub API with batch operations that maintain conversation consistency:

```http
POST /repos/owner/repo/contents/_batch
Content-Type: application/json

{
  "message": "Refactor authentication system",
  "spec_request_id": "auth-refactor-v2",
  "operations": [
    {
      "action": "create",
      "path": "lib/auth/oauth.ex",
      "content": "ZGVmbW9kdWxlIE9hdXRoIGRvCg=="
    },
    {
      "action": "update",
      "path": "lib/auth/base.ex",
      "sha": "abc123...",
      "content": "dXBkYXRlZCBjb250ZW50"
    },
    {
      "action": "delete",
      "path": "lib/auth/legacy.ex",
      "sha": "def456..."
    }
  ]
}
```

## Directory Listing with Conversation Metadata

**Enhanced Directory Response**
```json
[
  {
    "type": "file",
    "name": "auth.ex",
    "path": "lib/auth.ex",
    "sha": "abc123...",
    "size": 2048,
    "url": "https://pactis.dev/api/v1/repos/owner/repo/contents/lib/auth.ex",
    "html_url": "https://pactis.dev/owner/repo/blob/main/lib/auth.ex",
    "git_url": "https://pactis.dev/api/v1/repos/owner/repo/git/blobs/abc123",
    "download_url": "https://pactis.dev/owner/repo/raw/main/lib/auth.ex",

    // Per-file conversation context
    "conversation_context": {
      "has_active_conversations": true,
      "last_modified_via_conversation": true,
      "conversation_count": 5,
      "active_conversation_id": "auth-security-review"
    },
    "_links": {
      "self": "https://pactis.dev/api/v1/repos/owner/repo/contents/lib/auth.ex",
      "git": "https://pactis.dev/api/v1/repos/owner/repo/git/blobs/abc123",
      "html": "https://pactis.dev/owner/repo/blob/main/lib/auth.ex",
      "conversations": "https://pactis.dev/owner/repo/conversations?path=lib/auth.ex"
    }
  }
]
```

## Content-Addressable Storage Integration

### Storage Backend Operations

PCI integrates with Pactis's content-addressable storage system:

```elixir
defp store_file_content(repository, path, content, conversation_opts) do
  case StorageAdapter.store_blob(repository, content, conversation_opts) do
    {:ok, blob_sha} ->
      # Update repository tree with conversation context
      update_repository_tree(repository, path, blob_sha, conversation_opts)
    {:error, reason} ->
      {:error, reason}
  end
end
```

### Deduplication Awareness

PCI leverages content addressing for efficient storage:
- Identical files share storage regardless of path
- Content similarity detection for review optimization
- Delta compression for large file changes
- Cross-repository deduplication

## Git Integration Layer

### Repository Tree Operations

PCI manages Git repository structures through conversation-aware operations:

```elixir
defp get_content_from_commit(repository, commit_sha, path) do
  case StorageAdapter.open_repository(repository) do
    {:ok, git_repo} ->
      with {:ok, commit_info} <- Git.Repository.read_commit(git_repo, commit_sha),
           {:ok, tree_entries} <- Git.Repository.read_tree(git_repo, commit_info.tree) do
        find_path_in_tree(git_repo, tree_entries, String.split(path, "/", trim: true))
      end
  end
end
```

### Path Resolution

Efficient path traversal with conversation context tracking:

```elixir
defp find_path_in_tree(git_repo, tree_entries, path_segments) do
  case path_segments do
    [] -> {:ok, :directory, tree_entries}
    [segment | remaining] ->
      case Enum.find(tree_entries, &(&1.name == segment)) do
        %{mode: "040000", sha1: tree_sha} when remaining != [] ->
          # Continue traversing directory
          {:ok, sub_entries} = Git.Repository.read_tree(git_repo, tree_sha)
          find_path_in_tree(git_repo, sub_entries, remaining)

        %{mode: "040000", sha1: tree_sha} when remaining == [] ->
          # Target directory found
          {:ok, :directory, tree_sha}

        %{mode: mode, sha1: blob_sha} when remaining == [] and mode != "040000" ->
          # Target file found
          {:ok, :file, blob_sha}

        nil ->
          {:error, :not_found}
      end
  end
end
```

## Conversation Integration Workflows

### Automatic SpecRequest Generation

When conversation mode is enabled, file changes trigger SpecRequest creation:

```elixir
defp generate_file_change_spec_request(repository, path, message, user) do
  spec_request_attrs = %{
    id: "file-change-#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
    workspace_id: repository.workspace_id,
    project: repository.name,
    title: "File change: #{path}",
    metadata: %{
      repository_id: repository.id,
      change_type: "file_modification",
      file_path: path,
      author: user.username || user.name,
      commit_message: message,
      change_context: analyze_file_change_context(repository, path)
    }
  }

  case Pactis.Spec.SpecService.create_or_update_spec_request(
    repository.workspace_id,
    spec_request_attrs,
    user.id
  ) do
    {:ok, spec_request} -> spec_request.id
    {:error, _reason} -> nil
  end
end
```

### File Change Analysis

PCI analyzes file changes to provide rich conversation context:

```elixir
defp analyze_file_change_context(repository, path) do
  %{
    file_type: determine_file_type(path),
    estimated_impact: estimate_change_impact(repository, path),
    related_files: find_related_files(repository, path),
    test_files: find_associated_tests(repository, path),
    documentation_files: find_related_docs(repository, path)
  }
end
```

### Conversation Context Tracking

PCI maintains conversation metadata for all file operations:

```elixir
defp get_file_conversation_context(repository, path, sha) do
  case lookup_file_conversations(repository, path) do
    {:ok, conversations} ->
      %{
        has_active_conversations: has_active_conversations?(conversations),
        last_modified_via_conversation: last_change_from_conversation?(sha),
        conversation_count: length(conversations),
        last_conversation_url: get_most_recent_conversation_url(conversations)
      }
    {:error, _} ->
      %{
        has_active_conversations: false,
        last_modified_via_conversation: false,
        conversation_count: 0,
        last_conversation_url: nil
      }
  end
end
```

## Security & Access Control

### Permission Model

PCI enforces repository-level permissions:
- **Read Access**: Required for GET operations
- **Write Access**: Required for PUT/DELETE operations
- **Admin Access**: Required for sensitive file operations

### Access Validation

```elixir
defp validate_file_access(user, repository, operation, path) do
  base_permission = case operation do
    :read -> :repository_read
    :write -> :repository_write
    :delete -> :repository_write
  end

  with :ok <- check_base_permission(user, repository, base_permission),
       :ok <- check_path_restrictions(user, repository, path, operation),
       :ok <- check_conversation_requirements(user, repository, path, operation) do
    :ok
  else
    {:error, reason} -> {:error, reason}
  end
end
```

### Audit Trail

All file operations are logged with conversation context:

```elixir
defp log_file_operation(operation, user, repository, path, result) do
  Logger.info("File operation completed",
    operation: operation,
    user_id: user.id,
    repository_id: repository.id,
    file_path: path,
    result: result,
    conversation_context: extract_conversation_context(result)
  )
end
```

## Performance Optimizations

### Caching Strategy

**Content Caching**
- File content cached by SHA for fast retrieval
- Directory listings cached per commit
- Conversation metadata cached with TTL

**Path Resolution Caching**
- Tree traversal results cached by commit/path
- Negative lookups cached to avoid repeated searches
- Cache invalidation on repository updates

### Streaming Support

**Large File Handling**
- Streaming responses for files > 1MB
- Chunked transfer encoding
- Progress tracking for large operations

**Directory Listings**
- Paginated responses for large directories
- Lazy loading of conversation metadata
- Efficient sorting and filtering

## Event Integration

PCI emits events for all content operations via Pactis-PEI:

**File Operation Events**
```elixir
Pactis.Events.emit("Repository.FileCreated",
  version: "v1",
  actor: %{user_id: user.id, type: "user"},
  resource: "Repository/#{repository.id}/File/#{path}",
  payload: %{
    repository_id: repository.id,
    file_path: path,
    file_sha: blob_sha,
    operation: "create",
    spec_request_id: spec_request_id,
    conversation_context: conversation_context
  }
)
```

**Batch Operation Events**
```elixir
Pactis.Events.emit("Repository.BatchOperation",
  version: "v1",
  actor: %{user_id: user.id, type: "user"},
  resource: "Repository/#{repository.id}",
  payload: %{
    repository_id: repository.id,
    operation_count: length(operations),
    operations: operations_summary,
    spec_request_id: spec_request_id,
    total_files_affected: count_affected_files(operations)
  }
)
```

## Error Handling & Validation

### Content Validation

```elixir
defp validate_file_content(path, content, options) do
  with :ok <- validate_file_size(content, options),
       :ok <- validate_file_type(path, content, options),
       :ok <- validate_content_encoding(content, options),
       :ok <- validate_conversation_requirements(path, options) do
    :ok
  else
    {:error, reason} -> {:error, reason}
  end
end
```

### Error Response Format

**Standard GitHub-Compatible Errors**
```json
{
  "message": "Not Found",
  "documentation_url": "https://docs.pactis.dev/api/repositories/contents"
}
```

**Pactis-Enhanced Errors**
```json
{
  "message": "File modification requires conversation approval",
  "error": "conversation_required",
  "conversation_url": "https://pactis.dev/owner/repo/conversations/file-change-123",
  "required_approvals": 2,
  "current_approvals": 0,
  "documentation_url": "https://docs.pactis.dev/api/conversation-workflows"
}
```

## Configuration

### Repository Settings

```elixir
%Repository{
  conversation_mode: :enabled,
  content_restrictions: %{
    max_file_size: 100_000_000,  # 100MB
    allowed_extensions: :all,
    require_conversation: ["main", "develop"],
    auto_approve_paths: ["docs/", "README.md"]
  },
  content_analysis: %{
    enable_similarity_detection: true,
    enable_test_correlation: true,
    enable_impact_analysis: true
  }
}
```

### API Configuration

```elixir
config :pactis, PactisWeb.RepositoryContentController,
  max_response_size: 50_000_000,  # 50MB
  enable_streaming: true,
  enable_conversation_context: true,
  cache_ttl: 300  # 5 minutes
```

## Integration Patterns

### With Pactis-PSI (Specification Interface)
- Automatic SpecRequest creation for file changes
- File path references in conversation messages
- Change impact analysis in conversation context

### With Pactis-PGI (Git Interface)
- Coordinated Git operations with content API
- Shared repository access control
- Consistent conversation workflows

### With Pactis-CAI (Content Authoring Interface)
- Content management for authored artifacts
- Round-trip editing workflow integration
- Structured content validation

## Future Enhancements

### Advanced Content Features
- Binary file optimization
- Large file storage (LFS) integration
- Content search and indexing
- Multi-language syntax analysis

### Enhanced Conversation Integration
- File-specific conversation templates
- Automated change impact assessment
- Smart reviewer assignment
- Integration with external review tools

### Performance Improvements
- Content delta compression
- Advanced caching strategies
- Edge server deployment
- Parallel operation processing

## Examples

See `docs/examples/pci/` for complete examples:
- `basic-file-operations.md` - Standard CRUD operations
- `conversation-file-workflow.md` - File changes with conversations
- `batch-operations.md` - Bulk file management
- `content-analysis.md` - Advanced content analysis features

---

*Pactis-PCI v1.0 - Conversation-Enhanced Repository Content Interface*
