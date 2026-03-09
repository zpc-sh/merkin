///|
/// MerkinTree: the living substrate index (§3).
/// Manages a collection of MerkinNodes with a hot root.
pub(all) struct MerkinTree {
  nodes : Map[String, MerkinNode] // keyed by canonical hash key
  mut hot_root_id : String?
  mut epoch : UInt64
}

///|
/// Convert a hash digest to a hex string key for the node map.
fn hash_to_key(h : @hash.Hash) -> String {
  h.key()
}

///|
fn default_root_hash() -> @hash.Hash {
  @hash.Hash::of_bytes(b"\x00\x00\x00\x01")
}

///|
/// Create a new empty MerkinTree.
pub fn MerkinTree::new() -> MerkinTree {
  { nodes: {}, hot_root_id: None, epoch: 0UL }
}

///|
/// Resolve the active root key.
/// Uses hot root when present, otherwise falls back to the canonical root id.
pub fn MerkinTree::active_root_key(self : MerkinTree) -> String? {
  match self.hot_root_id {
    Some(key) => Some(key)
    None => {
      let root_key = hash_to_key(default_root_hash())
      if self.nodes.get(root_key) is Some(_) {
        Some(root_key)
      } else {
        None
      }
    }
  }
}

///|
/// Upsert a node by id.
pub fn MerkinTree::upsert_node(self : MerkinTree, node : MerkinNode) -> Unit {
  self.nodes[hash_to_key(node.node_id)] = node
}

///|
/// Add a child edge between existing nodes.
pub fn MerkinTree::add_child_edge(
  self : MerkinTree,
  parent_id : @hash.Hash,
  child_id : @hash.Hash,
) -> Bool {
  let parent_key = hash_to_key(parent_id)
  match self.nodes.get(parent_key) {
    Some(parent) => {
      self.nodes[parent_key] = parent.add_child(child_id)
      true
    }
    None => false
  }
}

///|
/// Ingest an envelope into the hot tree.
/// Routes the envelope to the root node (creating it if needed).
/// Returns the hot root hash key.
pub fn MerkinTree::ingest(
  self : MerkinTree,
  envelope_id : @hash.Hash,
  routing_tokens : Array[String],
) -> String {
  // Ensure root node exists
  let root_key = match self.hot_root_id {
    Some(key) => key
    None => {
      // Create root node
      let root_hash = default_root_hash()
      let root_key = hash_to_key(root_hash)
      let root_node = MerkinNode::leaf(root_hash)
      self.nodes[root_key] = root_node
      self.hot_root_id = Some(root_key)
      root_key
    }
  }
  // Attach envelope to root (flat routing for v0)
  match self.nodes.get(root_key) {
    Some(node) => {
      let updated = node.attach_envelope(envelope_id, routing_tokens)
      self.nodes[root_key] = updated
    }
    None => ()
  }
  root_key
}

///|
/// Seal the current epoch: freeze all nodes, rebuild sketches,
/// increment epoch, and return the sealed root key.
pub fn MerkinTree::seal(self : MerkinTree) -> String? {
  match self.hot_root_id {
    None => None
    Some(root_key) =>
      match self.nodes.get(root_key) {
        Some(root_node) => {
          // Gather children sketches
          let child_sketches : Array[@bloom.BloomSketch] = []
          for child_ref in root_node.children {
            let child_key = hash_to_key(child_ref.node_id)
            match self.nodes.get(child_key) {
              Some(child_node) => child_sketches.push(child_node.routing_sketch)
              None => ()
            }
          }
          // Seal root
          let sealed_node = root_node.seal(child_sketches)
          self.nodes[root_key] = sealed_node
          self.epoch = self.epoch + 1UL
          // Clear hot root so next epoch starts fresh
          self.hot_root_id = None
          Some(root_key)
        }
        None => None
      }
  }
}

///|
/// Get a node by its hash.
pub fn MerkinTree::get_node(
  self : MerkinTree,
  node_id : @hash.Hash,
) -> MerkinNode? {
  let key = hash_to_key(node_id)
  self.nodes.get(key)
}

///|
/// Get current epoch number.
pub fn MerkinTree::current_epoch(self : MerkinTree) -> UInt64 {
  self.epoch
}
