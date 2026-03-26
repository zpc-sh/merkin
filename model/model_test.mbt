///|
test "Artifact from_bytes and verify" {
  let data = b"\x01\x02\x03\x04"
  let art = @model.Artifact::from_bytes(data)
  assert_true(art.verify())
  assert_eq(art.size_bytes, 4UL)
}

///|
test "Artifact with mime" {
  let art = @model.Artifact::from_bytes_with_mime(
    b"\xFF", "application/octet-stream",
  )
  assert_true(art.mime is Some(_))
}

///|
test "Envelope header encoding arbyte_grin" {
  let hash = @hash.Hash::of_bytes(b"\x01")
  let header = ["a", "b", "c", "d", "e", "f", "g", "h"] // len=8
  let env = @model.Envelope::new(hash, header)
  assert_eq(env.header_encoding, @model.ArbyteGrin)
}

///|
test "Envelope header encoding chain_coda" {
  let hash = @hash.Hash::of_bytes(b"\x01")
  let header = ["a", "b", "c"] // len=3, not 8
  let env = @model.Envelope::new(hash, header)
  assert_eq(env.header_encoding, @model.ChainCoda)
}

///|
test "Envelope commit semantic hash" {
  let hash = @hash.Hash::of_bytes(b"\x01")
  let env = @model.Envelope::new(hash, ["x", "y"])
  assert_true(env.semantic_hash is None)
  let env2 = env.commit_semantic()
  assert_true(env2.semantic_hash is Some(_))
  assert_true(env2.state.semantic_committed)
}

///|
test "Envelope seal" {
  let hash = @hash.Hash::of_bytes(b"\x01")
  let env = @model.Envelope::new(hash, ["x"])
  let s = env.seal()
  assert_true(s.is_sealed())
}

///|
test "Envelope sealed immutability for semantic commit" {
  let hash = @hash.Hash::of_bytes(b"\x01")
  let env = @model.Envelope::new(hash, ["x"]).seal()
  let after = env.commit_semantic()
  assert_true(after.semantic_hash is None)
  assert_eq(after.state.freshness, @model.SEALED)
}

///|
test "Envelope subject_hash fallback" {
  let hash = @hash.Hash::of_bytes(b"\x01")
  let env = @model.Envelope::new(hash, ["x"])
  // No semantic hash => falls back to artifact_hash
  assert_eq(env.subject_hash(), env.artifact_hash)
  // With semantic hash => uses semantic
  let env2 = env.commit_semantic()
  match env2.semantic_hash {
    Some(sh) => assert_eq(env2.subject_hash(), sh)
    None => ()
  }
}

///|
test "Anchor state transitions" {
  let hash = @hash.Hash::of_bytes(b"\x01")
  let a = @model.Anchor::new(hash)
  assert_eq(a.anchor_state, @model.UNANCHORED)
  let a2 = a.mark_pending()
  assert_eq(a2.anchor_state, @model.PENDING)
  let root = @hash.Hash::of_bytes(b"\xFF")
  let a3 = a2.mark_anchored(42UL, root)
  assert_eq(a3.anchor_state, @model.ANCHORED)
}

///|
test "Anchor optional refs and replication vector" {
  let hash = @hash.Hash::of_bytes(b"\xAB")
  let a = @model.Anchor::new(hash)
    .set_mmr_proof_ref("proof://mmr/123")
    .set_temporash_ref("tempora://ref/456")
    .add_replica("replica-a")
  assert_true(a.mmr_proof_ref is Some(_))
  assert_true(a.temporash_ref is Some(_))
  assert_eq(a.replication_vector.length(), 1)
}

///|
test "Anchor set_time" {
  let hash = @hash.Hash::of_bytes(b"\xCC")
  let a = @model.Anchor::new(hash)
  assert_true(a.anchored_at is None)
  let a2 = a.set_time("2023-10-27T10:00:00Z")
  assert_eq(a2.anchored_at, Some("2023-10-27T10:00:00Z"))
}

///|
test "WorkPromise lifecycle" {
  let ih = @hash.Hash::of_bytes(b"\x01")
  let th = @hash.Hash::of_bytes(b"\x02")
  let ph = @hash.Hash::of_bytes(b"\x03")
  let wp = @model.WorkPromise::new(ih, th, ph)
  assert_eq(wp.state, @model.ABSENT)
  let wp2 = wp.promise()
  assert_eq(wp2.state, @model.PROMISED)
  let wp3 = wp2.start()
  assert_eq(wp3.state, @model.RUNNING)
}

///|
test "WorkPromise id includes policy id" {
  let input = @hash.Hash::of_bytes(b"\x01")
  let transform = @hash.Hash::of_bytes(b"\x02")
  let policy_a = @hash.Hash::of_bytes(b"\x03")
  let policy_b = @hash.Hash::of_bytes(b"\x04")
  let a = @model.WorkPromise::new(input, transform, policy_a)
  let b = @model.WorkPromise::new(input, transform, policy_b)
  assert_true(a.promise_id != b.promise_id)
}

///|
test "Anchor mark_failed" {
  let hash = @hash.Hash::of_bytes(b"\x01")
  let a = @model.Anchor::new(hash)
  let a2 = a.mark_failed()
  assert_eq(a2.anchor_state, @model.FAILED)
}
