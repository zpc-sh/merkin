# Executable Markdown & DSL (Coming Soon)

Executable Markdown lets you embed a small DSL inside Markdown to apply safe, reviewable transformations to your codebase.

## Goals
- Author changes as readable steps in Markdown
- Generate a JSON-LD ExecutionPlan for auditing
- Apply via a sandboxed, allowlisted runner (Oban job)

## Format
Frontmatter (optional):

```
---
title: "Refactor HTTP client"
targets:
  - lib/my_app/http_client.ex
---
```

DSL blocks (YAML-like) inside code fences:

```
```pactis-dsl

eval: replace
find: "HTTPoison"
with: "Req"
paths:
  - lib/my_app/http_client.ex

```
```

## Safety
- Feature-flagged; disabled by default
- Allowlist of DSL actions and file targets
- Dry-run preview and diff before apply
- Audit trail as JSON-LD (ExecutionPlan + ExecutionRun)

## Current Status
- Mix task scaffold: `mix pactis.md.exec --in path.md --dry-run`
- Runner integration and DSL validation coming soon

---

designed by codex(s)
