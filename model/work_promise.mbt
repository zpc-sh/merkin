///|
/// Work promise lifecycle states (§4.1).
pub(all) enum WorkPromiseState {
  ABSENT
  PROMISED
  RUNNING
  STALE
  FRESH
  FAILED
} derive(Eq, Show)

///|
/// WorkPromise: deferred work artifact promise (§4.1).
/// A node/envelope may carry promises for derived artifacts.
pub(all) struct WorkPromise {
  promise_id : @hash.Hash
  input_hash : @hash.Hash
  transform_id : @hash.Hash
  policy_id : @hash.Hash
  state : WorkPromiseState
  result_hash : @hash.Hash?
  result_envelope_id : @hash.Hash?
  cost_hint : UInt?
} derive(Show)

///|
/// Create a new work promise in ABSENT state.
pub fn WorkPromise::new(
  input_hash : @hash.Hash,
  transform_id : @hash.Hash,
  policy_id : @hash.Hash,
) -> WorkPromise {
  // promise_id = H(input_hash.digest ++ transform_id.digest ++ policy_id.digest)
  let material = bytes_concat(
    bytes_concat(input_hash.digest, transform_id.digest),
    policy_id.digest,
  )
  let promise_id = @hash.Hash::of_bytes(material)
  {
    promise_id,
    input_hash,
    transform_id,
    policy_id,
    state: ABSENT,
    result_hash: None,
    result_envelope_id: None,
    cost_hint: None,
  }
}

///|
/// Transition to PROMISED state.
pub fn WorkPromise::promise(self : WorkPromise) -> WorkPromise {
  { ..self, state: PROMISED }
}

///|
/// Transition to RUNNING state.
pub fn WorkPromise::start(self : WorkPromise) -> WorkPromise {
  { ..self, state: RUNNING }
}

///|
/// Complete with a result.
pub fn WorkPromise::complete(
  self : WorkPromise,
  result_hash : @hash.Hash,
  result_envelope_id : @hash.Hash,
) -> WorkPromise {
  {
    ..self,
    state: FRESH,
    result_hash: Some(result_hash),
    result_envelope_id: Some(result_envelope_id),
  }
}

///|
/// Mark as failed.
pub fn WorkPromise::fail(self : WorkPromise) -> WorkPromise {
  { ..self, state: FAILED }
}

///|
fn bytes_concat(a : Bytes, b : Bytes) -> Bytes {
  let buf = FixedArray::make(a.length() + b.length(), b'\x00')
  for i = 0; i < a.length(); i = i + 1 {
    buf[i] = a[i]
  }
  for i = 0; i < b.length(); i = i + 1 {
    buf[a.length() + i] = b[i]
  }
  Bytes::from_array(buf)
}
