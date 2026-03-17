///|
pub(all) struct TreeDiff {
  added : Array[String]
  removed : Array[String]
  changed : Array[String]
  unchanged : UInt
} derive(Show)

///|
pub fn TreeDiff::is_empty(self : TreeDiff) -> Bool {
  self.added.length() == 0 &&
  self.removed.length() == 0 &&
  self.changed.length() == 0
}

///|
pub fn diff_trees(lhs : MerkinTree, rhs : MerkinTree) -> TreeDiff {
  diff_node_maps(lhs.nodes, rhs.nodes)
}

///|
pub fn diff_sparse_trees(
  lhs : SparseMerkinTree,
  rhs : SparseMerkinTree,
) -> TreeDiff {
  diff_node_maps(lhs.nodes, rhs.nodes)
}

///|
fn diff_node_maps(
  lhs : Map[String, MerkinNode],
  rhs : Map[String, MerkinNode],
) -> TreeDiff {
  let keys = union_sorted_keys(lhs, rhs)
  let added : Array[String] = []
  let removed : Array[String] = []
  let changed : Array[String] = []
  let mut unchanged = 0U

  for key in keys {
    match lhs.get(key) {
      Some(left) =>
        match rhs.get(key) {
          Some(right) =>
            if node_signature(left) == node_signature(right) {
              unchanged = unchanged + 1U
            } else {
              changed.push(key)
            }
          None => removed.push(key)
        }
      None =>
        match rhs.get(key) {
          Some(_right) => added.push(key)
          None => ()
        }
    }
  }

  { added, removed, changed, unchanged }
}

///|
fn union_sorted_keys(
  lhs : Map[String, MerkinNode],
  rhs : Map[String, MerkinNode],
) -> Array[String] {
  let seen : Map[String, Bool] = {}
  let out : Array[String] = []
  for key, _ in lhs {
    if seen.get(key) is None {
      seen[key] = true
      out.push(key)
    }
  }
  for key, _ in rhs {
    if seen.get(key) is None {
      seen[key] = true
      out.push(key)
    }
  }
  out.sort()
  out
}

///|
fn node_signature(node : MerkinNode) -> String {
  let children : Array[String] = []
  for child in node.children {
    children.push(child.node_id.key())
  }

  let envelopes : Array[String] = []
  for envelope_ref in node.envelope_refs {
    envelopes.push(envelope_ref.envelope_id.key())
  }

  let work_items : Array[String] = []
  for work_ref in node.work_queue_refs {
    work_items.push(work_ref.promise_id.key())
  }

  node.node_id.key() +
  "|" +
  node_state_name(node.state) +
  "|" +
  node.mass.to_string() +
  "|" +
  node.heat.to_string() +
  "|" +
  diff_join(children, ",") +
  "|" +
  diff_join(envelopes, ",") +
  "|" +
  diff_join(work_items, ",")
}

///|
fn node_state_name(state : NodeState) -> String {
  match state {
    FRESH => "fresh"
    DIRTY => "dirty"
    DEFERRED => "deferred"
    SEALED => "sealed"
  }
}

///|
fn diff_join(items : Array[String], sep : String) -> String {
  let builder = StringBuilder::new()
  for i = 0; i < items.length(); i = i + 1 {
    if i > 0 {
      builder.write_string(sep)
    }
    builder.write_string(items[i])
  }
  builder.to_string()
}
