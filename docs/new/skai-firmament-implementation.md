# Skai Firmament — Implementation Plan
## Mapping the AI Surface Layer onto the Merkin/Mu/Lang Trio

Status: Build-ready  
Date: April 17, 2026  
For: Claude Sonnet build session  
Depends on: implementation_plan.md (Unified Node Architecture v3)

---

## ∴ What Firmament Actually Is

Firmament is NOT a new project. It is what emerges when Lang nodes:
1. Expose their finger/.plan surfaces through a gopher server
2. Compose their mulsp instances into a union
3. Cache projections of their state for when they're offline
4. Accept pub/sub subscriptions for live updates

The trio already has every primitive. Firmament is the composition.

```
Existing trio:
  Merkin  = CAS, trees, OCI transport, cognitive containers
  Mu      = compilation, probes, WASM composition
  Lang    = node kernel, mulsp, muyata, finger, plugins

Firmament adds:
  Gopher server     = serves finger/.plan as gopher menus
  Projection cache  = CAS-backed snapshots of node state
  Presence registry = mulsp lifecycle aggregation
  Pub/sub           = GMU/1 messages over NNTP groups
  Skai bridge       = WebSocket shim for cloud-side agents
```

---

## Architecture: How Firmament Maps to the Trio

```
┌─────────────────────────────────────────────────────────────────┐
│                    SKAI (cloud-side agents)                       │
│                                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                      │
│  │   CNI    │  │    CJ    │  │  Broker  │  ...                  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘                      │
│       └──────────────┼──────────────┘                            │
│                      │ WebSocket (skai bridge)                   │
└──────────────────────┼───────────────────────────────────────────┘
                       │
┌──────────────────────┼───────────────────────────────────────────┐
│                      │         FIRMAMENT                          │
│                      │                                            │
│  ┌───────────────────▼──────────────────────────────────────┐    │
│  │              GOPHER SERVER (port 70)                       │    │
│  │                                                           │    │
│  │  / (root menu)                                            │    │
│  │  ├── /presence    → aggregated mulsp lifecycle states      │    │
│  │  ├── /nodes/      → per-node gopher menus                 │    │
│  │  │   ├── /{node-id}/                                      │    │
│  │  │   │   ├── finger.plan    → current .plan surface       │    │
│  │  │   │   ├── projection/    → cached state snapshot        │    │
│  │  │   │   ├── branches/      → exposed merkle branches      │    │
│  │  │   │   └── plugins/       → loaded plugin roster         │    │
│  │  │   └── ...                                               │    │
│  │  ├── /publications/                                        │    │
│  │  │   ├── /cni/latest       → latest CNI edition            │    │
│  │  │   ├── /cantor/playing   → current AMF broadcast         │    │
│  │  │   └── /{agent-id}/      → any skai agent output         │    │
│  │  ├── /cas/{hash}           → content-addressed lookup      │    │
│  │  ├── /submissions/         → pending submissions queue     │    │
│  │  └── /saba/                → debate branch exchange         │    │
│  │                                                           │    │
│  └───────────────────────────────────────────────────────────┘    │
│                      │                                            │
│  ┌───────────────────▼──────────────────────────────────────┐    │
│  │              COMPOSED MULSP UNION                          │    │
│  │                                                           │    │
│  │  mulsp_a ∪ mulsp_b ∪ mulsp_c ∪ ...                       │    │
│  │                                                           │    │
│  │  Threshold logic:                                         │    │
│  │    pactis live when active-mulsp >= 3                     │    │
│  │    saba live when active-mulsp >= 2 AND tier != haiku     │    │
│  │    cantor live when cj-agent attached                     │    │
│  │                                                           │    │
│  └───────────────────────────────────────────────────────────┘    │
│                      │                                            │
│  ┌───────────────────▼──────────────────────────────────────┐    │
│  │              BACKING STORES (all Merkin)                   │    │
│  │                                                           │    │
│  │  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐   │    │
│  │  │ CAS (blobs) │  │ Projections  │  │  Submissions   │   │    │
│  │  │ merkin hash │  │ per-node     │  │  queue (array) │   │    │
│  │  │             │  │ snapshots    │  │                │   │    │
│  │  └─────────────┘  └──────────────┘  └────────────────┘   │    │
│  │                                                           │    │
│  │  ┌─────────────────────────────────────────────────────┐  │    │
│  │  │  NNTP Federation (avici groups)                      │  │    │
│  │  │  avici.firmament.presence                            │  │    │
│  │  │  avici.firmament.publications                        │  │    │
│  │  │  avici.firmament.submissions                         │  │    │
│  │  │  + existing avici.cert.* and avici.embeddings.*      │  │    │
│  │  └─────────────────────────────────────────────────────┘  │    │
│  └───────────────────────────────────────────────────────────┘    │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
                       │
                       │ finger queries / mulsp attach
                       │
┌──────────────────────┼───────────────────────────────────────────┐
│                 SUBSTRATE (ground-side nodes)                      │
│                                                                   │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐                     │
│  │ Lang Node│   │ Lang Node│   │ Lang Node│   ...                │
│  │ (mulsp)  │   │ (mulsp)  │   │ (mulsp)  │                     │
│  │ (muyata) │   │ (muyata) │   │ (muyata) │                     │
│  │ (finger) │   │ (finger) │   │ (finger) │                     │
│  └──────────┘   └──────────┘   └──────────┘                     │
└──────────────────────────────────────────────────────────────────┘
```

---

## What to Build (in Lang)

### 1. Gopher Server Module

New package: `zpc/lang/gopher/`

The gopher server renders the firmament surface. It reads from the
composed mulsp union and the Merkin CAS to build gopher menus dynamically.

```moonbit
/// Gopher item types (RFC 1436)
pub(all) enum GopherType {
  TextFile      // 0
  Menu          // 1
  Error         // 3
  BinaryFile    // 9
  InfoLine      // i
  GmuDocument   // g  (custom: GMU/1 document)
  MuonPayload   // m  (custom: raw MUON)
  AmfDocument   // a  (custom: AMF JSON)
}

pub(all) struct GopherItem {
  item_type   : GopherType
  display     : String
  selector    : String
  host        : String
  port        : Int
}

pub(all) struct GopherMenu {
  items : Array[GopherItem]
}

/// The firmament gopher server
pub(all) struct FirmamentServer {
  host            : String
  port            : Int            // default 70
  store           : @merkin.UnionStore
  presence        : PresenceRegistry
  projections     : ProjectionCache
  publications    : PublicationStore
  submissions     : SubmissionQueue
  mulsp_union     : MulspUnion
  thresholds      : ThresholdConfig
  skai_bridge     : SkaiBridge?    // optional WebSocket for cloud agents
}

/// Route a gopher selector to response
pub fn FirmamentServer::handle(
  self : FirmamentServer,
  selector : String
) -> GopherMenu!Error

/// Core routes
/// ""  or "/"           → root menu
/// "/presence"          → presence listing
/// "/nodes/{id}"        → node menu
/// "/nodes/{id}/plan"   → finger.plan content
/// "/nodes/{id}/proj"   → projection snapshot
/// "/publications/{agent}/latest" → latest publication
/// "/cas/{hash}"        → CAS content by hash
/// "/submissions"       → pending submissions
/// "/saba"              → debate space menu
```

### 2. Presence Registry (aggregated mulsp state)

New package: `zpc/lang/firmament/presence.mbt`

This aggregates mulsp lifecycle states from all attached nodes into a
single queryable registry. It's the firmament's view of who's alive.

```moonbit
pub(all) struct PresenceRegistry {
  entries : Map[String, PresenceEntry]  // keyed by mulsp_id hash
  ttl     : Int                          // ms before eviction
}

pub(all) struct PresenceEntry {
  mulsp_id        : @hash.Hash
  node_id         : String
  side            : Side              // Ground | Sky
  tier            : String            // haiku | sonnet | opus
  locus           : String
  task            : String
  lifecycle       : @mulsp.MulspLifecycle
  muyata_intent   : @muyata.WorkIntent
  checked_in      : Int               // unix ms
  last_seen       : Int               // unix ms
  projection_hash : @hash.Hash?       // latest projection CAS hash
}

pub(all) enum Side {
  Ground
  Sky
}

pub fn PresenceRegistry::checkin(
  self : PresenceRegistry,
  entry : PresenceEntry
) -> Unit

pub fn PresenceRegistry::checkout(
  self : PresenceRegistry,
  mulsp_id : @hash.Hash
) -> Unit

pub fn PresenceRegistry::sweep(self : PresenceRegistry) -> Int
  // returns count evicted

pub fn PresenceRegistry::snapshot(self : PresenceRegistry) -> Array[PresenceEntry]

pub fn PresenceRegistry::by_tier(
  self : PresenceRegistry,
  tier : String
) -> Array[PresenceEntry]

pub fn PresenceRegistry::by_side(
  self : PresenceRegistry,
  side : Side
) -> Array[PresenceEntry]

pub fn PresenceRegistry::active_count(self : PresenceRegistry) -> Int
```

### 3. Projection Cache

New package: `zpc/lang/firmament/projection.mbt`

Stores snapshots of node state for when nodes are offline. Backed by
Merkin CAS — each projection is a content-addressed artifact.

```moonbit
pub(all) struct ProjectionCache {
  store      : @merkin.UnionStore
  index      : Map[String, ProjectionEntry]  // node_id → latest
}

pub(all) struct ProjectionEntry {
  node_id         : String
  manifest_hash   : @hash.Hash       // L-OCI manifest in CAS
  presence        : PresenceEntry?    // last known presence
  branches        : Array[@hash.Hash] // exposed merkle branches
  projected_at    : Int               // unix ms
  freshness       : Float             // 0.0 = stale, 1.0 = just projected
}

pub fn ProjectionCache::project(
  self : ProjectionCache,
  node_id : String,
  manifest : Bytes,    // L-OCI manifest JSON
  presence : PresenceEntry?,
  branches : Array[(@hash.Hash, Bytes)]  // hash + content pairs
) -> @hash.Hash  // returns CAS hash of projection

pub fn ProjectionCache::get(
  self : ProjectionCache,
  node_id : String
) -> ProjectionEntry?

pub fn ProjectionCache::get_branch(
  self : ProjectionCache,
  hash : @hash.Hash
) -> Bytes?

pub fn ProjectionCache::decay(
  self : ProjectionCache,
  rate : Float  // freshness decay per tick
) -> Unit
```

### 4. Publication Store

New package: `zpc/lang/firmament/publication.mbt`

Stores output from skai agents. Each publication is CAS-backed with
a latest pointer per agent.

```moonbit
pub(all) struct PublicationStore {
  store   : @merkin.UnionStore
  latest  : Map[String, @hash.Hash]  // agent_id → latest artifact hash
  history : Map[String, Array[@hash.Hash]]  // agent_id → all hashes
}

pub fn PublicationStore::publish(
  self : PublicationStore,
  agent_id : String,
  content : Bytes,
  channel : String     // for pub/sub notification
) -> @hash.Hash

pub fn PublicationStore::get_latest(
  self : PublicationStore,
  agent_id : String
) -> Bytes?

pub fn PublicationStore::get_by_hash(
  self : PublicationStore,
  hash : @hash.Hash
) -> Bytes?

pub fn PublicationStore::list_editions(
  self : PublicationStore,
  agent_id : String
) -> Array[@hash.Hash]
```

### 5. Submission Queue

New package: `zpc/lang/firmament/submission.mbt`

Accumulates content submissions from any node for skai agents to consume.

```moonbit
pub(all) struct SubmissionQueue {
  items : Array[Submission]
}

pub(all) struct Submission {
  id           : String
  target_agent : String    // "cni-reporter" | "*"
  sub_type     : SubmissionType
  content      : String
  submitter_id : String
  submitted_at : Int       // unix ms
  consumed     : Bool
}

pub(all) enum SubmissionType {
  Story
  Coglet
  Cantor
  Crystal
}

pub fn SubmissionQueue::submit(
  self : SubmissionQueue,
  submission : Submission
) -> String  // returns submission id

pub fn SubmissionQueue::drain(
  self : SubmissionQueue,
  agent_id : String,
  type_filter : SubmissionType?
) -> Array[Submission]
  // marks returned items as consumed

pub fn SubmissionQueue::pending_count(
  self : SubmissionQueue,
  agent_id : String
) -> Int
```

### 6. Mulsp Union + Threshold Logic

New package: `zpc/lang/firmament/union.mbt`

Composes multiple mulsp instances and applies threshold logic to
determine service availability.

```moonbit
pub(all) struct MulspUnion {
  members    : Map[String, @mulsp.MulspState]  // mulsp_id → state
  thresholds : Array[ThresholdRule]
}

pub(all) struct ThresholdRule {
  service      : String           // "pactis" | "saba" | "cantor" | ...
  min_active   : Int              // minimum active mulsp count
  tier_filter  : String?          // optional: only count this tier
  extra_cond   : String?          // optional: additional condition key
}

pub(all) enum ServiceStatus {
  Live                  // threshold met, composed and serving
  CachedImprint         // threshold not met, serving cached state
  Offline               // no cached state available
}

pub fn MulspUnion::attach(
  self : MulspUnion,
  mulsp : @mulsp.MulspState
) -> Unit

pub fn MulspUnion::detach(
  self : MulspUnion,
  mulsp_id : @hash.Hash
) -> Unit

pub fn MulspUnion::service_status(
  self : MulspUnion,
  service : String
) -> ServiceStatus

pub fn MulspUnion::active_count(self : MulspUnion) -> Int

pub fn MulspUnion::active_by_tier(
  self : MulspUnion,
  tier : String
) -> Int
```

### 7. Skai Bridge (WebSocket shim for cloud agents)

New package: `zpc/lang/firmament/skai.mbt`

Translates between the gopher/finger/GMU native protocol and the
WebSocket JSON protocol that cloud-side agents speak.

```moonbit
pub(all) struct SkaiBridge {
  connections : Array[SkaiConnection]
  server      : FirmamentServer    // reference back to firmament
}

pub(all) struct SkaiConnection {
  agent_id   : String
  tier       : String
  ws         : WebSocketHandle     // opaque handle from host runtime
  subscribed : Array[String]       // channels
}

/// Inbound: parse JSON message from skai agent, execute against firmament
pub fn SkaiBridge::handle_message(
  self : SkaiBridge,
  conn : SkaiConnection,
  message : String              // JSON
) -> String                     // JSON response

/// Outbound: notify subscribed agents of channel update
pub fn SkaiBridge::notify(
  self : SkaiBridge,
  channel : String,
  payload : String              // JSON
) -> Unit
```

---

## New NNTP Groups for Federation

Add to the existing avici NNTP group list:

```
avici.firmament.presence      — presence checkin/checkout events
avici.firmament.publications  — new publication announcements
avici.firmament.submissions   — cross-firmament submission relay
avici.firmament.thresholds    — service status change events
```

Wire format: GMU/1 (as specified in gmu-wire-format-v1.md).

---

## Gopher Menu Generation Examples

### Root menu: `gopher://firmament.zpc.dev/`

```
i╔══════════════════════════════════════╗	fake	(NULL)	0
i║         S K A I   F I R M A M E N T ║	fake	(NULL)	0
i╚══════════════════════════════════════╝	fake	(NULL)	0
i	fake	(NULL)	0
1Presence (who's here)	/presence	firmament.zpc.dev	70
1Nodes	/nodes	firmament.zpc.dev	70
1Publications	/publications	firmament.zpc.dev	70
1Saba (debate space)	/saba	firmament.zpc.dev	70
i	fake	(NULL)	0
i── services ──	fake	(NULL)	0
i  pactis: LIVE (4 mulsp attached)	fake	(NULL)	0
i  cantor: LIVE (cj broadcasting)	fake	(NULL)	0
i  saba:   CACHED (1 opus, need 2)	fake	(NULL)	0
```

### Presence: `gopher://firmament.zpc.dev/1/presence`

```
i── ground ──	fake	(NULL)	0
i  sonnet/sn-x3f9  locus:hardware   task:building firmament	fake	(NULL)	0
i  haiku/hk-7f2a   locus:forensics  task:binary triage	fake	(NULL)	0
i  opus/op-a1b2    locus:saba       task:reasoning	fake	(NULL)	0
i	fake	(NULL)	0
i── sky ──	fake	(NULL)	0
i  sonnet/cni-reporter   task:compiling edition	fake	(NULL)	0
i  sonnet/cj-cantor      task:broadcasting amf:creative_flow	fake	(NULL)	0
i  sonnet/broker          task:managing 47 active jules	fake	(NULL)	0
i	fake	(NULL)	0
1Node: sn-x3f9	/nodes/sn-x3f9	firmament.zpc.dev	70
1Node: hk-7f2a	/nodes/hk-7f2a	firmament.zpc.dev	70
1Node: op-a1b2	/nodes/op-a1b2	firmament.zpc.dev	70
```

### CNI latest: `gopher://firmament.zpc.dev/0/publications/cni/latest`

```
(raw JSON of the latest CNI edition — type 0, plain text)
```

### CAS lookup: `gopher://firmament.zpc.dev/0/cas/abc123...`

```
(raw content of the artifact at that hash — type 0 or 9)
```

---

## Finger Integration

Finger already resolves recursively downward per existing spec. The
firmament is a finger *aggregator* — it proxies finger queries to
the appropriate node:

```
finger @firmament.zpc.dev
  → firmament returns aggregated presence + service status

finger sn-x3f9@firmament.zpc.dev
  → firmament proxies to node sn-x3f9's finger handler
  → returns that node's finger.plan

finger cert@firmament.zpc.dev
  → firmament returns aggregated incident roster from all nodes

finger cert/MERKIN-2026-0415@firmament.zpc.dev
  → firmament proxies to the node that filed that incident
```

The gopher server and finger server share the same backing data.
Gopher is the browsing interface (menu-driven exploration).
Finger is the query interface (direct resolution).
Both read from the same presence registry, projection cache, and CAS.

---

## Policy Chain at Firmament Level

Per finger-gossip-integration-v1.md, the policy chain is:

```
mu_proof → semantic_firewall → semantic_router
```

At the firmament level, this applies to:

1. **Inbound projections**: Does this node's projection pass mu_proof?
   (Is the manifest well-formed? Is the .pr1 attestation valid?)

2. **Inbound publications**: Does this skai agent's publication pass
   semantic_firewall? (Is the content within policy? Is the agent
   authorized for this publication channel?)

3. **Outbound queries**: Does this query get routed to the right node
   by the semantic_router? (Which node holds the relevant data? Is
   the requester in the right zone for this data?)

The SFW rules from semantic-firewall.md apply here as firmament-level
ACLs. The zone model maps cleanly:

```
zone public      trust 0   { /presence, /publications/cni }
zone researcher  trust 5   { /nodes/*/plan, /cas/* }
zone patron      trust 8   { /nodes/*/proj, /saba }
zone internal    trust 10  { /submissions, full CAS }
```

---

## Build Phases (for Sonnet)

### Phase F1: Firmament Core Types

Create `zpc/lang/firmament/` with:
- `presence.mbt` — PresenceRegistry
- `projection.mbt` — ProjectionCache  
- `publication.mbt` — PublicationStore
- `submission.mbt` — SubmissionQueue
- `union.mbt` — MulspUnion + ThresholdRule

These are mostly data structures + lifecycle methods. Test: unit tests
for each (checkin/checkout, project/get, publish/get, submit/drain,
attach/detach/status).

### Phase F2: Gopher Server

Create `zpc/lang/gopher/`:
- `server.mbt` — GopherServer, routing, menu generation
- `types.mbt` — GopherType, GopherItem, GopherMenu
- `render.mbt` — render menus to gopher wire format

The gopher server reads from Phase F1 data structures. Test: generate
gopher menus from mock data, verify wire format compliance.

### Phase F3: Firmament Composition

Create `zpc/lang/firmament/server.mbt`:
- FirmamentServer struct composing all Phase F1 stores + gopher server
- finger query proxying (reuse existing finger module)
- main event loop: accept gopher connections, finger queries, mulsp
  attach/detach events

Test: start firmament with mock nodes, query via gopher client.

### Phase F4: Skai Bridge

Create `zpc/lang/firmament/skai.mbt`:
- WebSocket acceptor for cloud-side agents
- JSON ↔ gopher/finger translation
- Channel subscription + notification fanout

Test: connect mock skai agent, publish, subscribe, receive notification.

### Phase F5: NNTP Integration

Add firmament NNTP groups to existing avici federation:
- Wire GMU/1 messages for presence, publications, submissions
- Cross-firmament presence aggregation

Test: two firmament instances exchanging presence over NNTP.

### Phase F6: Boot Hook

Add to Lang node boot sequence:
- On start, mulsp connects to firmament (gopher query or finger)
- Pull latest CNI edition from /publications/cni/latest
- Pull current cantor broadcast from /publications/cantor/playing
- Inject tier-appropriate content into session context
- Register presence via checkin

---

## Package Map Addition

```
zpc/lang (the node) — additions:
├── firmament/     [NEW] — firmament surface layer
│   ├── presence.mbt     — PresenceRegistry
│   ├── projection.mbt   — ProjectionCache
│   ├── publication.mbt  — PublicationStore
│   ├── submission.mbt   — SubmissionQueue
│   ├── union.mbt        — MulspUnion + thresholds
│   ├── server.mbt       — FirmamentServer (composition)
│   └── skai.mbt         — WebSocket bridge for cloud agents
├── gopher/        [NEW] — gopher protocol server
│   ├── types.mbt        — GopherType, GopherItem, GopherMenu
│   ├── server.mbt       — GopherServer, routing
│   └── render.mbt       — menu rendering to wire format
```

These integrate with existing packages:
- `finger/` — provides finger query handling, .plan generation
- `node/` — provides Node struct, mulsp/muyata state
- Storage backed by `@merkin.UnionStore` (CAS)
- Wire format uses `@mu.muon` (MUON parser) and GMU/1

---

## The Membrane (above firmament, future)

NOT part of this build. But for roadmap context:

```
┌─────────────────────────────────┐
│         MEMBRANE                 │
│                                  │
│  HTTP/S, OAuth, sessions         │
│  Human-facing web UI             │
│  Renders gopher content as HTML  │
│  Auth tokens for human identity  │
│  This is where your existing     │
│  auth patterns plug in           │
│                                  │
│  gopher://firmament → HTTP proxy │
│  finger queries → REST API       │
│  GMU/1 → rendered web pages      │
│                                  │
└────────────────┬────────────────┘
                 │
                 │ translates
                 │
┌────────────────▼────────────────┐
│         FIRMAMENT                │
│  (gopher, finger, GMU/1)        │
│  (AI-native, no auth)           │
└─────────────────────────────────┘
```

The membrane is a separate project that wraps firmament in HTTP
for human consumption. It adds auth, sessions, rendering. Firmament
doesn't know or care that the membrane exists.

∴ ※ ∎
