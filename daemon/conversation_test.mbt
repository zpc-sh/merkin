///|
test "ConversationHost append_turn rejects invalid thread id" {
  let host = ConversationHost::new()
  let request = TurnRequest::default("hello")
  let outcome = host.append_turn("invalid_thread", request)

  assert_false(outcome.accepted)
  assert_eq(outcome.issues.length(), 1)
  assert_eq(outcome.issues[0].code, "BAD_REQUEST")
  assert_eq(outcome.issues[0].message, "thread_id not found")
}

///|
test "ConversationHost append_turn rejects invalid length envelope" {
  let host = ConversationHost::new()
  let hall = host.create_hall("test_hall")
  let thread = host.create_thread("test_hall", "topic", General).unwrap()

  let mut request = TurnRequest::default("hello")
  request.length_envelope = {
    input_len_min: 10U,
    input_len_max: 5U, // min > max
    output_len_min: 1U,
    output_len_max: 100U,
  }
  let outcome = host.append_turn(thread.thread_id, request)

  assert_false(outcome.accepted)
  assert_eq(outcome.issues.length(), 1)
  assert_eq(outcome.issues[0].code, "BAD_LENGTH_ENVELOPE")
}

///|
test "ConversationHost append_turn rejects empty actor_overlay" {
  let host = ConversationHost::new()
  let hall = host.create_hall("test_hall")
  let thread = host.create_thread("test_hall", "topic", General).unwrap()

  let mut request = TurnRequest::default("hello")
  request.actor_overlay = ""

  let outcome = host.append_turn(thread.thread_id, request)

  assert_false(outcome.accepted)
  assert_eq(outcome.issues.length(), 1)
  assert_eq(outcome.issues[0].code, "BAD_REQUEST")
  assert_eq(outcome.issues[0].message, "actor_overlay is required")
}

///|
test "ConversationHost append_turn rejects conflicting idempotency key" {
  let host = ConversationHost::new()
  let hall = host.create_hall("test_hall")
  let thread = host.create_thread("test_hall", "topic", General).unwrap()

  let mut request1 = TurnRequest::default("first")
  request1.idempotency_key = "idemp-key-1"
  let outcome1 = host.append_turn(thread.thread_id, request1)
  assert_true(outcome1.accepted)

  let mut request2 = TurnRequest::default("second")
  request2.idempotency_key = "idemp-key-1"
  let outcome2 = host.append_turn(thread.thread_id, request2)

  assert_false(outcome2.accepted)
  assert_eq(outcome2.issues.length(), 1)
  assert_eq(outcome2.issues[0].code, "CONFLICTING_IDEMPOTENCY_KEY")
}

///|
test "ConversationHost append_turn rejects ingress content length violation" {
  let host = ConversationHost::new()
  let hall = host.create_hall("test_hall")
  let thread = host.create_thread("test_hall", "topic", General).unwrap()

  let mut request = TurnRequest::default("too long text")
  request.length_envelope = {
    input_len_min: 1U,
    input_len_max: 5U, // length of "too long text" is 13 > 5
    output_len_min: 1U,
    output_len_max: 100U,
  }

  let outcome = host.append_turn(thread.thread_id, request)

  assert_false(outcome.accepted)
  assert_eq(outcome.issues.length(), 1)
  assert_eq(outcome.issues[0].code, "LENGTH_ENVELOPE_VIOLATION")
}
