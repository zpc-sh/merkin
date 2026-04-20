# Phase 1: Repository Basics Specification

## Overview
Extend Pactis to support full repository hosting with Git protocol compatibility while maintaining the conversation-driven architecture. This phase establishes the foundation for repositories without disrupting existing Spec API functionality.

## Technical Specifications

### 1. Repository Resource Model

```elixir
# lib/pactis/core/repository.ex
defmodule Pactis.Repositories.Repository do
  use Ash.Resource,
    domain: Pactis.Core,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication.Resource]

  attributes do
    # Core repository identity
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
    attribute :full_name, :string # "owner/repo-name" 
    attribute :description, :string
    
    # Repository configuration
    attribute :visibility, :atom, constraints: [one_of: [:public, :private, :internal]]
    attribute :default_branch, :string, default: "main"
    attribute :archived, :boolean, default: false
    attribute :disabled, :boolean, default: false
    
    # Owner metadata for GitHub-compatible routing
    attribute :owner_type, :atom, constraints: [one_of: [:user, :organization]]
    attribute :owner_id, :uuid, allow_nil?: false
    
    # Repository metadata
    attribute :languages, :map # {"elixir" => 75.2, "javascript" => 24.8}
    attribute :topics, {:array, :string}
    attribute :homepage_url, :string
    attribute :clone_url_http, :string
    attribute :clone_url_ssh, :string
    
    # Statistics
    attribute :size_kb, :integer, default: 0
    attribute :stars_count, :integer, default: 0
    attribute :forks_count, :integer, default: 0
    attribute :watchers_count, :integer, default: 0
    attribute :open_issues_count, :integer, default: 0
    
    # Conversation integration
    attribute :conversation_enabled, :boolean, default: true
    attribute :auto_merge_enabled, :boolean, default: false
    attribute :required_reviewers, :integer, default: 1
    
    timestamps()
  end

  relationships do
    # Workspace relationship is REQUIRED for multitenancy  
    belongs_to :workspace, Pactis.Spec.Workspace
    
    # Owner can be User OR Organization within the workspace
    belongs_to :owner, Pactis.Accounts.User
    belongs_to :organization, Pactis.Accounts.Organization
    
    has_many :repository_branches, Pactis.Repositories.RepositoryBranch
    has_many :repository_refs, Pactis.Repositories.RepositoryRef
    has_many :repository_commits, Pactis.Repositories.RepositoryCommit
    has_many :repository_trees, Pactis.Repositories.RepositoryTree
    has_many :repository_blobs, Pactis.Repositories.RepositoryBlob
    
    # Conversation integration
    has_many :spec_requests, Pactis.Spec.SpecRequest,
      source_attribute: :id,
      destination_attribute: :repository_id
  end

  actions do
    defaults [:create, :read, :update, :destroy]
    
    create :create_repository do
      accept [:name, :description, :visibility, :default_branch, :owner_type, :owner_id]
      argument :workspace_id, :uuid, allow_nil?: false
      
      change fn changeset, _context ->
        owner_type = Ash.Changeset.get_attribute(changeset, :owner_type)
        owner_id = Ash.Changeset.get_attribute(changeset, :owner_id)
        workspace_id = Ash.Changeset.get_argument(changeset, :workspace_id)
        name = Ash.Changeset.get_attribute(changeset, :name)
        
        # Get owner name for GitHub-compatible full_name
        owner_name = case owner_type do
          :user -> 
            user = Pactis.Accounts.User |> Ash.get!(owner_id)
            user.username
          :organization ->
            org = Pactis.Accounts.Organization |> Ash.get!(owner_id)
            org.name
        end
        
        full_name = "#{owner_name}/#{name}"
        
        changeset
        |> Ash.Changeset.change_attribute(:workspace_id, workspace_id)
        |> Ash.Changeset.change_attribute(:full_name, full_name)
        |> Ash.Changeset.change_attribute(:clone_url_http, "https://pactis.dev/#{full_name}.git")
        |> Ash.Changeset.change_attribute(:clone_url_ssh, "git@pactis.dev:#{full_name}.git")
      end
    end
    
    read :list_public do
      filter expr(visibility == :public and not archived)
      pagination keyset?: true, countable: :by_count
    end
    
    read :list_by_owner do
      argument :owner_id, :uuid, allow_nil?: false
      filter expr(owner_id == ^arg(:owner_id))
    end
    
    update :archive do
      accept []
      change set_attribute(:archived, true)
    end
  end
end
```

### 2. Git Object Storage Model

```elixir
# lib/pactis/core/repository_commit.ex
defmodule Pactis.Repositories.RepositoryCommit do
  use Ash.Resource, domain: Pactis.Core, data_layer: AshPostgres.DataLayer

  attributes do
    attribute :sha, :string, primary_key?: true
    attribute :message, :string, allow_nil?: false
    attribute :author_name, :string
    attribute :author_email, :string
    attribute :committer_name, :string
    attribute :committer_email, :string
    attribute :tree_sha, :string
    attribute :parent_shas, {:array, :string}
    attribute :committed_at, :utc_datetime
    
    # Conversation integration
    attribute :spec_request_id, :string # Link to conversation that created this commit
    attribute :conversation_context, :map # Snapshot of conversation state
    
    timestamps()
  end

  relationships do
    belongs_to :repository, Pactis.Repositories.Repository
    belongs_to :author, Pactis.Accounts.User, source_attribute: :author_email, destination_attribute: :email
    belongs_to :committer, Pactis.Accounts.User, source_attribute: :committer_email, destination_attribute: :email
    has_one :tree, Pactis.Repositories.RepositoryTree, source_attribute: :tree_sha, destination_attribute: :sha
  end
end

# lib/pactis/core/repository_tree.ex  
defmodule Pactis.Repositories.RepositoryTree do
  use Ash.Resource, domain: Pactis.Core, data_layer: AshPostgres.DataLayer

  attributes do
    attribute :sha, :string, primary_key?: true
    attribute :entries, {:array, :map} # [%{mode: "100644", type: "blob", sha: "abc123", path: "lib/file.ex"}]
    timestamps()
  end

  relationships do
    belongs_to :repository, Pactis.Repositories.Repository
  end
end

# lib/pactis/core/repository_blob.ex
defmodule Pactis.Repositories.RepositoryBlob do
  use Ash.Resource, domain: Pactis.Core, data_layer: AshPostgres.DataLayer

  attributes do
    attribute :sha, :string, primary_key?: true
    attribute :content, :binary # For small files
    attribute :size, :integer
    attribute :encoding, :string # "base64", "utf-8"
    
    # Large file handling - delegate to Folder API
    attribute :storage_backend, :atom # :local, :folder_api, :s3
    attribute :storage_key, :string # Reference to Folder API blob
    
    timestamps()
  end

  relationships do
    belongs_to :repository, Pactis.Repositories.Repository
  end
end

# lib/pactis/core/repository_ref.ex
defmodule Pactis.Repositories.RepositoryRef do
  use Ash.Resource, domain: Pactis.Core, data_layer: AshPostgres.DataLayer

  attributes do
    attribute :name, :string # "refs/heads/main", "refs/tags/v1.0.0"
    attribute :sha, :string
    attribute :ref_type, :atom, constraints: [one_of: [:branch, :tag]]
    
    # Conversation-driven branching
    attribute :created_by_spec, :string # SpecRequest ID that created this ref
    attribute :conversation_policy, :map # Rules for who can modify this ref
    
    timestamps()
  end

  relationships do
    belongs_to :repository, Pactis.Repositories.Repository
    belongs_to :target_commit, Pactis.Repositories.RepositoryCommit, source_attribute: :sha, destination_attribute: :sha
  end
end
```

### 3. Git Protocol Compatibility Layer

```elixir
# lib/pactis_web/controllers/git_controller.ex
defmodule PactisWeb.GitController do
  use PactisWeb, :controller
  
  # Git Smart HTTP Protocol
  # GET  /:owner/:repo/info/refs?service=git-upload-pack
  # POST /:owner/:repo/git-upload-pack  
  # GET  /:owner/:repo/info/refs?service=git-receive-pack
  # POST /:owner/:repo/git-receive-pack
  
  def info_refs(conn, %{"owner" => owner, "repo" => repo, "service" => service}) do
    case get_repository(owner, repo) do
      {:ok, repository} ->
        case service do
          "git-upload-pack" -> handle_upload_pack_refs(conn, repository)
          "git-receive-pack" -> handle_receive_pack_refs(conn, repository)
          _ -> send_resp(conn, 400, "Invalid service")
        end
      {:error, :not_found} ->
        send_resp(conn, 404, "Repository not found")
    end
  end
  
  def git_upload_pack(conn, %{"owner" => owner, "repo" => repo}) do
    {:ok, repository} = get_repository(owner, repo)
    
    # Read git-upload-pack request from body
    {:ok, request_body, conn} = Plug.Conn.read_body(conn)
    
    # Process pack request
    response = Pactis.Git.UploadPack.process(repository, request_body)
    
    conn
    |> put_resp_content_type("application/x-git-upload-pack-result")
    |> send_resp(200, response)
  end
  
  def git_receive_pack(conn, %{"owner" => owner, "repo" => repo}) do
    {:ok, repository} = get_repository(owner, repo)
    
    # This is where conversation integration happens
    # Instead of directly applying changes, we create a SpecRequest
    {:ok, request_body, conn} = Plug.Conn.read_body(conn)
    
    case Pactis.Git.ReceivePack.process_with_conversation(repository, request_body, get_current_user(conn)) do
      {:ok, response} ->
        conn
        |> put_resp_content_type("application/x-git-receive-pack-result")  
        |> send_resp(200, response)
      {:error, reason} ->
        send_resp(conn, 422, "Push rejected: #{reason}")
    end
  end
  
  defp get_repository(owner, repo) do
    Pactis.Repositories.Repository
    |> Ash.Query.filter(full_name == "#{owner}/#{repo}")
    |> Ash.read_one()
  end
  
  defp get_current_user(conn) do
    # Extract user from Git auth (basic auth, token, etc.)
    Pactis.Accounts.User.get_by_git_credentials(conn)
  end
end
```

### 4. Repository Web Interface

```elixir
# lib/pactis_web/live/repository_live/index.ex
defmodule PactisWeb.RepositoryLive.Index do
  use PactisWeb, :live_view
  
  def mount(_params, _session, socket) do
    {:ok, assign(socket, repositories: list_repositories())}
  end
  
  def handle_params(%{"owner" => owner, "repo" => repo} = params, _uri, socket) do
    repository = get_repository!(owner, repo)
    
    socket =
      socket
      |> assign(:repository, repository)
      |> assign(:current_branch, params["branch"] || repository.default_branch)
      |> assign(:path, params["path"] || [])
      |> load_repository_content()
    
    {:noreply, socket}
  end
  
  defp load_repository_content(socket) do
    %{repository: repo, current_branch: branch, path: path} = socket.assigns
    
    # Load tree/blob content for current path
    case Pactis.Git.TreeWalker.get_content(repo, branch, path) do
      {:ok, :tree, entries} ->
        assign(socket, :content_type, :tree)
        |> assign(:entries, entries)
      {:ok, :blob, content} ->
        assign(socket, :content_type, :blob)
        |> assign(:blob_content, content)
      {:error, :not_found} ->
        assign(socket, :content_type, :not_found)
    end
  end
end
```

## File Storage Strategy

### 1. Integration with Folder API

```elixir
# lib/pactis/git/storage_adapter.ex
defmodule Pactis.Git.StorageAdapter do
  @behaviour Pactis.Git.Storage
  
  # Small files stored locally in PostgreSQL
  # Large files delegated to Folder API's content-addressable storage
  
  def store_blob(repository_id, content) when byte_size(content) < 1_048_576 do
    # Store small files (< 1MB) directly in PostgreSQL
    sha = :crypto.hash(:sha, content) |> Base.encode16(case: :lower)
    
    %Pactis.Repositories.RepositoryBlob{}
    |> Ash.Changeset.for_create(:create, %{
      sha: sha,
      content: content,
      size: byte_size(content),
      repository_id: repository_id,
      storage_backend: :local
    })
    |> Ash.create()
  end
  
  def store_blob(repository_id, content) do
    # Store large files in Folder API
    sha = :crypto.hash(:sha, content) |> Base.encode16(case: :lower)
    
    # Push to Folder API's content-addressable storage
    case Pactis.Folder.Client.store_blob(content) do
      {:ok, storage_key} ->
        %Pactis.Repositories.RepositoryBlob{}
        |> Ash.Changeset.for_create(:create, %{
          sha: sha,
          size: byte_size(content),
          repository_id: repository_id,
          storage_backend: :folder_api,
          storage_key: storage_key
        })
        |> Ash.create()
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  def get_blob(sha) do
    case Pactis.Repositories.RepositoryBlob |> Ash.get(sha) do
      {:ok, %{storage_backend: :local, content: content}} ->
        {:ok, content}
      {:ok, %{storage_backend: :folder_api, storage_key: key}} ->
        Pactis.Folder.Client.get_blob(key)
      {:error, reason} ->
        {:error, reason}
    end
  end
end
```

### 2. Repository Initialization

```elixir
# lib/pactis/git/repository_initializer.ex
defmodule Pactis.Git.RepositoryInitializer do
  
  def initialize_repository(repository, opts \\ []) do
    # Create initial commit with README
    readme_content = generate_readme(repository)
    
    # Create blob for README
    {:ok, readme_blob} = Pactis.Git.StorageAdapter.store_blob(repository.id, readme_content)
    
    # Create tree with README
    tree_entries = [%{
      mode: "100644",
      type: "blob", 
      sha: readme_blob.sha,
      path: "README.md"
    }]
    
    {:ok, tree} = create_tree(repository.id, tree_entries)
    
    # Create initial commit
    commit_message = opts[:initial_commit_message] || "Initial commit"
    {:ok, commit} = create_commit(repository.id, %{
      message: commit_message,
      tree_sha: tree.sha,
      author_name: "Pactis System",
      author_email: "system@pactis.dev",
      parent_shas: []
    })
    
    # Create main branch reference
    create_ref(repository.id, "refs/heads/#{repository.default_branch}", commit.sha)
    
    # Update repository statistics
    repository
    |> Ash.Changeset.for_update(:update, %{size_kb: 1})
    |> Ash.update()
  end
  
  defp generate_readme(repository) do
    """
    # #{repository.name}
    
    #{repository.description || "A new repository"}
    
    ## Getting Started
    
    Clone this repository:
    ```bash
    git clone #{repository.clone_url_http}
    ```
    
    ---
    
    This repository uses Pactis's conversation-driven development workflow.
    Changes are coordinated through structured conversations rather than traditional pull requests.
    """
  end
end
```

## API Extensions - GitHub Compatible with Workspace Resolution

### 1. Enhanced Router with Workspace Resolution

```elixir
# lib/pactis_web/router.ex - Updated with GitHub compatibility
defmodule PactisWeb.Router do
  use PactisWeb, :router

  # Existing conversation APIs stay workspace-scoped
  scope "/api/v1/workspaces/:workspace_id", PactisWeb do
    pipe_through [:api_authenticated, PactisWeb.Plugs.BillingGate]
    
    # Spec API (unchanged - existing functionality)
    scope "/spec" do
      post "/requests", SpecRequestsController, :create
      get "/requests/:id", SpecRequestsController, :show
      get "/requests", SpecRequestsController, :index
      post "/requests/:id/messages", SpecMessagesController, :create
      get "/requests/:id/messages", SpecMessagesController, :index
      get "/requests/:id/export.jsonld", SpecExportController, :show
      post "/requests/:id/status", SpecStatusController, :create
    end
    
    # Ops API (unchanged - existing functionality)  
    scope "/ops" do
      post "/changes", OpsChangesController, :create
      get "/changes/:id", OpsChangesController, :show
      get "/changes/:id/artifacts", OpsChangesController, :artifacts
      post "/changes/:id/apply", OpsChangesController, :apply
    end
    
    # Mem API (unchanged - existing functionality)
    scope "/mem" do
      get "/manifests/:ref/*name", MemController, :manifest
      get "/blobs/:digest", MemController, :blob
    end
  end

  # NEW: GitHub-Compatible Repository API with Workspace Resolution
  scope "/api/v1", PactisWeb do
    pipe_through [:api_authenticated, PactisWeb.Plugs.WorkspaceResolver]
    
    # GitHub-style repository routes
    scope "/repos/:owner/:repo" do
      get "/", RepositoryController, :show
      get "/contents/*path", RepositoryContentController, :show
      get "/commits", RepositoryCommitController, :index
      get "/commits/:sha", RepositoryCommitController, :show
      get "/branches", RepositoryBranchController, :index
      get "/tags", RepositoryTagController, :index
      
      # Issues map to conversations! (Revolutionary integration)
      get "/issues", ConversationIssueController, :index  # Maps to spec requests
      post "/issues", ConversationIssueController, :create # Creates spec request
      get "/issues/:number", ConversationIssueController, :show
      patch "/issues/:number", ConversationIssueController, :update
      
      # Repository statistics
      get "/languages", RepositoryStatsController, :languages
      get "/contributors", RepositoryStatsController, :contributors
    end
    
    # User/Organization repositories (GitHub-compatible)
    get "/users/:username/repos", UserRepositoryController, :index
    get "/orgs/:org/repos", OrganizationRepositoryController, :index
    
    # Repository creation (workspace-aware)
    post "/user/repos", RepositoryController, :create_user_repo
    post "/orgs/:org/repos", RepositoryController, :create_org_repo
  end

  # Git Protocol with Workspace Resolution
  scope "/", PactisWeb do
    pipe_through [:git_auth, PactisWeb.Plugs.WorkspaceResolver]
    
    get "/:owner/:repo/info/refs", GitController, :info_refs
    post "/:owner/:repo/git-upload-pack", GitController, :git_upload_pack
    post "/:owner/:repo/git-receive-pack", GitController, :git_receive_pack
  end
end
```

### 2. Workspace Resolution Middleware

```elixir
# lib/pactis_web/plugs/workspace_resolver.ex
defmodule PactisWeb.Plugs.WorkspaceResolver do
  @moduledoc """
  Resolves workspace context for GitHub-compatible API routes.
  Maintains multitenancy while providing familiar GitHub URL patterns.
  """
  
  import Plug.Conn
  
  def init(opts), do: opts
  
  def call(conn, _opts) do
    workspace_id = resolve_workspace(conn)
    
    case workspace_id do
      nil -> 
        conn 
        |> put_status(404)
        |> Phoenix.Controller.json(%{message: "Repository not found"})
        |> halt()
      workspace_id ->
        assign(conn, :workspace_id, workspace_id)
    end
  end
  
  defp resolve_workspace(conn) do
    cond do
      # 1. Explicit workspace header (for API clients)
      explicit = get_req_header(conn, "x-pactis-workspace") |> List.first() ->
        verify_workspace_access(conn, explicit)
        
      # 2. Resolve from repository ownership (GitHub-compatible URLs)
      owner_repo = extract_owner_repo(conn) ->
        resolve_from_repository(owner_repo)
        
      # 3. Resolve from authenticated user's default workspace
      true ->
        resolve_from_user_context(conn)
    end
  end
  
  defp extract_owner_repo(conn) do
    case conn.path_params do
      %{"owner" => owner, "repo" => repo} -> {owner, repo}
      _ -> nil
    end
  end
  
  defp resolve_from_repository({owner, repo}) do
    full_name = "#{owner}/#{repo}"
    
    case Pactis.Repositories.Repository.get_by_full_name(full_name) do
      {:ok, repository} -> repository.workspace_id
      {:error, :not_found} -> nil
    end
  end
  
  defp resolve_from_user_context(conn) do
    case conn.assigns[:current_user] do
      %{default_workspace_id: workspace_id} -> workspace_id
      _ -> nil
    end
  end
  
  defp verify_workspace_access(conn, workspace_id) do
    user = conn.assigns[:current_user]
    
    case Pactis.Accounts.has_workspace_access?(user, workspace_id) do
      true -> workspace_id
      false -> nil
    end
  end
end
```

### 3. GitHub-Compatible Repository Content API

```elixir
# lib/pactis_web/controllers/repository_content_controller.ex
defmodule PactisWeb.RepositoryContentController do
  use PactisWeb, :controller
  
  # GitHub-compatible content API with workspace resolution
  def show(conn, %{"owner" => owner, "repo" => repo, "path" => path}) do
    # Workspace already resolved by WorkspaceResolver plug
    workspace_id = conn.assigns.workspace_id
    
    case get_repository(owner, repo, workspace_id) do
      {:ok, repository} ->
        ref = conn.params["ref"] || repository.default_branch
        
        case Pactis.Git.TreeWalker.get_content(repository, ref, path) do
          {:ok, :blob, content} ->
            file_info = %{
              name: Path.basename(List.last(path)),
              path: Enum.join(path, "/"),
              sha: compute_sha(content),
              size: byte_size(content),
              type: "file",
              content: Base.encode64(content),
              encoding: "base64",
              # GitHub-compatible fields
              url: build_api_url(conn, owner, repo, path),
              html_url: build_web_url(conn, owner, repo, path),
              git_url: build_git_url(conn, owner, repo, path),
              download_url: build_download_url(conn, owner, repo, path)
            }
            json(conn, file_info)
            
          {:ok, :tree, entries} ->
            # Format entries in GitHub-compatible format
            formatted_entries = Enum.map(entries, fn entry ->
              %{
                name: entry.name,
                path: entry.path,
                sha: entry.sha,
                size: entry.size,
                type: entry.type,
                url: build_api_url(conn, owner, repo, entry.path),
                html_url: build_web_url(conn, owner, repo, entry.path),
                git_url: build_git_url(conn, owner, repo, entry.path)
              }
            end)
            json(conn, formatted_entries)
            
          {:error, :not_found} ->
            conn |> put_status(404) |> json(%{message: "Not Found"})
        end
        
      {:error, :not_found} ->
        conn |> put_status(404) |> json(%{message: "Repository not found"})
    end
  end
  
  defp get_repository(owner, repo, workspace_id) do
    full_name = "#{owner}/#{repo}"
    
    Pactis.Repositories.Repository
    |> Ash.Query.filter(full_name == ^full_name and workspace_id == ^workspace_id)
    |> Ash.read_one()
  end
  
  # GitHub-compatible URL builders
  defp build_api_url(conn, owner, repo, path) do
    "#{conn.scheme}://#{conn.host}/api/v1/repos/#{owner}/#{repo}/contents/#{path}"
  end
  
  defp build_web_url(conn, owner, repo, path) do
    "#{conn.scheme}://#{conn.host}/#{owner}/#{repo}/blob/main/#{path}"
  end
  
  defp build_git_url(conn, owner, repo, path) do
    "#{conn.scheme}://#{conn.host}/#{owner}/#{repo}/git/blobs/#{compute_sha(path)}"
  end
  
  defp build_download_url(conn, owner, repo, path) do
    "#{conn.scheme}://#{conn.host}/#{owner}/#{repo}/raw/main/#{path}"
  end
end

# NEW: Conversation-Issue Integration Controller
defmodule PactisWeb.ConversationIssueController do
  use PactisWeb, :controller
  
  @moduledoc """
  Maps GitHub Issues API to Pactis's conversation-driven development.
  Issues become Spec Requests, providing familiar GitHub workflow
  while leveraging Pactis's revolutionary conversation coordination.
  """
  
  def index(conn, %{"owner" => owner, "repo" => repo}) do
    workspace_id = conn.assigns.workspace_id
    
    case get_repository(owner, repo, workspace_id) do
      {:ok, repository} ->
        # List spec requests as GitHub issues
        spec_requests = Pactis.Spec.SpecRequest
          |> Ash.Query.filter(workspace_id == ^workspace_id and repository_id == ^repository.id)
          |> Ash.read!()
        
        issues = Enum.map(spec_requests, &format_as_github_issue/1)
        json(conn, issues)
        
      {:error, :not_found} ->
        conn |> put_status(404) |> json(%{message: "Repository not found"})
    end
  end
  
  def create(conn, %{"owner" => owner, "repo" => repo} = params) do
    workspace_id = conn.assigns.workspace_id
    user = conn.assigns.current_user
    
    case get_repository(owner, repo, workspace_id) do
      {:ok, repository} ->
        # Create spec request from GitHub issue format
        spec_attrs = %{
          id: generate_spec_id(params["title"]),
          workspace_id: workspace_id,
          project: repository.name,
          title: params["title"],
          metadata: %{
            repository_id: repository.id,
            github_issue_body: params["body"],
            labels: params["labels"] || [],
            assignees: params["assignees"] || []
          },
          created_by: user.id
        }
        
        case Pactis.Spec.SpecRequest.create(spec_attrs) do
          {:ok, spec_request} ->
            # Also create initial message with issue body
            if params["body"] do
              create_initial_message(spec_request, params["body"], user)
            end
            
            issue = format_as_github_issue(spec_request)
            conn |> put_status(201) |> json(issue)
            
          {:error, error} ->
            conn |> put_status(422) |> json(%{message: "Could not create issue", errors: error})
        end
        
      {:error, :not_found} ->
        conn |> put_status(404) |> json(%{message: "Repository not found"})
    end
  end
  
  defp format_as_github_issue(spec_request) do
    %{
      id: spec_request.id,
      number: generate_issue_number(spec_request),
      title: spec_request.title,
      body: extract_body_from_metadata(spec_request),
      state: map_status_to_state(spec_request.status),
      created_at: spec_request.inserted_at,
      updated_at: spec_request.updated_at,
      labels: spec_request.metadata["labels"] || [],
      assignees: spec_request.metadata["assignees"] || [],
      # Pactis-specific extensions
      spec_request_id: spec_request.id,
      conversation_url: "/api/v1/workspaces/#{spec_request.workspace_id}/spec/requests/#{spec_request.id}",
      messages_count: count_messages(spec_request)
    }
  end
  
  defp map_status_to_state(status) do
    case status do
      :proposed -> "open"
      :accepted -> "open" 
      :in_progress -> "open"
      :implemented -> "closed"
      :rejected -> "closed"
      :blocked -> "open"
    end
  end
end
```

## Database Migrations

```elixir
# priv/repo/migrations/20250101000001_add_repository_support.exs
defmodule Pactis.Repo.Migrations.AddRepositorySupport do
  use Ecto.Migration

  def change do
    create table(:repositories, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :full_name, :string, null: false
      add :description, :text
      add :visibility, :string, null: false, default: "private"
      add :default_branch, :string, null: false, default: "main"
      add :archived, :boolean, null: false, default: false
      add :disabled, :boolean, null: false, default: false
      
      add :languages, :map, null: false, default: %{}
      add :topics, {:array, :string}, null: false, default: []
      add :homepage_url, :string
      add :clone_url_http, :string
      add :clone_url_ssh, :string
      
      add :size_kb, :integer, null: false, default: 0
      add :stars_count, :integer, null: false, default: 0
      add :forks_count, :integer, null: false, default: 0
      add :watchers_count, :integer, null: false, default: 0
      add :open_issues_count, :integer, null: false, default: 0
      
      add :conversation_enabled, :boolean, null: false, default: true
      add :auto_merge_enabled, :boolean, null: false, default: false
      add :required_reviewers, :integer, null: false, default: 1
      
      add :owner_type, :string, null: false
      add :owner_id, :binary_id, null: false
      add :workspace_id, references(:workspaces, type: :binary_id), null: false
      
      timestamps()
    end
    
    create unique_index(:repositories, [:full_name])
    create index(:repositories, [:owner_type, :owner_id])
    create index(:repositories, [:workspace_id])
    create index(:repositories, [:visibility])
    
    create table(:repository_commits, primary_key: false) do
      add :sha, :string, primary_key: true
      add :message, :text, null: false
      add :author_name, :string
      add :author_email, :string
      add :committer_name, :string
      add :committer_email, :string
      add :tree_sha, :string
      add :parent_shas, {:array, :string}, null: false, default: []
      add :committed_at, :utc_datetime
      add :spec_request_id, :string
      add :conversation_context, :map
      
      add :repository_id, references(:repositories, type: :binary_id), null: false
      add :author_id, references(:users, type: :binary_id)
      add :committer_id, references(:users, type: :binary_id)
      
      timestamps()
    end
    
    create index(:repository_commits, [:repository_id])
    create index(:repository_commits, [:spec_request_id])
    
    create table(:repository_trees, primary_key: false) do
      add :sha, :string, primary_key: true
      add :entries, {:array, :map}, null: false, default: []
      add :repository_id, references(:repositories, type: :binary_id), null: false
      
      timestamps()
    end
    
    create index(:repository_trees, [:repository_id])
    
    create table(:repository_blobs, primary_key: false) do
      add :sha, :string, primary_key: true
      add :content, :binary
      add :size, :integer, null: false
      add :encoding, :string
      add :storage_backend, :string, null: false, default: "local"
      add :storage_key, :string
      add :repository_id, references(:repositories, type: :binary_id), null: false
      
      timestamps()
    end
    
    create index(:repository_blobs, [:repository_id])
    create index(:repository_blobs, [:storage_backend])
    
    create table(:repository_refs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :sha, :string, null: false
      add :ref_type, :string, null: false
      add :created_by_spec, :string
      add :conversation_policy, :map
      add :repository_id, references(:repositories, type: :binary_id), null: false
      
      timestamps()
    end
    
    create unique_index(:repository_refs, [:repository_id, :name])
    create index(:repository_refs, [:ref_type])
  end
end
```

## Testing Strategy

```elixir
# test/pactis/git/repository_test.exs
defmodule Pactis.Git.RepositoryTest do
  use Pactis.DataCase
  
  describe "repository creation" do
    test "creates repository with default branch" do
      user = insert(:user)
      
      {:ok, repo} = Pactis.Repositories.Repository
        |> Ash.Changeset.for_create(:create_repository, %{
          name: "test-repo",
          description: "Test repository",
          visibility: :public,
          owner_type: :user,
          owner_id: user.id
        })
        |> Ash.create()
      
      assert repo.name == "test-repo"
      assert repo.full_name == "#{user.username}/test-repo"
      assert repo.default_branch == "main"
      assert repo.conversation_enabled == true
    end
  end
  
  describe "git protocol compatibility" do
    test "handles git clone request" do
      repo = insert(:repository)
      
      conn = build_conn()
        |> get("/#{repo.full_name}/info/refs?service=git-upload-pack")
      
      assert conn.status == 200
      assert String.contains?(conn.resp_body, "refs/heads/main")
    end
  end
end

# test/cdfm_web/controllers/git_controller_test.exs  
defmodule PactisWeb.GitControllerTest do
  use PactisWeb.ConnCase
  
  test "GET /owner/repo/info/refs returns git references", %{conn: conn} do
    repo = insert(:repository, visibility: :public)
    
    conn = get(conn, "/#{repo.full_name}/info/refs", %{"service" => "git-upload-pack"})
    
    assert response(conn, 200)
    assert get_resp_header(conn, "content-type") == ["application/x-git-upload-pack-advertisement"]
  end
end
```

## Key Architectural Advantages

### 1. **GitHub Migration Path**
- **Familiar URLs**: `/api/v1/repos/:owner/:repo` matches GitHub exactly
- **Tool Compatibility**: Existing GitHub clients and tools work without modification
- **Issue Integration**: GitHub Issues map directly to Pactis's conversation system
- **Clone URLs**: Standard Git URLs with workspace resolution behind the scenes

### 2. **Conversation-Driven Innovation**
- **Issues → Spec Requests**: Every GitHub issue becomes a structured conversation
- **Push → Conversation**: Git pushes can trigger conversation workflows
- **Consensus Building**: Traditional PR process replaced with real-time semantic dialogue
- **Context Preservation**: Full conversation history linked to commits

### 3. **Workspace Security with GitHub UX**
- **Transparent Multitenancy**: Workspace isolation without complex URLs
- **Flexible Resolution**: Workspace determined by repository ownership or explicit headers
- **Enterprise Ready**: Workspaces provide natural organizational boundaries
- **Billing Integration**: Existing workspace billing applies to repository operations

### 4. **Revolutionary Issues System**
```json
// Creating a GitHub issue via API
POST /api/v1/repos/acme/web-app/issues
{
  "title": "Add user authentication",
  "body": "We need OAuth integration with Google and GitHub",
  "labels": ["feature", "auth"]
}

// Automatically becomes a Pactis conversation with:
// - Structured semantic messages
// - Real-time stakeholder participation  
// - Impact analysis and context preservation
// - Automatic resolution workflow
```

## Implementation Priority (Updated)

### Week 1-2: Core Repository Model + Workspace Integration
1. Create Ash resources for Repository, Commit, Tree, Blob, Ref
2. Database migrations with workspace relationships
3. Repository creation with automatic workspace assignment
4. **NEW**: Workspace resolution middleware implementation

### Week 3-4: GitHub-Compatible API Layer  
1. GitHub-compatible repository routes (`/api/v1/repos/:owner/:repo`)
2. Conversation-Issue integration controller
3. Content API with GitHub-compatible response format
4. **NEW**: Authentication with workspace context resolution

### Week 5-6: Git Protocol + Conversation Integration
1. Git Smart HTTP protocol with workspace resolution
2. Push-to-conversation workflow (conversation-driven pushes)
3. Clone/fetch functionality with content-addressable storage
4. **NEW**: Automatic spec request creation from Git operations

### Week 7-8: Web Interface + Testing
1. GitHub-style repository browsing UI
2. Issues interface that exposes conversation features
3. Comprehensive testing with real GitHub API clients
4. **NEW**: Performance optimization for workspace resolution

### Week 9-10: Migration & Compatibility Tools
1. GitHub repository import tools
2. GitHub API compatibility testing suite
3. Documentation for GitHub → Pactis migration
4. **NEW**: Webhook compatibility for existing GitHub integrations

## Revolutionary Outcomes

This architecture positions Pactis to be the **GitHub killer** by offering:

1. **Zero Migration Friction**: Existing GitHub workflows work immediately
2. **Conversation Enhancement**: Issues become powerful semantic conversations
3. **Real-time Coordination**: Eliminate PR ceremony with live consensus building
4. **Enterprise Multitenancy**: Workspace isolation with familiar GitHub UX
5. **Content-Addressable Storage**: Better performance than traditional Git hosting

**The beautiful advantage**: Organizations can migrate from GitHub incrementally, gaining conversation-driven development benefits while maintaining familiar tooling and workflows.
