///|
test "MerkinTree ingest and seal" {
  let tree = @tree.MerkinTree::new()
  let env_id = @hash.Hash::of_bytes(b"\x01\x02")
  let root_key = tree.ingest(env_id, ["image", "photo"])
  // Root should exist and be DIRTY
  let root_hash = @hash.Hash::of_bytes(b"\x00\x00\x00\x01")
  match tree.get_node(root_hash) {
    Some(node) => {
      assert_eq(node.state, @tree.DIRTY)
      assert_true(node.maybe_routes("image"))
      assert_true(node.maybe_routes("photo"))
    }
    None => assert_true(false) // should not happen
  }
  // Seal
  match tree.seal() {
    Some(key) => {
      assert_eq(key, root_key)
      assert_eq(tree.current_epoch(), 1UL)
    }
    None => assert_true(false)
  }
}

///|
test "MerkinTree multiple ingests" {
  let tree = @tree.MerkinTree::new()
  let id1 = @hash.Hash::of_bytes(b"\x01")
  let id2 = @hash.Hash::of_bytes(b"\x02")
  let _k1 = tree.ingest(id1, ["doc"])
  let _k2 = tree.ingest(id2, ["video"])
  let root_hash = @hash.Hash::of_bytes(b"\x00\x00\x00\x01")
  match tree.get_node(root_hash) {
    Some(node) => {
      assert_eq(node.envelope_refs.length(), 2)
      assert_true(node.maybe_routes("doc"))
      assert_true(node.maybe_routes("video"))
    }
    None => assert_true(false)
  }
}

///|
test "MerkinTree seal clears hot root" {
  let tree = @tree.MerkinTree::new()
  let id = @hash.Hash::of_bytes(b"\x01")
  let _k = tree.ingest(id, ["test"])
  let _s = tree.seal()
  // After seal, hot_root should be None => next seal returns None
  assert_true(tree.seal() is None)
}

///|
test "MerkinNode enqueue work marks dirty" {
  let node_id = @hash.Hash::of_bytes(b"\x10")
  let promise_id = @hash.Hash::of_bytes(b"\x20")
  let node = @tree.MerkinNode::leaf(node_id)
  let node2 = node.enqueue_work(promise_id)
  assert_eq(node2.work_queue_refs.length(), 1)
  assert_eq(node2.state, @tree.DIRTY)
}

///|
test "MerkinTree active_root_key without hot_root" {
  let tree = @tree.MerkinTree::new()
  assert_eq(tree.active_root_key(), None)
}
