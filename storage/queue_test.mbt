///|
fn mk_item(
  op_key : @hash.Hash,
  state : @storage.QueueItemState,
  size_bytes : UInt64,
) -> @storage.QueueItem {
  {
    op_key,
    target_id: "node-1",
    lane: @storage.Hot,
    event: @storage.Ingest,
    digest: @hash.Hash::of_bytes(b"digest"),
    size_bytes,
    state,
  }
}

///|
test "ReplicationQueue upsert/get/mark_state" {
  let q = @storage.ReplicationQueue::new()
  let key = @hash.Hash::of_bytes(b"op-1")
  q.upsert(mk_item(key, @storage.Pending, 10UL))
  assert_true(q.get(key) is Some(_))

  q.mark_state(key, @storage.InFlight)
  match q.get(key) {
    Some(item) => assert_eq(item.state, @storage.InFlight)
    None => assert_true(false)
  }
}

///|
test "ReplicationQueue stats" {
  let q = @storage.ReplicationQueue::new()
  q.upsert(mk_item(@hash.Hash::of_bytes(b"op-a"), @storage.Pending, 5UL))
  q.upsert(mk_item(@hash.Hash::of_bytes(b"op-b"), @storage.InFlight, 7UL))
  q.upsert(mk_item(@hash.Hash::of_bytes(b"op-c"), @storage.Done, 9UL))

  let s = q.stats()
  assert_eq(s.pending_ops, 1UL)
  assert_eq(s.pending_bytes, 5UL)
  assert_eq(s.inflight_ops, 1UL)
  assert_eq(s.inflight_bytes, 7UL)
}

///|
test "ReplicationQueue snapshot and restore" {
  let q = @storage.ReplicationQueue::new()
  q.upsert(mk_item(@hash.Hash::of_bytes(b"op-a"), @storage.Pending, 5UL))
  q.upsert(mk_item(@hash.Hash::of_bytes(b"op-b"), @storage.Failed, 7UL))

  let snap = q.snapshot()
  let restored = @storage.ReplicationQueue::restore(snap)

  assert_true(restored.get(@hash.Hash::of_bytes(b"op-a")) is Some(_))
  assert_true(restored.get(@hash.Hash::of_bytes(b"op-b")) is Some(_))
}

///|
test "IdempotencyLedger snapshot and restore" {
  let ledger = @storage.IdempotencyLedger::new()
  let k1 = @hash.Hash::of_bytes(b"k1")
  let k2 = @hash.Hash::of_bytes(b"k2")
  ledger.mark_pending(k1)
  ledger.mark_committed(k2)

  let snap = ledger.snapshot()
  let restored = @storage.IdempotencyLedger::restore(snap)

  assert_true(restored.state(k1) is Some(_))
  assert_true(restored.state(k2) is Some(@storage.Committed))
}
