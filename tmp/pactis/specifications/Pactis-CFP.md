# Pactis‑CFP: Context Frame Protocol

- Status: Draft
- Last Updated: 2026-04-02
- Owners: Pactis Core
- Related: Pactis‑CCV2, Pactis‑KEI, Pactis‑SRI, SpecAPI, Kyozo

## Summary
Pactis‑CFP defines the canonical “Context Frame” object supplied to every conversation/negotiation. The frame conveys cognitive state, service capabilities, active project context, and correlations to related systems so agents (humans or LLMs) can act with shared context and correct altitude.

## CCV2 Compatibility (Sabha Profile)

Under Pactis-CCV2, CFP is the canonical bootstrap envelope for Sabha sessions and branch contexts:

1. frames seed Hall orchestration with scope, capabilities, and active decision context
2. frames are context carriers and MUST NOT replace SymbolForm as canonical truth
3. frame references should include commitment/provenance pointers where available for replay continuity

Reference:

- [Pactis-CCV2.md](./Pactis-CCV2.md)
- [Pactis-Sabha-Operations.md](./Pactis-Sabha-Operations.md)

## Concepts
- ContextFrame: primary envelope delivered to callers.
- CognitiveState: indirection/altitude (0–5) and current mode.
- ServiceRegistry: AI‑oriented view of services (from Pactis‑SRI) with summaries and capabilities.
- ActiveContext: projects, patterns, decisions, and recent work relevant to the current scope.
- Correlation: links to SpecAPI threads/requests and Kyozo sessions.

## JSON‑LD Shapes

Base context (reference):
```json
{
  "@context": {
    "avici": "https://pactis.dev/avici#",
    "sri": "https://pactis.dev/sri#",
    "spec": "https://pactis.dev/spec#",
    "prov": "http://www.w3.org/ns/prov#",
    "schema": "https://schema.org/"
  }
}
```

Example ContextFrame:
```json
{
  "@context": {"avici": "https://pactis.dev/avici#", "sri": "https://pactis.dev/sri#", "spec": "https://pactis.dev/spec#"},
  "@type": "avici:ContextFrame",
  "avici:frameVersion": "1.0",
  "avici:issuedAt": "2025-09-20T12:00:00Z",
  "avici:cognitiveState": {
    "avici:indirection": 3,
    "avici:mode": "architect",
    "avici:avoid": ["implementation_details"]
  },
  "avici:serviceRegistry": [
    {
      "@type": "sri:Service",
      "@id": "urn:pactis:service:specapi",
      "sri:name": "SpecAPI",
      "avici:capabilities": ["cross-repo-negotiation", "message-exchange"],
      "avici:aiSummary": "Conversation-driven spec requests, checkpoints, and consensus."
    },
    {
      "@type": "sri:Service",
      "@id": "urn:pactis:service:kyozo",
      "sri:name": "Kyozo Store",
      "avici:capabilities": ["ai-memory", "state-persistence"],
      "avici:aiSummary": "Long-lived memory and session state for agents."
    }
  ],
  "avici:activeContext": {
    "avici:projects": [ {"@id": "urn:proj:pactis"} ],
    "avici:patterns": [ {"@id": "urn:pattern:async-jobs"} ],
    "avici:decisions": [ {"@id": "urn:decision:use-oban"} ],
    "avici:recentWork": [ {"@id": "urn:work:smi-billing"} ]
  },
  "avici:correlation": {
    "spec:thread": {"@id": "urn:spec:thread:t123"},
    "spec:request": {"@id": "urn:spec:req:r456"},
    "avici:kyozoSession": "sess_abc"
  }
}
```

Fields (required):
- frameVersion, issuedAt
- cognitiveState.indirection (0–5), cognitiveState.mode
- serviceRegistry[] (sri:Service entries or references)

## Conformance
- Frames MUST be deterministic for a given (scope, include, dependency versions) tuple.
- Frames MUST reference services defined in Pactis‑SRI or include minimal inlined service entries.
- CognitiveState MUST use defined ranges and modes.
- Updates MUST preserve provenance (prov:wasDerivedFrom where applicable).

## Integration
- SpecAPI: attach a ContextFrame to each request before evaluation.
- SRI: populate serviceRegistry from the canonical service registry; AI summaries/capabilities may be augmented by KEI.
- Kyozo: expose session link(s) for continuity.

## Versioning
- frameVersion is semver-ish; breaking field changes bump the major version.
- Context IRIs SHOULD be immutable per major version.
