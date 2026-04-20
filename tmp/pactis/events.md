Event Naming & Versioning Guidelines

Purpose
- Establish consistent, auditable events across the app using AshEvents.
- Support versioned payloads, correlation/causation tracking, and safe, minimal data.

Core Concepts
- Action events (AshEvents): Logged automatically when a resource has `events do event_log(Pactis.Events.Event) end`.
- Business events (custom): Emitted via `Pactis.Events.emit/2` for non-action flows (e.g., Auth.Register, Org.InviteAccepted).
- Versioning: Use semantic versions per event name (start at "v1"). Bump when payload semantics change.
- Context: Include `actor` (user id/email), optional `tenant` (org/workspace id), `correlation_id` and `causation_id` to stitch event chains.

Resource Setup (Action Events)
- Add to each resource you want logged:

  events do
    event_log(Pactis.Events.Event)
    # current_action_versions(create: 1, update: 1)
    # store_sensitive_attributes([]) # default: don't store sensitive values
  end

Business Events (Custom)
- Use `Pactis.Events.emit/2`:

  Pactis.Events.emit("Org.InviteAccepted",
    version: "v1",
    actor: %{user_id: to_string(user.id)},
    tenant: org_id,
    resource: "Pactis.Accounts.Invitation/#{invite.id}",
    correlation_id: corr_id,
    causation_id: cause_id,
    payload: %{role: invite.role}
  )

Naming Conventions
- Names: Domain.Action (VerbPastTense where appropriate)
  - Auth.Register, Auth.SignIn, Org.InviteCreated, Org.InviteResent, Org.InviteAccepted
  - Spec.RequestCreated, Spec.RequestStatusUpdated
  - LGI.ModelCallStarted, LGI.ModelCallCompleted
- Resource: Fully-qualified resource reference when relevant, e.g. `Pactis.Accounts.User/UUID`.

Versioning
- Start with "v1" for each event name.
- Bump (v2, v3, …) when:
  - Payload keys change meaning or structure
  - You add/remove required keys consumed by downstream services
- Keep old emit points during migrations if consumers rely on both versions.

Correlation & Causation
- correlation_id: A stable id for a request/flow to tie multiple events together.
- causation_id: The originating event id if one event triggers another.
- For HTTP requests, set correlation_id from request id; propagate across async jobs and emits.

Actor & Tenant
- actor: Include minimal identifiers (e.g., user_id, email).
- tenant: Include org/workspace id when available to scope the event.

Sensitive Data
- Do NOT include secrets, plaintext tokens, or PII beyond minimal ids.
- Prefer ids and summaries over full objects.
- For action events: leave `store_sensitive_attributes` empty (default).

Telemetry
- Each emit produces telemetry: `[:pactis, :events, :emit]` with measurements `%{count: 1}` and metadata `%{name, severity}`.
- Use this for metrics dashboards and alerting.

Implementation Checklist
- [ ] Resource has `events do event_log(Pactis.Events.Event) end`.
- [ ] Non-action flows emit via `Pactis.Events.emit/2` with version, actor, correlation_id where applicable.
- [ ] No sensitive data in event payloads.
- [ ] correlation_id/causation_id propagated across jobs/steps.
- [ ] Tests (where applicable) assert the presence of a logged event for critical flows.

Examples
- User registered (controller):

  Pactis.Events.emit("Auth.Register",
    version: "v1",
    actor: %{user_id: to_string(user.id), email: user.email},
    resource: "Pactis.Accounts.User/#{user.id}"
  )

- Invitation created (resource after_action):

  Pactis.Events.emit("Org.InviteCreated",
    version: "v1",
    actor: %{user_id: to_string(inviter_id)},
    resource: "Pactis.Accounts.Invitation/#{invite.id}",
    payload: %{org_id: invite.org_id, invitee_email: to_string(invite.invitee_email), role: invite.role}
  )

