///|
/// Conversation track for Saba/Pactis threads.
pub(all) enum ConversationTrack {
  Program
  Git
} derive(Eq, Show)

///|
/// Actor role within one conversational turn.
pub(all) enum ConversationActorRole {
  Ai
  Human
  System
} derive(Eq, Show)

///|
/// Embedding action for runtime handling in conversational flows.
pub(all) enum ConversationEmbeddingAction {
  Observe
  FlipAot
  Purge
} derive(Eq, Show)

///|
/// Length envelope used for ingress/egress replay guards.
pub(all) struct LengthEnvelope {
  input_len_min : UInt
  input_len_max : UInt
  output_len_min : UInt
  output_len_max : UInt
} derive(Show)

///|
pub fn LengthEnvelope::default() -> LengthEnvelope {
  {
    input_len_min: 1U,
    input_len_max: 12000U,
    output_len_min: 1U,
    output_len_max: 24000U,
  }
}

///|
/// Structured issue surface for conversational handlers.
pub(all) struct ConversationIssue {
  code : String
  message : String
} derive(Show)

///|
pub(all) struct SabaHall {
  hall_id : String
  name : String
  policy_profile : String
  created_at_seq : UInt
} derive(Show)

///|
pub(all) struct SabaThread {
  thread_id : String
  hall_id : String
  topic : String
  track : ConversationTrack
  head_checkpoint : String
} derive(Show)

///|
pub(all) struct SabaTurn {
  turn_id : String
  thread_id : String
  turn_seq : UInt
  actor_overlay : String
  actor_role : ConversationActorRole
  content : String
  length_envelope : LengthEnvelope
  idempotency_key : String
  non_replayable : Bool
  checkpoint_id : String
} derive(Show)

///|
pub(all) struct SabaCheckpoint {
  checkpoint_id : String
  thread_id : String
  turn_seq : UInt
  label : String
} derive(Show)

///|
/// Compact per-file embedding annotation attached to a thread timeline.
pub(all) struct ThreadEmbeddingRecord {
  record_id : String
  thread_id : String
  file_ref : String
  file_type : String
  mime_type : String
  found : Bool
  count : UInt
  action : ConversationEmbeddingAction
  ephemeral : Bool
  purge_after_turns : UInt
  recorded_turn_seq : UInt
  note : String
} derive(Show)

///|
pub(all) struct TurnRequest {
  actor_overlay : String
  actor_role : ConversationActorRole
  content : String
  length_envelope : LengthEnvelope
  idempotency_key : String
} derive(Show)

///|
pub fn TurnRequest::default(content : String) -> TurnRequest {
  {
    actor_overlay: "chatgpt",
    actor_role: Ai,
    content,
    length_envelope: LengthEnvelope::default(),
    idempotency_key: "",
  }
}

///|
pub(all) struct TurnOutcome {
  accepted : Bool
  turn_id : String?
  turn_seq : UInt?
  checkpoint_id : String?
  issues : Array[ConversationIssue]
  canonical_addresses : Array[String]
} derive(Show)

///|
pub(all) struct ReplayRequest {
  from_seq : UInt
  to_seq : UInt?
  length_guard_enforced : Bool
} derive(Show)

///|
pub fn ReplayRequest::default() -> ReplayRequest {
  { from_seq: 1U, to_seq: None, length_guard_enforced: true }
}

///|
pub(all) struct ReplayOutcome {
  ok : Bool
  replayed_count : UInt
  non_replayable_count : UInt
  issues : Array[ConversationIssue]
} derive(Show)

///|
/// In-memory conversation host scaffold for Saba/Pactis.
pub(all) struct ConversationHost {
  mut halls : Array[SabaHall]
  mut threads : Array[SabaThread]
  mut turns : Array[SabaTurn]
  mut checkpoints : Array[SabaCheckpoint]
  mut embedding_records : Array[ThreadEmbeddingRecord]
  mut next_hall_seq : UInt
  mut next_thread_seq : UInt
  mut next_turn_seq : UInt
  mut next_checkpoint_seq : UInt
  mut next_embedding_seq : UInt
} derive(Show)

///|
pub fn ConversationHost::new() -> ConversationHost {
  {
    halls: [],
    threads: [],
    turns: [],
    checkpoints: [],
    embedding_records: [],
    next_hall_seq: 1U,
    next_thread_seq: 1U,
    next_turn_seq: 1U,
    next_checkpoint_seq: 1U,
    next_embedding_seq: 1U,
  }
}

///|
pub fn ConversationHost::create_hall(
  self : ConversationHost,
  name : String,
  policy_profile : String,
) -> SabaHall {
  let hall = {
    hall_id: "hall-" + self.next_hall_seq.to_string(),
    name,
    policy_profile,
    created_at_seq: self.next_hall_seq,
  }
  self.halls.push(hall)
  self.next_hall_seq = self.next_hall_seq + 1U
  hall
}

///|
pub fn ConversationHost::create_thread(
  self : ConversationHost,
  hall_id : String,
  topic : String,
  track : ConversationTrack,
) -> SabaThread? {
  if !self.has_hall(hall_id) {
    return None
  }
  let checkpoint_id = "checkpoint-" + self.next_checkpoint_seq.to_string()
  let thread = {
    thread_id: "thread-" + self.next_thread_seq.to_string(),
    hall_id,
    topic,
    track,
    head_checkpoint: checkpoint_id,
  }
  self.next_thread_seq = self.next_thread_seq + 1U
  self.next_checkpoint_seq = self.next_checkpoint_seq + 1U
  self.threads.push(thread)
  self.checkpoints.push({
    checkpoint_id,
    thread_id: thread.thread_id,
    turn_seq: 0U,
    label: "thread-init",
  })
  Some(thread)
}

///|
pub fn ConversationHost::append_turn(
  self : ConversationHost,
  thread_id : String,
  request : TurnRequest,
) -> TurnOutcome {
  let mut issues : Array[ConversationIssue] = []

  if !self.has_thread(thread_id) {
    issues.push({ code: "BAD_REQUEST", message: "thread_id not found" })
    return rejected_turn_outcome(issues)
  }
  if !length_envelope_valid(request.length_envelope) {
    issues.push({
      code: "BAD_LENGTH_ENVELOPE",
      message: "length envelope must be positive and min <= max",
    })
    return rejected_turn_outcome(issues)
  }
  if request.actor_overlay == "" {
    issues.push({ code: "BAD_REQUEST", message: "actor_overlay is required" })
    return rejected_turn_outcome(issues)
  }
  if request.idempotency_key != "" &&
    self.has_idempotency(thread_id, request.idempotency_key) {
    issues.push({
      code: "CONFLICTING_IDEMPOTENCY_KEY",
      message: "idempotency key already exists in this thread",
    })
    return rejected_turn_outcome(issues)
  }

  let ingress_len = request.content.length().to_uint()
  if ingress_len < request.length_envelope.input_len_min ||
    ingress_len > request.length_envelope.input_len_max {
    issues.push({
      code: "LENGTH_ENVELOPE_VIOLATION",
      message: "ingress content length is outside declared bounds",
    })
    return rejected_turn_outcome(issues)
  }

  let turn_seq = self.next_turn_seq_for_thread(thread_id)
  let turn_id = "turn-" + self.next_turn_seq.to_string()
  let checkpoint_id = "checkpoint-" + self.next_checkpoint_seq.to_string()
  let mut non_replayable = false

  let egress_preview = "turn.accepted:" + turn_id + ":" + thread_id
  let egress_len = egress_preview.length().to_uint()
  if egress_len < request.length_envelope.output_len_min ||
    egress_len > request.length_envelope.output_len_max {
    non_replayable = true
    issues.push({
      code: "LENGTH_ENVELOPE_VIOLATION",
      message: "egress projection length is outside declared bounds",
    })
    issues.push({
      code: "NON_REPLAYABLE_TURN",
      message: "turn is accepted but marked non-replayable by guard policy",
    })
  }

  self.turns.push({
    turn_id,
    thread_id,
    turn_seq,
    actor_overlay: request.actor_overlay,
    actor_role: request.actor_role,
    content: request.content,
    length_envelope: request.length_envelope,
    idempotency_key: request.idempotency_key,
    non_replayable,
    checkpoint_id,
  })
  self.checkpoints.push({
    checkpoint_id,
    thread_id,
    turn_seq,
    label: "turn-" + turn_seq.to_string(),
  })
  self.next_turn_seq = self.next_turn_seq + 1U
  self.next_checkpoint_seq = self.next_checkpoint_seq + 1U
  self.set_thread_head_checkpoint(thread_id, checkpoint_id)

  {
    accepted: true,
    turn_id: Some(turn_id),
    turn_seq: Some(turn_seq),
    checkpoint_id: Some(checkpoint_id),
    issues,
    canonical_addresses: [
      "cog://pactis/" +
      thread_id +
      "?overlay=" +
      request.actor_overlay +
      "&mode=debate&gap=1#overlay",
      "cas://pactis/blake3/" +
      turn_id +
      "?overlay=" +
      request.actor_overlay +
      "&mode=debate#overlay",
    ],
  }
}

///|
pub fn ConversationHost::create_checkpoint(
  self : ConversationHost,
  thread_id : String,
  label : String,
) -> SabaCheckpoint? {
  if !self.has_thread(thread_id) {
    return None
  }
  let checkpoint = {
    checkpoint_id: "checkpoint-" + self.next_checkpoint_seq.to_string(),
    thread_id,
    turn_seq: self.latest_turn_seq(thread_id),
    label: if label == "" {
      "manual"
    } else {
      label
    },
  }
  self.next_checkpoint_seq = self.next_checkpoint_seq + 1U
  self.checkpoints.push(checkpoint)
  self.set_thread_head_checkpoint(thread_id, checkpoint.checkpoint_id)
  Some(checkpoint)
}

///|
pub fn ConversationHost::replay(
  self : ConversationHost,
  thread_id : String,
  request : ReplayRequest,
) -> ReplayOutcome {
  let mut issues : Array[ConversationIssue] = []
  if !self.has_thread(thread_id) {
    issues.push({ code: "BAD_REQUEST", message: "thread_id not found" })
    return { ok: false, replayed_count: 0U, non_replayable_count: 0U, issues }
  }

  let max_seq = self.latest_turn_seq(thread_id)
  let to_seq = match request.to_seq {
    Some(value) => value
    None => max_seq
  }
  let mut replayed_count : UInt = 0U
  let mut non_replayable_count : UInt = 0U
  for turn in self.turns {
    if turn.thread_id != thread_id {
      continue
    }
    if turn.turn_seq < request.from_seq || turn.turn_seq > to_seq {
      continue
    }
    replayed_count = replayed_count + 1U
    if turn.non_replayable {
      non_replayable_count = non_replayable_count + 1U
      if request.length_guard_enforced {
        issues.push({
          code: "NON_REPLAYABLE_TURN",
          message: "replay window contains non-replayable turn",
        })
      }
    }
  }

  let ok = if request.length_guard_enforced {
    non_replayable_count == 0U
  } else {
    true
  }
  { ok, replayed_count, non_replayable_count, issues }
}

///|
pub fn ConversationHost::timeline(
  self : ConversationHost,
  thread_id : String,
  from_seq : UInt,
  limit : UInt,
) -> Array[SabaTurn] {
  let mut out : Array[SabaTurn] = []
  for turn in self.turns {
    if turn.thread_id != thread_id {
      continue
    }
    if turn.turn_seq < from_seq {
      continue
    }
    if out.length().to_uint() >= limit {
      break
    }
    out.push(turn)
  }
  out
}

///|
/// Record embedding metadata for an arbitrary file in one thread.
pub fn ConversationHost::record_embedding(
  self : ConversationHost,
  thread_id : String,
  file_ref : String,
  file_type : String,
  mime_type : String,
  found : Bool,
  count : UInt,
  action : ConversationEmbeddingAction,
  ephemeral : Bool,
  purge_after_turns : UInt,
  note : String,
) -> ThreadEmbeddingRecord? {
  if !self.has_thread(thread_id) {
    return None
  }
  if file_ref == "" || file_type == "" {
    return None
  }
  let recorded_turn_seq = self.latest_turn_seq(thread_id)
  let record = {
    record_id: "embed-" + self.next_embedding_seq.to_string(),
    thread_id,
    file_ref,
    file_type,
    mime_type,
    found,
    count,
    action,
    ephemeral,
    purge_after_turns,
    recorded_turn_seq,
    note,
  }
  self.next_embedding_seq = self.next_embedding_seq + 1U
  self.embedding_records.push(record)
  Some(record)
}

///|
/// Purge ephemeral embedding records that exceed their turn-age budget.
pub fn ConversationHost::purge_embedding_records(
  self : ConversationHost,
  thread_id : String,
  current_turn_seq : UInt,
) -> UInt {
  let mut kept : Array[ThreadEmbeddingRecord] = []
  let mut purged : UInt = 0U
  for record in self.embedding_records {
    if record.thread_id != thread_id {
      kept.push(record)
      continue
    }
    if !record.ephemeral {
      kept.push(record)
      continue
    }
    let age = if current_turn_seq > record.recorded_turn_seq {
      current_turn_seq - record.recorded_turn_seq
    } else {
      0U
    }
    if age >= record.purge_after_turns {
      purged = purged + 1U
    } else {
      kept.push(record)
    }
  }
  self.embedding_records = kept
  purged
}

///|
/// Read all embedding records for one thread.
pub fn ConversationHost::embedding_timeline(
  self : ConversationHost,
  thread_id : String,
) -> Array[ThreadEmbeddingRecord] {
  let out : Array[ThreadEmbeddingRecord] = []
  for record in self.embedding_records {
    if record.thread_id == thread_id {
      out.push(record)
    }
  }
  out
}

///|
fn rejected_turn_outcome(issues : Array[ConversationIssue]) -> TurnOutcome {
  {
    accepted: false,
    turn_id: None,
    turn_seq: None,
    checkpoint_id: None,
    issues,
    canonical_addresses: [],
  }
}

///|
fn length_envelope_valid(envelope : LengthEnvelope) -> Bool {
  envelope.input_len_min > 0U &&
  envelope.output_len_min > 0U &&
  envelope.input_len_min <= envelope.input_len_max &&
  envelope.output_len_min <= envelope.output_len_max
}

///|
fn ConversationHost::has_hall(
  self : ConversationHost,
  hall_id : String,
) -> Bool {
  for hall in self.halls {
    if hall.hall_id == hall_id {
      return true
    }
  }
  false
}

///|
fn ConversationHost::has_thread(
  self : ConversationHost,
  thread_id : String,
) -> Bool {
  for thread in self.threads {
    if thread.thread_id == thread_id {
      return true
    }
  }
  false
}

///|
fn ConversationHost::has_idempotency(
  self : ConversationHost,
  thread_id : String,
  key : String,
) -> Bool {
  for turn in self.turns {
    if turn.thread_id == thread_id && turn.idempotency_key == key {
      return true
    }
  }
  false
}

///|
fn ConversationHost::next_turn_seq_for_thread(
  self : ConversationHost,
  thread_id : String,
) -> UInt {
  let mut out : UInt = 1U
  for turn in self.turns {
    if turn.thread_id == thread_id && turn.turn_seq >= out {
      out = turn.turn_seq + 1U
    }
  }
  out
}

///|
fn ConversationHost::latest_turn_seq(
  self : ConversationHost,
  thread_id : String,
) -> UInt {
  let mut out : UInt = 0U
  for turn in self.turns {
    if turn.thread_id == thread_id && turn.turn_seq > out {
      out = turn.turn_seq
    }
  }
  out
}

///|
fn ConversationHost::set_thread_head_checkpoint(
  self : ConversationHost,
  thread_id : String,
  checkpoint_id : String,
) -> Unit {
  let mut next : Array[SabaThread] = []
  for thread in self.threads {
    if thread.thread_id == thread_id {
      next.push({ ..thread, head_checkpoint: checkpoint_id })
    } else {
      next.push(thread)
    }
  }
  self.threads = next
}
