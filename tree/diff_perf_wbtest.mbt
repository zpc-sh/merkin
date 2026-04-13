///|
fn build_tree(size : Int) -> MerkinTree {
  let tree = MerkinTree::new()
  let root = @hash.Hash::of_bytes(b"\x00")
  tree.upsert_node(MerkinNode::leaf(root))

  for i = 0; i < size; i = i + 1 {
    let id = @hash.Hash::of_bytes(i.to_string().to_bytes())
    tree.upsert_node(MerkinNode::leaf(id))
  }
  tree
}

///|
test "perf: diff_trees large legacy" {
  let lhs = build_tree(100000)
  let rhs = build_tree(100000)

  // modify rhs slightly
  rhs.upsert_node(MerkinNode::leaf(@hash.Hash::of_bytes(b"diff1")))
  rhs.upsert_node(MerkinNode::leaf(@hash.Hash::of_bytes(b"diff2")))
  lhs.upsert_node(MerkinNode::leaf(@hash.Hash::of_bytes(b"diff3")))

  for i = 0; i < 5; i = i + 1 {
    let diff = diff_trees_legacy(lhs, rhs)
    if diff.added.length() != 2 || diff.removed.length() != 1 {
      fail("unexpected diff")
    }
  }
}

///|
test "perf: diff_trees large new" {
  let lhs = build_tree(100000)
  let rhs = build_tree(100000)

  // modify rhs slightly
  rhs.upsert_node(MerkinNode::leaf(@hash.Hash::of_bytes(b"diff1")))
  rhs.upsert_node(MerkinNode::leaf(@hash.Hash::of_bytes(b"diff2")))
  lhs.upsert_node(MerkinNode::leaf(@hash.Hash::of_bytes(b"diff3")))

  for i = 0; i < 5; i = i + 1 {
    let diff = diff_trees(lhs, rhs)
    if diff.added.length() != 2 || diff.removed.length() != 1 {
      fail("unexpected diff")
    }
  }
}

///|
test "diff equality legacy vs new" {
  let lhs = build_tree(500)
  let rhs = build_tree(500)

  // random mutations
  rhs.upsert_node(MerkinNode::leaf(@hash.Hash::of_bytes(b"added1")))
  rhs.upsert_node(MerkinNode::leaf(@hash.Hash::of_bytes(b"added2")))

  lhs.upsert_node(MerkinNode::leaf(@hash.Hash::of_bytes(b"removed1")))

  // update an existing one
  let changed_id = @hash.Hash::of_bytes("42".to_bytes())
  lhs.upsert_node(MerkinNode::leaf(changed_id))
  rhs.upsert_node(
    MerkinNode::leaf(changed_id).attach_envelope(@hash.Hash::of_bytes(b"env"), [
      "tag",
    ]),
  )

  let diff_legacy = diff_trees_legacy(lhs, rhs)
  let diff_new = diff_trees(lhs, rhs)

  assert_eq(diff_legacy.added, diff_new.added)
  assert_eq(diff_legacy.removed, diff_new.removed)
  assert_eq(diff_legacy.changed, diff_new.changed)
  assert_eq(diff_legacy.unchanged, diff_new.unchanged)
}
