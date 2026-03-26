///|
fn sample_targets() -> Array[@storage.TargetRule] {
  [
    {
      target_id: "local-1",
      role: @storage.Local,
      lanes: [@storage.Critical, @storage.Hot, @storage.Warm],
      min_availability: @storage.Degraded,
      write_mode: @storage.SyncQuorum,
      pull_on_miss: true,
    },
    {
      target_id: "remote-1",
      role: @storage.Remote,
      lanes: [@storage.Hot, @storage.Warm, @storage.Cold],
      min_availability: @storage.Online,
      write_mode: @storage.AsyncFanout,
      pull_on_miss: true,
    },
  ]
}

///|
fn sample_policy() -> @storage.ReplicationPolicy {
  @storage.ReplicationPolicy::new(
    1U,
    42UL,
    1U,
    1U,
    @storage.IdempotencyPolicy::default(),
    @storage.BackpressurePolicy::default(),
    {
      enabled: true,
      repository: "registry.example.com/merkin/main",
      artifact_media_type: "application/vnd.merkin.artifact.v1+octet-stream",
      tag_mode: @storage.EpochTag,
    },
    sample_targets(),
    [],
  )
}

///|
test "ReplicationPolicy id is deterministic" {
  let p1 = sample_policy()
  let p2 = sample_policy()
  assert_eq(p1.policy_id, p2.policy_id)
}

///|
test "ReplicationPolicy allows target by role, lane, availability" {
  let policy = sample_policy()
  assert_true(
    policy.allows_target(
      "local-1",
      @storage.Local,
      @storage.Hot,
      @storage.Degraded,
    ),
  )
  assert_true(
    !policy.allows_target(
      "remote-1",
      @storage.Remote,
      @storage.Hot,
      @storage.Degraded,
    ),
  )
  assert_true(
    !policy.allows_target(
      "remote-1",
      @storage.Cache,
      @storage.Hot,
      @storage.Online,
    ),
  )
}

///|
test "ReplicationPolicy tree rules support prefix/exact checks" {
  let policy = @storage.ReplicationPolicy::new(
    1U,
    1UL,
    1U,
    1U,
    @storage.IdempotencyPolicy::default(),
    @storage.BackpressurePolicy::default(),
    @storage.OciPolicy::disabled(),
    sample_targets(),
    [
      {
        path: ["epochs", "sealed"],
        match_mode: @storage.Prefix,
        lane: @storage.ArchiveLane,
        require_sealed_epoch: true,
        min_replicas: 2U,
      },
      {
        path: ["ingest", "hot"],
        match_mode: @storage.Exact,
        lane: @storage.Hot,
        require_sealed_epoch: false,
        min_replicas: 1U,
      },
    ],
  )

  assert_true(
    policy.tree_accepts(
      ["epochs", "sealed", "2026"],
      @storage.ArchiveLane,
      true,
      2U,
    ),
  )
  assert_true(
    !policy.tree_accepts(
      ["epochs", "sealed", "2026"],
      @storage.ArchiveLane,
      false,
      2U,
    ),
  )
  assert_true(policy.tree_accepts(["ingest", "hot"], @storage.Hot, false, 1U))
  assert_true(
    policy.tree_accepts(["ingest", "hot", "extra"], @storage.Hot, false, 1U),
  )
}

///|
test "Backpressure gate blocks non-critical when saturated" {
  let policy = sample_policy()
  let saturated : @storage.QueueStats = {
    inflight_ops: policy.backpressure.max_inflight_ops + 1UL,
    inflight_bytes: policy.backpressure.max_inflight_bytes + 1UL,
    pending_ops: policy.backpressure.max_pending_ops + 1UL,
    pending_bytes: policy.backpressure.max_pending_bytes + 1UL,
  }
  assert_true(!policy.allow_dispatch(@storage.Hot, saturated))
}

///|
test "Backpressure gate permits critical within 2x overflow" {
  let policy = sample_policy()
  let elevated : @storage.QueueStats = {
    inflight_ops: policy.backpressure.max_inflight_ops * 2UL,
    inflight_bytes: policy.backpressure.max_inflight_bytes * 2UL,
    pending_ops: policy.backpressure.max_pending_ops * 2UL,
    pending_bytes: policy.backpressure.max_pending_bytes * 2UL,
  }
  assert_true(policy.allow_dispatch(@storage.Critical, elevated))
}

///|
test "Idempotency ledger tracks committed states" {
  let ledger = @storage.IdempotencyLedger::new()
  let key = @hash.Hash::of_bytes(b"op-key")
  assert_true(!ledger.is_committed(key))
  ledger.mark_pending(key)
  ledger.mark_committed(key)
  assert_true(ledger.is_committed(key))
}

///|
test "UnionStore put/get and idempotent duplicate suppression" {
  let local_node = @storage.ArtifactCasNode::new("local-1", @storage.Local)
  let remote = @storage.ArtifactCasNode::new("remote-1", @storage.Remote)
  let union = @storage.UnionStore::new()
  union.add_node(local_node.as_store_node())
  union.add_node(remote.as_store_node())

  let policy = sample_policy()
  let payload = b"merkin-subject"
  let queue = @storage.QueueStats::idle()

  let first = union.put_blob(
    payload,
    @storage.Hot,
    @storage.Ingest,
    ["ingest", "hot"],
    false,
    1U,
    queue,
    policy,
  )
  assert_eq(first.committed_count, 2U)
  assert_true(first.quorum_met)

  let second = union.put_blob(
    payload,
    @storage.Hot,
    @storage.Ingest,
    ["ingest", "hot"],
    false,
    1U,
    queue,
    policy,
  )
  assert_eq(second.committed_count, 0U)

  let mut duplicate_count = 0
  for dispatch in second.dispatches {
    if dispatch.state == @storage.Duplicate {
      duplicate_count = duplicate_count + 1
    }
  }
  assert_eq(duplicate_count, 2)

  assert_true(union.has_blob(first.subject_hash, @storage.Hot, policy))
  match union.get_blob(first.subject_hash, @storage.Hot, policy) {
    Some(bytes) => assert_eq(bytes, payload)
    None => assert_true(false)
  }
}

///|
test "UnionStore respects policy availability gating" {
  let local_node = @storage.ArtifactCasNode::new("local-1", @storage.Local)
  let remote = @storage.ArtifactCasNode::new(
    "remote-1",
    @storage.Remote,
    status=@storage.Degraded,
  )
  let union = @storage.UnionStore::new()
  union.add_node(local_node.as_store_node())
  union.add_node(remote.as_store_node())

  let policy = sample_policy()
  let receipt = union.put_blob(
    b"availability-check",
    @storage.Hot,
    @storage.Ingest,
    ["ingest", "hot"],
    false,
    1U,
    @storage.QueueStats::idle(),
    policy,
  )

  // local committed, remote skipped by min_availability=Online
  assert_eq(receipt.committed_count, 1U)
  let mut skipped_policy = 0
  for dispatch in receipt.dispatches {
    if dispatch.state == @storage.SkippedPolicy {
      skipped_policy = skipped_policy + 1
    }
  }
  assert_eq(skipped_policy, 1)
}

///|
test "UnionStore restore_ledger reverts idempotency state" {
  let local_node = ArtifactCasNode::new("local-1", Local)
  let union = UnionStore::new()
  union.add_node(local_node.as_store_node())

  let policy = sample_policy()
  let payload1 = b"payload-1"
  let payload2 = b"payload-2"
  let queue = QueueStats::idle()

  // Put first blob to modify ledger state
  let first_receipt = union.put_blob(
    payload1,
    Hot,
    Ingest,
    ["ingest", "hot"],
    false,
    1U,
    queue,
    policy,
  )
  assert_eq(first_receipt.committed_count, 1U)

  // Take snapshot
  let snapshot = union.ledger_snapshot()

  // Put second blob to change state again
  let second_receipt = union.put_blob(
    payload2,
    Hot,
    Ingest,
    ["ingest", "hot"],
    false,
    1U,
    queue,
    policy,
  )
  assert_eq(second_receipt.committed_count, 1U)

  // Restore snapshot
  union.restore_ledger(snapshot)

  // Verify that putting the first blob again is treated as a duplicate (ledger remembers it)
  let dup_first = union.put_blob(
    payload1,
    Hot,
    Ingest,
    ["ingest", "hot"],
    false,
    1U,
    queue,
    policy,
  )
  assert_eq(dup_first.committed_count, 0U)
  assert_eq(dup_first.dispatches[0].state, Duplicate)

  // Verify that putting the second blob again is NOT treated as a duplicate (ledger forgot it)
  let dup_second = union.put_blob(
    payload2,
    Hot,
    Ingest,
    ["ingest", "hot"],
    false,
    1U,
    queue,
    policy,
  )
  assert_eq(dup_second.committed_count, 1U)
  assert_eq(dup_second.dispatches[0].state, Committed)
}
