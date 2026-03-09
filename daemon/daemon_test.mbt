///|
fn sample_policy_for(target_ids : Array[String]) -> @storage.ReplicationPolicy {
  let targets : Array[@storage.TargetRule] = []
  for id in target_ids {
    targets.push({
      target_id: id,
      role: if id.contains("oci") {
        @storage.Oci
      } else {
        @storage.Local
      },
      lanes: [@storage.Hot, @storage.Warm, @storage.Critical],
      min_availability: @storage.Online,
      write_mode: @storage.SyncQuorum,
      pull_on_miss: true,
    })
  }
  @storage.ReplicationPolicy::new(
    1U,
    1UL,
    1U,
    1U,
    @storage.IdempotencyPolicy::default(),
    @storage.BackpressurePolicy::default(),
    @storage.OciPolicy::disabled(),
    targets,
    [],
  )
}

///|
test "OciFacility defaults per daemon mode" {
  assert_eq(@daemon.OciFacility::from_mode(@daemon.Receiver), {
    receiver: true,
    proxy: false,
    passthrough: false,
  })
  assert_eq(@daemon.OciFacility::from_mode(@daemon.Proxy), {
    receiver: false,
    proxy: true,
    passthrough: false,
  })
  assert_eq(@daemon.OciFacility::from_mode(@daemon.PassThrough), {
    receiver: false,
    proxy: false,
    passthrough: true,
  })
}

///|
test "Daemon receiver mode stores OCI payload through union store" {
  let policy = sample_policy_for(["local-1"])
  let daemon = @daemon.DaemonNode::new("node-a", @daemon.Receiver, policy)
  let local_node = @storage.ArtifactCasNode::new("local-1", @storage.Local)
  daemon.add_store(local_node.as_store_node())

  let result = daemon.handle_oci_put(@daemon.OciPutRequest::default(b"blob-1"))
  assert_eq(result.disposition, @daemon.Stored)

  match daemon.handle_get(result.digest) {
    Some(bytes) => assert_eq(bytes, b"blob-1")
    None => assert_true(false)
  }
}

///|
test "Daemon proxy mode forwards without local commit" {
  let policy = sample_policy_for(["local-1"])
  let daemon = @daemon.DaemonNode::new("node-b", @daemon.Proxy, policy)
  let result = daemon.handle_oci_put(
    @daemon.OciPutRequest::default(b"blob-proxy"),
  )
  assert_eq(result.disposition, @daemon.Forwarded)
  assert_true(result.receipt is None)
}

///|
test "Daemon pass-through mode bypasses local commit" {
  let policy = sample_policy_for(["local-1"])
  let daemon = @daemon.DaemonNode::new("node-c", @daemon.PassThrough, policy)
  let result = daemon.handle_oci_put(
    @daemon.OciPutRequest::default(b"blob-pass"),
  )
  assert_eq(result.disposition, @daemon.Bypassed)
  assert_true(result.receipt is None)
}

///|
test "Daemon custom OCI facility overrides mode defaults" {
  let policy = sample_policy_for(["local-1"])
  let daemon = @daemon.DaemonNode::new(
    "node-d",
    @daemon.Receiver,
    policy,
    oci=Some({ receiver: false, proxy: true, passthrough: true }),
  )

  assert_true(!daemon.can_receive_oci())
  assert_true(daemon.can_proxy_oci())
  assert_true(daemon.can_passthrough_oci())
}

///|
test "Daemon receiver supports OCI-backed store node" {
  let policy = sample_policy_for(["oci-1"])
  let daemon = @daemon.DaemonNode::new("node-oci", @daemon.Receiver, policy)
  let reg = @storage.InMemoryOciRegistry::new()
  let oci_node = @storage.OciCasNode::new(
    "oci-1", "registry.example.com/merkin/node-oci", reg,
  )
  daemon.add_store(oci_node.as_store_node())

  let result = daemon.handle_oci_put(
    @daemon.OciPutRequest::default(b"blob-oci"),
  )
  assert_eq(result.disposition, @daemon.Stored)
  assert_true(daemon.handle_get(result.digest) is Some(_))
}

///|
test "Daemon sparse view indexes hierarchical routes" {
  let policy = sample_policy_for(["local-1"])
  let daemon = @daemon.DaemonNode::new("node-tree", @daemon.Receiver, policy)
  let local_node = @storage.ArtifactCasNode::new("local-1", @storage.Local)
  daemon.add_store(local_node.as_store_node())

  ignore(
    daemon.handle_oci_put({
      payload: b"blob-a",
      lane: @storage.Hot,
      event: @storage.Ingest,
      path: ["alpha", "doc"],
      sealed_epoch: false,
    }),
  )
  ignore(
    daemon.handle_oci_put({
      payload: b"blob-b",
      lane: @storage.Hot,
      event: @storage.Ingest,
      path: ["beta", "doc"],
      sealed_epoch: false,
    }),
  )

  let alpha_view = daemon.sparse_view(["alpha"])
  assert_true(alpha_view.node_count() >= 2)
  assert_true(daemon.indexed_node_count() >= alpha_view.node_count())
}

///|
test "Daemon diff endpoints compare sparse snapshots and token views" {
  let policy = sample_policy_for(["local-1"])
  let daemon = @daemon.DaemonNode::new("node-diff", @daemon.Receiver, policy)
  let local_node = @storage.ArtifactCasNode::new("local-1", @storage.Local)
  daemon.add_store(local_node.as_store_node())

  ignore(
    daemon.handle_oci_put({
      payload: b"left-blob",
      lane: @storage.Hot,
      event: @storage.Ingest,
      path: ["alpha", "one"],
      sealed_epoch: false,
    }),
  )
  let baseline = daemon.sparse_view([])

  ignore(
    daemon.handle_oci_put({
      payload: b"right-blob",
      lane: @storage.Hot,
      event: @storage.Ingest,
      path: ["beta", "two"],
      sealed_epoch: false,
    }),
  )

  let growth = daemon.diff_from_sparse(baseline, [])
  assert_true(!growth.is_empty())

  let token_diff = daemon.diff_views(["alpha"], ["beta"])
  assert_true(!token_diff.is_empty())
}
