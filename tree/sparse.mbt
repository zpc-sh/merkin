///|
/// A filtered projection of MerkinTree that keeps only selected nodes.
pub(all) struct SparseMerkinTree {
  root_key : String?
  nodes : Map[String, MerkinNode]
} derive(Show)

///|
pub fn SparseMerkinTree::node_count(self : SparseMerkinTree) -> Int {
  self.nodes.length()
}

///|
pub fn SparseMerkinTree::has_node(
  self : SparseMerkinTree,
  node_id : @hash.Hash,
) -> Bool {
  self.nodes.get(hash_to_key(node_id)) is Some(_)
}

///|
pub fn SparseMerkinTree::get_node(
  self : SparseMerkinTree,
  node_id : @hash.Hash,
) -> MerkinNode? {
  self.nodes.get(hash_to_key(node_id))
}

///|
pub fn SparseMerkinTree::root(self : SparseMerkinTree) -> String? {
  self.root_key
}

///|
fn node_matches_tokens(node : MerkinNode, tokens : Array[String]) -> Bool {
  for token in tokens {
    if !node.maybe_routes(token) {
      return false
    }
  }
  true
}

///|
/// Build a sparse projection by token filter and include ancestor chain to root.
pub fn MerkinTree::sparse(
  self : MerkinTree,
  tokens : Array[String],
) -> SparseMerkinTree {
  let include_all = tokens.length() == 0
  let included : Map[String, Bool] = {}

  for key, node in self.nodes {
    if include_all || node_matches_tokens(node, tokens) {
      included[key] = true
    }
  }

  let root_key = self.active_root_key()
  match root_key {
    Some(key) => included[key] = true
    None => ()
  }

  // N passes are sufficient to lift matches to root in a finite tree.
  for _i = 0; _i < self.nodes.length(); _i = _i + 1 {
    for parent_key, parent in self.nodes {
      for child_ref in parent.children {
        let child_key = hash_to_key(child_ref.node_id)
        if included.get(child_key) is Some(_) {
          included[parent_key] = true
        }
      }
    }
  }

  let nodes : Map[String, MerkinNode] = {}
  for key, _ in included {
    match self.nodes.get(key) {
      Some(node) => nodes[key] = node
      None => ()
    }
  }

  { root_key, nodes }
}
