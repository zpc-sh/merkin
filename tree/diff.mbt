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
  let builder = StringBuilder::new()

  builder.write_string(node.node_id.key())
  builder.write_string("|")
  builder.write_string(node_state_name(node.state))
  builder.write_string("|")
  builder.write_string(node.mass.to_string())
  builder.write_string("|")
  builder.write_string(node.heat.to_string())
  builder.write_string("|")

  for i = 0; i < node.children.length(); i = i + 1 {
    if i > 0 {
      builder.write_string(",")
    }
    builder.write_string(node.children[i].node_id.key())
  }
  builder.write_string("|")

  for i = 0; i < node.envelope_refs.length(); i = i + 1 {
    if i > 0 {
      builder.write_string(",")
    }
    builder.write_string(node.envelope_refs[i].envelope_id.key())
  }
  builder.write_string("|")

  for i = 0; i < node.work_queue_refs.length(); i = i + 1 {
    if i > 0 {
      builder.write_string(",")
    }
    builder.write_string(node.work_queue_refs[i].promise_id.key())
  }

  builder.to_string()
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
