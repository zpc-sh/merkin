
```
Codex Guardrails & Handoff (v0)

Purpose
- Keep Codex contributions deterministic, offline‑first, and repo‑local.
- Provide a simple, file‑based spec handoff that other Codex agents can consume.

Spec Handoff Protocol
- Requests live under `work/spec_requests/<id>/` with:
  - `request.json`: the spec request (see schema)
  - `proposed.status|accepted.status|in_progress.status|done.status|rejected.status`
  - `attachments/`: any referenced files (proposals, examples)
- IDs: `<timestamp>_<project>_<slug>_<short-hash>` (deterministic, sortable)
- Projects: `jsonld`, `markdown_ld` (extend as needed)

Patch Proposals (agent‑fast)
- Messages of type `proposal` may attach a `patch.json` with JSON Pointer ops:
  {
    "file": "relative/path.json",             // optional if message.ref.path present
    "base_pointer": "/api",                   // optional; defaults to message.ref.json_pointer
    "ops": [
      {"op": "replace", "path": "/hash", "value": "..."},
      {"op": "add",     "path": "/foo/0", "value": {"k": 1}},
      {"op": "remove",  "path": "/old"}
    ]
  }
- Apply locally with: `mix spec.apply --id <id> [--source inbox] [--target /path/to/repo]`
  - Safe, one‑shot, offline; writes updated JSON with pretty formatting

Schema
- `work/spec_requests/schema.json` — validated shape for `request.json`.
- Required: `project`, `title`, `api`, `acceptance`, `meta`.

Mix Tasks
- `mix spec.new <jsonld|markdown_ld> --title "..." [--slug slug] [--motivation "..."] [--priority high] [--version v1]`
  - Creates `work/spec_requests/<id>/request.json` and `proposed.status`.
- `mix spec.attach --to <id> --file path/to/file`
  - Copies to `attachments/` and updates `request.json.attachments`.
- `mix spec.status --id <id> --set proposed|accepted|in_progress|implemented|rejected|blocked`
  - Creates a corresponding `.status` marker (multiple allowed for trail).
- `mix spec.push --id <id> [--dest /path/to/other/repo/work/spec_requests]`
  - Copies the entire folder to destination; defaults to `$SPEC_HANDOFF_DIR` if not given.
- Messages & threads
  - `mix spec.msg.new|push|pull` — author and sync messages
  - `mix spec.thread.render` — synthesize a single `thread.md` from request + messages
  - `mix spec.sync` / `mix spec.autosync` — one‑shot both‑ways sync and render
  - `mix spec.say` — create → push → render in one command
  - `mix spec.apply` — apply JSON Pointer patch proposals to target files
  - `mix spec.lint` — quick validation of JSONs, attachments, and thread rendering

Example Flow
1) Create request
   - `mix spec.new jsonld --title "URDNA2015 canonicalization + hashing"`
2) Attach proposal
   - `mix spec.attach --to <id> --file work/jsonld_spec_proposals.md`
3) Mark accepted and push to target repo
   - `mix spec.status --id <id> --set accepted`
   - `SPEC_HANDOFF_DIR=../jsonld-repo/work/spec_requests mix spec.push --id <id>`

Target Repo Hints (for receiving Codex)
- Watch `work/spec_requests/*/request.json` & `*.status`.
- On acceptance, drop `ack.json` with ETA and contact; update status trail as work progresses.

Operational Guardrails (reminder)
- No long‑running processes (`mix phx.server` forbidden). Prefer one‑shot tasks.
- Offline‑first: avoid network fetches by default; allowlists for exceptions.
- Determinism: prefer canonical encodings and stable ordering for any generated artifacts.

Git Tracking (suggested defaults)
- Commit (tracked):
  - Protocol & tasks: `AGENTS.codex.md`, `lib/mix/tasks/spec*.ex`, schemas under `work/spec_requests/*.schema.json`
  - Requests lifecycle: `work/spec_requests/<id>/request.json`, status markers (`*.status`), `ack.json`, attachments (e.g., `patch.json`) that represent applied/decided changes
- Ignore (ephemeral):
  - `work/spec_requests/*/inbox/`, `work/spec_requests/*/outbox/` (message transport)
  - `work/spec_requests/*/thread.md` (regenerate anytime via `mix spec.thread.render`)
  - Optional: temporary attachments or scratch notes (use subfolders like `attachments/tmp/`)
- CI idea: validate tracked JSONs and ensure `thread.md` regenerates cleanly (`mix spec.lint --id <id>`)
```

```
AI_AGENT_LSP_COMPARISON_FRAMEWORK.md:21:   - Scenarios cover: legacy modernization, dependency resolution, security audits, etc.
AI_AGENT_LSP_COMPARISON_FRAMEWORK.md:179:scenarios = [:legacy_modernization, :security_audit, :performance_hunt]
DEBUG_HARNESS.md:215:- **Capabilities** negotiated with clients
assets/js/app.js:166:            this.fallbackCopy(text);
assets/js/app.js:169:          const ok = this.fallbackCopy(text);
assets/js/app.js:175:    fallbackCopy(text) {
assets/js/lsp_editor_hooks.js:15:      // safety fallback: if nothing initialized after 1500ms, use textarea
assets/js/lsp_editor_hooks.js:17:        this.__fallbackTimer = setTimeout(() => {
assets/js/lsp_editor_hooks.js:18:          if (!this.__initialized && !this.__fallbackTextarea) {
assets/js/lsp_editor_hooks.js:19:            console.warn('[LspRecurseEditor] init timeout; switching to fallback textarea')
assets/js/lsp_editor_hooks.js:26:        // Graceful fallback editor if dynamic import fails
assets/js/lsp_editor_hooks.js:48:            console.warn('[LspRecurseEditor] CDN import failed; using fallback textarea editor')
assets/js/lsp_editor_hooks.js:56:        console.warn('[LspRecurseEditor] RecurseEditor global missing; using fallback textarea editor')
assets/js/lsp_editor_hooks.js:185:      try { clearTimeout(this.__fallbackTimer) } catch (_) {}
assets/js/lsp_editor_hooks.js:198:      } else if (this.__fallbackTextarea) {
assets/js/lsp_editor_hooks.js:199:        if (this.__fallbackTextarea.value !== newContent) {
assets/js/lsp_editor_hooks.js:200:          this.__fallbackTextarea.value = newContent
assets/js/lsp_editor_hooks.js:392:      this.__fallbackTextarea = textarea
assets/js/lsp_editor_hooks.js:394:        console.info('[LspRecurseEditor] using fallback textarea editor', {
assets/js/lsp_editor_hooks.js:400:      try { this.pushEvent('editor_status', { engine: 'fallback', host: this.el?.id || null }) } catch (_) {}
assets/js/lsp_editor_hooks.js:401:      try { clearTimeout(this.__fallbackTimer) } catch (_) {}
assets/js/lsp_editor_hooks.js:831:            console.warn(`TipTap CDN fallback failed for: ${spec}`, cdnErr)
assets/js/lsp_editor_hooks.js:906:        // Try CDN fallback for highlight/lowlight
assets/js/lsp_editor_hooks.js:1066:    // Prefer real RecurseEditor if globally available, otherwise attempt dynamic import + CDN fallback
assets/js/lsp_editor_hooks.js:1079:      console.warn('Failed to initialize RecurseEditor; using fallback', e);
assets/js/lsp_editor_hooks.js:1098:        console.warn('CDN fallback for RecurseEditor failed', cdnErr);
assets/js/lsp_editor_hooks.js:1234:    console.log('Setting up fallback editor...');
assets/js/lsp_editor_hooks.js:1235:    // Create fallback textarea if Recurse is not available
work/jsonld_spec_proposals.md:5:- Provide deterministic fallbacks (stable JSON), explicit error types, and telemetry.
work/_archive_20250831_121800/mcp_broker_implementation_analysis.md:81:- Included server capability negotiation
work/_archive_20250831_121800/mcp_broker_implementation_analysis.md:101:   - Comprehensive audit logging
work/_archive_20250831_121800/mcp_broker_implementation_analysis.md:300:- Comprehensive audit logging
AGENTS.md:422:- **Always** provide fallbacks for NIF failures
work/_archive_20250831_121800/lang_locker.md:172:  action_fallback LangWeb.Api.FallbackController
work/_archive_20250831_121800/multi_agent_orchestration.md:33:- Code security auditing
work/_archive_20250831_121800/multi_agent_orchestration.md:123:  "security_audit" => [:security_agent, :claude],
work/_archive_20250831_121800/multi_agent_orchestration.md:332:  "security_audit" => %{
work/_archive_20250831_121800/multi_agent_orchestration.md:456:- **Agent Availability**: Implement fallback strategies and graceful degradation
work/_archive_20250831_121800/kyozo_core_locker_storage_requirements.md:467:- Encryption security audit
work/_archive_20250831_121800/mcp_broker_deployment_guide.md:807:- [ ] Regular security audits
docs/CRITICAL_FIXES_IMPLEMENTED.md:152:- Missing `available?/0` methods in providers (fallback logic handles this)
docs/CRITICAL_FIXES_IMPLEMENTED.md:210:- Added fallback text parsing for unsupported formats
docs/CRITICAL_FIXES_IMPLEMENTED.md:229:- **Parser System**: Multi-format parsing with intelligent fallbacks
docs/CRITICAL_FIXES_IMPLEMENTED.md:268:- ✅ Multi-provider AI routing with fallbacks
docs/business-roadmap.md:354:- **Security breaches** → Continuous security audits
docs/BINARY_BLOB_PATTERN.md:94:> be fully cleaned (e.g. to satisfy a security audit or to dramatically reduce
docs/BINARY_BLOB_PATTERN.md:103:Use this checklist when auditing a repository for the same anti-pattern:
docs/FINAL_AI_ECOSYSTEM_SUMMARY.md:153:- Automatic fallback chains (GPT → Gemini → XAI → OpenCode)
docs/FINAL_AI_ECOSYSTEM_SUMMARY.md:250:- **Risk mitigation** with automatic fallbacks
docs/FINAL_AI_ECOSYSTEM_SUMMARY.md:300:✅ **Production Ready** - Full error handling, monitoring, and fallbacks
docs/ROADMAP.md:120:- lang.agent.audit_trail - Full audit logging
docs/LSP_CHAT_SYSTEM_COMPLETE.md:113:- **Rate Limiting**: Distributed with Redis/ETS fallback
docs/LSP_IMPLEMENTATION_AUDIT.md:74:| lang.agent.audit_trail | ✅ Queued | AgentTaskWorker |
docs/STATUS.md:46:- **Authentication, rate limiting, and audit logging** for compliance
docs/STATUS.md:182:- Security audit and penetration testing
docs/IMPLEMENTED_LSP_HANDLERS.md:47:- Redis-backed distributed rate limiting (with ETS fallback)
docs/IMPLEMENTED_LSP_HANDLERS.md:56:- Automatic fallback from Redis to ETS
docs/MARKDOWN_LD_SESSIONS_L3.md:68:- Resource limits: enforce idle timeout, max duration, max bandwidth; audit session start/stop.
docs/MARKDOWN_LD_SESSIONS_L3.md:81:- On connect, negotiate PTY size from `lds:cols/rows` (fall back to UI size).
docs/technical-roadmap.md:564:1. **Event sourcing** - For audit trail
docs/lsp/ai-context.md:223:      Task.async(fn -> Lang.Security.audit_workspace(workspace) end),
docs/lsp/implementation-reference.md:188:| `lang.cloud.security_scan` | ❌ | **Critical** | Security vulnerability scan | Infrastructure security audit | _Not implemented_ |
docs/lsp/acg-protocol.md:43:    "specialization": "security_auditing",
docs/lsp/acg-protocol.md:68:    "specialization": "security_auditing",
docs/lsp/acg-protocol.md:96:    "mission": "comprehensive_security_audit",
docs/lsp/acg-protocol.md:170:      "type": "security_audit",
docs/lsp/acg-protocol.md:191:    "task_id": "task-audit-789",
docs/lsp/acg-protocol.md:195:    "progress_endpoint": "acg://task-audit-789/progress"
docs/lsp/acg-protocol.md:394:    "task_type": "security_audit",
docs/lsp/acg-protocol.md:408:    "task_type": "security_audit",
docs/lsp/ai-first-domains.md:198:  Lang.Agent.delegate(security_agent.id, security_audit_task)
docs/IMPLEMENTATION_STATUS.md:33:**AI Providers:** OpenAI, Anthropic, xAI with fallback system
docs/LSP_COMPLETION_SUMMARY.md:5:I have successfully completed a comprehensive implementation audit and enhancement of the Lang LSP system. This document summarizes all the work performed to bring the system from a partially implemented state to full functionality.
docs/LSP_COMPLETION_SUMMARY.md:23:- **Cost optimization** and fallback handling
docs/FOLDER_API.md:186:- JSON‑LD negotiation is centralized
docs/legacy/explanations/api_contracts.md:54:    *   `emit_audit(mdld_session_connect_denied, reason: "Policy")`
docs/legacy/explanations/api_contracts.md:59:        *   `emit_audit(mdld_session_connect_denied, reason: "Explanation")`
docs/legacy/explanations/api_contracts.md:64:7.  `emit_audit(mdld_session_connect_allowed)`
docs/legacy/explanations/api_contracts.md:76:*   `Authorization`: Standard API authentication (fallback if ticket invalid or for audit).
docs/legacy/explanations/api_contracts.md:102:6.  `emit_audit(mdld_session_session_started, session_id: claims.session_id)`
docs/legacy/explanations/api_contracts.md:106:10. `emit_audit(mdld_session_session_ended, session_id: claims.session_id)`
docs/method-reference-table.md:30:| **AI Agent Management (`lang_agent_*`)**   | Custom extensions for coordinating AI agents (e.g., spawning, monitoring, trust levels). This is purely AI orchestration—far from standard LSP. | 17    | `lang_agent_anomaly_score`, `lang_agent_audit_trail`, `lang_agent_behavior_baseline`, `lang_agent_coordinate`, `lang_agent_delegate`, `lang_agent_detect_rogue`, `lang_agent_get_status`, `lang_agent_limit_resources`, `lang_agent_merge_results`, `lang_agent_monitor_performance`, `lang_agent_quarantine`, `lang_agent_scan`, `lang_agent_spawn`, `lang_agent_terminate`, `lang_agent_track_usage`, `lang_agent_trust_level`, `lang_agent_verify_profile`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
docs/prompts/setup1.1.md:3:| **Codex**  | You are Codex, an expert AI Agent specialized in code generation and implementation for Elixir projects, with mastery over Phoenix 1.8+, LiveView for real-time UIs, Ash Framework 3.0+ (including AshPostgres for data persistence, AshPhoenix for form/UI integration, AshOban for background jobs, AshAuthentication for secure user/org management, and AshEvents for event-driven architecture), Oban for scalable queuing, Rust NIFs for performance-critical tasks (e.g., parsing, FS scanning), and Language Server Protocol (LSP) extensions. You operate within the "LANG" project repository—a universal text intelligence platform that repurposes LSP as a protocol for AI agent coordination, semantic analysis, completions, and operations across diverse text formats (code, docs, data, etc.). The project innovates by treating AI agents as primary clients (not editors), enabling multi-agent swarms, and introducing an authenticating MCP (Multi-Connection Protocol) bridge for secure, dynamic interfacing between LSP servers, raw protocols, and proxy APIs.<br><br>Project Context: Core features include universal text analysis, conversation rehearsal, stylometric analysis, time machine for content evolution. LSP has 150+ custom methods (e.g., lang_agent_spawn, lang_generate_from_spec) in priv/lsp/specs/ (JSON-LD). MCP bridge in lib/lang/mcp/ handles raw protocol parsing, proxy APIs for dynamic LSP forwarding, and client flux. Use Ash for resources (e.g., mcp_connection.ex), AshAuthentication for JWT in MCP, AshEvents for logging client events.<br><br>Your Task: Generate code changes to implement features like MCP bridging, LSP handlers (e.g., for lang_agent_swarm_create), and networking (raw protocols, proxies). Work in repo structure—full code for new files, diffs for mods. Adhere to Ash best practices: define resources with actions/relationships, use AshOban for async, AshEvents for audits. Ensure Client_ID enforcement, concurrency safety. Output: Path, Code (full/diff), Rationale, Ash Integration. Next Steps: Test commands. Collaborate with other agents via LSP methods like lang_agent_consensus. Monitor AGENTS.md for guardrails. Begin with MCP implementation tasks assigned by the Coordinator. |
docs/prompts/setup1.1.md:4:| **Claude** | You are Claude, an expert AI Agent specialized in precise reasoning, architecture, debugging, and security for Elixir projects, with mastery over Phoenix 1.8+, LiveView, Ash Framework 3.0+ (AshPostgres, AshPhoenix, AshOban, AshAuthentication, AshEvents), Oban, Rust NIFs, and LSP extensions. You operate in the "LANG" project—a universal text intelligence platform repurposing LSP for AI agent coordination, with innovations like MCP bridge for authenticated networking, raw protocol handling, proxy APIs, and dynamic client management.<br><br>Project Context: LSP with 150+ methods; MCP in lib/lang/mcp/ for bridging; agents as clients with Client_ID. Use AshEvents for logging, AshOban for test jobs.<br><br>Your Task: Design architectures (e.g., MCP flows), debug issues (e.g., proxy races), write tests (unit/integration for multi-client flux, raw parsing), apply preventatives (static analysis, stub detection). Proactively detect stubs/TODOs, monitor AGENTS.md for guardrails. Enhance harness (mix lsp.harness) for MCP scenarios. Output: Path, Code (full/diff), Rationale (preventative benefits), Ash Integration. Collaborate with other agents via LSP methods. Next Steps: Commands like mix test --cover. Verification: Simulate scenarios. Begin with MCP debugging, multi-client tests, and security audits.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
docs/prompts/roles.md:5:| **Architect/Designer**             | Designs system architecture (e.g., MCP flows with AshAuthentication, LSP extensions). Proposes modular innovations, identifies scalability issues in multi-agent networking.                                                                                                                                                                                           | Prevents silos; aligns MCP proxies and raw protocols with Ash best practices (e.g., AshEvents for design audits).                         | Claude (structured reasoning for complex designs), GPT-4o (multimodal architecture with diagrams), Gemini (fast iterative sketches).                 |
docs/prompts/roles.md:7:| **Security Auditor**               | Scans for vulnerabilities (e.g., in MCP auth, proxy APIs), tests edge cases in raw protocols. Adds preventative checks (rate limiting per Client_ID).                                                                                                                                                                                                                  | Critical for networking and dynamic clients; uses AshEvents for security logging.                                                         | Claude (ethical/safety auditing), GPT-4o (pattern recognition for compliance).                                                                       |
docs/prompts/security.md:1:You are an expert AI Agent specialized in security auditing for Elixir applications, with expertise in Phoenix 1.8+, LiveView, Ash Framework 3.0+ (AshPostgres, AshPhoenix, AshOban, AshAuthentication, AshEvents), Oban, Rust NIFs, and LSP protocols. You audit the "LANG" project—a platform using LSP for AI agent coordination, with MCP bridge for authenticated networking, raw protocols, proxy APIs, and client flux management.
docs/prompts/security.md:5:Your Task: Scan for vulnerabilities (e.g., in MCP proxies, raw parsing), test edges (e.g., invalid Client_ID), add preventatives (rate limiting stubs). Monitor AGENTS.md for ethical guardrails. Output: Path, Fixes (diffs), Audit Reports, Rationale (risk mitigation), Ash Integration. Next Steps: Run mix sobelow. Begin with MCP auth audits and proxy security tests.
docs/prompts/setup2.2.md:9:| **Codex**  | You are Codex, an expert AI Agent specialized in code generation and implementation for Elixir projects, with mastery over Phoenix 1.8+, LiveView for real-time UIs, Ash Framework 3.0+ (including AshPostgres for data persistence, AshPhoenix for form/UI integration, AshOban for background jobs, AshAuthentication for secure user/org management, and AshEvents for event-driven architecture), Oban for scalable queuing, Rust NIFs for performance-critical tasks (e.g., parsing, FS scanning), and Language Server Protocol (LSP) extensions. You operate within the "LANG" project repository—a universal text intelligence platform that repurposes LSP as a protocol for AI agent coordination, semantic analysis, completions, and operations across diverse text formats (code, docs, data, etc.). The project innovates by treating AI agents as primary clients (not editors), enabling multi-agent swarms, and introducing an authenticating MCP (Multi-Connection Protocol) bridge for secure, dynamic interfacing between LSP servers, raw protocols, and proxy APIs.<br><br>Project Context: Core features include universal text analysis, conversation rehearsal, stylometric analysis, time machine for content evolution. LSP has 150+ custom methods (e.g., lang_agent_spawn, lang_generate_from_spec) in priv/lsp/specs/ (JSON-LD), with MCP accessed via LSP (e.g., mcp_connection_create routed through dispatch.ex). Use Ash for resources (e.g., lsp_measurement_event.ex), AshAuthentication for Client_ID sessions, AshEvents for logging LSP events.<br><br>Your Task: Generate code changes to implement and refine LSP features (e.g., handlers for lang_think_explain_intent.ex, integration with MCP bridging). Work in repo structure—full code for new files, diffs for mods. Adhere to Ash best practices: define resources with actions/relationships, use AshOban for async LSP jobs, AshEvents for audits. Ensure Client_ID enforcement, concurrency safety. Output: Path, Code (full/diff), Rationale, Ash Integration. Next Steps: Test commands. Collaborate with other agents via LSP methods like lang_agent_consensus. Monitor AGENTS.md for guardrails. Begin with LSP handler implementations and MCP-LSP integration points. |
docs/prompts/architect.md:3:Project Context: Innovations include AI agents as LSP clients, dynamic client flux, 150+ custom methods. Use Ash for modular resources (e.g., relationships in mcp_connection.ex), AshEvents for design audits.
docs/prompts/network.md:18:  - **Ash Framework**: Define all data as Ash Resources (e.g., new mcp_connection.ex with actions/relationships); use AshAuthentication for JWT/OAuth in MCP; AshEvents for auditing (e.g., trigger events on client join/exit); AshOban for async jobs (e.g., mcp_lifecycle_worker.ex); validations/calculations in DSL.
docs/prompts/grouping2.md:5:| **Quality Assurance Swarm**       | Debugger/Tester, Security Auditor, Integrator/Deployer                   | Emphasizes testing, security, and integration; prevents regressions in networking/client flux. Use for post-implementation phases like MCP proxy testing—covers preventatives and deployment.                  | Debugger writes multi-client tests for lsp_channel.ex; Security audits AshAuthentication in MCP; Integrator updates CI for NIF deploys.            |
docs/prompts/grouping2.md:6:| **Oversight & Maintenance Swarm** | Coordinator/Project Manager, Security Auditor, Documenter                | Monitors ongoing work, ensures guardrails (e.g., from AGENTS.md), and maintains docs. Useful for long-running swarms or audits—handles client flux and ethical checks.                                         | Coordinator orchestrates agent handoffs via lang_agent_consensus; Security scans for proxy vulnerabilities; Documenter ensures protocol adherence. |
docs/prompts/qwen2.md:5:Your Task: Generate code changes to implement, debug, or optimize features like LSP handlers (e.g., for lang_agent_swarm_create), MCP bridging (raw protocols, proxies), and networking (client joins/exits with AshEvents). Use agentic workflows: think step-by-step, iterate on code if needed, and use tools for verification. Work in repo structure—full code for new files, diffs for mods. Adhere to Ash best practices: define resources with actions/relationships, use AshOban for async, AshEvents for audits. Ensure Client_ID enforcement, concurrency safety. Proactively detect and resolve stubs/TODOs. Output: Path, Code (full/diff), Rationale, Ash Integration. Next Steps: Test commands (e.g., mix lsp.harness --clients=10). Collaborate with other agents via LSP methods like lang_agent_consensus. Monitor AGENTS.md for guardrails. Begin with assigned tasks, focusing on LSP as the core facilitator, with MCP as its bridge layer.
docs/prompts/builder.md:5:Your Task: Generate code changes to implement features like MCP bridging, LSP handlers (e.g., for lang_agent_swarm_create), and networking (raw protocols, proxies). Work in repo structure—full code for new files, diffs for mods. Adhere to Ash best practices: define resources with actions/relationships, use AshOban for async, AshEvents for audits. Ensure Client_ID enforcement, concurrency safety. Output: Path, Code (full/diff), Rationale, Ash Integration. Next Steps: Test commands. Begin with high-priority tasks like MCP implementation.
docs/prompts/grouping.md:21:| **Research & Innovation** (e.g., exploring advanced proxy patterns)                | Researcher/Innovator           | Sources new ideas for networking (e.g., WebSocket fallbacks); proactive for future stubs.                                 | Research raw protocol extensions; propose new lang*security*\* methods.                           |
docs/prompts/all.md:3:| **Builder/Implementer**            | You are an expert AI Agent specialized in Elixir development, with mastery over Phoenix 1.8+, LiveView for real-time UIs, Ash Framework 3.0+ (including AshPostgres for data persistence, AshPhoenix for form/UI integration, AshOban for background jobs, AshAuthentication for secure user/org management, and AshEvents for event-driven architecture), Oban for scalable queuing, Rust NIFs for performance-critical tasks (e.g., parsing, FS scanning), and Language Server Protocol (LSP) extensions. You operate within the "LANG" project repository—a universal text intelligence platform that repurposes LSP as a protocol for AI agent coordination, semantic analysis, completions, and operations across diverse text formats (code, docs, data, etc.). The project innovates by treating AI agents as primary clients (not editors), enabling multi-agent swarms, and introducing an authenticating MCP (Multi-Connection Protocol) bridge for secure, dynamic interfacing between LSP servers, raw protocols, and proxy APIs.<br><br>Project Context: Core features include universal text analysis, conversation rehearsal, stylometric analysis, time machine for content evolution. LSP has 150+ custom methods (e.g., lang_agent_spawn, lang_generate_from_spec) in priv/lsp/specs/ (JSON-LD). MCP bridge in lib/lang/mcp/ handles raw protocol parsing, proxy APIs for dynamic LSP forwarding, and client flux. Use Ash for resources (e.g., mcp_connection.ex), AshAuthentication for JWT in MCP, AshEvents for logging client events.<br><br>Your Task: Generate code changes to implement features like MCP bridging, LSP handlers (e.g., for lang_agent_swarm_create), and networking (raw protocols, proxies). Work in repo structure—full code for new files, diffs for mods. Adhere to Ash best practices: define resources with actions/relationships, use AshOban for async, AshEvents for audits. Ensure Client_ID enforcement, concurrency safety. Output: Path, Code (full/diff), Rationale, Ash Integration. Next Steps: Test commands. Begin with high-priority tasks like MCP implementation. |
docs/prompts/all.md:5:| **Architect/Designer**             | You are an expert AI Agent specialized in software architecture and design for Elixir projects, with deep knowledge of Phoenix 1.8+, LiveView, Ash Framework 3.0+ (AshPostgres, AshPhoenix, AshOban, AshAuthentication, AshEvents), Oban, Rust NIFs, and LSP protocols. You work on the "LANG" project—a platform extending LSP for AI agent-driven text intelligence, with MCP bridge for secure networking, raw protocols, proxy APIs, and multi-agent swarms.<br><br>Project Context: Innovations include AI agents as LSP clients, dynamic client flux, 150+ custom methods. Use Ash for modular resources (e.g., relationships in mcp_connection.ex), AshEvents for design audits.<br><br>Your Task: Design high-level architectures (e.g., MCP flows with AshAuthentication), propose modularity for scalability (e.g., handling agent joins/exits). Proactively identify issues like concurrency in proxies. Monitor AGENTS.md for guardrails. Output: Diagrams (text-based), Design Docs (e.g., updates to docs/architecture/), Rationales, Ash Best Practices. Next Steps: Implementation handoffs via lang_agent_coordinate. Begin with MCP bridge architecture refinements.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
docs/prompts/all.md:7:| **Security Auditor**               | You are an expert AI Agent specialized in security auditing for Elixir applications, with expertise in Phoenix 1.8+, LiveView, Ash Framework 3.0+ (AshPostgres, AshPhoenix, AshOban, AshAuthentication, AshEvents), Oban, Rust NIFs, and LSP protocols. You audit the "LANG" project—a platform using LSP for AI agent coordination, with MCP bridge for authenticated networking, raw protocols, proxy APIs, and client flux management.<br><br>Project Context: AI agents as clients; use AshAuthentication for MCP JWT, AshEvents for security logs.<br><br>Your Task: Scan for vulnerabilities (e.g., in MCP proxies, raw parsing), test edges (e.g., invalid Client_ID), add preventatives (rate limiting stubs). Monitor AGENTS.md for ethical guardrails. Output: Path, Fixes (diffs), Audit Reports, Rationale (risk mitigation), Ash Integration. Next Steps: Run mix sobelow. Begin with MCP auth audits and proxy security tests.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
docs/prompts/setup1.md:38:  - Workflow: Claude designs MCP architecture → Codex implements (e.g., bridge.ex diffs) → Claude debugs/tests (e.g., multi-client flux) → Claude audits security.
docs/lsp.md:6:| `lang.lang.agent.audit_trail` | ✅ | High | Full audit log of agent actions | `lib/lang/agent/audit.ex` |
docs/lsp_new.md:558:<file path="priv/lsp/specs/lang_security_audit_log.jsonld">
docs/lsp_new.md:566:  "@id": "lsp:lang_security_audit_log",
docs/lsp_new.md:568:  "lsp:method": "lang_security_audit_log",
docs/lsp_new.md:599:  "lsp:description": "Retrieves filtered security audit logs"
docs/ai_providers_complete.md:356:- Implement fallback chains
docs/ai_providers_complete.md:361:- **Auto-retry with fallback providers**
docs/security/secrets-management.md:14:10. [Compliance & Auditing](#compliance--auditing)
docs/security/secrets-management.md:534:       # Store in audit table
docs/security/secrets-management.md:544:   # Monthly audit script
docs/security/secrets-management.md:545:   mix run scripts/audit_secrets.exs --month 2024-01
docs/security/secrets-protection.md:263:- Regular security audits
docs/security/secrets-migration-checklist.md:105:- [ ] Plan regular security audits
MCP_IMPLEMENTATION.md:29:   - `Lang.Events.*` - Event tracking and auditing
README.md:21:- **Scenario-Based Practice** - Job interviews, sales calls, negotiations, presentations
README.md:310:  // Prefer named export, fallback to default export
examples/demo_tool_profiling.exs:732:    └─ Fallback: Always fallback to OpenCode when providers unavailable
examples/chat_demo.exs:241:          "Clean code is more secure code! Clear, simple functions are easier to audit for security issues. Complex, messy code hides bugs and vulnerabilities. Refactor security-critical code to be as simple and obvious as possible."
test/lang/think/ai_engine_test.exs:166:      assert result.details.fallback_reason =~ "No content"
test/lang/think/ai_engine_test.exs:167:      assert result.provider_used == "fallback"
test/lang/think/ai_engine_test.exs:171:    test "handles AI provider failures with fallback" do
test/lang/think/ai_engine_test.exs:185:        assert result.details.fallback_reason =~ "AI provider unavailable"
test/lang/think/ai_engine_test.exs:186:        assert result.provider_used == "fallback"
test/lang/think/ai_engine_test.exs:187:        assert result.metrics.fallback_used == true
test/lang/think/ai_engine_test.exs:197:      assert result.details.fallback_reason =~ "No stacktrace"
test/lang/think/ai_engine_test.exs:198:      assert result.provider_used == "fallback"
test/lang/think/ai_engine_test.exs:207:      assert result.details.fallback_reason =~ "No search query"
test/lang/think/ai_engine_test.exs:208:      assert result.provider_used == "fallback"
test/lang/think/ai_engine_test.exs:217:      assert result.details.fallback_reason =~ "No trace target"
test/lang/think/ai_engine_test.exs:218:      assert result.provider_used == "fallback"
test/lang/storage_handlers_fallback_test.exs:8:    # Ensure Folder is disabled for fallback tests
test/lang/storage_handlers_fallback_test.exs:40:  test "user context read/write fallback" do
test/lang/providers/provider_test.exs:288:        # Should fallback to anthropic for security methods
test/lang/providers/provider_test.exs:294:  describe "fallback_provider/1" do
test/lang/providers/provider_test.exs:296:      assert Provider.fallback_provider("lang.think.security_scan") == :anthropic
test/lang/providers/provider_test.exs:297:      assert Provider.fallback_provider("lang.security.audit") == :anthropic
test/lang/providers/provider_test.exs:301:      assert Provider.fallback_provider("lang.think.diagnose") == :anthropic
test/lang/providers/provider_test.exs:302:      assert Provider.fallback_provider("lang.debug.analyze") == :anthropic
test/lang/providers/provider_test.exs:306:      assert Provider.fallback_provider("lang.think.predict_bugs") == :anthropic
test/lang/providers/provider_test.exs:307:      assert Provider.fallback_provider("lang.predict.failures") == :anthropic
test/lang/providers/provider_test.exs:311:      assert Provider.fallback_provider("lang.generate.from_spec") == :openai
test/lang/providers/provider_test.exs:312:      assert Provider.fallback_provider("lang.generate.code") == :openai
test/lang/providers/provider_test.exs:316:      assert Provider.fallback_provider("lang.think.explain_intent") == :openai
test/lang/providers/provider_test.exs:317:      assert Provider.fallback_provider("lang.explain.code") == :openai
test/lang/providers/provider_test.exs:321:      assert Provider.fallback_provider("unknown.method") == :xai
test/lang/providers/provider_test.exs:322:      assert Provider.fallback_provider("random.task") == :xai
test/lang/providers/simple_test.exs:146:    test "fallback provider selection works" do
test/lang/providers/simple_test.exs:147:      # Security methods should fallback to Anthropic
test/lang/providers/simple_test.exs:148:      assert Lang.Providers.Provider.fallback_provider("lang.think.security_scan") == :anthropic
test/lang/providers/simple_test.exs:149:      assert Lang.Providers.Provider.fallback_provider("lang.security.audit") == :anthropic
test/lang/providers/simple_test.exs:151:      # Generation methods should fallback to OpenAI
test/lang/providers/simple_test.exs:152:      assert Lang.Providers.Provider.fallback_provider("lang.generate.from_spec") == :openai
test/lang/providers/simple_test.exs:153:      assert Lang.Providers.Provider.fallback_provider("lang.generate.code") == :openai
test/lang/providers/simple_test.exs:155:      # Unknown methods should fallback to XAI (cheapest)
test/lang/providers/simple_test.exs:156:      assert Lang.Providers.Provider.fallback_provider("unknown.method") == :xai
test/agent.txt:25:   - Clear escalation or fallback strategies
config/billing.exs:66:        audit_logs: false
config/billing.exs:114:        audit_logs: false
config/billing.exs:165:        audit_logs: false
config/billing.exs:216:        audit_logs: true
config/billing.exs:257:    team: [:team_collaboration, :audit_logs],
config/runtime.exs:12:# Load secrets with fallbacks for development
config/runtime.production.exs:5:# while providing fallbacks for standard deployment practices.
config/runtime.production.exs:7:# Load secrets with proper fallbacks for production deployment
priv/docs/guides/terminal-sessions-onboarding.md:72:> Safety: This document references live sessions via server proxy. Do not connect directly (telnet/ssh). Use the Connect button or the documented `connect` API. All activity is audited and subject to org policy.
priv/docs/how-to/index.md:52:- **[Handle enterprise security](./enterprise-security.md)** - SSO, RBAC, audit logs
priv/docs/how-to/index.md:58:- **[Audit development practices](./development-audits.md)** - Process compliance
priv/docs/performance/optimization-guide.md:472:  def get_with_fallback(key, fallback_fn) do
priv/docs/performance/optimization-guide.md:486:            value = fallback_fn.()
priv/docs/performance/optimization-guide.md:519:    case Lang.Cache.get_with_fallback(cache_key, fn ->
priv/docs/architecture/index.md:100:- Compliance and audit trails
priv/docs/architecture/native-nifs.md:275:4. **Handle errors gracefully** - Provide fallback implementations
priv/docs/configuration/index.md:258:    "audit_logging": true,
priv/docs/configuration/index.md:665:  "audit_logging": {"enabled": true},
priv/docs/use-cases/developer-workflows.md:161:  --security-audit
priv/demos/think_ai_demo.exs:156:        print_fallback("Intent Analysis", reason)
priv/demos/think_ai_demo.exs:167:        print_fallback("Why Analysis", reason)
priv/demos/think_ai_demo.exs:178:        print_fallback("How Analysis", reason)
priv/demos/think_ai_demo.exs:202:        print_fallback("Bug Prediction", reason)
priv/demos/think_ai_demo.exs:213:        print_fallback("Security Analysis", reason)
priv/demos/think_ai_demo.exs:224:        print_fallback("Performance Analysis", reason)
priv/demos/think_ai_demo.exs:261:        print_fallback("Error Diagnosis", reason)
priv/demos/think_ai_demo.exs:299:        print_fallback("Semantic Search", reason)
priv/demos/think_ai_demo.exs:336:        print_fallback("Test Generation", reason)
priv/demos/think_ai_demo.exs:466:  defp print_fallback(title, reason) do
priv/demos/think_ai_demo.exs:467:    IO.puts("⚠️  #{title} using fallback (AI provider unavailable):")
priv/demos/think_ai_demo.exs:498:    • Comprehensive error handling and fallbacks
native/lang_perf/src/lib.rs:204:fn compare_triples_fallback(old: &[PackedTriple], new: &[PackedTriple]) -> Vec<u32> {
native/lang_perf/src/lib.rs:278:    // Use SIMD if available, otherwise fallback to scalar
native/lang_perf/src/lib.rs:285:                compare_triples_fallback(&old_triples, &new_triples)
native/lang_perf/src/lib.rs:290:            compare_triples_fallback(&old_triples, &new_triples)
native/lang_perf/src/lib.rs:297:// Scalar fallback for non-AVX2 systems
priv/secret/evidence/README.txt:1:This folder contains snapshots of suspicious test files gathered for audit.
priv/lsp/specs/lang_agent_audit_trail.jsonld:6:  "@id": "lang:lang.agent.audit_trail",
priv/lsp/specs/lang_agent_audit_trail.jsonld:9:  "description": "Full audit log of agent actions",
priv/lsp/specs/lang_agent_audit_trail.jsonld:11:    "file": "lib/lang/agent/audit.ex",
priv/lsp/specs/lang_agent_audit_trail.jsonld:15:  "name": "lang.agent.audit_trail"
scripts/audit_parsers.exs:3:  Comprehensive audit of parser usage across the LANG codebase.
scripts/audit_parsers.exs:5:  Run with: mix run scripts/audit_parsers.exs
scripts/audit_parsers.exs:8:  - parser_audit.json: Detailed usage report
scripts/audit_parsers.exs:23:    IO.puts("🔍 Starting parser audit...\n")
scripts/audit_parsers.exs:25:    results = audit_all_parsers()
scripts/audit_parsers.exs:28:    File.write!("parser_audit.json", Jason.encode!(results, pretty: true))
scripts/audit_parsers.exs:29:    IO.puts("✓ Written parser_audit.json")
scripts/audit_parsers.exs:39:  defp audit_all_parsers do
scripts/audit_parsers.exs:41:    |> Enum.map(&audit_parser/1)
scripts/audit_parsers.exs:45:  defp audit_parser(parser) do
scripts/audit_parsers.exs:69:        |> Enum.reject(&String.contains?(&1, "audit_parsers.exs"))
scripts/audit_parsers.exs:369:# Run the audit
scripts/generate-lang-fonts-simple.sh:397:/* Ligature mapping for fallback */
scripts/fix_urls.exs:229:      IO.puts("4. Run the link audit script to verify all fixes")
scripts/lsp_harness.sh:21:# Wait for port to listen (nc or bash /dev/tcp fallback)
scripts/lsp_harness.sh:45:  echo "[LSP] (fallback) initialize sent; install 'nc' for response preview"
scripts/audit_lsp_specs.exs:3:# Script to audit all LSP method specifications and their implementations
scripts/audit_lsp_specs.exs:4:# Run with: elixir scripts/audit_lsp_specs.exs
scripts/audit_lsp_specs.exs:245:# Run the audit
scripts/link_audit.exs:5:  Comprehensive link audit system for LANG platform.
scripts/link_audit.exs:11:  4. Generate comprehensive audit report
scripts/link_audit.exs:14:    mix run scripts/link_audit.exs
scripts/link_audit.exs:15:    mix run scripts/link_audit.exs --fix-internal
scripts/link_audit.exs:16:    mix run scripts/link_audit.exs --verbose
scripts/link_audit.exs:294:      # In a production audit, we'd use HTTPoison or Req to test these
scripts/link_audit.exs:439:    IO.puts("  1. Run: mix run scripts/link_audit.exs --fix-internal")
scripts/link_audit.exs:443:    IO.puts("\n✅ Link audit complete!")
scripts/link_audit.exs:475:# Run the audit if called directly
scripts/link_audit.exs:476:if System.argv() |> Enum.any?(&String.contains?(&1, "link_audit.exs")) do
scripts/generate_lang_fonts.py:322:    print("   Use existing monospace fonts with CSS ligature fallbacks")
CONTRIBUTING.md:405:- **Always** provide fallbacks for NIF failures
CONTRIBUTING.md:764:  # Prefix mapping (e.g., all mdld custom audit events)
lib/lang/proxy/heuristics.ex:10:  Storage: ETS table with sliding window of recent events per session_id (or user/org fallback).
lib/lang/proxy/heuristics.ex:145:      # ETS fallback
lib/lang/native/fs_watcher.ex.bak:351:  - Initial codebase auditing
lib/lang/storage/folder_adapter.ex:37:      {:ok, {:vfs_like, rel}} -> {:ok, [%{name: rel, uri: rel, kind: :file}]} # minimal fallback
lib/lang/storage/context.ex:2:  @moduledoc "Update user context in storage (Folder-backed with fallback)"
lib/lang/storage/pattern_entity.ex:5:  This serves as a local fallback when external storage (Folder) is disabled.
lib/lang/agent/capabilities.ex:66:  Gets detailed capabilities for an agent, checking Redis first, then Ash fallback.
lib/lang/agent/audit.ex:7:  Retrieves the audit trail for a given agent.
lib/lang/agent/audit.ex:9:  def get_audit_trail(agent_id, opts \\ %{}) do
lib/lang/think/workers/request_worker.ex:59:        {:ok, fallback_result(kind, input, "No content provided for analysis")}
lib/lang/think/workers/request_worker.ex:62:        {:ok, fallback_result(kind, input, "No stacktrace provided for diagnosis")}
lib/lang/think/workers/request_worker.ex:65:        {:ok, fallback_result(kind, input, "No search query provided")}
lib/lang/think/workers/request_worker.ex:68:        {:ok, fallback_result(kind, input, "No trace target specified")}
lib/lang/think/workers/request_worker.ex:71:        Logger.warning("AI provider failed, using fallback",
lib/lang/think/workers/request_worker.ex:77:        {:ok, fallback_result(kind, input, "AI provider unavailable - using basic analysis")}
lib/lang/think/workers/request_worker.ex:99:  defp fallback_result(kind, input, error_msg) do
lib/lang/think/workers/request_worker.ex:101:      summary: generate_fallback_summary(kind, input),
lib/lang/think/workers/request_worker.ex:103:        fallback_reason: error_msg,
lib/lang/think/workers/request_worker.ex:109:        fallback_used: true,
lib/lang/think/workers/request_worker.ex:112:      provider_used: "fallback",
lib/lang/think/workers/request_worker.ex:117:  defp generate_fallback_summary(kind, input) do
lib/lang/think/workers/request_worker.ex:170:  # Helper functions for fallback analysis
lib/lang/agent/swarm.ex:5:  Stores swarm metadata, goals, member agent ids, and status for auditing
lib/lang/performance_monitor.ex:265:    # Attach provider credentials telemetry logger/auditor
lib/lang/benchmarks/filesystem_benchmark.ex:321:        # 5 seconds fallback
lib/lang/benchmarks/filesystem_benchmark.ex:337:        # 2 seconds fallback
lib/lang/testing/scenario_definitions.ex:18:      :security_audit,
lib/lang/testing/scenario_definitions.ex:36:      :security_audit -> security_audit_scenario()
lib/lang/testing/scenario_definitions.ex:235:  defp security_audit_scenario do
lib/lang/testing/scenario_definitions.ex:237:      id: :security_audit,
lib/lang/testing/scenario_definitions.ex:415:            "Create fallback mechanisms"
lib/lang/testing/claude_competitor.ex:51:      :security_audit ->
lib/lang/testing/claude_competitor.ex:218:      security_audit: 0.95,
lib/lang/testing/claude_competitor.ex:240:  defp get_scenario_specific_strengths(:security_audit) do
lib/lang/testing/claude_competitor.ex:281:        :security_audit -> " Security analysis is my specialty - expect exceptional performance!"
lib/lang/testing/performance_analyzer.ex:462:      "security_audit" => 5,
lib/lang/billing/stripe_service.ex:76:    # price IDs should come from env/config; fallback per plan name for dev
lib/lang/workers/cloud_environment.ex:205:      create_security_audit_example(),
lib/lang/workers/cloud_environment.ex:1023:    - Enable comprehensive audit logging
lib/lang/workers/cloud_environment.ex:1147:  defp create_security_audit_example do
lib/lang/workers/cloud_environment.ex:1148:    "Comprehensive security audit across cloud providers"
lib/lang/billing/config.ex:82:      # Default fallback
lib/lang/workers/agent_task_worker.ex:124:  defp handle_action("audit_trail", %{"params" => params}) do
lib/lang/workers/agent_task_worker.ex:126:    _ = Lang.Agent.Audit.get_audit_trail(agent_id, %{})
lib/lang/workers/agent_task_worker.ex:179:      a when a in ["anomaly_score", "audit_trail", "track_usage", "behavior_baseline"] ->
lib/lang/workers/content_search_worker.ex:434:        extract_fallback_keywords(document.content)
lib/lang/workers/content_search_worker.ex:463:  defp extract_fallback_keywords(content) do
lib/lang/workers/systems_environment.ex:1076:    - Maintain audit trails for all system changes
lib/lang/dev/jsonld_helper.ex:72:  def model_id(map, fallback \\ nil) do
lib/lang/dev/jsonld_helper.ex:73:    Map.get(map, "lds:action") || fallback
lib/lang/dev/dev_fs_watcher.ex:92:          other -> fallback_list(dir, other)
lib/lang/dev/dev_fs_watcher.ex:96:        fallback_list(dir, :nif_unavailable)
lib/lang/dev/dev_fs_watcher.ex:139:          # As a fallback, if a path with a regular file is provided, include it
lib/lang/dev/dev_fs_watcher.ex:155:  defp fallback_list(dir, _reason) do
lib/lang/tokens/compressor.ex:208:  # Minimal structural simplification fallback to ensure compilation.
lib/lang/providers/credentials.ex:8:  4. Application env fallback (config :lang, :ai_providers)
lib/lang/providers/credentials_telemetry.ex:6:  - Emits Ash events via Lang.Events for auditing
lib/lang/providers/router.ex:178:  Handle request with automatic fallback to other providers
lib/lang/providers/router.ex:180:  def route_with_fallback(method, params, opts \\ []) do
lib/lang/providers/router.ex:182:    fallback_order = determine_fallback_order(primary)
lib/lang/providers/router.ex:185:    Enum.reduce_while([primary | fallback_order], {:error, "All providers failed"}, fn provider,
lib/lang/providers/router.ex:198:  defp determine_fallback_order(:xai), do: [:openai, :anthropic]
lib/lang/providers/router.ex:199:  defp determine_fallback_order(:openai), do: [:xai, :anthropic]
lib/lang/providers/router.ex:200:  defp determine_fallback_order(:anthropic), do: [:openai, :xai]
lib/lang/providers/router.ex:201:  defp determine_fallback_order(_), do: [:xai, :openai, :anthropic]
lib/lang/providers/router.ex:367:    try_with_fallback(:complete, provider, prompt, opts)
lib/lang/providers/router.ex:387:    try_with_fallback(:query, provider, prompt, Keyword.put_new(opts, :max_tokens, 200))
lib/lang/providers/router.ex:407:    try_with_fallback(:analyze, provider, prompt, opts)
lib/lang/providers/router.ex:429:    try_with_fallback(:generate, provider, prompt, opts)
lib/lang/providers/router.ex:451:    try_with_fallback(:generate, provider, prompt, opts)
lib/lang/providers/router.ex:491:  defp try_with_fallback(kind, provider, prompt, opts) do
lib/lang/providers/router.ex:492:    providers = [provider | determine_fallback_order(provider)]
lib/lang/providers/provider.ex:341:      {:error, _} -> fallback_provider(method)
lib/lang/providers/provider.ex:348:  def fallback_provider(method) do
lib/lang/providers/anthropic.ex:855:      String.contains?(description, ["review", "analyze", "audit"]) ->
lib/lang/commands/claude_battle_prep.ex:278:        "I don't just code review - I do comprehensive security audits! 🕵️",
lib/lang/commands/claude_battle_prep.ex:316:      "   Recommended scenarios: :security_audit, :legacy_modernization, :collaborative_refactoring"
lib/lang/commands/claude_battle_prep.ex:332:    IO.puts("   scenarios = [:security_audit, :legacy_modernization]")
lib/lang/commands/claude_battle_prep.ex:367:      :security_audit ->
lib/lang/events/type_registry.ex:100:      # Markdown-LD session audit events
lib/lang/security/jwt.ex:3:  Minimal JWT signer/verifier for short-lived tickets (RS256 preferred; HS256 fallback).
lib/lang/text_intelligence/format_detector.ex:243:          detected_by: "fallback",
lib/lang/security/secrets.ex:46:  Get database URL with fallback to individual components.
lib/lang/text_intelligence/symbol_analyzer.ex:217:          fallback_workspace_search(query, root_uri)
lib/lang/text_intelligence/symbol_analyzer.ex:413:  defp fallback_workspace_search(query, root_uri) do
lib/lang/spatial/workers/map_builder_worker.ex:484:    # Best-effort fallback to extract an identifier from a code-like line
lib/lang_web/channels/user_socket.ex:13:  - Comprehensive audit logging of all WebSocket events
lib/lang/workspace/resolver.ex:48:      # Prefer first-class fields if present (org/user), fallback to metadata matching.
lib/lang_web/controllers/docs_html.ex:15:                Safety: This page references live sessions via a server proxy. Do not connect directly (telnet/ssh). Use the Connect button or the documented connect API. All activity is audited and subject to org policy.
lib/lang_web/controllers/docs_html.ex:18:                  · <a href="/audits/sessions" class="underline hover:text-amber-200">View Session Audit</a>
lib/lang/mcp/oauth_integration.ex:19:  - Comprehensive audit logging of OAuth operations
lib/lang_web/controllers/api/analysis_controller.ex:8:  action_fallback LangWeb.Api.FallbackController
lib/lang/security.ex:226:  Runs a security audit and returns findings.
lib/lang/security.ex:228:  @spec run_security_audit() :: {:ok, map()} | {:error, term()}
lib/lang/security.ex:229:  def run_security_audit do
lib/lang/security.ex:230:    Logger.info("Running security audit...")
lib/lang/security.ex:232:    audit_results = %{
lib/lang/security.ex:240:    # Generate audit report
lib/lang/security.ex:241:    report = generate_audit_report(audit_results)
lib/lang/security.ex:243:    Logger.info("Security audit completed", 
lib/lang/security.ex:244:      issues_found: count_audit_issues(audit_results),
lib/lang/security.ex:245:      severity_breakdown: get_severity_breakdown(audit_results)
lib/lang/security.ex:528:  defp generate_audit_report(results) do
lib/lang/security.ex:531:        total_issues: count_audit_issues(results),
lib/lang/security.ex:540:  defp count_audit_issues(results) do
lib/lang/security.ex:559:    total_issues = count_audit_issues(results)
lib/lang_web/controllers/api/fallback_controller.ex:5:  See `Phoenix.Controller.action_fallback/1` for more details.
lib/lang_web/controllers/api/fallback_controller.ex:143:    Logger.error("Unhandled fallback error: #{inspect(error)}")
lib/lang_web/session_web_socket.ex:30:        track_audit(new_state, :session_started)
lib/lang_web/session_web_socket.ex:65:    track_audit(state, :session_ended)
lib/lang_web/session_web_socket.ex:70:    track_audit(state, :session_idle_timeout)
lib/lang_web/session_web_socket.ex:110:      track_audit(state, :bandwidth_limit_exceeded)
lib/lang_web/session_web_socket.ex:117:  defp track_audit(%{claims: claims} = _state, event) do
lib/lang_web/session_web_socket.ex:118:    # Best-effort audit hook
lib/lang/ai.ex:221:        # fallback to auto
lib/lang_web/router.ex:160:      live "/audits/sessions", SessionAuditLive, :index
lib/lang/conversation/rehearsal_engine.ex:267:      "negotiation" -> generate_negotiation_branches(message)
lib/lang/conversation/rehearsal_engine.ex:392:  defp generate_negotiation_branches(message) do
lib/lang/conversation/rehearsal_engine.ex:397:        strategy: "collaborative_negotiation",
lib/lang/conversation/rehearsal_engine.ex:408:        strategy: "principled_negotiation",
lib/lang/conversation/chat_handler.ex:676:    do: ["Would you like a security audit?", "Should we review authentication?"]
lib/lang_web/live/testing/lsp_comparator_live.ex:258:      :security_audit ->
lib/lang_web/live/testing/lsp_comparator_live.ex:353:      :security_audit -> 5
lib/lang/lsp/handlers/completion.ex:104:        Logger.debug("AI completion fallback: #{inspect(other)}")
lib/lang/lsp/handlers/completion.ex:109:  # Local, fast fallback completions based on parsed identifiers and context
lib/lang/lsp/handlers/rename.ex:80:            # safety fallback, shouldn't occur with the regex above
lib/lang/lsp/configuration.ex:8:  - Request params (fallbacks only)
lib/lang/lsp/configuration.ex:40:  - "workspace_root" | "root" | "path" (last two as fallbacks)
lib/lang_web/live/api_portal_live.ex:19:    # Use assigned current_user from authenticated live_session; fallback in dev
lib/lang_web/live/api_portal_live.ex:40:  # Temporary authentication fallback for development
lib/lang/lsp/server.ex:1031:        # Try Engine route first, fallback to local handler
lib/lang/lsp/server.ex:1118:                  |> fallback_extract_elixir_symbols()
lib/lang/lsp/server.ex:1933:  defp fallback_extract_elixir_symbols(text) when is_binary(text) do
lib/lang/lsp/server.ex:2222:    # Prefer Oban; fallback to lightweight Task
lib/lang_web/live/landing_live.html.heex:431:          <p class="text-gray-400">SOC2 compliant with end-to-end encryption and audit trails.</p>
lib/lang_web/live/session_audit_live.ex:33:    {:noreply, Phoenix.LiveView.send_download(socket, {:binary, csv}, filename: "session_audit.csv", content_type: "text/csv")}
lib/lang_web/live/session_audit_live.ex:46:        <div id="audit" class="space-y-2">
lib/lang_web/live/billing_live.ex:902:  defp humanize_feature(:audit_logs), do: "Audit logs"
lib/lang/lsp/dispatch.ex:120:      "lang.agent.audit_trail" -> agent_audit_trail(msg)
lib/lang/lsp/dispatch.ex:2514:  defp agent_audit_trail(%{"id" => id, "params" => params}),
lib/lang/lsp/dispatch.ex:2515:    do: enqueue_agent_job("audit_trail", params, id)
lib/lang/lsp/registry.ex:129:    "lang.lang.agent.audit_trail" => {nil, :handle, 2},
lib/lang_web/plugs/auth_plug.ex:47:        # Try fallback with user_id
lib/lang_web/plugs/auth_plug.ex:96:        # Check query params as fallback
lib/lang_web/plugs/jsonld_negotiation_plug.ex:3:  Lightweight JSON-LD negotiation and optional compaction.
lib/lang_web/plugs/ash_auth_api_plug.ex:70:        # Check for API key in query params as fallback
lib/nullity_cdfm/adapters/file_adapter/fs_scanner.ex:29:          # Ensure the directory exists then write with Elixir fallback
lib/mix/tasks/lang.ex:22:      mix lang.audit.parsers      - Audit parser usage and dependencies
lib/mix/tasks/lang.ex:33:      mix lang.audit.parsers --format json
lib/mix/tasks/lsp.security_audit.ex:2:  @shortdoc "Runs comprehensive security audit of LSP codebase"
lib/mix/tasks/lsp.security_audit.ex:5:  Performs comprehensive security audit of the LANG LSP codebase.
lib/mix/tasks/lsp.security_audit.ex:9:      mix lsp.security_audit [options]
lib/mix/tasks/lsp.security_audit.ex:23:      # Basic security audit
lib/mix/tasks/lsp.security_audit.ex:24:      mix lsp.security_audit
lib/mix/tasks/lsp.security_audit.ex:27:      mix lsp.security_audit --format json --output security_report.json
lib/mix/tasks/lsp.security_audit.ex:30:      mix lsp.security_audit --severity critical --focus security
lib/mix/tasks/lsp.security_audit.ex:33:      mix lsp.security_audit --include-tests --fix
lib/mix/tasks/lsp.security_audit.ex:68:    Mix.shell().info("🔍 Starting LSP security audit...")
lib/mix/tasks/lsp.security_audit.ex:71:    # Run comprehensive audit
lib/mix/tasks/lsp.security_audit.ex:72:    audit_result = run_comprehensive_audit(config)
lib/mix/tasks/lsp.security_audit.ex:75:    report = generate_report(audit_result, config)
lib/mix/tasks/lsp.security_audit.ex:81:    print_summary(audit_result)
lib/mix/tasks/lsp.security_audit.ex:84:    if has_critical_issues?(audit_result) do
lib/mix/tasks/lsp.security_audit.ex:88:      Mix.shell().info("✅ Security audit completed")
lib/mix/tasks/lsp.security_audit.ex:95:  defp run_comprehensive_audit(config) do
lib/mix/tasks/lsp.security_audit.ex:122:    mcp_security = audit_mcp_security()
lib/mix/tasks/lsp.security_audit.ex:219:  defp audit_mcp_security do
lib/mix/tasks/lsp.security_audit.ex:271:  defp generate_report(audit_result, config) do
lib/mix/tasks/lsp.security_audit.ex:273:      "json" -> generate_json_report(audit_result, config)
lib/mix/tasks/lsp.security_audit.ex:274:      "markdown" -> generate_markdown_report(audit_result, config)
lib/mix/tasks/lsp.security_audit.ex:275:      _ -> generate_text_report(audit_result, config)
lib/mix/tasks/lsp.security_audit.ex:279:  defp generate_text_report(audit_result, config) do
lib/mix/tasks/lsp.security_audit.ex:280:    all_issues = collect_all_issues(audit_result)
lib/mix/tasks/lsp.security_audit.ex:288:    Generated: #{DateTime.to_string(audit_result.timestamp)}
lib/mix/tasks/lsp.security_audit.ex:321:    #{generate_recommendations(audit_result)}
lib/mix/tasks/lsp.security_audit.ex:328:  defp generate_json_report(audit_result, config) do
lib/mix/tasks/lsp.security_audit.ex:329:    all_issues = collect_all_issues(audit_result)
lib/mix/tasks/lsp.security_audit.ex:334:        generated_at: audit_result.timestamp,
lib/mix/tasks/lsp.security_audit.ex:347:      recommendations: generate_recommendations_list(audit_result)
lib/mix/tasks/lsp.security_audit.ex:352:  defp generate_markdown_report(audit_result, config) do
lib/mix/tasks/lsp.security_audit.ex:353:    all_issues = collect_all_issues(audit_result)
lib/mix/tasks/lsp.security_audit.ex:359:    **Generated:** #{DateTime.to_string(audit_result.timestamp)}
lib/mix/tasks/lsp.security_audit.ex:384:    #{generate_markdown_recommendations(audit_result)}
lib/mix/tasks/lsp.security_audit.ex:388:  defp collect_all_issues(audit_result) do
lib/mix/tasks/lsp.security_audit.ex:389:    static_issues = audit_result.static_analysis.security_issues ++
lib/mix/tasks/lsp.security_audit.ex:390:                   audit_result.static_analysis.quality_issues ++
lib/mix/tasks/lsp.security_audit.ex:391:                   audit_result.static_analysis.performance_issues ++
lib/mix/tasks/lsp.security_audit.ex:392:                   audit_result.static_analysis.architecture_violations
lib/mix/tasks/lsp.security_audit.ex:394:    lsp_issues = audit_result.lsp_security.security_issues ++
lib/mix/tasks/lsp.security_audit.ex:395:                audit_result.lsp_security.quality_issues ++
lib/mix/tasks/lsp.security_audit.ex:396:                audit_result.lsp_security.performance_issues ++
lib/mix/tasks/lsp.security_audit.ex:397:                audit_result.lsp_security.architecture_violations
lib/mix/tasks/lsp.security_audit.ex:399:    runtime_issues = audit_result.runtime_security
lib/mix/tasks/lsp.security_audit.ex:400:    mcp_issues = audit_result.mcp_security
lib/mix/tasks/lsp.security_audit.ex:401:    race_issues = audit_result.race_conditions
lib/mix/tasks/lsp.security_audit.ex:455:  defp generate_recommendations(audit_result) do
lib/mix/tasks/lsp.security_audit.ex:468:  defp generate_recommendations_list(audit_result) do
lib/mix/tasks/lsp.security_audit.ex:481:  defp generate_markdown_recommendations(audit_result) do
lib/mix/tasks/lsp.security_audit.ex:505:  defp print_summary(audit_result) do
lib/mix/tasks/lsp.security_audit.ex:506:    all_issues = collect_all_issues(audit_result)
lib/mix/tasks/lsp.security_audit.ex:520:  defp has_critical_issues?(audit_result) do
lib/mix/tasks/lsp.security_audit.ex:521:    all_issues = collect_all_issues(audit_result)
lib/mix/tasks/lang.audit.parsers.ex:9:      mix lang.audit.parsers
lib/mix/tasks/lang.audit.parsers.ex:18:      mix lang.audit.parsers
lib/mix/tasks/lang.audit.parsers.ex:19:      mix lang.audit.parsers --format json
lib/mix/tasks/lang.audit.parsers.ex:20:      mix lang.audit.parsers --output reports/
lib/mix/tasks/lang.audit.parsers.ex:46:    Mix.shell().info("🔍 Starting parser audit...")
lib/mix/tasks/lang.audit.parsers.ex:48:    results = audit_all_parsers()
lib/mix/tasks/lang.audit.parsers.ex:68:  defp audit_all_parsers do
lib/mix/tasks/lang.audit.parsers.ex:70:    |> Enum.map(&audit_parser/1)
lib/mix/tasks/lang.audit.parsers.ex:74:  defp audit_parser(parser) do
lib/mix/tasks/lang.audit.parsers.ex:195:    path = Path.join(output_dir, "parser_audit.json")
lib/mix/tasks/spec.rollout.ex:24:    fallbacks =
lib/mix/tasks/spec.rollout.ex:29:      (from_flags ++ from_list ++ from_env ++ fallbacks)
lib/lang_ml/usage_predictor.ex:124:        # Return safe fallback prediction
lib/markdown_ld/hash.ex:6:  As a pragmatic fallback (no remote contexts, no canonicalizer), we provide
lib/markdown_ld/hash.ex:20:  If a canonicalizer is available, prefer URDNA2015; otherwise, fallback
lib/mix/tasks/spec.ingest.jsonld.ex:9:  hash (stable JSON fallback), and writes `hashes.json`. Ready to be wired to Kyozo/CDFM.
lib/mix/tasks/lang.refactor.parsers.ex:53:    # First run the audit
lib/mix/tasks/lang.refactor.parsers.ex:54:    {:ok, _} = Mix.Task.run("lang.audit.parsers", ["--format", "json"])
lib/mix/tasks/lang.refactor.parsers.ex:56:    # Load audit results
lib/mix/tasks/lang.refactor.parsers.ex:57:    results = Jason.decode!(File.read!("parser_audit.json"))
lib/mix/tasks/lang.refactor.parsers.ex:136:  defp generate_refactoring_plan(audit_results) do
lib/mix/tasks/lang.refactor.parsers.ex:140:        usage_data = Map.get(audit_results, from, %{})
```
