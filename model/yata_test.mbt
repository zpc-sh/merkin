///|
test "Yata lifecycle is abstract and contract-first" {
  let contract = @model.YataContract::new(
    "TextSummary",
    ["sorted", "total"],
    ["read"],
    42U,
  )
  let hole = @model.YataHole::new("notes/overview.md", contract, [], [], [])
  assert_eq(hole.state, @model.Open)
  assert_eq(hole.candidates.length(), 0)
  let candidate = @model.YataCandidate::new("c1", "candidate summary", 50U, "rough draft")
  let active = hole.propose(candidate)
  assert_eq(active.state, @model.Converging)
  assert_eq(active.candidates.length(), 1)
  let sealed = active.seal("c1", None)
  assert_eq(sealed.state, @model.Sealed("c1"))
  let resolved = sealed.resolve()
  assert_eq(resolved.state, @model.Resolved("c1"))
}

///|
test "Yata admissibility uses confidence floor against candidates" {
  let contract = @model.YataContract::new(
    "TreeShape",
    [],
    [],
    80U,
  )
  let hole = @model.YataHole::new("notes/plan.md", contract, [], [], [])
  let first = hole.propose(@model.YataCandidate::new("low", "low confidence", 12U, "temp"))
  assert_eq(first.admissible(), false)
  let admitted = first.propose(@model.YataCandidate::new("high", "high confidence", 95U, "good"))
  assert_eq(admitted.admissible(), true)
  match admitted.best_candidate() {
    Some(top) => assert_eq(top.candidate_id, "high")
    None => assert_true(false)
  }
}

///|
test "Yata dependency readiness is explicit and local" {
  let contract = @model.YataContract::new(
    "BinaryBlob",
    [],
    [],
    0U,
  )
  let base = @model.YataHole::new("notes/base.md", contract, [], [], [])
    .propose(@model.YataCandidate::new("base", "base value", 99U, "r0"))
    .seal("base", None)
    .resolve()
  let mut dependent = @model.YataHole::new(
    "notes/child.md",
    contract,
    [],
    [base.hole_id],
    [],
  )
  dependent = dependent.propose(@model.YataCandidate::new("child", "child value", 99U, "c1"))
  let unresolved_graph = @model.YataGraph::new().add(dependent).add(base)
  let ready_0 = unresolved_graph.ready_set()
  assert_eq(ready_0.length(), 2)
  let base_entry = @model.YataGraph::new().add(base).add(dependent)
  let base_only = base_entry.get(base.hole_id)
  match base_only {
    Some(value) => assert_true(value.is_ready(base_entry))
    None => assert_true(false)
  }
}

///|
test "Yata plan emission is deterministic and track-aware" {
  let contract = @model.YataContract::new("TokenStream", [], [], 0U)
  let hole = @model.YataHole::new("notes/plan.md", contract, [], [], [])
    .propose(@model.YataCandidate::new("c1", "summary", 70U, "proof"))
    .seal("c1", None)
    .resolve()
  let plan = @model.YataGraph::new().add(hole).to_plan(@model.Program, @model.Full, "chatgpt", "unit")
  assert_eq(plan.track, @model.Program)
  assert_eq(plan.mode, @model.Full)
  assert_eq(plan.entries.length(), 1)
  let wire = plan.to_wire()
  assert_true(wire.length() > 10)
}

///|
test "Yata project and reparent are deterministic transforms" {
  let contract = @model.YataContract::new("Tree", [], [], 0U)
  let root = @model.YataHole::new("notes/root.md", contract, [], [], [])
  let child = @model.YataHole::new("notes/child.md", contract, [], [root.hole_id], [])
  let grandchild = @model.YataHole::new("notes/grand.md", contract, [], [child.hole_id], [])
  let graph = @model.YataGraph::new()
    .add(root)
    .add(child)
    .add(grandchild)
  let subset = graph.project([grandchild.hole_id, child.hole_id])
  assert_eq(subset.holes.length(), 2)

  let reparented = graph.reparent(
    child.hole_id,
    root.hole_id,
    Some(grandchild.hole_id),
  )
  let maybe_child = reparented.get(child.hole_id)
  match maybe_child {
    Some(item) => {
      assert_eq(item.dependencies.length(), 1)
      assert_eq(item.dependencies[0], grandchild.hole_id)
    }
    None => assert_true(false)
  }
}

///|
test "Yata lineage replay follows ancestry before target" {
  let contract = @model.YataContract::new("Timeline", [], [], 0U)
  let root = @model.YataHole::new("notes/root.md", contract, [], [], [])
  let parent = @model.YataHole::new("notes/parent.md", contract, [], [root.hole_id], [])
  let target = @model.YataHole::new("notes/target.md", contract, [], [parent.hole_id], [])
  let graph = @model.YataGraph::new().add(root).add(parent).add(target)
  let steps = graph.lineage_replay(target.hole_id, 8U)
  assert_eq(steps.length(), 3)
  assert_eq(steps[0].state, "open")
  assert_eq(steps[2].hole_id, target.hole_id)
}

///|
test "Yata `.plan` wire can be produced, parsed, and cursor-validated" {
  let contract = @model.YataContract::new("ParserCheck", [], [], 10U)
  let hole = @model.YataHole::new("notes/parser.md", contract, [], [], [])
    .propose(@model.YataCandidate::new("c1", "candidate", 99U, "ok"))
    .seal("c1", None)
    .resolve()
  let plan = @model.YataGraph::new().add(hole).to_plan(@model.Program, @model.Full, "chatgpt", "parser")
  let wire = plan.to_wire()
  match @model.YataPlan::parse_wire(wire) {
    Some(parsed) => {
      let cursor = parsed.validate()
      assert_eq(cursor.expected_entries, 1U)
      assert_eq(cursor.observed_entries, 1U)
      assert_eq(cursor.ready_count, 1U)
      assert_eq(cursor.unresolved_count, 0U)
    }
    None => assert_true(false)
  }
}

test "Yata `.plan` emits and reparses self-report metadata" {
  let contract = @model.YataContract::new("ParserReport", [], [], 10U)
  let hole = @model.YataHole::new("notes/report.md", contract, [], [], [])
    .propose(@model.YataCandidate::new("c1", "candidate", 99U, "ok"))
    .seal("c1", None)
    .resolve()
  let plan = @model.YataGraph::new()
    .add(hole)
    .to_plan(@model.Program, @model.Full, "chatgpt", "parser")
    .with_self_report({
      overlay: "chatgpt",
      peer: "chatgpt",
      authority: "loc.machine",
      anchor_hint: "notes/report.md",
      gap: 2U,
      view_hint: "overlay",
    })
  let wire = plan.to_wire()
  let outcome = @model.YataPlan::parse_wire_strict(wire)
  assert_eq(outcome.ok, true)
  match outcome.plan {
    Some(parsed) => match parsed.self_report {
      Some(report) => {
        assert_eq(report.overlay, "chatgpt")
        assert_eq(report.peer, "chatgpt")
        assert_eq(report.authority, "loc.machine")
        assert_eq(report.anchor_hint, "notes/report.md")
        assert_eq(report.gap, 2U)
        assert_eq(report.view_hint, "overlay")
      }
      None => assert_true(false)
    }
    None => assert_true(false)
  }
}

test "Yata `.plan` emits and reparses git report metadata" {
  let contract = @model.YataContract::new("ParserReportGit", [], [], 10U)
  let hole = @model.YataHole::new("notes/report-git.md", contract, [], [], [])
    .propose(@model.YataCandidate::new("c1", "candidate", 99U, "ok"))
    .seal("c1", None)
    .resolve()
  let plan = @model.YataGraph::new()
    .add(hole)
    .to_plan(@model.Git, @model.Full, "chatgpt", "parser")
    .with_git_report({
      branch: "feat/yata-track",
      remote: "origin",
      merge_base: "8ab1",
      head: "9bc2",
      commit_count: 3U,
      refs: "8ab1,9bc2,5dd4",
    })
  let wire = plan.to_wire()
  let outcome = @model.YataPlan::parse_wire_strict(wire)
  assert_eq(outcome.ok, true)
  match outcome.plan {
    Some(parsed) => match parsed.git_report {
      Some(report) => {
        assert_eq(report.branch, "feat/yata-track")
        assert_eq(report.remote, "origin")
        assert_eq(report.merge_base, "8ab1")
        assert_eq(report.head, "9bc2")
        assert_eq(report.commit_count, 3U)
        assert_eq(report.refs, "8ab1,9bc2,5dd4")
      }
      None => assert_true(false)
      }
    None => assert_true(false)
  }
}

test "Yata `.plan` strict parser flags malformed git report fields" {
  let raw = "kind: merkin.yata.plan\ntrack=git\nmode=full\ngenerator=chatgpt\nnote=parser\nmaterial_hash=blake3:abc\ngit_report=1\ngit_report_remote=origin\n- a1b2 state=resolved ready=true candidates=3 conf_floor=70 selected=impl_a provenance=2"
  let outcome = @model.YataPlan::parse_wire_strict(raw)
  assert_eq(outcome.ok, false)
  assert_eq(outcome.issues[0].code, "MISSING_GIT_REPORT_BRANCH")
}

test "Yata `.plan` strict parser rejects bad git commit count" {
  let raw = "kind: merkin.yata.plan\ntrack=git\nmode=full\ngenerator=chatgpt\nnote=parser\nmaterial_hash=blake3:abc\ngit_report=1\ngit_report_branch=main\ngit_report_remote=origin\ngit_report_merge_base=abc\ngit_report_head=def\ngit_report_commit_count=not-a-number\ngit_report_refs=a,b,c\n- a1b2 state=resolved ready=true candidates=3 conf_floor=70 selected=impl_a provenance=2"
  let outcome = @model.YataPlan::parse_wire_strict(raw)
  assert_eq(outcome.ok, false)
  assert_eq(outcome.issues[0].code, "BAD_HEADER_NUMBER")
}

test "Yata git snapshot helper derives refs and commit count" {
  let snapshot = @model.YataGitSnapshot{
    branch: "main",
    remote: "origin",
    merge_base: "abc123",
    head: "def456",
    refs: ["abc123", "def456", "789fff"],
  }
  let report = snapshot.to_report()
  assert_eq(report.branch, "main")
  assert_eq(report.remote, "origin")
  assert_eq(report.merge_base, "abc123")
  assert_eq(report.head, "def456")
  assert_eq(report.commit_count, 3U)
  assert_eq(report.refs, "abc123,def456,789fff")
}

test "Yata one-shot snapshot can attach both self and git envelopes" {
  let contract = @model.YataContract::new("SnapshotBundle", [], [], 10U)
  let hole = @model.YataHole::new("notes/snapshot.md", contract, [], [], [])
    .propose(@model.YataCandidate::new("c1", "candidate", 99U, "ok"))
    .seal("c1", None)
    .resolve()
  let graph = @model.YataGraph::new().add(hole)
  let plan = graph.snapshot_with_reports(
    @model.Program,
    @model.Full,
    "chatgpt",
    "snapshot-bundle",
    Some({
      overlay: "chatgpt",
      peer: "claude",
      authority: "loc.machine",
      anchor_hint: "notes/snapshot.md",
      gap: 1U,
      view_hint: "overlay",
    }),
    Some({
      branch: "main",
      remote: "origin",
      merge_base: "abc123",
      head: "def456",
      refs: ["abc123", "def456"],
    }),
  )
  assert_eq(plan.track, @model.Program)
  match plan.self_report {
    Some(report) => assert_eq(report.peer, "claude")
    None => assert_true(false)
  }
  match plan.git_report {
    Some(report) => {
      assert_eq(report.branch, "main")
      assert_eq(report.commit_count, 2U)
      assert_eq(report.refs, "abc123,def456")
    }
    None => assert_true(false)
  }
}

///|
test "Yata addresses expose cognitic overlays and are parseable across schemes" {
  let contract = @model.YataContract::new("Address", [], [], 10U)
  let hole = @model.YataHole::new("notes/address.md", contract, [], [], [])
  let hint = @model.YataAddressHint{
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
  let hint = @model.YataAddressHint{
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
      assert_eq(addr.uri, "cog://loc.machine/notes/agenda.md?overlay=chatgpt&peer=chatgpt&mode=surface&gap=1&track=program&id=abc#overlay")
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
    Some(canonical) => assert_eq(
      canonical,
      "substrate://loc.machine/notes/state.md?overlay=chatgpt&peer=chatgpt&mode=surface&gap=3&track=git&id=abc#overlay",
    )
    None => assert_true(false)
  }
}

///|
test "Yata `.plan` strict parser rejects unknown fields and reports issues" {
  let raw = "kind: merkin.yata.plan\ntrack=program\nmode=compact\ngenerator=chatgpt\nnote=manual\nentries=1\nmaterial_hash=blake3:abc\na=1\n- zzz anchor state ready=true candidates=1 conf_floor=10 selected=none provenance=0"
  let outcome = @model.YataPlan::parse_wire_strict(raw)
  assert_eq(outcome.ok, false)
  assert_eq(outcome.issues.length(), 2U)
  assert_eq(outcome.issues[1].code, "ENTRY_COUNT_MISMATCH")
  assert_eq(outcome.issues[0].code, "UNRECOGNIZED_LINE")
}

///|
test "Yata address supports perspective-relative parse and projection" {
  let context = @model.YataAddressContext{
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

///|
test "Yata topology fanout analysis highlights overbranched parents" {
  let contract = @model.YataContract::new("Topology", [], [], 0U)
  let root = @model.YataHole::new("notes/root.md", contract, [], [], [])
  let c1 = @model.YataHole::new("notes/c1.md", contract, [], [root.hole_id], [])
  let c2 = @model.YataHole::new("notes/c2.md", contract, [], [root.hole_id], [])
  let c3 = @model.YataHole::new("notes/c3.md", contract, [], [root.hole_id], [])
  let graph = @model.YataGraph::new().add(root).add(c1).add(c2).add(c3)
  assert_eq(graph.child_fanout(root.hole_id), 3U)
  assert_eq(graph.max_branch_fanout(), 3U)
  let hotspots = graph.overbranched(2U)
  assert_eq(hotspots.length(), 1)
  assert_eq(hotspots[0].hole_id, root.hole_id)
}

///|
test "Yata detachment analysis finds missing and rootless chains" {
  let contract = @model.YataContract::new("Topology", [], [], 0U)
  let root = @model.YataHole::new("notes/root.md", contract, [], [], [])
  let attached = @model.YataHole::new("notes/attached.md", contract, [], [root.hole_id], [])

  let orphan_dep = @hash.Hash::of_bytes(b"missing-dependency")
  let orphan = @model.YataHole::new("notes/orphan.md", contract, [], [orphan_dep], [])

  let cycle_a_seed = @model.YataHole::new("notes/cycle-a.md", contract, [], [], [])
  let cycle_b_seed = @model.YataHole::new("notes/cycle-b.md", contract, [], [cycle_a_seed.hole_id], [])
  let cycle_a = cycle_a_seed.add_dependency(cycle_b_seed.hole_id)

  let graph = @model.YataGraph::new()
    .add(root)
    .add(attached)
    .add(orphan)
    .add(cycle_a)
    .add(cycle_b_seed)

  let missing = graph.holes_with_missing_dependencies()
  assert_eq(missing.length(), 1)
  assert_eq(missing[0].hole_id, orphan.hole_id)

  let detached = graph.detached_holes(8U)
  let mut seen_orphan = false
  let mut seen_cycle_a = false
  let mut seen_cycle_b = false
  let mut seen_attached = false
  for hole in detached {
    if hole.hole_id == orphan.hole_id {
      seen_orphan = true
    }
    if hole.hole_id == cycle_a.hole_id {
      seen_cycle_a = true
    }
    if hole.hole_id == cycle_b_seed.hole_id {
      seen_cycle_b = true
    }
    if hole.hole_id == attached.hole_id {
      seen_attached = true
    }
  }
  assert_true(seen_orphan)
  assert_true(seen_cycle_a)
  assert_true(seen_cycle_b)
  assert_true(!seen_attached)
}
