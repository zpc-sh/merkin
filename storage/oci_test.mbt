///|
test "InMemoryOciRegistry blob and tag operations" {
  let reg = @storage.InMemoryOciRegistry::new()
  let payload = b"oci-payload"
  let digest = reg.put_blob("repo/a", payload)
  assert_true(reg.has_blob("repo/a", digest))
  match reg.get_blob("repo/a", digest) {
    Some(bytes) => assert_eq(bytes, payload)
    None => assert_true(false)
  }

  reg.put_tag("repo/a", "latest", digest)
  match reg.resolve_tag("repo/a", "latest") {
    Some(d) => assert_eq(d, digest)
    None => assert_true(false)
  }
}

///|
test "OciCasNode participates in StoreNode API" {
  let reg = @storage.InMemoryOciRegistry::new()
  let node = @storage.OciCasNode::new(
    "oci-1", "registry.example.com/merkin/main", reg,
  )

  let payload = b"oci-node-subject"
  let digest = node.put_blob(payload)
  assert_true(node.has_blob(digest))

  match node.get_blob(digest) {
    Some(bytes) => assert_eq(bytes, payload)
    None => assert_true(false)
  }
}

///|
test "OciCasNode epoch tag mode publishes epoch tag" {
  let reg = @storage.InMemoryOciRegistry::new()
  let node = @storage.OciCasNode::new(
    "oci-epoch",
    "registry.example.com/merkin/epoch",
    reg,
    tag_mode=@storage.EpochTag,
    epoch=77UL,
  )
  ignore(node.put_blob(b"epoch-tagged"))

  assert_true(
    reg.resolve_tag("registry.example.com/merkin/epoch", "epoch-77") is Some(_),
  )
}

///|
test "OciCasNode latest tag mode publishes latest" {
  let reg = @storage.InMemoryOciRegistry::new()
  let node = @storage.OciCasNode::new(
    "oci-latest",
    "registry.example.com/merkin/latest",
    reg,
    tag_mode=@storage.LatestTag,
  )
  ignore(node.put_blob(b"latest-tagged"))

  assert_true(
    reg.resolve_tag("registry.example.com/merkin/latest", "latest") is Some(_),
  )
}

///|
test "InMemoryOciRegistry non-existent blob and tag operations" {
  let reg = @storage.InMemoryOciRegistry::new()
  assert_false(reg.has_blob("repo/b", "non-existent-digest"))
  assert_eq(reg.get_blob("repo/b", "non-existent-digest"), None)
  assert_eq(reg.resolve_tag("repo/b", "non-existent-tag"), None)
}
