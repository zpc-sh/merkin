///|
test "BoundaryWalkerFSM emits clean posture for clean scalars" {
  let fsm = @model.BoundaryWalkerFsm::new("codex", "ratio://merkin/root")
    .walk_scalars([("branch", "main"), ("peer_ref", "mu:abc")])
    .mark()
  assert_eq(fsm.status(), @model.Clean)
  let wire = fsm.emit_stigmergy(note="clean pass")
  assert_true(wire.contains("kind: merkin.boundary.stigmergy"))
  assert_true(wire.contains("boundary_cognitive=1"))
  assert_true(wire.contains("boundary_ticks=2"))
  assert_true(wire.contains("boundary_attention_score=0"))
  assert_true(wire.contains("boundary_attention_gradient=quiescent"))
  assert_true(wire.contains("boundary_attention_saturated=0"))
  assert_true(wire.contains("boundary_status=clean"))
  assert_true(wire.contains("material_hash=blake3:"))
}

///|
fn ghost_main() -> String {
  let out = StringBuilder::new(size_hint=8)
  out.write_string("main")
  out.write_char((8203).unsafe_to_char()) // U+200B
  out.to_string()
}

///|
test "BoundaryWalkerFSM marks ghost bytes as attention and preserves canonical value" {
  let fsm = @model.BoundaryWalkerFsm::new("codex", "ratio://merkin/root")
    .walk_scalar("branch", ghost_main())
    .mark()
  assert_eq(fsm.status(), @model.Attention)
  assert_eq(fsm.findings.length(), 1)
  let finding = fsm.findings[0]
  assert_eq(finding.field_key, "branch")
  assert_eq(finding.canonical_value, "main")
  assert_eq(finding.ghost_u200b, 1U)
  let wire = fsm.emit_stigmergy(note="ghost scan")
  assert_true(wire.contains("boundary_attention_score=3"))
  assert_true(wire.contains("boundary_attention_gradient=watch"))
  assert_true(wire.contains("boundary_attention_saturated=0"))
  assert_true(wire.contains("boundary_ghost_u200b=1"))
  assert_true(wire.contains("boundary_status=attention"))
}

///|
fn bidi_payload() -> String {
  let out = StringBuilder::new(size_hint=12)
  out.write_string("safe")
  out.write_char((8238).unsafe_to_char()) // U+202E (RLO)
  out.write_string("txt")
  out.to_string()
}

///|
test "BoundaryWalkerFSM escalates bidi controls to containment" {
  let fsm = @model.BoundaryWalkerFsm::new("codex", "ratio://merkin/root")
    .walk_scalar("path", bidi_payload())
    .mark()
  assert_eq(fsm.status(), @model.Containment)
  assert_eq(fsm.findings.length(), 1)
  let finding = fsm.findings[0]
  assert_eq(finding.bidi_controls, 1U)
  let wire = fsm.emit_stigmergy(note="bidi containment")
  assert_true(wire.contains("boundary_attention_score=9"))
  assert_true(wire.contains("boundary_attention_gradient=pulled"))
  assert_true(wire.contains("boundary_attention_saturated=0"))
  assert_true(wire.contains("boundary_bidi_controls=1"))
  assert_true(wire.contains("boundary_status=containment"))
}
