///|
/// Store role in the composed union storage graph.
pub(all) enum StoreRole {
  Local
  Remote
  Cache
  Replica
  Archive
  Oci
} derive(Eq, Show)

///|
/// Runtime availability signal for each store node.
pub(all) enum Availability {
  Online
  Degraded
  Offline
} derive(Eq, Show)

///|
/// Replication lanes encode priority and durability intent.
pub(all) enum ReplicationLane {
  Critical
  Hot
  Warm
  Cold
  ArchiveLane
} derive(Eq, Show)

///|
/// Event triggers that drive replication without cron jobs.
pub(all) enum ReplicationEvent {
  Ingest
  SealEpoch
  ReadMiss
  PeerHandshake
} derive(Eq, Show)

///|
/// Per-target write mode.
pub(all) enum WriteMode {
  SyncQuorum
  AsyncFanout
  LocalOnly
} derive(Eq, Show)

///|
/// OCI tag strategy for publication.
pub(all) enum OciTagMode {
  DigestOnly
  EpochTag
  LatestTag
} derive(Eq, Show)

///|
/// Tree rule matching mode.
pub(all) enum TreeMatchMode {
  Prefix
  Exact
} derive(Eq, Show)

///|
/// One replication target and its policy constraints.
pub(all) struct TargetRule {
  target_id : String
  role : StoreRole
  lanes : Array[ReplicationLane]
  min_availability : Availability
  write_mode : WriteMode
  pull_on_miss : Bool
} derive(Show)

///|
/// Backpressure guardrails.
pub(all) struct BackpressurePolicy {
  max_inflight_ops : UInt64
  max_inflight_bytes : UInt64
  max_pending_ops : UInt64
  max_pending_bytes : UInt64
} derive(Show)

///|
pub fn BackpressurePolicy::default() -> BackpressurePolicy {
  {
    max_inflight_ops: 1024UL,
    max_inflight_bytes: 64UL * 1024UL * 1024UL,
    max_pending_ops: 4096UL,
    max_pending_bytes: 256UL * 1024UL * 1024UL,
  }
}

///|
/// Runtime queue snapshot used by backpressure checks.
pub(all) struct QueueStats {
  inflight_ops : UInt64
  inflight_bytes : UInt64
  pending_ops : UInt64
  pending_bytes : UInt64
} derive(Show)

///|
pub fn QueueStats::idle() -> QueueStats {
  {
    inflight_ops: 0UL,
    inflight_bytes: 0UL,
    pending_ops: 0UL,
    pending_bytes: 0UL,
  }
}

///|
/// Idempotency key derivation policy.
pub(all) struct IdempotencyPolicy {
  scope : String
  include_epoch : Bool
} derive(Show)

///|
pub fn IdempotencyPolicy::default() -> IdempotencyPolicy {
  { scope: "merkin.replication.v1", include_epoch: true }
}

///|
/// OCI publishing and retrieval integration policy.
pub(all) struct OciPolicy {
  enabled : Bool
  repository : String
  artifact_media_type : String
  tag_mode : OciTagMode
} derive(Show)

///|
pub fn OciPolicy::disabled() -> OciPolicy {
  {
    enabled: false,
    repository: "",
    artifact_media_type: "application/vnd.merkin.artifact.v1+octet-stream",
    tag_mode: DigestOnly,
  }
}

///|
/// Tree-based policy rule for path/lane checks.
pub(all) struct TreeRule {
  path : Array[String]
  match_mode : TreeMatchMode
  lane : ReplicationLane
  require_sealed_epoch : Bool
  min_replicas : UInt
} derive(Show)

///|
/// Content-addressed replication policy root object.
pub(all) struct ReplicationPolicy {
  policy_id : @hash.Hash
  version : UInt
  active_epoch : UInt64
  quorum_write : UInt
  quorum_read : UInt
  idempotency : IdempotencyPolicy
  backpressure : BackpressurePolicy
  oci : OciPolicy
  targets : Array[TargetRule]
  tree_rules : Array[TreeRule]
} derive(Show)

///|
/// Construct a deterministic policy object and compute policy_id.
pub fn ReplicationPolicy::new(
  version : UInt,
  active_epoch : UInt64,
  quorum_write : UInt,
  quorum_read : UInt,
  idempotency : IdempotencyPolicy,
  backpressure : BackpressurePolicy,
  oci : OciPolicy,
  targets : Array[TargetRule],
  tree_rules : Array[TreeRule],
) -> ReplicationPolicy {
  let bytes = policy_material(
    version, active_epoch, quorum_write, quorum_read, idempotency, backpressure,
    oci, targets, tree_rules,
  )
  let policy_id = @hash.Hash::of_bytes(bytes)
  {
    policy_id,
    version,
    active_epoch,
    quorum_write,
    quorum_read,
    idempotency,
    backpressure,
    oci,
    targets,
    tree_rules,
  }
}

///|
/// Convenience constructor for initial drafts.
pub fn ReplicationPolicy::draft_v1(
  active_epoch : UInt64,
  targets : Array[TargetRule],
  tree_rules? : Array[TreeRule] = [],
) -> ReplicationPolicy {
  ReplicationPolicy::new(
    1U,
    active_epoch,
    1U,
    1U,
    IdempotencyPolicy::default(),
    BackpressurePolicy::default(),
    OciPolicy::disabled(),
    targets,
    tree_rules,
  )
}

///|
/// Compute deterministic idempotency key for one replication op.
pub fn ReplicationPolicy::idempotency_key(
  self : ReplicationPolicy,
  subject_hash : @hash.Hash,
  target_id : String,
  lane : ReplicationLane,
  event : ReplicationEvent,
) -> @hash.Hash {
  let epoch_component = if self.idempotency.include_epoch {
    self.active_epoch.to_string()
  } else {
    "0"
  }
  let material = self.idempotency.scope +
    "|" +
    subject_hash.key() +
    "|" +
    target_id +
    "|" +
    lane_name(lane) +
    "|" +
    event_name(event) +
    "|" +
    epoch_component
  @hash.Hash::of_bytes(string_to_bytes(material))
}

///|
/// Check whether a target is eligible for a lane at current availability.
pub fn ReplicationPolicy::allows_target(
  self : ReplicationPolicy,
  target_id : String,
  role : StoreRole,
  lane : ReplicationLane,
  availability : Availability,
) -> Bool {
  match find_target(self.targets, target_id) {
    None => false
    Some(rule) => {
      if rule.role != role {
        return false
      }
      if !contains_lane(rule.lanes, lane) {
        return false
      }
      availability_rank(availability) >=
      availability_rank(rule.min_availability)
    }
  }
}

///|
/// Backpressure gate for dispatch decisions.
pub fn ReplicationPolicy::allow_dispatch(
  self : ReplicationPolicy,
  lane : ReplicationLane,
  stats : QueueStats,
) -> Bool {
  let hard_ok = stats.inflight_ops <= self.backpressure.max_inflight_ops &&
    stats.inflight_bytes <= self.backpressure.max_inflight_bytes &&
    stats.pending_ops <= self.backpressure.max_pending_ops &&
    stats.pending_bytes <= self.backpressure.max_pending_bytes
  if hard_ok {
    return true
  }
  // Critical lane can exceed soft limits by up to 2x.
  if lane == Critical {
    stats.inflight_ops <= self.backpressure.max_inflight_ops * 2UL &&
    stats.inflight_bytes <= self.backpressure.max_inflight_bytes * 2UL &&
    stats.pending_ops <= self.backpressure.max_pending_ops * 2UL &&
    stats.pending_bytes <= self.backpressure.max_pending_bytes * 2UL
  } else {
    false
  }
}

///|
/// Evaluate tree/path rules for a candidate replication operation.
pub fn ReplicationPolicy::tree_accepts(
  self : ReplicationPolicy,
  path : Array[String],
  lane : ReplicationLane,
  sealed_epoch : Bool,
  live_replicas : UInt,
) -> Bool {
  let mut matched = 0
  for rule in self.tree_rules {
    if rule.lane != lane {
      continue
    }
    if !path_matches(rule.match_mode, rule.path, path) {
      continue
    }
    matched = matched + 1
    if rule.require_sealed_epoch && !sealed_epoch {
      continue
    }
    if live_replicas < rule.min_replicas {
      continue
    }
    return true
  }
  // No matching rule means "allow".
  matched == 0
}

///|
/// Count configured targets for one lane.
pub fn ReplicationPolicy::target_count_for_lane(
  self : ReplicationPolicy,
  lane : ReplicationLane,
) -> UInt {
  let mut count = 0U
  for target in self.targets {
    if contains_lane(target.lanes, lane) {
      count = count + 1U
    }
  }
  count
}

///|
/// Idempotency ledger state.
pub(all) enum IdempotencyState {
  Pending
  Committed
  Failed
} derive(Eq, Show)

///|
/// In-memory idempotency ledger.
pub(all) struct IdempotencyLedger {
  states : Map[String, IdempotencyState]
}

///|
pub(all) struct IdempotencySnapshot {
  snapshot_id : @hash.Hash
  entries : Array[(String, IdempotencyState)]
} derive(Show)

///|
pub fn IdempotencyLedger::new() -> IdempotencyLedger {
  { states: {} }
}

///|
pub fn IdempotencyLedger::state(
  self : IdempotencyLedger,
  op_key : @hash.Hash,
) -> IdempotencyState? {
  self.states.get(op_key.key())
}

///|
pub fn IdempotencyLedger::is_committed(
  self : IdempotencyLedger,
  op_key : @hash.Hash,
) -> Bool {
  match self.states.get(op_key.key()) {
    Some(state) => state == Committed
    None => false
  }
}

///|
pub fn IdempotencyLedger::mark_pending(
  self : IdempotencyLedger,
  op_key : @hash.Hash,
) -> Unit {
  self.states[op_key.key()] = Pending
}

///|
pub fn IdempotencyLedger::mark_committed(
  self : IdempotencyLedger,
  op_key : @hash.Hash,
) -> Unit {
  self.states[op_key.key()] = Committed
}

///|
pub fn IdempotencyLedger::mark_failed(
  self : IdempotencyLedger,
  op_key : @hash.Hash,
) -> Unit {
  self.states[op_key.key()] = Failed
}

///|
pub fn IdempotencyLedger::snapshot(
  self : IdempotencyLedger,
) -> IdempotencySnapshot {
  let keys : Array[String] = []
  for key, _state in self.states {
    keys.push(key)
  }
  keys.sort()

  let entries : Array[(String, IdempotencyState)] = []
  let lines : Array[String] = []
  for key in keys {
    match self.states.get(key) {
      Some(state) => {
        entries.push((key, state))
        lines.push(key + ";" + idempotency_state_name(state))
      }
      None => ()
    }
  }
  let snapshot_id = @hash.Hash::of_bytes(string_to_bytes(join(lines, "\n")))
  { snapshot_id, entries }
}

///|
pub fn IdempotencyLedger::restore(
  snapshot : IdempotencySnapshot,
) -> IdempotencyLedger {
  let ledger = IdempotencyLedger::new()
  for entry in snapshot.entries {
    let (key, state) = entry
    ledger.states[key] = state
  }
  ledger
}

///|
fn find_target(targets : Array[TargetRule], target_id : String) -> TargetRule? {
  for target in targets {
    if target.target_id == target_id {
      return Some(target)
    }
  }
  None
}

///|
fn contains_lane(
  lanes : Array[ReplicationLane],
  lane : ReplicationLane,
) -> Bool {
  for it in lanes {
    if it == lane {
      return true
    }
  }
  false
}

///|
fn availability_rank(v : Availability) -> Int {
  match v {
    Offline => 0
    Degraded => 1
    Online => 2
  }
}

///|
fn path_matches(
  mode : TreeMatchMode,
  expected : Array[String],
  got : Array[String],
) -> Bool {
  match mode {
    Exact => array_eq(expected, got)
    Prefix => array_starts_with(got, expected)
  }
}

///|
fn array_eq(a : Array[String], b : Array[String]) -> Bool {
  if a.length() != b.length() {
    return false
  }
  for i = 0; i < a.length(); i = i + 1 {
    if a[i] != b[i] {
      return false
    }
  }
  true
}

///|
fn array_starts_with(value : Array[String], prefix : Array[String]) -> Bool {
  if prefix.length() > value.length() {
    return false
  }
  for i = 0; i < prefix.length(); i = i + 1 {
    if value[i] != prefix[i] {
      return false
    }
  }
  true
}

///|
fn policy_material(
  version : UInt,
  active_epoch : UInt64,
  quorum_write : UInt,
  quorum_read : UInt,
  idempotency : IdempotencyPolicy,
  backpressure : BackpressurePolicy,
  oci : OciPolicy,
  targets : Array[TargetRule],
  tree_rules : Array[TreeRule],
) -> Bytes {
  let target_chunks : Array[String] = []
  for t in targets {
    let lanes : Array[String] = []
    for lane in t.lanes {
      lanes.push(lane_name(lane))
    }
    target_chunks.push(
      t.target_id +
      ";" +
      role_name(t.role) +
      ";" +
      join(lanes, ",") +
      ";" +
      availability_name(t.min_availability) +
      ";" +
      write_mode_name(t.write_mode) +
      ";" +
      bool_to_string(t.pull_on_miss),
    )
  }

  let tree_chunks : Array[String] = []
  for rule in tree_rules {
    tree_chunks.push(
      join(rule.path, "/") +
      ";" +
      tree_mode_name(rule.match_mode) +
      ";" +
      lane_name(rule.lane) +
      ";" +
      bool_to_string(rule.require_sealed_epoch) +
      ";" +
      rule.min_replicas.to_string(),
    )
  }

  let b = StringBuilder::new()
  b.write_string(version.to_string())
  b.write_string("|")
  b.write_string(active_epoch.to_string())
  b.write_string("|")
  b.write_string(quorum_write.to_string())
  b.write_string("|")
  b.write_string(quorum_read.to_string())
  b.write_string("|")
  b.write_string(idempotency.scope)
  b.write_string("|")
  b.write_string(bool_to_string(idempotency.include_epoch))
  b.write_string("|")
  b.write_string(backpressure.max_inflight_ops.to_string())
  b.write_string("|")
  b.write_string(backpressure.max_inflight_bytes.to_string())
  b.write_string("|")
  b.write_string(backpressure.max_pending_ops.to_string())
  b.write_string("|")
  b.write_string(backpressure.max_pending_bytes.to_string())
  b.write_string("|")
  b.write_string(bool_to_string(oci.enabled))
  b.write_string("|")
  b.write_string(oci.repository)
  b.write_string("|")
  b.write_string(oci.artifact_media_type)
  b.write_string("|")
  b.write_string(oci_tag_mode_name(oci.tag_mode))
  b.write_string("|")
  b.write_string(join(target_chunks, "||"))
  b.write_string("|")
  b.write_string(join(tree_chunks, "||"))
  string_to_bytes(b.to_string())
}

///|
// Use StringBuilder to avoid quadratic-time string concatenation.
fn join(items : Array[String], sep : String) -> String {
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
fn bool_to_string(v : Bool) -> String {
  if v {
    "true"
  } else {
    "false"
  }
}

///|
fn role_name(v : StoreRole) -> String {
  match v {
    Local => "local"
    Remote => "remote"
    Cache => "cache"
    Replica => "replica"
    Archive => "archive"
    Oci => "oci"
  }
}

///|
fn availability_name(v : Availability) -> String {
  match v {
    Online => "online"
    Degraded => "degraded"
    Offline => "offline"
  }
}

///|
fn lane_name(v : ReplicationLane) -> String {
  match v {
    Critical => "critical"
    Hot => "hot"
    Warm => "warm"
    Cold => "cold"
    ArchiveLane => "archive"
  }
}

///|
fn event_name(v : ReplicationEvent) -> String {
  match v {
    Ingest => "ingest"
    SealEpoch => "seal_epoch"
    ReadMiss => "read_miss"
    PeerHandshake => "peer_handshake"
  }
}

///|
fn write_mode_name(v : WriteMode) -> String {
  match v {
    SyncQuorum => "sync_quorum"
    AsyncFanout => "async_fanout"
    LocalOnly => "local_only"
  }
}

///|
fn oci_tag_mode_name(v : OciTagMode) -> String {
  match v {
    DigestOnly => "digest_only"
    EpochTag => "epoch_tag"
    LatestTag => "latest_tag"
  }
}

///|
fn tree_mode_name(v : TreeMatchMode) -> String {
  match v {
    Prefix => "prefix"
    Exact => "exact"
  }
}

///|
fn idempotency_state_name(v : IdempotencyState) -> String {
  match v {
    Pending => "pending"
    Committed => "committed"
    Failed => "failed"
  }
}

///|
fn string_to_bytes(s : String) -> Bytes {
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
