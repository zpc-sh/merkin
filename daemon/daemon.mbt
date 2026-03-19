///|
/// Daemon runtime mode.
pub(all) enum DaemonMode {
  Receiver
  Proxy
  PassThrough
  Hybrid
} derive(Eq, Show)

///|
/// OCI facility toggles for one node.
pub(all) struct OciFacility {
  receiver : Bool
  proxy : Bool
  passthrough : Bool
} derive(Eq, Show)

///|
pub fn OciFacility::from_mode(mode : DaemonMode) -> OciFacility {
  match mode {
    Receiver => { receiver: true, proxy: false, passthrough: false }
    Proxy => { receiver: false, proxy: true, passthrough: false }
    PassThrough => { receiver: false, proxy: false, passthrough: true }
    Hybrid => { receiver: true, proxy: true, passthrough: true }
  }
}

///|
/// Dispatch outcome for OCI ingress handling.
pub(all) enum OciDisposition {
  Stored
  Forwarded
  Bypassed
  Rejected
} derive(Eq, Show)

///|
pub(all) struct OciPutRequest {
  payload : Bytes
  lane : @storage.ReplicationLane
  event : @storage.ReplicationEvent
  path : Array[String]
  sealed_epoch : Bool
} derive(Show)

///|
pub fn OciPutRequest::default(payload : Bytes) -> OciPutRequest {
  {
    payload,
    lane: @storage.Hot,
    event: @storage.Ingest,
    path: ["ingest", "oci"],
    sealed_epoch: false,
  }
}

///|
pub(all) struct OciPutResult {
  disposition : OciDisposition
  digest : @hash.Hash
  receipt : @storage.ReplicationReceipt?
  reason : String?
} derive(Show)

///|
fn root_node_hash() -> @hash.Hash {
  @hash.Hash::of_bytes(b"\x00\x00\x00\x01")
}

///|
fn route_path(path : Array[String]) -> Array[String] {
  if path.length() == 0 {
    ["ingest", "oci"]
  } else {
    path
  }
}

///|
fn has_child(node : @tree.MerkinNode, child_id : @hash.Hash) -> Bool {
  for child in node.children {
    if child.node_id == child_id {
      return true
    }
  }
  false
}

///|
fn route_child_hash(parent_id : @hash.Hash, segment : String) -> @hash.Hash {
  @hash.Hash::of_bytes(daemon_string_to_bytes(parent_id.key() + "|" + segment))
}

///|
pub(all) struct DaemonNode {
  node_id : String
  mode : DaemonMode
  oci : OciFacility
  union_store : @storage.UnionStore
  mut index_tree : @tree.MerkinTree
  mut policy : @storage.ReplicationPolicy
  mut queue_stats : @storage.QueueStats
  mut live_replicas : UInt
}

///|
pub fn DaemonNode::new(
  node_id : String,
  mode : DaemonMode,
  policy : @storage.ReplicationPolicy,
  oci? : OciFacility? = None,
  live_replicas? : UInt = 1U,
) -> DaemonNode {
  {
    node_id,
    mode,
    oci: match oci {
      Some(flags) => flags
      None => OciFacility::from_mode(mode)
    },
    union_store: @storage.UnionStore::new(),
    index_tree: @tree.MerkinTree::new(),
    policy,
    queue_stats: @storage.QueueStats::idle(),
    live_replicas,
  }
}

///|
pub fn DaemonNode::add_store(
  self : DaemonNode,
  node : &@storage.StoreNode,
) -> Unit {
  self.union_store.add_node(node)
}

///|
pub fn DaemonNode::set_policy(
  self : DaemonNode,
  policy : @storage.ReplicationPolicy,
) -> Unit {
  self.policy = policy
}

///|
pub fn DaemonNode::set_queue_stats(
  self : DaemonNode,
  stats : @storage.QueueStats,
) -> Unit {
  self.queue_stats = stats
}

///|
pub fn DaemonNode::set_live_replicas(self : DaemonNode, live : UInt) -> Unit {
  self.live_replicas = live
}

///|
pub fn DaemonNode::capabilities(self : DaemonNode) -> OciFacility {
  self.oci
}

///|
pub fn DaemonNode::can_receive_oci(self : DaemonNode) -> Bool {
  self.oci.receiver
}

///|
pub fn DaemonNode::can_proxy_oci(self : DaemonNode) -> Bool {
  self.oci.proxy
}

///|
pub fn DaemonNode::can_passthrough_oci(self : DaemonNode) -> Bool {
  self.oci.passthrough
}

///|
fn DaemonNode::index_digest_route(
  self : DaemonNode,
  digest : @hash.Hash,
  path : Array[String],
) -> Unit {
  let routed = route_path(path)
  let root_id = root_node_hash()

  if self.index_tree.get_node(root_id) is None {
    self.index_tree.upsert_node(@tree.MerkinNode::leaf(root_id))
  }

  let mut parent_id = root_id
  for segment in routed {
    let child_id = route_child_hash(parent_id, segment)
    if self.index_tree.get_node(child_id) is None {
      self.index_tree.upsert_node(@tree.MerkinNode::leaf(child_id))
    }
    match self.index_tree.get_node(parent_id) {
      Some(parent) =>
        if !has_child(parent, child_id) {
          ignore(self.index_tree.add_child_edge(parent_id, child_id))
        }
      None => ()
    }
    parent_id = child_id
  }

  match self.index_tree.get_node(parent_id) {
    Some(leaf) =>
      self.index_tree.upsert_node(leaf.attach_envelope(digest, routed))
    None => ()
  }
}

///|
pub fn DaemonNode::sparse_view(
  self : DaemonNode,
  tokens : Array[String],
) -> @tree.SparseMerkinTree {
  self.index_tree.sparse(tokens)
}

///|
pub fn DaemonNode::indexed_node_count(self : DaemonNode) -> Int {
  self.index_tree.sparse([]).node_count()
}

///|
pub fn DaemonNode::diff_from_sparse(
  self : DaemonNode,
  baseline : @tree.SparseMerkinTree,
  tokens : Array[String],
) -> @tree.TreeDiff {
  @tree.diff_sparse_trees(baseline, self.index_tree.sparse(tokens))
}

///|
pub fn DaemonNode::diff_views(
  self : DaemonNode,
  left_tokens : Array[String],
  right_tokens : Array[String],
) -> @tree.TreeDiff {
  @tree.diff_sparse_trees(
    self.index_tree.sparse(left_tokens),
    self.index_tree.sparse(right_tokens),
  )
}

///|
/// Handle OCI PUT behavior according to daemon capability flags.
pub fn DaemonNode::handle_oci_put(
  self : DaemonNode,
  request : OciPutRequest,
) -> OciPutResult {
  let digest = @hash.Hash::of_bytes(request.payload)

  if self.oci.receiver {
    let receipt = self.union_store.put_blob(
      request.payload,
      request.lane,
      request.event,
      request.path,
      request.sealed_epoch,
      self.live_replicas,
      self.queue_stats,
      self.policy,
    )
    if receipt.committed_count > 0U {
      self.index_digest_route(digest, request.path)
    }
    return { disposition: Stored, digest, receipt: Some(receipt), reason: None }
  }

  if self.oci.proxy {
    // Proxy mode intentionally avoids local write commitment and signals forward.
    return {
      disposition: Forwarded,
      digest,
      receipt: None,
      reason: Some("proxy-forward"),
    }
  }

  if self.oci.passthrough {
    return {
      disposition: Bypassed,
      digest,
      receipt: None,
      reason: Some("passthrough"),
    }
  }

  { disposition: Rejected, digest, receipt: None, reason: Some("oci disabled") }
}

///|
/// Read path over configured union store.
pub fn DaemonNode::handle_get(
  self : DaemonNode,
  digest : @hash.Hash,
  lane? : @storage.ReplicationLane = @storage.Hot,
) -> Bytes? {
  self.union_store.get_blob(digest, lane, self.policy)
}

///|
fn daemon_string_to_bytes(s : String) -> Bytes {
  let total = s.length() * 4
  let buf = FixedArray::make(total, b'\x00')
  let mut pos = 0
  for ch in s {
    let code = ch.to_uint()
    buf[pos] = ((code >> 24) & 0xFFU).to_byte()
    buf[pos + 1] = ((code >> 16) & 0xFFU).to_byte()
    buf[pos + 2] = ((code >> 8) & 0xFFU).to_byte()
    buf[pos + 3] = (code & 0xFFU).to_byte()
    pos = pos + 4
  }
  Bytes::from_array(buf)
}
