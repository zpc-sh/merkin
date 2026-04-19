///|
fn string_contains(haystack : String, needle : String) -> Bool {
  if needle == "" {
    return true
  }
  if needle.length() > haystack.length() {
    return false
  }
  let last = haystack.length() - needle.length()
  let mut i = 0
  while i <= last {
    let mut matched = true
    let mut j = 0
    while j < needle.length() {
      if haystack[i + j] != needle[j] {
        matched = false
        break
      }
      j = j + 1
    }
    if matched {
      return true
    }
    i = i + 1
  }
  false
}

///|
test "WASM finger plan emission includes drift coordination fields" {
  @api.reset()
  ignore(@api.tree_ingest("route://alpha/doc", "alpha,doc"))
  ignore(@api.tree_ingest("route://beta/doc", "beta,doc"))
  ignore(@api.tree_seal())

  let wire = @api.plan_finger_wasm("alpha", "mu:abc,muyata:def")

  assert_true(string_contains(wire, "kind: merkin.yata.plan"))
  assert_true(string_contains(wire, "mode=compact"))
  assert_true(string_contains(wire, "note=finger.plan.wasm"))
  assert_true(string_contains(wire, "git_report=1"))
  assert_true(string_contains(wire, "git_report_merge_base=mu:abc"))
  assert_true(string_contains(wire, "git_report_head=muyata:def"))
  assert_true(
    string_contains(wire, "git_report_refs=peer_a:mu:abc,peer_b:muyata:def,"),
  )
  assert_true(string_contains(wire, "boundary_mode=sanitize"))
  assert_true(string_contains(wire, "boundary_cognitive=1"))
  assert_true(string_contains(wire, "boundary_domain=ratio_loci"))
  assert_true(string_contains(wire, "boundary_bidi_controls=0"))
  assert_true(string_contains(wire, "boundary_ascii_controls=0"))
  assert_true(string_contains(wire, "boundary_ticks=2"))
  assert_true(string_contains(wire, "boundary_attention_score=0"))
  assert_true(string_contains(wire, "boundary_attention_gradient=quiescent"))
  assert_true(string_contains(wire, "boundary_attention_saturated=0"))
  assert_true(string_contains(wire, "boundary_status=clean"))
  assert_true(
    string_contains(
      wire, "wasm/finger.plan.wasm converging ready=true candidates=1 conf_floor=100 selected=none provenance=1",
    ),
  )
}

///|
test "WASM finger plan boundary posture flips to attention on ghost refs" {
  @api.reset()
  ignore(@api.tree_ingest("route://alpha/doc", "alpha,doc"))
  ignore(@api.tree_seal())

  let peer_b = {
    let out = StringBuilder::new(size_hint=10)
    out.write_string("muyata:def")
    out.write_char((65279).unsafe_to_char())
    out.to_string()
  }
  let wire = @api.plan_finger_wasm("alpha", "mu:abc," + peer_b)

  assert_true(string_contains(wire, "boundary_refs_sanitized=1"))
  assert_true(string_contains(wire, "boundary_ghost_ufeff=1"))
  assert_true(string_contains(wire, "boundary_attention_score=3"))
  assert_true(string_contains(wire, "boundary_attention_gradient=watch"))
  assert_true(string_contains(wire, "boundary_status=attention"))
}

///|
test "WASM finger plan boundary posture flips to containment on bidi refs" {
  @api.reset()
  ignore(@api.tree_ingest("route://alpha/doc", "alpha,doc"))
  ignore(@api.tree_seal())

  let peer_b = {
    let out = StringBuilder::new(size_hint=16)
    out.write_string("muyata:def")
    out.write_char((8238).unsafe_to_char()) // U+202E
    out.to_string()
  }
  let wire = @api.plan_finger_wasm("alpha", "mu:abc," + peer_b)

  assert_true(string_contains(wire, "boundary_bidi_controls=1"))
  assert_true(string_contains(wire, "boundary_attention_score=9"))
  assert_true(string_contains(wire, "boundary_attention_gradient=pulled"))
  assert_true(string_contains(wire, "boundary_status=containment"))
}

///|
test "WASM drift commitment is deterministic and peer-sensitive" {
  @api.reset()
  ignore(@api.tree_ingest("route://alpha/doc", "alpha,doc"))
  ignore(@api.tree_ingest("route://beta/doc", "beta,doc"))
  ignore(@api.tree_seal())

  let c1 = @api.plan_drift_commitment("alpha", "mu:abc,muyata:def")
  let c2 = @api.plan_drift_commitment("alpha", "mu:abc,muyata:def")
  let c3 = @api.plan_drift_commitment("alpha", "mu:abc,muyata:zzz")

  assert_eq(c1, c2)
  assert_true(c1 != c3)
  assert_true(string_contains(c1, "blake3:"))

  ignore(@api.tree_ingest("route://gamma/doc", "gamma,doc"))
  ignore(@api.tree_seal())
  let c4 = @api.plan_drift_commitment("alpha", "mu:abc,muyata:def")
  assert_true(c1 != c4)
}

///|
fn ghost_main_branch() -> String {
  let out = StringBuilder::new(size_hint=5)
  out.write_char('m')
  out.write_char('a')
  out.write_char('i')
  out.write_char('n')
  out.write_char((8203).unsafe_to_char())
  out.to_string()
}

///|
test "Triad contract reports ghost bytes and ABI gaps" {
  @api.reset()
  ignore(@api.tree_ingest("route://alpha/doc", "alpha,doc"))
  ignore(@api.tree_seal())

  let triad = @api.triad_contract_wasm(
    "alpha",
    "mu:abc,lang:def",
    "merkin-head",
    "mu-head",
    "lang-head",
    ghost_main_branch(),
    "main",
    "dev/lang",
    "plan_finger_wasm,plan_drift_commitment",
    "2026-04-14T12:00:00Z",
    "v0.1",
  )

  assert_true(string_contains(triad, "\"kind\": \"merkin.triad.contract\""))
  assert_true(string_contains(triad, "\"void_detected\": true"))
  assert_true(string_contains(triad, "\"refs_byte_clean\": false"))
  assert_true(string_contains(triad, "\"status\": \"missing\""))
  assert_true(string_contains(triad, "\"triad_contract_wasm\""))
  assert_true(string_contains(triad, "\\u200b"))
}

///|
test "Triad ABI status helper and seal stability" {
  let status_ok = @api.triad_abi_status(
    "plan_finger_wasm,plan_drift_commitment,triad_contract_wasm",
  )
  let status_missing = @api.triad_abi_status("plan_finger_wasm")
  assert_eq(status_ok, "ok")
  assert_eq(status_missing, "missing:plan_drift_commitment,triad_contract_wasm")

  @api.reset()
  ignore(@api.tree_ingest("route://alpha/doc", "alpha,doc"))
  ignore(@api.tree_seal())
  let c1 = @api.triad_contract_wasm(
    "alpha", "mu:abc,lang:def", "merkin-head", "mu-head", "lang-head", "main", "main",
    "main", "plan_finger_wasm,plan_drift_commitment,triad_contract_wasm", "2026-04-14T12:00:00Z",
    "v0.1",
  )
  let c2 = @api.triad_contract_wasm(
    "alpha", "mu:abc,lang:def", "merkin-head", "mu-head", "lang-head", "main", "main",
    "main", "plan_finger_wasm,plan_drift_commitment,triad_contract_wasm", "2026-04-14T12:00:00Z",
    "v0.1",
  )
  let c3 = @api.triad_contract_wasm(
    "alpha", "mu:abc,lang:def", "merkin-head", "mu-head", "lang-head-v2", "main",
    "main", "main", "plan_finger_wasm,plan_drift_commitment,triad_contract_wasm",
    "2026-04-14T12:00:00Z", "v0.1",
  )
  assert_eq(c1, c2)
  assert_true(c1 != c3)
}
