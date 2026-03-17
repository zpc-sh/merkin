///|
///se do
/// Unified content-addressable store interface.
pub(open) trait StoreNode {
  node_id(Self) -> String
  role(Self) -> StoreRole
  availability(Self) -> Availability
  has_blob(Self, @hash.Hash) -> Bool
  get_blob(Self, @hash.Hash) -> Bytes?
  put_blob(Self, Bytes) -> @hash.Hash
}

///|
/// Adapter for the in-memory ArtifactStore backend.
pub(all) struct ArtifactCasNode {
  id : String
  role_kind : StoreRole
  mut status : Availability
  backend : @store.ArtifactStore
}

///|
pub fn ArtifactCasNode::new(
  id : String,
  role_kind : StoreRole,
  status? : Availability = Online,
) -> ArtifactCasNode {
  { id, role_kind, status, backend: @store.ArtifactStore::new() }
}

///|
pub fn ArtifactCasNode::set_availability(
  self : ArtifactCasNode,
  status : Availability,
) -> Unit {
  self.status = status
}

///|
/// Expose this node as a trait object for union composition.
pub fn ArtifactCasNode::as_store_node(self : ArtifactCasNode) -> &StoreNode {
  self as &StoreNode
}

///|
impl StoreNode for ArtifactCasNode with node_id(self : ArtifactCasNode) -> String {
  self.id
}

///|
impl StoreNode for ArtifactCasNode with role(self : ArtifactCasNode) -> StoreRole {
  self.role_kind
}

///|
impl StoreNode for ArtifactCasNode with availability(self : ArtifactCasNode) -> Availability {
  self.status
}

///|
impl StoreNode for ArtifactCasNode with has_blob(
  self : ArtifactCasNode,
  digest : @hash.Hash,
) -> Bool {
  self.backend.get(digest) is Some(_)
}

///|
impl StoreNode for ArtifactCasNode with get_blob(
  self : ArtifactCasNode,
  digest : @hash.Hash,
) -> Bytes? {
  match self.backend.get(digest) {
    Some(artifact) =>
      match artifact.payload_ref {
        @model.Inline(data) => Some(data)
      }
    None => None
  }
}

///|
impl StoreNode for ArtifactCasNode with put_blob(
  self : ArtifactCasNode,
  bytes : Bytes,
) -> @hash.Hash {
  let artifact = @model.Artifact::from_bytes(bytes)
  ignore(self.backend.put(artifact))
  artifact.content_hash
}

///|
pub(all) enum DispatchState {
  Committed
  Duplicate
  SkippedTree
  SkippedPolicy
  SkippedBackpressure
} derive(Eq, Show)

///|
pub(all) struct DispatchResult {
  target_id : String
  state : DispatchState
  op_key : @hash.Hash?
  digest : @hash.Hash?
} derive(Show)

///|
pub(all) struct ReplicationReceipt {
  subject_hash : @hash.Hash
  lane : ReplicationLane
  event : ReplicationEvent
  committed_count : UInt
  quorum_met : Bool
  dispatches : Array[DispatchResult]
} derive(Show)

///|
/// Composable union store over heterogeneous store nodes.
pub(all) struct UnionStore {
  nodes : Array[&StoreNode]
  mut ledger : IdempotencyLedger
}

///|
pub fn UnionStore::new() -> UnionStore {
  { nodes: [], ledger: IdempotencyLedger::new() }
}

///|
pub fn UnionStore::add_node(self : UnionStore, node : &StoreNode) -> Unit {
  self.nodes.push(node)
}

///|
pub fn UnionStore::node_count(self : UnionStore) -> Int {
  self.nodes.length()
}

///|
pub fn UnionStore::ledger_snapshot(self : UnionStore) -> IdempotencySnapshot {
  self.ledger.snapshot()
}

///|
pub fn UnionStore::restore_ledger(
  self : UnionStore,
  snapshot : IdempotencySnapshot,
) -> Unit {
  self.ledger = IdempotencyLedger::restore(snapshot)
}

///|
/// Presence check across eligible nodes in order.
pub fn UnionStore::has_blob(
  self : UnionStore,
  digest : @hash.Hash,
  lane : ReplicationLane,
  policy : ReplicationPolicy,
) -> Bool {
  for node in self.nodes {
    if !policy.allows_target(
        node.node_id(),
        node.role(),
        lane,
        node.availability(),
      ) {
      continue
    }
    if node.has_blob(digest) {
      return true
    }
  }
  false
}

///|
/// Read from the first eligible node that has the blob.
pub fn UnionStore::get_blob(
  self : UnionStore,
  digest : @hash.Hash,
  lane : ReplicationLane,
  policy : ReplicationPolicy,
) -> Bytes? {
  for node in self.nodes {
    if !policy.allows_target(
        node.node_id(),
        node.role(),
        lane,
        node.availability(),
      ) {
      continue
    }
    match node.get_blob(digest) {
      Some(bytes) => return Some(bytes)
      None => ()
    }
  }
  None
}

///|
/// Replicate bytes to eligible nodes with idempotency and backpressure gating.
pub fn UnionStore::put_blob(
  self : UnionStore,
  bytes : Bytes,
  lane : ReplicationLane,
  event : ReplicationEvent,
  path : Array[String],
  sealed_epoch : Bool,
  live_replicas : UInt,
  queue_stats : QueueStats,
  policy : ReplicationPolicy,
) -> ReplicationReceipt {
  let subject_hash = @hash.Hash::of_bytes(bytes)
  let mut committed = 0U
  let dispatches : Array[DispatchResult] = []

  if !policy.tree_accepts(path, lane, sealed_epoch, live_replicas) {
    for node in self.nodes {
      dispatches.push({
        target_id: node.node_id(),
        state: SkippedTree,
        op_key: None,
        digest: None,
      })
    }
    return {
      subject_hash,
      lane,
      event,
      committed_count: 0U,
      quorum_met: false,
      dispatches,
    }
  }

  for node in self.nodes {
    let target_id = node.node_id()
    let role = node.role()
    let availability = node.availability()

    if !policy.allows_target(target_id, role, lane, availability) {
      dispatches.push({
        target_id,
        state: SkippedPolicy,
        op_key: None,
        digest: None,
      })
      continue
    }

    let op_key = policy.idempotency_key(subject_hash, target_id, lane, event)
    if self.ledger.is_committed(op_key) {
      dispatches.push({
        target_id,
        state: Duplicate,
        op_key: Some(op_key),
        digest: Some(subject_hash),
      })
      continue
    }

    if !policy.allow_dispatch(lane, queue_stats) {
      dispatches.push({
        target_id,
        state: SkippedBackpressure,
        op_key: Some(op_key),
        digest: None,
      })
      continue
    }

    self.ledger.mark_pending(op_key)
    let digest = node.put_blob(bytes)
    self.ledger.mark_committed(op_key)
    committed = committed + 1U
    dispatches.push({
      target_id,
      state: Committed,
      op_key: Some(op_key),
      digest: Some(digest),
    })
  }

  {
    subject_hash,
    lane,
    event,
    committed_count: committed,
    quorum_met: committed >= policy.quorum_write,
    dispatches,
  }
}
