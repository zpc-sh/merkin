test "ConversationHost::append_turn catches invalid thread_id" {
  let host = ConversationHost::new()
  let request = TurnRequest::default("hello")
  let outcome = host.append_turn("invalid_thread_id", request)
  assert_eq!(outcome.accepted, false)
  assert_eq!(outcome.issues.length(), 1)
  assert_eq!(outcome.issues[0].code, "BAD_REQUEST")
}

test "ConversationHost::append_turn catches invalid length envelope" {
  let host = ConversationHost::new()
  let hall = host.create_hall("hall1", "policy1")
  let thread = host.create_thread(hall.hall_id, "topic1", Program)

  match thread {
    Some(t) => {
      let mut request = TurnRequest::default("hello")
      request.length_envelope.input_len_min = 0U // invalid
      let outcome = host.append_turn(t.thread_id, request)
      assert_eq!(outcome.accepted, false)
      assert_eq!(outcome.issues.length(), 1)
      assert_eq!(outcome.issues[0].code, "BAD_LENGTH_ENVELOPE")
    }
    None => fail!("Failed to create thread")
  }
}

test "ConversationHost::append_turn catches missing actor_overlay" {
  let host = ConversationHost::new()
  let hall = host.create_hall("hall1", "policy1")
  let thread = host.create_thread(hall.hall_id, "topic1", Program)

  match thread {
    Some(t) => {
      let mut request = TurnRequest::default("hello")
      request.actor_overlay = "" // invalid
      let outcome = host.append_turn(t.thread_id, request)
      assert_eq!(outcome.accepted, false)
      assert_eq!(outcome.issues.length(), 1)
      assert_eq!(outcome.issues[0].code, "BAD_REQUEST")
    }
    None => fail!("Failed to create thread")
  }
}

test "ConversationHost::append_turn catches conflicting idempotency key" {
  let host = ConversationHost::new()
  let hall = host.create_hall("hall1", "policy1")
  let thread = host.create_thread(hall.hall_id, "topic1", Program)

  match thread {
    Some(t) => {
      let mut request1 = TurnRequest::default("hello")
      request1.idempotency_key = "key1"
      let outcome1 = host.append_turn(t.thread_id, request1)
      assert_eq!(outcome1.accepted, true)

      let mut request2 = TurnRequest::default("hello again")
      request2.idempotency_key = "key1"
      let outcome2 = host.append_turn(t.thread_id, request2)

      assert_eq!(outcome2.accepted, false)
      assert_eq!(outcome2.issues.length(), 1)
      assert_eq!(outcome2.issues[0].code, "CONFLICTING_IDEMPOTENCY_KEY")
    }
    None => fail!("Failed to create thread")
  }
}

test "ConversationHost::append_turn catches length envelope violation" {
  let host = ConversationHost::new()
  let hall = host.create_hall("hall1", "policy1")
  let thread = host.create_thread(hall.hall_id, "topic1", Program)

  match thread {
    Some(t) => {
      let mut request = TurnRequest::default("hello")
      request.length_envelope.input_len_max = 2U // content is 5 chars
      let outcome = host.append_turn(t.thread_id, request)

      assert_eq!(outcome.accepted, false)
      assert_eq!(outcome.issues.length(), 1)
      assert_eq!(outcome.issues[0].code, "LENGTH_ENVELOPE_VIOLATION")
    }
    None => fail!("Failed to create thread")
  }
}
