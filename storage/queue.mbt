///|
/// Queue state for replication operations.
pub(all) enum QueueItemState {
  Pending
  InFlight
  Done
  Failed
} derive(Eq, Show)

///|
pub(all) struct QueueItem {
  op_key : @hash.Hash
  target_id : String
  lane : ReplicationLane
  event : ReplicationEvent
  digest : @hash.Hash
  size_bytes : UInt64
  state : QueueItemState
} derive(Show)

///|
pub(all) struct QueueSnapshot {
  snapshot_id : @hash.Hash
  items : Array[QueueItem]
} derive(Show)

///|
pub(all) struct ReplicationQueue {
  items : Map[String, QueueItem]
}

///|
pub fn ReplicationQueue::new() -> ReplicationQueue {
  { items: {} }
}

///|
fn op_id(op_key : @hash.Hash) -> String {
  op_key.key()
}

///|
pub fn ReplicationQueue::upsert(
  self : ReplicationQueue,
  item : QueueItem,
) -> Unit {
  self.items[op_id(item.op_key)] = item
}

///|
pub fn ReplicationQueue::get(
  self : ReplicationQueue,
  op_key : @hash.Hash,
) -> QueueItem? {
  self.items.get(op_id(op_key))
}

///|
pub fn ReplicationQueue::mark_state(
  self : ReplicationQueue,
  op_key : @hash.Hash,
  state : QueueItemState,
) -> Unit {
  match self.items.get(op_id(op_key)) {
    Some(item) => self.items[op_id(op_key)] = { ..item, state, }
    None => ()
  }
}

///|
pub fn ReplicationQueue::stats(self : ReplicationQueue) -> QueueStats {
  let mut inflight_ops = 0UL
  let mut inflight_bytes = 0UL
  let mut pending_ops = 0UL
  let mut pending_bytes = 0UL
  for _k, item in self.items {
    match item.state {
      InFlight => {
        inflight_ops = inflight_ops + 1UL
        inflight_bytes = inflight_bytes + item.size_bytes
      }
      Pending => {
        pending_ops = pending_ops + 1UL
        pending_bytes = pending_bytes + item.size_bytes
      }
      Done => ()
      Failed => ()
    }
  }
  { inflight_ops, inflight_bytes, pending_ops, pending_bytes }
}

///|
pub fn ReplicationQueue::snapshot(self : ReplicationQueue) -> QueueSnapshot {
  let keys : Array[String] = []
  for key, _item in self.items {
    keys.push(key)
  }
  keys.sort()

  let entries : Array[QueueItem] = []
  for key in keys {
    match self.items.get(key) {
      Some(item) => entries.push(item)
      None => ()
    }
  }

  let snapshot_id = @hash.Hash::of_bytes(queue_snapshot_material(entries))
  { snapshot_id, items: entries }
}

///|
pub fn ReplicationQueue::restore(snapshot : QueueSnapshot) -> ReplicationQueue {
  let queue = ReplicationQueue::new()
  for item in snapshot.items {
    queue.items[op_id(item.op_key)] = item
  }
  queue
}

///|
fn queue_snapshot_material(items : Array[QueueItem]) -> Bytes {
  let lines : Array[String] = []
  for item in items {
    lines.push(
      item.op_key.key() +
      ";" +
      item.target_id +
      ";" +
      lane_name(item.lane) +
      ";" +
      event_name(item.event) +
      ";" +
      item.digest.key() +
      ";" +
      item.size_bytes.to_string() +
      ";" +
      state_name(item.state),
    )
  }
  queue_string_to_bytes(queue_join(lines, "\n"))
}

///|
fn state_name(v : QueueItemState) -> String {
  match v {
    Pending => "pending"
    InFlight => "inflight"
    Done => "done"
    Failed => "failed"
  }
}

///|
// Use StringBuilder to avoid O(N²) string concatenation
fn queue_join(items : Array[String], sep : String) -> String {
  let builder = StringBuilder::new()
  for i = 0; i < items.length(); i = i + 1 {
    if i > 0 {
      builder.write_string(sep)
    }
    builder.write_string(items[i])
  }
  builder.to_string()
}

///|
fn queue_string_to_bytes(s : String) -> Bytes {
  let total = s.length() * 4
  let buf = FixedArray::make(total, b'\x00')
  let mut pos = 0
  for ch in s {
    let code = ch.to_uint()
    buf[pos] = ((code >> 24) & 0xFFU).to_byte()
    buf[pos + 1] = ((code >> 16) & 0xFFU).to_byte()
    buf[pos + 2] = ((code >> 8) & 0xFFU).to_byte()
    buf[pos + 3] = (code & 0xFFU).to_byte()
    pos = pos + 4
  }
  Bytes::from_array(buf)
}
