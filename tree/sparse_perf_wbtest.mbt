///|
fn build_deep_tree(depth : Int) -> MerkinTree {
  let tree = MerkinTree::new()
  let root = @hash.Hash::of_bytes(b"\x00\x00\x00\x01")
  tree.upsert_node(MerkinNode::leaf(root))

  let mut parent_id = root
  for i = 0; i < depth; i = i + 1 {
    let child_seed = i.to_string().to_bytes()
    let child_id = @hash.Hash::of_bytes(child_seed)
    let env_id = @hash.Hash::of_bytes(b"env")
    let child_node = MerkinNode::leaf(child_id).attach_envelope(env_id, [
      "token" + i.to_string(),
    ])
    tree.upsert_node(child_node)
    ignore(tree.add_child_edge(parent_id, child_id))
    parent_id = child_id
  }
  tree
}

///|
test "perf: sparse tree deep" {
  let tree = build_deep_tree(2000) // 2000 depth
  let _ = tree.sparse(["token1999"]) // should propagate from bottom to top
}
