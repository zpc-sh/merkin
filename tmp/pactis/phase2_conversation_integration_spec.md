# Phase 2: Conversation Integration Specification

## Overview
Transform Pactis from a traditional Git hosting platform into a conversation-driven development platform. This phase replaces pull requests with structured conversations, integrates AI agents as first-class participants, and enables cross-service coordination through the existing Spec API.

## Technical Specifications

### 1. Extended Spec API for Repository Operations

```elixir
# lib/pactis/spec/spec_message.ex - Extend existing message types
defmodule Pactis.Spec.SpecMessage do
  # ... existing attributes ...
  
  # New repository-specific message types
  attribute :type, :atom, constraints: [one_of: [
    # Existing types
    :comment, :question, :proposal, :decision,
    # New repository operation types  
    :code_change, :review_request, :merge_proposal, :rollback_request,
    :branch_operation, :release_proposal, :security_analysis, :performance_impact
  ]]
  
  # Enhanced repository context
  attribute :repository_context, :map do
    # %{
    #   repository_id: "uuid",
    #   branch: "feature/auth",
    #   base_branch: "main", 
    #   affected_files: ["lib/auth.ex", "test/auth_test.exs"],
    #   diff_summary: %{additions: 45, deletions: 12, files: 2},
    #   impact_analysis: %{
    #     services_affected: ["user-service", "auth-service"],
    #     breaking_changes: false,
    #     test_coverage: 95.2
    #   }
    # }
  end
  
  # Code-specific references with enhanced context
  attribute :code_ref, :map do
    # %{
    #   repository_id: "uuid",
    #   commit_sha: "abc123",
    #   file_path: "lib/user.ex",
    #   line_range: {45, 67},
    #   function_name: "validate_email",
    #   diff_hunk: "@@ -45,7 +45,12 @@..."
    # }
  end
end
```

### 2. Conversation-Driven Code Review System

```elixir
# lib/pactis/spec/code_review.ex
defmodule Pactis.Spec.CodeReview do
  @moduledoc """
  Conversation-driven code review replacing traditional pull requests.
  Reviews happen through structured conversations with AI and human participants.
  """
  
  use Ash.Resource, domain: Pactis.Spec, data_layer: AshPostgres.DataLayer

  attributes do
    uuid_primary_key :id
    attribute :title, :string, allow_nil?: false
    attribute :description, :string
    attribute :status, :atom, constraints: [one_of: [
      :draft, :review_requested, :under_review, :changes_requested,
      :approved, :merged, :closed, :blocked
    ]], default: :draft
    
    # Repository context
    attribute :repository_id, :uuid, allow_nil?: false
    attribute :source_branch, :string, allow_nil?: false
    attribute :target_branch, :string, allow_nil?: false
    attribute :head_commit, :string
    attribute :base_commit, :string
    
    # Conversation integration
    attribute :spec_request_id, :string, allow_nil?: false
    attribute :auto_merge_eligible, :boolean, default: false
    attribute :required_approvals, :integer, default: 1
    attribute :current_approvals, :integer, default: 0
    
    # Code analysis
    attribute :diff_stats, :map # %{additions: 45, deletions: 12, files: 2}
    attribute :affected_services, {:array, :string}
    attribute :breaking_changes, :boolean, default: false
    attribute :test_coverage_delta, :float
    attribute :security_score, :float
    attribute :performance_impact, :map
    
    timestamps()
  end

  relationships do
    belongs_to :repository, Pactis.Repositories.Repository
    belongs_to :author, Pactis.Accounts.User
    belongs_to :spec_request, Pactis.Spec.SpecRequest, source_attribute: :spec_request_id, destination_attribute: :id
    has_many :review_comments, Pactis.Spec.ReviewComment
    has_many :approvals, Pactis.Spec.ReviewApproval
  end

  actions do
    defaults [:create, :read, :update, :destroy]
    
    create :create_from_branch do
      accept [:repository_id, :source_branch, :target_branch, :title, :description]
      argument :author_id, :uuid, allow_nil?: false
      
      change fn changeset, _context ->
        # Analyze code changes and create spec request
        repo_id = Ash.Changeset.get_attribute(changeset, :repository_id)
        source = Ash.Changeset.get_attribute(changeset, :source_branch)
        target = Ash.Changeset.get_attribute(changeset, :target_branch)
        
        # Get diff analysis
        {:ok, analysis} = Pactis.Git.DiffAnalyzer.analyze_branch_diff(repo_id, source, target)
        
        # Create corresponding spec request
        {:ok, spec_request} = create_spec_request_for_review(changeset, analysis)
        
        changeset
        |> Ash.Changeset.change_attribute(:spec_request_id, spec_request.id)
        |> Ash.Changeset.change_attribute(:diff_stats, analysis.stats)
        |> Ash.Changeset.change_attribute(:affected_services, analysis.services)
        |> Ash.Changeset.change_attribute(:breaking_changes, analysis.breaking_changes)
      end
    end
    
    update :request_review do
      accept []
      change set_attribute(:status, :review_requested)
      
      change fn changeset, _context ->
        # Trigger conversation notifications
        code_review = changeset.data
        Pactis.Spec.ConversationOrchestrator.initiate_review_conversation(code_review)
        changeset
      end
    end
    
    update :approve do
      argument :reviewer_id, :uuid, allow_nil?: false
      argument :review_message, :string
      
      change fn changeset, context ->
        reviewer_id = Ash.Changeset.get_argument(changeset, :reviewer_id)
        message = Ash.Changeset.get_argument(changeset, :review_message) || "Approved"
        
        # Create approval record
        Pactis.Spec.ReviewApproval.create(%{
          code_review_id: changeset.data.id,
          reviewer_id: reviewer_id,
          status: :approved,
          message: message
        })
        
        # Increment approval count
        current = changeset.data.current_approvals
        changeset = Ash.Changeset.change_attribute(changeset, :current_approvals, current + 1)
        
        # Check if auto-merge eligible
        if changeset.data.current_approvals + 1 >= changeset.data.required_approvals do
          changeset
          |> Ash.Changeset.change_attribute(:auto_merge_eligible, true)
          |> Ash.Changeset.change_attribute(:status, :approved)
        else
          changeset
        end
      end
    end
    
    update :merge do
      accept []
      argument :merge_strategy, :atom, constraints: [one_of: [:merge, :squash, :rebase]], default: :merge
      argument :merger_id, :uuid, allow_nil?: false
      
      change fn changeset, context ->
        merge_strategy = Ash.Changeset.get_argument(changeset, :merge_strategy)
        merger_id = Ash.Changeset.get_argument(changeset, :merger_id)
        
        # Perform the actual merge through conversation
        case Pactis.Git.ConversationMerge.execute_merge(changeset.data, merge_strategy, merger_id) do
          {:ok, merge_commit} ->
            changeset
            |> Ash.Changeset.change_attribute(:status, :merged)
            |> Ash.Changeset.change_attribute(:head_commit, merge_commit.sha)
          {:error, reason} ->
            Ash.Changeset.add_error(changeset, reason)
        end
      end
    end
  end
end
```

### 3. AI Agent Integration for Code Review

```elixir
# lib/pactis/spec/review_agents.ex
defmodule Pactis.Spec.ReviewAgents do
  @moduledoc """
  AI agents that participate in code review conversations.
  Each agent has specialized knowledge and review capabilities.
  """
  
  @agents %{
    security_agent: %{
      name: "Security Analyst",
      model: "claude-3-opus",
      specialization: "security vulnerabilities, authentication, authorization",
      triggers: ["auth", "security", "crypto", "password", "token", "permissions"]
    },
    performance_agent: %{
      name: "Performance Optimizer", 
      model: "gpt-4-turbo",
      specialization: "performance bottlenecks, database queries, caching",
      triggers: ["query", "database", "cache", "performance", "optimization", "slow"]
    },
    testing_agent: %{
      name: "Test Coverage Analyst",
      model: "claude-3-sonnet", 
      specialization: "test coverage, edge cases, test quality",
      triggers: ["test", "coverage", "edge case", "validation", "mock"]
    },
    architecture_agent: %{
      name: "Architecture Reviewer",
      model: "gpt-4",
      specialization: "system design, patterns, maintainability",
      triggers: ["architecture", "pattern", "design", "coupling", "cohesion"]
    },
    documentation_agent: %{
      name: "Documentation Reviewer",
      model: "claude-3-haiku",
      specialization: "code comments, documentation, API specs", 
      triggers: ["docs", "comment", "readme", "api", "spec"]
    }
  }
  
  def trigger_agent_reviews(code_review) do
    # Analyze code changes to determine which agents should participate
    relevant_agents = determine_relevant_agents(code_review)
    
    Enum.each(relevant_agents, fn agent_key ->
      agent = @agents[agent_key]
      spawn_agent_review_task(code_review, agent)
    end)
  end
  
  defp determine_relevant_agents(code_review) do
    # Analyze diff content, file paths, and commit messages
    diff_content = Pactis.Git.DiffAnalyzer.get_diff_content(code_review)
    
    @agents
    |> Enum.filter(fn {_key, agent} ->
      Enum.any?(agent.triggers, fn trigger ->
        String.contains?(String.downcase(diff_content), trigger)
      end)
    end)
    |> Enum.map(fn {key, _agent} -> key end)
  end
  
  defp spawn_agent_review_task(code_review, agent) do
    Task.start(fn ->
      # Generate agent review through LLM API
      review_prompt = build_review_prompt(code_review, agent)
      
      case Pactis.LLM.Client.complete(agent.model, review_prompt) do
        {:ok, review_response} ->
          # Parse response and create spec message
          create_agent_review_message(code_review, agent, review_response)
        {:error, reason} ->
          Logger.warn("Agent review failed for #{agent.name}: #{reason}")
      end
    end)
  end
  
  defp build_review_prompt(code_review, agent) do
    diff_content = Pactis.Git.DiffAnalyzer.get_diff_content(code_review)
    
    """
    You are #{agent.name}, specializing in #{agent.specialization}.
    
    Please review the following code changes and provide feedback:
    
    ## Repository Context
    Repository: #{code_review.repository.name}
    Branch: #{code_review.source_branch} -> #{code_review.target_branch}
    Author: #{code_review.author.name}
    
    ## Change Summary
    #{code_review.title}
    #{code_review.description}
    
    ## Code Diff
    ```diff
    #{diff_content}
    ```
    
    ## Analysis Request
    Focus on your specialization area and provide:
    1. Specific issues or concerns you identify
    2. Suggestions for improvement
    3. Praise for good practices you see
    4. Overall assessment (approve/request changes/comment only)
    
    Respond in this format:
    {
      "assessment": "approve|request_changes|comment", 
      "summary": "Brief overall assessment",
      "findings": [
        {
          "type": "issue|suggestion|praise",
          "severity": "high|medium|low",
          "file": "path/to/file.ex",
          "line": 42,
          "message": "Detailed feedback message",
          "suggestion": "Specific code improvement if applicable"
        }
      ]
    }
    """
  end
  
  defp create_agent_review_message(code_review, agent, review_response) do
    case Jason.decode(review_response) do
      {:ok, parsed_review} ->
        # Create spec message from agent
        %{
          type: :review_request,
          from: %{project: "pactis-agents", agent: String.replace(agent.name, " ", "-")},
          body: format_agent_review_message(parsed_review),
          repository_context: %{
            repository_id: code_review.repository_id,
            code_review_id: code_review.id,
            assessment: parsed_review["assessment"]
          },
          code_ref: extract_code_references(parsed_review["findings"])
        }
        |> create_spec_message(code_review.spec_request_id)
        
      {:error, _} ->
        Logger.warn("Failed to parse agent review response from #{agent.name}")
    end
  end
end
```

### 4. Cross-Service Coordination through Conversations

```elixir
# lib/pactis/spec/service_coordinator.ex
defmodule Pactis.Spec.ServiceCoordinator do
  @moduledoc """
  Coordinates changes across multiple services through conversation-driven consensus.
  When a change in one service affects others, it automatically initiates coordination conversations.
  """
  
  def coordinate_cross_service_change(code_review) do
    # Analyze which services are affected by this change
    affected_services = analyze_service_dependencies(code_review)
    
    if length(affected_services) > 1 do
      initiate_cross_service_conversation(code_review, affected_services)
    else
      {:ok, :no_coordination_needed}
    end
  end
  
  defp analyze_service_dependencies(code_review) do
    # Look for API changes, shared library modifications, database schema changes
    diff_analysis = Pactis.Git.DiffAnalyzer.analyze_service_impact(code_review)
    
    services = []
    
    # Check for API contract changes
    services = if has_api_changes?(diff_analysis) do
      services ++ get_api_consumers(code_review.repository)
    else
      services
    end
    
    # Check for shared library changes
    services = if has_shared_lib_changes?(diff_analysis) do
      services ++ get_library_dependents(code_review.repository)
    else
      services
    end
    
    # Check for database schema changes
    services = if has_schema_changes?(diff_analysis) do
      services ++ get_database_dependents(code_review.repository)
    else
      services
    end
    
    Enum.uniq(services)
  end
  
  defp initiate_cross_service_conversation(code_review, affected_services) do
    # Create a coordination spec request
    coordination_spec = %{
      id: "cross-service-#{code_review.id}",
      project: code_review.repository.name,
      title: "Cross-service coordination: #{code_review.title}",
      workspace_id: code_review.repository.workspace_id,
      metadata: %{
        coordination_type: "cross_service_change",
        primary_change: code_review.id,
        affected_services: affected_services
      }
    }
    
    {:ok, spec_request} = Pactis.Spec.SpecRequest.create(coordination_spec)
    
    # Send initial coordination message
    initial_message = %{
      type: :proposal,
      from: %{project: code_review.repository.name, agent: "change-coordinator"},
      body: build_coordination_message(code_review, affected_services),
      repository_context: %{
        repository_id: code_review.repository_id,
        code_review_id: code_review.id,
        coordination_required: true
      }
    }
    
    Pactis.Spec.SpecMessage.create(spec_request.id, initial_message)
    
    # Notify affected services
    notify_affected_services(spec_request, affected_services, code_review)
    
    {:ok, spec_request}
  end
  
  defp build_coordination_message(code_review, affected_services) do
    """
    ## Cross-Service Change Coordination Required
    
    A change in `#{code_review.repository.name}` affects multiple services and requires coordination:
    
    **Primary Change**: #{code_review.title}
    **Author**: #{code_review.author.name}
    **Branch**: #{code_review.source_branch} → #{code_review.target_branch}
    
    **Affected Services**: #{Enum.join(affected_services, ", ")}
    
    ## Change Summary
    #{code_review.description}
    
    ## Impact Analysis
    #{format_service_impacts(code_review, affected_services)}
    
    ## Required Actions
    Each affected service should:
    1. Review the proposed changes
    2. Assess impact on their service
    3. Identify any required changes in their codebase
    4. Provide timeline for implementation
    5. Approve or request modifications
    
    ## Coordination Process
    This conversation will remain open until:
    - All affected services have acknowledged the change
    - Any required coordinated changes are implemented
    - All services approve the change
    - Deployment sequence is agreed upon
    
    Please respond with your service's assessment and any questions.
    """
  end
  
  defp notify_affected_services(spec_request, services, code_review) do
    Enum.each(services, fn service_name ->
      # Look up service webhook/notification endpoints
      case Pactis.Services.Registry.get_service(service_name) do
        {:ok, service} ->
          # Send notification to service's webhook
          notification = %{
            type: "cross_service_coordination_required",
            spec_request_id: spec_request.id,
            primary_change: %{
              repository: code_review.repository.name,
              title: code_review.title,
              author: code_review.author.name
            },
            conversation_url: "#{PactisWeb.Endpoint.url()}/spec/#{spec_request.id}"
          }
          
          Pactis.Webhooks.send_notification(service.webhook_url, notification)
          
        {:error, :not_found} ->
          Logger.warn("Service #{service_name} not found in registry")
      end
    end)
  end
end
```

### 5. Conversation-Driven Merge Process

```elixir
# lib/pactis/git/conversation_merge.ex
defmodule Pactis.Git.ConversationMerge do
  @moduledoc """
  Executes merges based on conversation consensus rather than traditional merge buttons.
  """
  
  def execute_merge(code_review, merge_strategy, merger_id) do
    # Verify consensus has been reached
    case verify_consensus(code_review) do
      {:ok, :consensus_reached} ->
        perform_conversational_merge(code_review, merge_strategy, merger_id)
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  defp verify_consensus(code_review) do
    spec_request = Pactis.Spec.SpecRequest.get!(code_review.spec_request_id)
    messages = Pactis.Spec.SpecMessage.list_for_request(spec_request.id)
    
    # Analyze conversation for consensus
    consensus_analysis = analyze_conversation_consensus(messages)
    
    cond do
      consensus_analysis.blocking_concerns > 0 ->
        {:error, "Unresolved blocking concerns in conversation"}
      
      consensus_analysis.approval_count < code_review.required_approvals ->
        {:error, "Insufficient approvals in conversation"}
      
      consensus_analysis.cross_service_coordination_pending ->
        {:error, "Cross-service coordination not complete"}
      
      true ->
        {:ok, :consensus_reached}
    end
  end
  
  defp analyze_conversation_consensus(messages) do
    %{
      approval_count: count_approvals(messages),
      blocking_concerns: count_blocking_concerns(messages),
      cross_service_coordination_pending: check_coordination_status(messages),
      agent_reviews_complete: check_agent_reviews(messages),
      test_results: extract_test_results(messages)
    }
  end
  
  defp perform_conversational_merge(code_review, merge_strategy, merger_id) do
    # Create merge commit with conversation context
    merge_message = build_conversational_commit_message(code_review)
    
    case Pactis.Git.Operations.merge_branches(
      code_review.repository_id,
      code_review.source_branch,
      code_review.target_branch,
      merge_strategy,
      merge_message
    ) do
      {:ok, merge_commit} ->
        # Record merge in conversation
        record_merge_in_conversation(code_review, merge_commit, merger_id)
        
        # Notify participants
        notify_merge_completion(code_review, merge_commit)
        
        # Clean up feature branch if requested
        maybe_delete_feature_branch(code_review)
        
        {:ok, merge_commit}
        
      {:error, reason} ->
        # Record merge failure in conversation
        record_merge_failure(code_review, reason)
        {:error, reason}
    end
  end
  
  defp build_conversational_commit_message(code_review) do
    spec_request = Pactis.Spec.SpecRequest.get!(code_review.spec_request_id)
    
    """
    #{code_review.title}
    
    #{code_review.description}
    
    Conversation-Driven Merge Details:
    - Spec Request: #{spec_request.id}
    - Approvals: #{code_review.current_approvals}/#{code_review.required_approvals}
    - Files Changed: #{length(code_review.diff_stats.files)}
    - Lines Added: #{code_review.diff_stats.additions}
    - Lines Removed: #{code_review.diff_stats.deletions}
    
    Conversation URL: #{PactisWeb.Endpoint.url()}/spec/#{spec_request.id}
    
    Co-authored-by: [Generated from conversation participants]
    """
  end
  
  defp record_merge_in_conversation(code_review, merge_commit, merger_id) do
    merger = Pactis.Accounts.User.get!(merger_id)
    
    merge_message = %{
      type: :decision,
      from: %{project: code_review.repository.name, agent: merger.name},
      body: "✅ **Merge Completed**\n\nBranch `#{code_review.source_branch}` successfully merged into `#{code_review.target_branch}`",
      repository_context: %{
        repository_id: code_review.repository_id,
        merge_commit: merge_commit.sha,
        merge_strategy: :squash,
        status: :completed
      }
    }
    
    Pactis.Spec.SpecMessage.create(code_review.spec_request_id, merge_message)
  end
end
```

### 6. Enhanced Web Interface for Conversations

```elixir
# lib/pactis_web/live/code_review_live/show.ex
defmodule PactisWeb.CodeReviewLive.Show do
  use PactisWeb, :live_view
  
  def mount(%{"id" => code_review_id}, _session, socket) do
    code_review = Pactis.Spec.CodeReview.get!(code_review_id)
    spec_request = Pactis.Spec.SpecRequest.get!(code_review.spec_request_id)
    messages = Pactis.Spec.SpecMessage.list_for_request(spec_request.id)
    
    # Subscribe to real-time conversation updates
    PactisWeb.Endpoint.subscribe("spec:#{spec_request.id}")
    
    socket =
      socket
      |> assign(:code_review, code_review)
      |> assign(:spec_request, spec_request)
      |> assign(:messages, messages)
      |> assign(:diff_content, load_diff_content(code_review))
      |> assign(:conversation_active, true)
    
    {:ok, socket}
  end
  
  def handle_info({:new_message, message}, socket) do
    messages = [message | socket.assigns.messages]
    {:noreply, assign(socket, :messages, messages)}
  end
  
  def handle_event("send_message", %{"message" => message_params}, socket) do
    code_review = socket.assigns.code_review
    current_user = socket.assigns.current_user
    
    message = %{
      type: String.to_atom(message_params["type"]),
      from: %{project: code_review.repository.name, agent: current_user.name},
      body: message_params["body"],
      repository_context: %{
        repository_id: code_review.repository_id,
        code_review_id: code_review.id
      }
    }
    
    case Pactis.Spec.SpecMessage.create(code_review.spec_request_id, message) do
      {:ok, _message} ->
        {:noreply, socket}
      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to send message: #{reason}")}
    end
  end
  
  def handle_event("approve_change", _params, socket) do
    code_review = socket.assigns.code_review
    current_user = socket.assigns.current_user
    
    case Pactis.Spec.CodeReview.approve(code_review.id, %{
      reviewer_id: current_user.id,
      review_message: "Approved via conversation interface"
    }) do
      {:ok, updated_review} ->
        socket =
          socket
          |> assign(:code_review, updated_review)
          |> put_flash(:info, "Change approved!")
        {:noreply, socket}
      
      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Approval failed: #{reason}")}
    end
  end
  
  def handle_event("merge_change", %{"merge_strategy" => strategy}, socket) do
    code_review = socket.assigns.code_review
    current_user = socket.assigns.current_user
    
    case Pactis.Spec.CodeReview.merge(code_review.id, %{
      merge_strategy: String.to_atom(strategy),
      merger_id: current_user.id
    }) do
      {:ok, merged_review} ->
        socket =
          socket
          |> assign(:code_review, merged_review)
          |> assign(:conversation_active, false)
          |> put_flash(:info, "Successfully merged!")
        {:noreply, socket}
        
      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Merge failed: #{reason}")}
    end
  end
end
```

### 7. API Extensions for Conversation-Driven Development

```elixir
# lib/pactis_web/router.ex - Add conversation-driven repository routes
scope "/api/v1/repositories/:repository_id", PactisWeb.Api do
  pipe_through :api
  
  # Conversation-driven code review
  resources "/reviews", CodeReviewController, except: [:new, :edit] do
    post "/approve", CodeReviewController, :approve
    post "/merge", CodeReviewController, :merge
    post "/request_changes", CodeReviewController, :request_changes
    get "/conversation", CodeReviewController, :conversation
  end
  
  # Cross-service coordination
  post "/coordinate", ServiceCoordinationController, :initiate_coordination
  get "/coordination/:spec_id", ServiceCoordinationController, :show_coordination
  
  # AI agent integration
  post "/agent_review", AgentReviewController, :trigger_agents
  get "/agent_reviews/:review_id", AgentReviewController, :list_agent_reviews
end

# Service-to-service conversation endpoints
scope "/api/v1/services", PactisWeb.Api do
  pipe_through :api
  
  post "/conversation/join", ServiceConversationController, :join_conversation
  post "/conversation/:spec_id/message", ServiceConversationController, :send_message
  get "/conversation/:spec_id/status", ServiceConversationController, :get_status
end
```

### 8. Integration with Existing Multi-Agent System

```elixir
# lib/pactis/spec/conversation_orchestrator.ex
defmodule Pactis.Spec.ConversationOrchestrator do
  @moduledoc """
  Orchestrates conversations between humans, AI agents, and services.
  Integrates with Astral's multi-agent chatroom system.
  """
  
  def initiate_review_conversation(code_review) do
    # Create multi-agent chatroom for this code review
    chatroom_config = %{
      room_id: "code-review-#{code_review.id}",
      room_name: "Review: #{code_review.title}",
      context: %{
        type: :code_review,
        repository_id: code_review.repository_id,
        code_review_id: code_review.id,
        spec_request_id: code_review.spec_request_id
      }
    }
    
    {:ok, chatroom} = Pactis.Astral.Client.create_chatroom(chatroom_config)
    
    # Invite relevant participants
    participants = determine_review_participants(code_review)
    
    Enum.each(participants, fn participant ->
      case participant.type do
        :human ->
          Pactis.Astral.Client.invite_human(chatroom.room_id, participant.user_id)
        :ai_agent ->
          Pactis.Astral.Client.invite_agent(chatroom.room_id, participant.agent_type)
        :service ->
          Pactis.Services.NotificationService.notify_service(participant.service_name, chatroom)
      end
    end)
    
    # Send initial context to chatroom
    initial_context = %{
      type: :context_share,
      content: build_review_context(code_review),
      description: "Code review context and diff"
    }
    
    Pactis.Astral.Client.send_message(chatroom.room_id, initial_context)
    
    {:ok, chatroom}
  end
  
  defp determine_review_participants(code_review) do
    participants = []
    
    # Always include the author
    participants = [%{type: :human, user_id: code_review.author_id} | participants]
    
    # Include repository maintainers
    maintainers = Pactis.Repositories.Repository.get_maintainers(code_review.repository_id)
    human_participants = Enum.map(maintainers, fn user -> %{type: :human, user_id: user.id} end)
    participants = participants ++ human_participants
    
    # Include relevant AI agents based on code changes
    agent_types = Pactis.Spec.ReviewAgents.determine_relevant_agents(code_review)
    agent_participants = Enum.map(agent_types, fn type -> %{type: :ai_agent, agent_type: type} end)
    participants = participants ++ agent_participants
    
    # Include affected services for cross-service changes
    if length(code_review.affected_services) > 0 do
      service_participants = Enum.map(code_review.affected_services, fn service -> 
        %{type: :service, service_name: service}
      end)
      participants = participants ++ service_participants
    end
    
    participants
  end
end
```

## Database Migrations for Phase 2

```sql
-- Add conversation integration to repositories
ALTER TABLE repositories ADD COLUMN conversation_enabled BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE repositories ADD COLUMN auto_merge_enabled BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE repositories ADD COLUMN required_reviewers INTEGER NOT NULL DEFAULT 1;

-- Code review system
CREATE TABLE code_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL DEFAULT 'draft',
  repository_id UUID NOT NULL REFERENCES repositories(id),
  source_branch TEXT NOT NULL,
  target_branch TEXT NOT NULL,
  head_commit TEXT,
  base_commit TEXT,
  spec_request_id TEXT NOT NULL,
  auto_merge_eligible BOOLEAN NOT NULL DEFAULT false,
  required_approvals INTEGER NOT NULL DEFAULT 1,
  current_approvals INTEGER NOT NULL DEFAULT 0,
  author_id UUID NOT NULL REFERENCES users(id),
  diff_stats JSONB NOT NULL DEFAULT '{}',
  affected_services TEXT[] NOT NULL DEFAULT '{}',
  breaking_changes BOOLEAN NOT NULL DEFAULT false,
  test_coverage_delta DECIMAL,
  security_score DECIMAL,
  performance_impact JSONB,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_code_reviews_repository_id ON code_reviews(repository_id);
CREATE INDEX idx_code_reviews_spec_request_id ON code_reviews(spec_request_id);
CREATE INDEX idx_code_reviews_status ON code_reviews(status);
CREATE INDEX idx_code_reviews_author_id ON code_reviews(author_id);

-- Review approvals
CREATE TABLE review_approvals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code_review_id UUID NOT NULL REFERENCES code_reviews(id),
  reviewer_id UUID NOT NULL REFERENCES users(id),
  status TEXT NOT NULL, -- approved, changes_requested, commented
  message TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_review_approvals_unique ON review_approvals(code_review_id, reviewer_id);

-- Review comments (code-specific)
CREATE TABLE review_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code_review_id UUID NOT NULL REFERENCES code_reviews(id),
  author_id UUID NOT NULL REFERENCES users(id),
  file_path TEXT NOT NULL,
  line_number INTEGER,
  body TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_review_comments_code_review_id ON review_comments(code_review_id);
CREATE INDEX idx_review_comments_author_id ON review_comments(author_id);

-- Extend spec_messages with repository context
ALTER TABLE spec_messages ADD COLUMN repository_context JSONB;
ALTER TABLE spec_messages ADD COLUMN code_ref JSONB;

-- Service registry for cross-service coordination
CREATE TABLE service_registry (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  webhook_url TEXT,
  api_base_url TEXT,
  description TEXT,
  maintainer_team TEXT,
  dependencies TEXT[] NOT NULL DEFAULT '{}',
  dependents TEXT[] NOT NULL DEFAULT '{}',
  active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_service_registry_name ON service_registry(name);
CREATE INDEX idx_service_registry_active ON service_registry(active);
```

## Implementation Strategy

### Week 1-2: Core Conversation Integration
1. Extend SpecMessage types for repository operations
2. Create CodeReview resource and basic workflow
3. Database migrations and core models

### Week 3-4: AI Agent Integration  
1. Implement ReviewAgents system
2. LLM integration for automated code analysis
3. Agent message creation and conversation participation

### Week 5-6: Cross-Service Coordination
1. ServiceCoordinator for multi-service changes
2. Service registry and notification system
3. Cross-service conversation orchestration

### Week 7-8: Web Interface and Integration
1. Conversation-driven review interface
2. Real-time updates and notifications
3. Integration with existing Spec API UI

### Week 9-10: Advanced Features
1. Conversation-driven merge system
2. Integration with Astral multi-agent chatrooms
3. Performance optimization and caching

This phase transforms Pactis from a traditional Git platform into a genuinely conversation-driven development platform where all coordination happens through structured semantic conversations rather than traditional development ceremonies.
