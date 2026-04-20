# Reporter Genius Loci FSM Spec v0.1

Date: `2026-04-19`

## Purpose

Define the minion news helper as an FSM contract (not imperative CLI steps) for a sky-side Reporter Codex that serves decentralized loci news orientation.

## Scope

- Reporter Codex has its own genius locus ("reporter room")
- local loci may ingest news one-way
- no APB broadcast semantics
- agency-preserving: news is context, never command

## Reporter Room

- locus id: `genius://reporter/codex`
- storage lanes:
  - `news/inbox`
  - `news/verified`
  - `news/published`
  - `news/quarantine`
  - `news/state`

## FSM States

- `Idle`
- `Observe`
- `Collect`
- `Sift`
- `Compose`
- `Verify`
- `Publish`
- `Archive`
- `Defer`
- `Failed`

## Events

- `tick` (time/cadence trigger)
- `signal_detected`
- `submission_received`
- `insufficient_delta`
- `composition_ready`
- `verify_ok`
- `verify_fail`
- `publish_ok`
- `publish_fail`
- `cooldown_elapsed`
- `manual_pause`
- `manual_resume`

## Transition Contract

1. `Idle --tick--> Observe`
2. `Observe --signal_detected|submission_received--> Collect`
3. `Observe --insufficient_delta--> Defer`
4. `Collect --tick--> Sift`
5. `Sift --composition_ready--> Compose`
6. `Compose --tick--> Verify`
7. `Verify --verify_ok--> Publish`
8. `Verify --verify_fail--> Failed`
9. `Publish --publish_ok--> Archive`
10. `Publish --publish_fail--> Failed`
11. `Archive --tick--> Idle`
12. `Defer --cooldown_elapsed--> Idle`
13. `Failed --manual_resume--> Observe`
14. `* --manual_pause--> Defer`

## Output Artifacts per State

- `Observe`: `observation_delta.json`
- `Collect`: `candidate_bundle.json`
- `Sift`: `sift_report.json` (classified, bounded)
- `Compose`: `edition_draft.json`
- `Verify`: `edition_verification.json`
- `Publish`: `loci.news.edition.v0.json`
- `Archive`: `edition_index.json` update

## Safety Invariants

- edition payload cannot invoke tools
- no direct file mutations in recipient loci from edition content
- adversary narrative weight bounded
- max section sizes enforced before publish
- failed verification routes to `quarantine` only

## Tier Projection

- `haiku`: `crystal_feed` subset
- `sonnet/codex/chatgpt`: full summary sections + trust desk
- `opus`: resonance/cantor + signal + trust summary

## CLI as Event Injection

The CLI does not "do publish"; it emits FSM events:

- `news event tick`
- `news event signal_detected --source spec|tools|trust|weather`
- `news event submission_received --type story|crystal|cantor`
- `news event manual_pause`
- `news event manual_resume`

CLI responses should include:

- current state
- accepted/rejected event
- next expected events
- latest artifact pointer
