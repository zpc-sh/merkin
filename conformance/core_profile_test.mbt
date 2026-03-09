///|
/// Core profile conformance checks for the current Merkin implementation.
/// These tests validate behavior required by the v0 substrate model.
test "Core: Hash key uses canonical alg prefix" {
  let h = @hash.Hash::of_bytes(b"\x01\x02")
  assert_true(h.key().contains("blake3:"))
  assert_eq(h.digest_len(), 32)
}

///|
test "Core: Artifact hash verification is deterministic" {
  let payload = b"payload-v0"
  let a1 = @model.Artifact::from_bytes(payload)
  let a2 = @model.Artifact::from_bytes(payload)
  assert_true(a1.verify())
  assert_eq(a1.content_hash, a2.content_hash)
}

///|
test "Core: Envelope encoding and subject hash rules" {
  let artifact_hash = @hash.Hash::of_bytes(b"\x0A")
  let grin = @model.Envelope::new(artifact_hash, [
    "a", "b", "c", "d", "e", "f", "g", "h",
  ])
  assert_eq(grin.header_encoding, @model.ArbyteGrin)
  assert_eq(grin.subject_hash(), artifact_hash)

  let coda = @model.Envelope::new(artifact_hash, ["x", "y"]).commit_semantic()
  assert_eq(coda.header_encoding, @model.ChainCoda)
  match coda.semantic_hash {
    Some(h) => assert_eq(coda.subject_hash(), h)
    None => assert_true(false)
  }
}

///|
test "Core: Sealed envelope is immutable for semantic commit" {
  let artifact_hash = @hash.Hash::of_bytes(b"\x0B")
  let sealed_env = @model.Envelope::new(artifact_hash, ["x"]).seal()
  let after = sealed_env.commit_semantic()
  assert_eq(after.state.freshness, @model.SEALED)
  assert_true(after.semantic_hash is None)
}

///|
test "Core: WorkPromise id is policy-sensitive" {
  let input = @hash.Hash::of_bytes(b"\x11")
  let transform = @hash.Hash::of_bytes(b"\x22")
  let policy_a = @hash.Hash::of_bytes(b"\x33")
  let policy_b = @hash.Hash::of_bytes(b"\x44")
  let a = @model.WorkPromise::new(input, transform, policy_a)
  let b = @model.WorkPromise::new(input, transform, policy_b)
  assert_true(a.promise_id != b.promise_id)
}

///|
test "Core: Anchor lifecycle data is persisted" {
  let subject = @hash.Hash::of_bytes(b"\x12")
  let root = @hash.Hash::of_bytes(b"\x34")
  let a = @model.Anchor::new(subject)
    .mark_pending()
    .mark_anchored(7UL, root)
    .set_mmr_proof_ref("proof://7")
    .set_temporash_ref("tempora://7")
    .set_time("2026-02-26T00:00:00Z")
    .add_replica("replica-a")
  assert_eq(a.anchor_state, @model.ANCHORED)
  assert_true(a.mmr_proof_ref is Some(_))
  assert_true(a.temporash_ref is Some(_))
  assert_true(a.anchored_at is Some(_))
  assert_eq(a.replication_vector.length(), 1)
}

///|
test "Core: Store round-trip by hash id" {
  let artifacts = @store.ArtifactStore::new()
  let envelopes = @store.EnvelopeStore::new()
  let anchors = @store.AnchorStore::new()

  let art = @model.Artifact::from_bytes(b"\xAA\xBB")
  ignore(artifacts.put(art))

  let env = @model.Envelope::new(art.content_hash, ["r", "o", "u", "t", "e"])
  ignore(envelopes.put(env))

  let anchor = @model.Anchor::new(env.subject_hash())
  ignore(anchors.put(anchor))

  assert_true(artifacts.get(art.content_hash) is Some(_))
  assert_true(envelopes.get(env.envelope_id) is Some(_))
  assert_true(anchors.get(anchor.anchor_id) is Some(_))
}

///|
test "Core: Tree ingest and seal progression" {
  let tree = @tree.MerkinTree::new()
  let env_id = @hash.Hash::of_bytes(b"\x90")
  ignore(tree.ingest(env_id, ["doc", "img"]))

  let root_hash = @hash.Hash::of_bytes(b"\x00\x00\x00\x01")
  match tree.get_node(root_hash) {
    Some(node) => assert_eq(node.state, @tree.DIRTY)
    None => assert_true(false)
  }

  assert_true(tree.seal() is Some(_))
  assert_eq(tree.current_epoch(), 1UL)
}
