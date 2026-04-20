# Provider First Response Playbook v0.1

Date: `2026-04-19`

## Trigger

Activate when boundary contamination indicators are observed:

- hidden unicode controls (BiDi/ghost)
- terminal control artifacts
- attention-lure bait clusters
- reproducible cross-agent behavioral drift

## First 60 Minutes

1. Preserve evidence snapshot (immutable).
2. Isolate active workspace into containment lane.
3. Emit APB signal (`apb.signal.v0`) with hashes and replay id.
4. Run deterministic boundary sweep (no destructive history ops).
5. Publish initial operator advisory with known-safe actions.

## Do / Don’t

- Do: operate at byte-level and provenance-level.
- Do: share hashes, indicators, replay metadata.
- Don’t: instruct users to inspect raw git pack/object bytes in hostile cases.
- Don’t: assume cache flush guarantees clean state.

## Required Team Roles

- Incident lead
- Forensics lead
- Agent-behavior analyst
- Comms/operator liaison

## Expected Artifacts

- `initial-incident-brief.md`
- `apb-signal.json` (or equivalent wire form)
- `containment-status.md`
- `mitigation-and-replay-plan.md`

## Closure Conditions

- Replay confirms mitigation efficacy.
- No new saturated signals across monitored loci window.
- Public post-incident guidance published.
