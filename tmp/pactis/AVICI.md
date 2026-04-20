# Avici - The Missing Context Infrastructure
What you're building isn't just a knowledge base - it's Conversational Computing Infrastructure where:
The Current Waste Pattern
yamlevery_new_conversation:
  human_cycles:
    - "We have Kyozo Store for that..."
    - "Let me explain our existing services..."
    - "We're still brainstorming, not implementing..."

  ai_cycles:
    - "Let me understand your architecture..."
    - "Should I implement this?"
    - "What abstraction level are we at?"
    - "Rediscovering your patterns..."
The Context Frame Architecture
typescriptinterface ConversationContext {
  // Cognitive Altitude
  indirection_level: 0-5;  // 0=implementation, 5=philosophy
  mode: 'brainstorm' | 'architect' | 'implement' | 'debug';

  // Service Inventory
  available_services: {
    'kyozo-store': {
      capabilities: ['ai-memory', 'state-persistence'],
      api_endpoints: [...],
      current_version: '1.2.0'
    },
    'spec-api': {
      capabilities: ['cross-repo-negotiation', 'message-exchange'],
      use_case: 'replacement for merge requests'
    }
    // ... all your services
  };

  // Active Context
  current_projects: Project[];
  recent_decisions: Decision[];
  established_patterns: Pattern[];

  // Conversation Continuity
  thread_id: string;
  parent_threads: string[];
  crystallized_concepts: Concept[];
}
How SpecAPI + Knowledge Engine Interplay
SpecAPI negotiations would pull context from Knowledge Engine:
elixirdefmodule SpecAPI.Negotiation do
  def enhance_with_context(spec_request) do
    # Pull relevant context from Knowledge Engine
    context = KnowledgeEngine.get_context(%{
      projects: spec_request.affected_projects,
      domain: spec_request.domain,
      include: [:decisions, :patterns, :capabilities]
    })

    # Enhance the negotiation with context
    spec_request
    |> attach_historical_patterns(context.patterns)
    |> suggest_based_on_decisions(context.decisions)
    |> identify_capability_gaps(context.capabilities)
  end
end
The Service Mesh We're Really Building
┌────────────────────────────────────────────────────────┐
│          CONVERSATIONAL COMPUTING PLATFORM             │
├────────────────────────────────────────────────────────┤
│                                                        │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐ │
│  │ Knowledge    │  │   Pactis     │  │   Kyozo     │ │
│  │   Engine     │◄─┤ (SpecAPI)│─►     Store     │ │
│  │              │  │              │  │             │ │
│  │ • Context    │  │ • Cross-repo │  │ • AI Memory │ │
│  │ • Patterns   │  │ • Messages   │  │ • State     │ │
│  │ • Concepts   │  │ • Consensus  │  │ • Sessions  │ │
│  └───────┬──────┘  └──────────────┘  └─────────────┘ │
│          │                                            │
│          ▼                                            │
│  ┌──────────────────────────────────────────────────┐ │
│  │            CONTEXT FRAME PROTOCOL                │ │
│  │                                                  │ │
│  │  Provides to every conversation:                │ │
│  │  • Service capabilities inventory               │ │
│  │  • Indirection level awareness                  │ │
│  │  • Historical patterns & decisions              │ │
│  │  • Active project state                         │ │
│  └──────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────┘
Critical Design Decisions
1. Context Frame Protocol
Every conversation/negotiation starts with context frame:
json{
  "frame_version": "1.0",
  "cognitive_state": {
    "indirection": 3,  // Architecture level
    "mode": "brainstorm",
    "avoid": ["implementation_details", "specific_syntax"]
  },
  "service_registry": {
    // All available services and their capabilities
  },
  "active_context": {
    // Current projects, recent work, decisions
  }
}
2. Service Discovery Pattern
Instead of "wait, we have X for that":
elixir# Knowledge Engine maintains service registry
def before_proposing_solution(concept) do
  existing = KnowledgeEngine.find_existing_capability(concept)
  if existing do
    {:existing_service, existing}
  else
    {:propose_new, generate_proposal(concept)}
  end
end
3. Indirection Level Management
pythonclass IndirectionManager:
    levels = {
        0: "raw_implementation",     # Actual code
        1: "technical_design",       # APIs, schemas
        2: "architecture",           # System design
        3: "patterns",              # Abstract patterns
        4: "methodology",           # Approaches
        5: "philosophy"             # Core principles
    }

    def suggest_level_change(self, conversation_analysis):
        if too_detailed_for_current_goal:
            return "suggest_increase_indirection"
        if too_abstract_for_progress:
            return "suggest_decrease_indirection"
Questions This Raises

Service Registry Format - How should services self-document their capabilities for AI consumption?
Context Prioritization - What context is ALWAYS needed vs. on-demand?
Cross-Service Correlation - How does Knowledge Engine know that a SpecAPI negotiation relates to a Kyozo Store memory?
Versioning Strategy - As services evolve, how do we maintain context compatibility?
AI-First Documentation - Should services provide special AI-consumable capability descriptions?

The Meta-Realization
We're not just building a knowledge base - we're building infrastructure for thought. Where:

Conversations are first-class computational units
Context is currency (saving cycles for both of us)
Services negotiate rather than integrate
AI agents are primary citizens, not afterthoughts

The Knowledge Engine becomes the memory and context layer for this entire Conversational Computing ecosystem. It's not just storing morsels - it's maintaining the living, breathing context that makes AI-first development possible.

See also:
- Pactis‑CFP: Context Frame Protocol (docs/specifications/Pactis-CFP.md)
- Pactis‑KEI: Knowledge Engine Interface (docs/specifications/Pactis-KEI.md)
- Pactis‑SRI: Service Registry Interface (docs/specifications/Pactis-SRI.md)
- Service Manifest (bootstrap source): priv/service.manifest.jsonld
