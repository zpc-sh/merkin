///|
/// Node lifecycle states, mirroring Freshness (§3.4).
pub(all) enum NodeState {
  FRESH
  DIRTY
  DEFERRED
  SEALED
} derive(Eq, Show)

///|
/// NodeRef: reference to a child node.
pub(all) struct NodeRef {
  node_id : @hash.Hash
} derive(Eq, Show)

///|
/// EnvelopeRef: reference to an envelope under this node.
pub(all) struct EnvelopeRef {
  envelope_id : @hash.Hash
} derive(Eq, Show)

///|
/// WorkPromiseRef: queued work attached to this node.
pub(all) struct WorkPromiseRef {
  promise_id : @hash.Hash
} derive(Eq, Show)

///|
/// MerkinNode: the core tree node header (§3.1).
pub(all) struct MerkinNode {
  node_id : @hash.Hash
  children : Array[NodeRef]
  routing_sketch : @bloom.BloomSketch
  salience_field : @gaussian.GaussianField
  mass : UInt64
  heat : UInt64
  state : NodeState
  envelope_refs : Array[EnvelopeRef]
  work_queue_refs : Array[WorkPromiseRef]
} derive(Show)

///|
/// Create a new empty leaf node.
pub fn MerkinNode::leaf(node_id : @hash.Hash) -> MerkinNode {
  {
    node_id,
    children: [],
    routing_sketch: @bloom.BloomSketch::new(),
    salience_field: @gaussian.GaussianField::new(),
    mass: 0UL,
    heat: 0UL,
    state: FRESH,
    envelope_refs: [],
    work_queue_refs: [],
  }
}

///|
/// Attach an envelope to this node and mark DIRTY.
/// Updates mass and heat counters.
pub fn MerkinNode::attach_envelope(
  self : MerkinNode,
  envelope_id : @hash.Hash,
  routing_tokens : Array[String],
) -> MerkinNode {
  let refs = self.envelope_refs
  refs.push({ envelope_id, })
  // Update bloom sketch with routing tokens
  for token in routing_tokens {
    self.routing_sketch.add(token)
  }
  {
    ..self,
    envelope_refs: refs,
    mass: self.mass + 1UL,
    heat: self.heat + 1UL,
    state: DIRTY,
  }
}

///|
/// Add a child node reference. Marks this node DIRTY.
pub fn MerkinNode::add_child(
  self : MerkinNode,
  child_id : @hash.Hash,
) -> MerkinNode {
  let kids = self.children
  kids.push({ node_id: child_id })
  { ..self, children: kids, state: DIRTY }
}

///|
/// Seal this node: freeze it, rebuild BloomSketch from children sketches.
/// In v0, children_sketches are passed in manually (tree holds them).
pub fn MerkinNode::seal(
  self : MerkinNode,
  children_sketches : Array[@bloom.BloomSketch],
) -> MerkinNode {
  // Merge all children bloom sketches into this node's sketch
  let mut merged = @bloom.BloomSketch::new()
  for sketch in children_sketches {
    merged = merged.merge(sketch)
  }
  // Also merge our own sketch (which has direct envelope tokens)
  merged = merged.merge(self.routing_sketch)
  { ..self, routing_sketch: merged, state: SEALED }
}

///|
/// Check if a token might be routable through this node.
pub fn MerkinNode::maybe_routes(self : MerkinNode, token : String) -> Bool {
  self.routing_sketch.maybe_contains(token)
}

///|
/// Check if this node is sealed.
pub fn MerkinNode::is_sealed(self : MerkinNode) -> Bool {
  self.state == SEALED
}

///|
/// Add a work promise reference and mark the node DIRTY.
pub fn MerkinNode::enqueue_work(
  self : MerkinNode,
  promise_id : @hash.Hash,
) -> MerkinNode {
  let refs = self.work_queue_refs
  refs.push({ promise_id, })
  { ..self, work_queue_refs: refs, state: DIRTY }
}
