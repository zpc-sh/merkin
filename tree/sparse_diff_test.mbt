///|
fn array_contains(items : Array[String], target : String) -> Bool {
  for item in items {
    if item == target {
      return true
    }
  }
  false
}

///|
fn build_child(
  seed : Bytes,
  env_seed : Bytes,
  token : String,
) -> @tree.MerkinNode {
  let id = @hash.Hash::of_bytes(seed)
  let env = @hash.Hash::of_bytes(env_seed)
  @tree.MerkinNode::leaf(id).attach_envelope(env, [token])
}

///|
fn root_hash() -> @hash.Hash {
  @hash.Hash::of_bytes(b"\x00\x00\x00\x01")
}

///|
test "MerkinTree sparse projection keeps root and matching branch" {
  let tree = @tree.MerkinTree::new()
  let root = root_hash()
  let child_a = build_child(b"\x11", b"\x21", "alpha")
  let child_b = build_child(b"\x12", b"\x22", "beta")

  tree.upsert_node(@tree.MerkinNode::leaf(root))
  tree.upsert_node(child_a)
  tree.upsert_node(child_b)
  assert_true(tree.add_child_edge(root, child_a.node_id))
  assert_true(tree.add_child_edge(root, child_b.node_id))

  let sparse = tree.sparse(["alpha"])
  assert_true(sparse.has_node(root))
  assert_true(sparse.has_node(child_a.node_id))
  assert_true(!sparse.has_node(child_b.node_id))
  assert_eq(sparse.node_count(), 2)
}

///|
test "diff_trees reports added and changed nodes" {
  let root = root_hash()
  let child_a = build_child(b"\x31", b"\x41", "alpha")
  let child_b = build_child(b"\x32", b"\x42", "beta")

  let left = @tree.MerkinTree::new()
  left.upsert_node(@tree.MerkinNode::leaf(root))
  left.upsert_node(child_a)
  ignore(left.add_child_edge(root, child_a.node_id))

  let right = @tree.MerkinTree::new()
  right.upsert_node(@tree.MerkinNode::leaf(root))
  right.upsert_node(child_a)
  right.upsert_node(child_b)
  ignore(right.add_child_edge(root, child_a.node_id))
  ignore(right.add_child_edge(root, child_b.node_id))

  let diff = @tree.diff_trees(left, right)
  assert_true(array_contains(diff.added, child_b.node_id.key()))
  assert_true(array_contains(diff.changed, root.key()))
  assert_eq(diff.removed.length(), 0)
}

///|
test "diff_sparse_trees reports branch swap" {
  let root = root_hash()
  let child_a = build_child(b"\x51", b"\x61", "alpha")
  let child_b = build_child(b"\x52", b"\x62", "beta")

  let tree = @tree.MerkinTree::new()
  tree.upsert_node(@tree.MerkinNode::leaf(root))
  tree.upsert_node(child_a)
  tree.upsert_node(child_b)
  ignore(tree.add_child_edge(root, child_a.node_id))
  ignore(tree.add_child_edge(root, child_b.node_id))

  let sparse_alpha = tree.sparse(["alpha"])
  let sparse_beta = tree.sparse(["beta"])
  let diff = @tree.diff_sparse_trees(sparse_alpha, sparse_beta)

  assert_true(array_contains(diff.removed, child_a.node_id.key()))
  assert_true(array_contains(diff.added, child_b.node_id.key()))
  assert_eq(diff.changed.length(), 0)
}
