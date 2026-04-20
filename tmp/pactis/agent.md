# Agent Action Planning Dashboard - Full Workflow System

## Overview
Transform the existing Dynamic Personal Productivity Dashboard into a comprehensive **Planning → Work Item → Action Plan → Progress → Status** system that bridges human intent (markdown specs) with agent actions and real code execution.

## Core Workflow Integration

### 1. Planning Phase (Input)
```
┌─ Planning Pane ──────────────────────────────────────────────────┐
│ 📝 New Planning Input                                            │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ # Pactis Documentation Consolidation                         │ │
│ │                                                             │ │
│ │ ## Objective                                                │ │
│ │ Scan codebase, consolidate docs, create unified system...  │ │
│ │                                                             │ │
│ │ [Paste Markdown] [Upload File] [Voice Input] [AI Generate] │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
│ 🤖 AI Planning Assistant: "I see you want to consolidate docs.   │
│    This will involve 4 phases. Should I break this down?"        │
│                                                                   │
│ [✓ Auto-Generate Work Items] [Manual Edit] [Save as Template]    │
└───────────────────────────────────────────────────────────────────┘
```

### 2. Work Item Generation (Breakdown)
```
┌─ Work Items Pane ────────────────────────────────────────────────┐
│ 📋 Generated from: "Pactis Documentation Consolidation"           │
│                                                                   │
│ ┌─ Phase 1: Discovery & Audit ─────────────────────────────────┐ │
│ │ ⚪ WI-001: Scan all .md files in codebase                    │ │
│ │ ⚪ WI-002: Extract @moduledoc from Elixir files              │ │
│ │ ⚪ WI-003: Find architectural decisions in comments          │ │
│ │ └─ Est: 2 hours │ Agent: Claude Code │ Status: Ready          │ │
│ └───────────────────────────────────────────────────────────────┘ │
│                                                                   │
│ ┌─ Phase 2: Consolidation ──────────────────────────────────────┐ │
│ │ ⚪ WI-004: Create unified docs/ structure                    │ │
│ │ ⚪ WI-005: Merge duplicate information                       │ │
│ │ └─ Depends on: WI-001, WI-002 │ Est: 3 hours                  │ │
│ └───────────────────────────────────────────────────────────────┘ │
│                                                                   │
│ [Assign to Agent] [Schedule] [Edit Breakdown] [View Dependencies] │
└───────────────────────────────────────────────────────────────────┘
```

### 3. Action Plan Execution (Real-Time)
```
┌─ Agent Action Monitor ───────────────────────────────────────────┐
│ 🤖 Claude Code executing: WI-001 "Scan all .md files"           │
│                                                                   │
│ ┌─ Live Agent Reasoning ────────────────────────────────────────┐ │
│ │ 🧠 Planning: Finding .md files in project structure...       │ │
│ │ 📁 Scanning: /docs, /lib, /config, /priv                    │ │
│ │ ✅ Found: README.md, ARCHITECTURE.md, 3 other files         │ │
│ │ 🤔 Decision: Skipping node_modules (too large)              │ │
│ │ ⚠️  Issue: Found conflicting info in 2 files                │ │
│ └───────────────────────────────────────────────────────────────┘ │
│                                                                   │
│ ┌─ File Changes (Real-Time) ────────────────────────────────────┐ │
│ │ 📝 docs/discovery-report.md      [Created]                   │ │
│ │ 📝 docs/file-inventory.json      [Created]                   │ │
│ │ 📝 docs/conflicts-found.md       [Created]                   │ │
│ └───────────────────────────────────────────────────────────────┘ │
│                                                                   │
│ [Pause Agent] [Clarify Issue] [Override Decision] [Continue]      │
└───────────────────────────────────────────────────────────────────┘
```

### 4. Progress Tracking (Status)
```
┌─ Progress Dashboard ─────────────────────────────────────────────┐
│ 📊 Pactis Documentation Consolidation                             │
│                                                                   │
│ Overall Progress: ████████░░░░ 67% (4/6 phases complete)        │
│                                                                   │
│ ┌─ Phase Status ────────────────────────────────────────────────┐ │
│ │ ✅ Phase 1: Discovery      100% │ 4/4 work items complete    │ │
│ │ ✅ Phase 2: Consolidation  100% │ 2/2 work items complete    │ │
│ │ 🔄 Phase 3: Implementation  45% │ 2/5 work items in progress │ │
│ │ ⏳ Phase 4: Validation       0% │ 0/3 work items started     │ │
│ └───────────────────────────────────────────────────────────────┘ │
│                                                                   │
│ ┌─ Deliverables Status ─────────────────────────────────────────┐ │
│ │ ✅ Consolidated docs/ directory                               │ │
│ │ ✅ Implementation gap analysis report                         │ │
│ │ 🔄 Updated project README (75% complete)                     │ │
│ │ ⏳ Documentation maintenance tools                            │ │
│ │ ⏳ Action plan for addressing gaps                            │ │
│ └───────────────────────────────────────────────────────────────┘ │
│                                                                   │
│ [View Detailed Report] [Export Status] [Schedule Review]         │
└───────────────────────────────────────────────────────────────────┘
```

## Enhanced Dashboard Architecture

### Elixir/Phoenix Implementation

```elixir
# Enhanced Action Plan Resource
defmodule Dashboard.ActionPlans.ActionPlan do
  use Ash.Resource,
    domain: Dashboard.Core,
    data_layer: AshPostgres.DataLayer

  attributes do
    uuid_primary_key :id
    attribute :title, :string, allow_nil?: false
    attribute :description, :string
    attribute :source_type, :atom, constraints: [one_of: [:markdown_spec, :manual, :ai_generated]]
    attribute :source_content, :string # Original markdown/input
    attribute :priority, :atom, constraints: [one_of: [:low, :medium, :high, :urgent]]
    attribute :status, :atom, constraints: [one_of: [:planning, :ready, :in_progress, :blocked, :completed]]
    attribute :overall_progress, :integer, default: 0
    attribute :estimated_duration, :integer # minutes
    attribute :actual_duration, :integer
    attribute :agent_assigned, :string # "claude_code", "human", etc.

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    has_many :work_items, Dashboard.ActionPlans.WorkItem
    has_many :agent_actions, Dashboard.AgentActions.Action
    belongs_to :user, Dashboard.Accounts.User
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    read :active do
      filter expr(status != :completed)
    end

    update :update_progress do
      change Dashboard.ActionPlans.Changes.CalculateProgress
    end
  end
end

# Work Item Resource
defmodule Dashboard.ActionPlans.WorkItem do
  use Ash.Resource,
    domain: Dashboard.Core,
    data_layer: AshPostgres.DataLayer

  attributes do
    uuid_primary_key :id
    attribute :title, :string, allow_nil?: false
    attribute :description, :string
    attribute :phase, :string
    attribute :order_index, :integer
    attribute :status, :atom, constraints: [one_of: [:ready, :in_progress, :blocked, :completed]]
    attribute :progress_percentage, :integer, default: 0
    attribute :estimated_hours, :decimal
    attribute :actual_hours, :decimal
    attribute :agent_assigned, :string
    attribute :blocking_reason, :string

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :action_plan, Dashboard.ActionPlans.ActionPlan
    has_many :dependencies, Dashboard.ActionPlans.WorkItemDependency, destination_attribute: :dependent_item_id
    has_many :agent_actions, Dashboard.AgentActions.Action
  end
end

# Agent Action Tracking
defmodule Dashboard.AgentActions.Action do
  use Ash.Resource,
    domain: Dashboard.Core,
    data_layer: AshPostgres.DataLayer

  attributes do
    uuid_primary_key :id
    attribute :agent_name, :string, allow_nil?: false # "claude_code"
    attribute :action_type, :atom, constraints: [one_of: [:planning, :executing, :file_change, :decision, :issue]]
    attribute :description, :string
    attribute :reasoning, :string # Why the agent made this decision
    attribute :file_path, :string # If it's a file change
    attribute :before_content, :string
    attribute :after_content, :string
    attribute :metadata, :map, default: %{}
    attribute :status, :atom, constraints: [one_of: [:in_progress, :completed, :failed, :paused]]

    create_timestamp :inserted_at
  end

  relationships do
    belongs_to :action_plan, Dashboard.ActionPlans.ActionPlan
    belongs_to :work_item, Dashboard.ActionPlans.WorkItem
  end
end
```

### LiveView Components

```elixir
# Main Dashboard LiveView
defmodule DashboardWeb.MainLive do
  use DashboardWeb, :live_view

  def mount(_params, _session, socket) do
    # Subscribe to real-time agent actions
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Dashboard.PubSub, "agent_actions")
      Phoenix.PubSub.subscribe(Dashboard.PubSub, "work_item_updates")
    end

    {:ok,
     socket
     |> assign(:active_action_plans, load_active_action_plans())
     |> assign(:agent_monitor, %{active: false, current_action: nil})
     |> assign(:pane_layouts, initial_pane_layouts())
     |> assign(:chat_panel_open, false)}
  end

  # Handle real-time agent action updates
  def handle_info({:agent_action, action}, socket) do
    {:noreply,
     socket
     |> update(:agent_monitor, fn monitor ->
       %{monitor | active: true, current_action: action}
     end)
     |> push_event("agent_action_update", %{
       action: action,
       timestamp: DateTime.utc_now()
     })}
  end

  # Handle work item progress updates
  def handle_info({:work_item_progress, work_item_id, progress}, socket) do
    {:noreply,
     socket
     |> update(:active_action_plans, fn plans ->
       update_work_item_progress(plans, work_item_id, progress)
     end)}
  end

  # Create action plan from markdown input
  def handle_event("create_action_plan", %{"markdown" => markdown_content}, socket) do
    case Dashboard.PlanningAI.generate_action_plan(markdown_content) do
      {:ok, action_plan} ->
        {:noreply,
         socket
         |> put_flash(:info, "Action plan created with #{length(action_plan.work_items)} work items")
         |> assign(:active_action_plans, load_active_action_plans())}

      {:error, error} ->
        {:noreply, put_flash(socket, :error, "Failed to create action plan: #{error}")}
    end
  end

  # Assign work item to agent
  def handle_event("assign_to_agent", %{"work_item_id" => id, "agent" => agent}, socket) do
    work_item = Dashboard.ActionPlans.WorkItem.get!(id)
    Dashboard.ActionPlans.WorkItem.update!(work_item, %{agent_assigned: agent, status: :ready})

    # Trigger agent execution
    Dashboard.AgentOrchestrator.execute_work_item(work_item, agent)

    {:noreply,
     socket
     |> put_flash(:info, "Work item assigned to #{agent}")
     |> assign(:active_action_plans, load_active_action_plans())}
  end
end

# Agent Action Monitor Component
defmodule DashboardWeb.Components.AgentMonitor do
  use DashboardWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="agent-monitor bg-gray-900 text-green-400 p-4 rounded-lg font-mono">
      <div class="flex items-center gap-2 mb-3">
        <div class="w-3 h-3 bg-green-400 rounded-full animate-pulse"></div>
        <span class="text-sm">Agent Active: <%= @agent_name %></span>
      </div>

      <div class="space-y-2">
        <div class="text-xs opacity-75">Current Action:</div>
        <div class="text-sm"><%= @current_action.description %></div>

        <div class="text-xs opacity-75 mt-3">Reasoning:</div>
        <div class="text-sm text-blue-300"><%= @current_action.reasoning %></div>

        <div :if={@current_action.file_path} class="text-xs opacity-75 mt-3">
          File: <span class="text-yellow-300"><%= @current_action.file_path %></span>
        </div>
      </div>

      <div class="flex gap-2 mt-4">
        <button class="btn btn-sm bg-red-600 hover:bg-red-700">Pause</button>
        <button class="btn btn-sm bg-blue-600 hover:bg-blue-700">Clarify</button>
        <button class="btn btn-sm bg-green-600 hover:bg-green-700">Continue</button>
      </div>
    </div>
    """
  end
end

# Progress Visualization Component
defmodule DashboardWeb.Components.ProgressDashboard do
  use DashboardWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="progress-dashboard bg-white p-6 rounded-lg shadow-lg">
      <h3 class="text-lg font-bold mb-4"><%= @action_plan.title %></h3>

      <!-- Overall Progress -->
      <div class="mb-6">
        <div class="flex justify-between text-sm mb-1">
          <span>Overall Progress</span>
          <span><%= @action_plan.overall_progress %>%</span>
        </div>
        <div class="w-full bg-gray-200 rounded-full h-3">
          <div class="bg-blue-600 h-3 rounded-full transition-all duration-300"
               style={"width: #{@action_plan.overall_progress}%"}></div>
        </div>
      </div>

      <!-- Phase Status -->
      <div class="space-y-3">
        <div :for={phase <- @phases} class="border rounded p-3">
          <div class="flex justify-between items-center mb-2">
            <span class="font-medium"><%= phase.name %></span>
            <span class={"badge " <> status_color(phase.status)}><%= phase.status %></span>
          </div>

          <div class="text-sm text-gray-600 mb-2">
            <%= phase.completed_items %>/<%= phase.total_items %> work items complete
          </div>

          <div class="w-full bg-gray-200 rounded-full h-2">
            <div class={"h-2 rounded-full transition-all " <> progress_color(phase.progress)}
                 style={"width: #{phase.progress}%"}></div>
          </div>
        </div>
      </div>

      <!-- Deliverables -->
      <div class="mt-6">
        <h4 class="font-medium mb-3">Deliverables Status</h4>
        <div class="space-y-2">
          <div :for={deliverable <- @deliverables} class="flex items-center gap-2">
            <div class={"w-4 h-4 rounded-full " <> deliverable_status_color(deliverable.status)}></div>
            <span class="text-sm"><%= deliverable.name %></span>
            <span :if={deliverable.progress < 100} class="text-xs text-gray-500">
              (<%= deliverable.progress %>% complete)
            </span>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
```

### Chat Panel Integration

```elixir
# Enhanced Chat Panel with Planning Context
defmodule DashboardWeb.Components.ChatPanel do
  use DashboardWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="chat-panel fixed right-0 top-0 h-full w-96 bg-white shadow-xl border-l">
      <!-- Chat Header -->
      <div class="p-4 border-b bg-gray-50">
        <div class="flex justify-between items-center">
          <h3 class="font-medium">Planning Assistant</h3>
          <button phx-click="close_chat_panel" class="text-gray-500 hover:text-gray-700">×</button>
        </div>

        <!-- Context Indicators -->
        <div class="mt-2 flex gap-2">
          <span class="text-xs bg-blue-100 text-blue-700 px-2 py-1 rounded">
            Context: <%= @current_context.type %>
          </span>
          <span :if={@active_action_plan} class="text-xs bg-green-100 text-green-700 px-2 py-1 rounded">
            Action Plan Active
          </span>
        </div>
      </div>

      <!-- Relevant Past Chats -->
      <div class="p-4 border-b bg-gray-50">
        <h4 class="text-sm font-medium mb-2">Relevant Previous Discussions</h4>
        <div class="space-y-2">
          <div :for={chat <- @relevant_chats} class="text-xs">
            <a href="#" class="text-blue-600 hover:underline"
               phx-click="load_relevant_chat" phx-value-chat-id={chat.id}>
              <%= chat.title %>
            </a>
            <div class="text-gray-500"><%= chat.relevance_reason %></div>
          </div>
        </div>
      </div>

      <!-- Chat Messages -->
      <div class="flex-1 overflow-y-auto p-4 space-y-4">
        <div :for={message <- @chat_messages} class={"message " <> message_class(message.role)}>
          <div class="text-sm"><%= message.content %></div>

          <!-- Action Buttons for AI Suggestions -->
          <div :if={message.role == :assistant && message.suggestions} class="mt-2 space-y-1">
            <button :for={suggestion <- message.suggestions}
                    class="btn btn-xs btn-outline w-full text-left"
                    phx-click="apply_suggestion"
                    phx-value-suggestion={suggestion.action}>
              <%= suggestion.text %>
            </button>
          </div>
        </div>
      </div>

      <!-- Chat Input -->
      <div class="p-4 border-t">
        <form phx-submit="send_chat_message" class="space-y-2">
          <textarea name="message" placeholder="Ask about planning, get suggestions, or paste markdown specs..."
                    class="w-full p-2 border rounded text-sm" rows="3"></textarea>
          <div class="flex gap-2">
            <button type="submit" class="btn btn-sm btn-primary flex-1">Send</button>
            <button type="button" class="btn btn-sm btn-outline"
                    phx-click="toggle_voice_input">🎤</button>
          </div>
        </form>
      </div>
    </div>
    """
  end
end
```

## Key Features Integration

### 1. **Markdown → Work Items Flow**
- Paste any planning markdown into dashboard
- AI automatically breaks down into actionable work items
- Creates dependencies and estimates

### 2. **Agent Action Visualization**
- Real-time view of what Claude Code is thinking/doing
- File changes tracked and attributed to work items
- Ability to pause/clarify/override agent decisions

### 3. **Progress Tracking**
- Visual progress bars for phases and overall completion
- Deliverables checklist with status indicators
- Time estimates vs. actual tracking

### 4. **Contextual Chat Integration**
- AI assistant that understands current planning context
- Suggests relevant past conversations
- Can generate action plans from chat discussions

### 5. **Status Dashboard**
- Real-time status of all active planning initiatives
- Dependency tracking and blocking issue identification
- Integration with agent execution status

## What This Solves

### The "Agent Action Gap"
- **"What is the agent actually doing?"** - Live reasoning display
- **"Did it follow my specs?"** - Work item to code traceability
- **"What's implemented vs. planned?"** - Status dashboard with deliverables
- **"Where did this code come from?"** - File changes attributed to work items
- **"Is the agent stuck?"** - Blocking issue detection and intervention

### Complete Workflow Visibility
```
Planning Input → Work Items → Agent Execution → Real-time Monitoring → Status Tracking
      ↑                                                                        ↓
   (markdown)                                                            (deliverables)
```

This creates a complete **Planning → Execution → Tracking** system that bridges the gap between human intent (markdown specs) and agent actions (real code changes), all within your existing dynamic dashboard framework.

## Implementation Benefits

### 1. **Solves Industry Gap**
- **Real-time agent reasoning display** - see what Claude Code is thinking
- **File change attribution** - every code change links back to work items
- **Interactive debugging** - pause/clarify/override agent decisions mid-task

### 2. **Bridges Markdown Specs to Reality**
- **Paste any planning markdown** → automatically generates work items
- **Traceability links** - every piece of code traces back to original intent
- **Implementation diff tracking** - what's planned vs. what's built

### 3. **Enhanced Dashboard Architecture**
- **Builds on existing dockable panes system**
- **Integrates with chat panel** for contextual AI assistance
- **Maintains process lifecycle approach**

This essentially creates the **missing layer** between human planning and agent execution that doesn't exist in current AI development tools. It's both a productivity dashboard AND an agent development environment.
