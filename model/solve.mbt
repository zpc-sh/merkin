///|
/// Generic solve modes for mu- and provider-backed execution.
pub(all) enum SolveMode {
  Accumulate
  Offload
  Execute
} derive(Eq, Show)

///|
/// Generalized solve lifecycle status.
pub(all) enum SolveStatus {
  Absent
  Promised
  Queued
  Running
  Blocked
  RateLimited
  Stale
  Materialized
  Verified
  Failed
  Purged
} derive(Eq, Show)

///|
/// Execution and replay traits emitted by policy over solve units.
pub(all) struct SolveTraits {
  deterministic : Bool
  replayable : Bool
  idempotent : Bool
  ephemeral : Bool
  requires_verification : Bool
  requires_proof : Bool
  may_offload : Bool
  may_parallelize : Bool
  bounded_write_scope : Bool
} derive(Show)

///|
/// Routing hints emitted by policy or compiler shaping.
pub(all) struct SolvePolicyHints {
  preferred_surface : String
  preferred_tier : String
  preferred_lane : String
  fallback_handler : String
  max_parallelism : UInt
} derive(Show)

///|
/// Compact solve ticket that can be carried through replay and offload flows.
pub(all) struct SolveTicket {
  solve_id : @hash.Hash
  solve_kind : String
  offloaded_to : String
  status : SolveStatus
  handler : String
  result_hash : @hash.Hash?
  result_envelope_id : @hash.Hash?
  witness_ref : String?
  detail : String
} derive(Show)

///|
pub fn SolveTraits::new(
  deterministic : Bool,
  replayable : Bool,
  idempotent : Bool,
  ephemeral : Bool,
  requires_verification : Bool,
  requires_proof : Bool,
  may_offload : Bool,
  may_parallelize : Bool,
  bounded_write_scope : Bool,
) -> SolveTraits {
  {
    deterministic,
    replayable,
    idempotent,
    ephemeral,
    requires_verification,
    requires_proof,
    may_offload,
    may_parallelize,
    bounded_write_scope,
  }
}

///|
pub fn SolvePolicyHints::new(
  preferred_surface : String,
  preferred_tier : String,
  preferred_lane : String,
  fallback_handler : String,
  max_parallelism : UInt,
) -> SolvePolicyHints {
  {
    preferred_surface,
    preferred_tier,
    preferred_lane,
    fallback_handler,
    max_parallelism,
  }
}

///|
pub fn SolveTicket::new(
  solve_id : @hash.Hash,
  solve_kind : String,
  offloaded_to : String,
  status : SolveStatus,
  handler : String,
  detail : String,
) -> SolveTicket {
  {
    solve_id,
    solve_kind,
    offloaded_to,
    status,
    handler,
    result_hash: None,
    result_envelope_id: None,
    witness_ref: None,
    detail,
  }
}

///|
pub fn SolveTicket::attach_result(
  self : SolveTicket,
  result_hash : @hash.Hash,
  result_envelope_id : @hash.Hash,
) -> SolveTicket {
  {
    ..self,
    status: Materialized,
    result_hash: Some(result_hash),
    result_envelope_id: Some(result_envelope_id),
  }
}

///|
pub fn SolveTicket::with_witness(
  self : SolveTicket,
  witness_ref : String,
) -> SolveTicket {
  { ..self, witness_ref: Some(witness_ref) }
}

///|
pub fn SolveTicket::mark_verified(self : SolveTicket) -> SolveTicket {
  { ..self, status: Verified }
}

///|
pub fn SolveTicket::mark_failed(
  self : SolveTicket,
  detail : String,
) -> SolveTicket {
  { ..self, status: Failed, detail }
}

///|
pub fn WorkPromise::to_solve_ticket(
  self : WorkPromise,
  solve_kind : String,
  offloaded_to : String,
  handler : String,
  detail : String,
) -> SolveTicket {
  {
    solve_id: self.promise_id,
    solve_kind,
    offloaded_to,
    status: promise_state_to_solve_status(self.state),
    handler,
    result_hash: self.result_hash,
    result_envelope_id: self.result_envelope_id,
    witness_ref: None,
    detail,
  }
}

///|
fn promise_state_to_solve_status(state : WorkPromiseState) -> SolveStatus {
  match state {
    ABSENT => Absent
    PROMISED => Promised
    RUNNING => Running
    STALE => Stale
    FRESH => Materialized
    FAILED => Failed
  }
}
