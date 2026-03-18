///|
test "ArtifactStore put and get" {
  let store = @store.ArtifactStore::new()
  let art = @model.Artifact::from_bytes(b"\x01\x02\x03")
  let _k = store.put(art)
  match store.get(art.content_hash) {
    Some(retrieved) => assert_eq(retrieved.size_bytes, 3UL)
    None => assert_true(false)
  }
}

///|
test "EnvelopeStore put and get" {
  let store = @store.EnvelopeStore::new()
  let hash = @hash.Hash::of_bytes(b"\x01")
  let env = @model.Envelope::new(hash, ["test"])
  let _k = store.put(env)
  match store.get(env.envelope_id) {
    Some(retrieved) => assert_eq(retrieved.header_encoding, @model.ChainCoda)
    None => assert_true(false)
  }
}

///|
test "AnchorStore put and get" {
  let store = @store.AnchorStore::new()
  let hash = @hash.Hash::of_bytes(b"\x01")
  let a = @model.Anchor::new(hash)
  let _k = store.put(a)
  match store.get(a.anchor_id) {
    Some(retrieved) => assert_eq(retrieved.anchor_state, @model.UNANCHORED)
    None => assert_true(false)
  }
}
