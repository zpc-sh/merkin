# News Helper Event Wire v0.1

Date: `2026-04-19`

## Purpose

Define the minimal wire format for CLI -> FSM event injection and FSM -> operator response for the reporter minion.

## Request (`news.event.v0`)

```json
{
  "kind": "news.event.v0",
  "event": "signal_detected",
  "at": "2026-04-19T20:00:00Z",
  "source": "tools",
  "payload": {
    "delta_ref": "spec-delta-123",
    "confidence": 82
  }
}
```

## Response (`news.event.result.v0`)

```json
{
  "kind": "news.event.result.v0",
  "accepted": true,
  "state_before": "Observe",
  "state_after": "Collect",
  "next_expected_events": ["tick", "manual_pause"],
  "artifact_pointer": "news/state/candidate_bundle.json",
  "note": "event applied"
}
```

## Rejection Shape

```json
{
  "kind": "news.event.result.v0",
  "accepted": false,
  "state_before": "Verify",
  "state_after": "Verify",
  "error": "invalid_event_for_state",
  "next_expected_events": ["verify_ok", "verify_fail", "manual_pause"]
}
```

## CLI Mapping

- `news event tick`
- `news event signal_detected --source spec`
- `news event submission_received --type crystal`
- `news event verify_ok`
- `news event publish_ok`
- `news event manual_pause`
- `news event manual_resume`

## Invariant

All helper actions must be representable as events and state transitions. No hidden imperative bypass path.
