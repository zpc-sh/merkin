///|
test "Yata addresses expose cognitic overlays and are parseable across schemes" {
  let contract = @model.YataContract::new("Address", [], [], 10U)
  let hole = @model.YataHole::new("notes/address.md", contract, [], [], [])
  let hint : @model.YataAddressHint = {
    overlay: "chatgpt",
    peer: "chatgpt",
    mode: "surface",
    gap: 1U,
    view: "overlay",
  }
  let cog = hole.to_cog_uri("loc.machine", hint, @model.Program)
  match @model.YataAddress::parse(cog) {
    Some(addr) => {
      assert_true(addr.scheme == "cog")
      assert_eq(addr.overlay, "chatgpt")
      assert_eq(addr.track, @model.Program)
      assert_eq(addr.view, "overlay")
    }
    None => assert_true(false)
  }
  let substrate = hole.to_substrate_uri("loc.machine", hint, @model.Program)
  match @model.YataAddress::parse(substrate) {
    Some(addr) => {
      assert_true(addr.scheme == "substrate")
      assert_eq(addr.anchor, "notes/address.md")
    }
    None => assert_true(false)
  }
}

///|
test "Yata CAS uri roundtrips for hole-centric addressing" {
  let contract = @model.YataContract::new("CasAddress", [], [], 10U)
  let hole = @model.YataHole::new("notes/cas/address.md", contract, [], [], [])
  let hint : @model.YataAddressHint = {
    overlay: "chatgpt",
    peer: "claude",
    mode: "surface",
    gap: 2U,
    view: "overlay",
  }
  let cas = hole.to_cas_uri("loc.machine", hint, @model.Program, "blake3")
  match @model.YataAddress::parse(cas) {
    Some(addr) => {
      assert_eq(addr.scheme, "cas")
      assert_eq(addr.cas_alg, "blake3")
      assert_eq(addr.anchor, "notes/cas/address.md")
      assert_eq(addr.overlay, "chatgpt")
      assert_eq(addr.peer, "claude")
    }
    None => assert_true(false)
  }
}

///|
test "Yata address strict parser normalizes slash-heavy routes" {
  let raw = "cog://loc.machine////notes///agenda.md/?overlay=chatgpt&peer=chatgpt&mode=surface&gap=1&track=program&id=abc#overlay"
  let outcome = @model.YataAddress::parse_strict(raw)
  assert_eq(outcome.ok, true)
  match outcome.address {
    Some(addr) => {
      assert_eq(addr.anchor, "notes/agenda.md")
      assert_eq(addr.gap, 1U)
      assert_eq(
        addr.uri,
        "cog://loc.machine/notes/agenda.md?overlay=chatgpt&peer=chatgpt&mode=surface&gap=1&track=program&id=abc#overlay",
      )
    }
    None => assert_true(false)
  }
}

///|
test "Yata CAS parser allows digest-only target without anchor" {
  let raw = "cas://loc.machine/blake3/abc123?overlay=chatgpt&peer=chatgpt&mode=surface&gap=1&track=program#overlay"
  let outcome = @model.YataAddress::parse_strict(raw)
  assert_eq(outcome.ok, true)
  match outcome.address {
    Some(addr) => {
      assert_eq(addr.scheme, "cas")
      assert_eq(addr.cas_alg, "blake3")
      assert_eq(addr.cas_digest, "abc123")
      assert_eq(addr.anchor, "")
    }
    None => assert_true(false)
  }
}

///|
test "Yata address canonicalize helper rewrites slash-heavy uri" {
  let raw = "substrate://loc.machine////notes///state.md/?overlay=chatgpt&peer=chatgpt&mode=surface&gap=3&track=git&id=abc#overlay"
  match @model.YataAddress::canonicalize(raw) {
    Some(canonical) =>
      assert_eq(
        canonical, "substrate://loc.machine/notes/state.md?overlay=chatgpt&peer=chatgpt&mode=surface&gap=3&track=git&id=abc#overlay",
      )
    None => assert_true(false)
  }
}

///|
test "Yata address supports perspective-relative parse and projection" {
  let context : @model.YataAddressContext = {
    authority: "loc.machine",
    anchor: "notes/roadmap/session-01.md",
  }
  let raw = "../summary.md?overlay=claude&peer=claude&mode=defense&gap=2#overlay"
  match @model.YataAddress::parse_in_context(raw, context) {
    Some(addr) => {
      assert_eq(addr.authority, "loc.machine")
      assert_eq(addr.anchor, "notes/summary.md")
      assert_eq(addr.overlay, "claude")
      assert_eq(addr.peer, "claude")
      assert_eq(addr.track, @model.Program)
      assert_eq(addr.view, "overlay")
    }
    None => assert_true(false)
  }
}

///|
test "Yata address strict parser emits unknown-query issue for unsupported keys" {
  let raw = "cog://loc.device/notes/abc?overlay=chatgpt&peer=chatgpt&mode=surface&gap=1&track=program&extra=1#overlay"
  let outcome = @model.YataAddress::parse_strict(raw)
  assert_eq(outcome.ok, false)
  let mut has_unknown = false
  for issue in outcome.issues {
    if issue.code == "UNKNOWN_QUERY_KEY" {
      has_unknown = true
    }
  }
  assert_true(has_unknown)
}
