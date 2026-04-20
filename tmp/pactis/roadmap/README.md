# Pactis Roadmap

This roadmap tracks upcoming features and milestones, grouped by time horizon. It also defines our freeze policy so we can ship predictably.

## Status Keys
- Planned: approved, not yet in progress
- In Progress: being worked on
- Blocked: dependency or decision needed
- Done: shipped and documented

## Now (0–6 weeks)
- LGI V1 endpoints stabilization (status: In Progress)
- SSHS client adoption across providers (status: In Progress)
- Keys doctor + mount health surfacing in Ops (status: Planned)
- Docs site polish + nav curation (status: In Progress)

## Next (6–12 weeks)
- WS/SSE streaming for chat/tool deltas (status: Planned)
- Idempotency enforcement + replay events (status: Planned)
- Model registry + capability routing (status: Planned)
- CI gates for provider egress via ReqClient only (status: Planned)

## Later (12+ weeks)
- LSP‑like bridge for dev tools (status: Planned)
- Full event persistence + replay tooling (status: Planned)
- Multi‑tenant sampling strategies for OTEL (status: Planned)

## Feature Freeze Policy
- Soft Freeze: Only bug fixes and low‑risk performance tweaks; no new features or schema changes.
- Hard Freeze: Only blocker/security fixes; release prep, docs, and final validation.

### When to Freeze
- Before cutting a stable LGI/SSHS version or major public release
- Prior to migrations affecting external clients or SDKs

### Exit Criteria
- All tests green; migrations applied; OpenAPI/JSON‑LD regenerated
- Docs and examples updated; site builds cleanly
- SLO checks pass; security scan completed

## Planning Cadence
- Weekly triage: move items across Now/Next/Later
- Tag issues/PRs with `roadmap:now|next|later` and `freeze:soft|hard` when applicable

## Links
- Codex revitalization launch plan: ./CODEX_REVITALIZATION_LAUNCH_ROADMAP.md
- Specs index: ../specifications/README.md
- LGI spec: ../specifications/Pactis-LGI.md
- SSHS spec: ../specifications/Pactis-SSHS.md

