///|
fn build_wide_tree(width : Int) -> MerkinTree {
  let tree = MerkinTree::new()
  let root = @hash.Hash::of_bytes(b"\x00\x00\x00\x01")
  tree.upsert_node(MerkinNode::leaf(root))

  for i = 0; i < width; i = i + 1 {
    let child_seed = i.to_string().to_bytes()
    let child_id = @hash.Hash::of_bytes(child_seed)
    let env_id = @hash.Hash::of_bytes(b"env")
    let child_node = MerkinNode::leaf(child_id).attach_envelope(env_id, [
      "token" + i.to_string(),
    ])
    tree.upsert_node(child_node)
    ignore(tree.add_child_edge(root, child_id))
  }
  tree
}

///|
test "perf: diff wide trees" {
  let tree1 = build_wide_tree(60000)
  let tree2 = build_wide_tree(60000)

  // They should be identical, measuring node_signature speed.
  let diff = diff_trees(tree1, tree2)
  ignore(diff)
}
