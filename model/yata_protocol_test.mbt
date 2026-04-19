///|
test "Yata `.plan` wire can be produced, parsed, and cursor-validated" {
  let contract = @model.YataContract::new("ParserCheck", [], [], 10U)
  let hole = @model.YataHole::new("notes/parser.md", contract, [], [], [])
    .propose(@model.YataCandidate::new("c1", "candidate", 99U, "ok"))
    .seal("c1", None)
    .resolve()
  let plan = @model.YataGraph::new()
    .add(hole)
    .to_plan(@model.Program, @model.Full, "chatgpt", "parser")
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

///|
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
    Some(parsed) =>
      match parsed.self_report {
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

///|
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
    Some(parsed) =>
      match parsed.git_report {
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

///|
test "Yata `.plan` emits and reparses solve report metadata" {
  let contract = @model.YataContract::new("ParserSolve", [], [], 10U)
  let hole = @model.YataHole::new("notes/report-solve.md", contract, [], [], [])
    .propose(@model.YataCandidate::new("c1", "candidate", 99U, "ok"))
    .seal("c1", None)
    .resolve()
  let plan = @model.YataGraph::new()
    .add(hole)
    .to_plan(@model.Program, @model.Full, "chatgpt", "solve-parser")
    .with_solve_report({
      solve_kind: "repair",
      status: "running",
      handler: "provider.codex",
      offloaded_to: "delegate-control",
      count: 2U,
    })
  let wire = plan.to_wire()
  let outcome = @model.YataPlan::parse_wire_strict(wire)
  assert_eq(outcome.ok, true)
  match outcome.plan {
    Some(parsed) =>
      match parsed.solve_report {
        Some(report) => {
          assert_eq(report.solve_kind, "repair")
          assert_eq(report.status, "running")
          assert_eq(report.handler, "provider.codex")
          assert_eq(report.offloaded_to, "delegate-control")
          assert_eq(report.count, 2U)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "Yata `.plan` emits finger-style procsi and capability disclosure" {
  let contract = @model.YataContract::new("ParserProcsi", [], [], 10U)
  let hole = @model.YataHole::new("notes/report-procsi.md", contract, [], [], [])
    .propose(@model.YataCandidate::new("c1", "candidate", 99U, "ok"))
    .seal("c1", None)
    .resolve()
  let plan = @model.YataGraph::new()
    .add(hole)
    .to_plan(@model.Program, @model.Compact, "codex", "finger")
    .with_procsi_report({
      project: "zpc-sh/merkin",
      ratio_loci: "ratio://merkin/root",
      session_surface: "codex",
      fingerprint_commitment: "blake3:fp-commitment",
      app_ref: "app://repo/ai/codex",
      app_audience: "ratio.loci.merkin",
      masked: true,
    })
    .with_capability_report(
      @model.YataPlanCapabilityReport::new(
        "ratio://merkin/root", "service", "genius.write", "issued", 2U, "store://app/tickets/root",
      ),
    )
  let wire = plan.to_wire()
  let outcome = @model.YataPlan::parse_wire_strict(wire)
  assert_eq(outcome.ok, true)
  match outcome.plan {
    Some(parsed) => {
      match parsed.procsi_report {
        Some(report) => {
          assert_eq(report.project, "zpc-sh/merkin")
          assert_eq(report.ratio_loci, "ratio://merkin/root")
          assert_eq(report.session_surface, "codex")
          assert_eq(report.fingerprint_commitment, "blake3:fp-commitment")
          assert_eq(report.app_ref, "app://repo/ai/codex")
          assert_eq(report.app_audience, "ratio.loci.merkin")
          assert_eq(report.masked, true)
        }
        None => assert_true(false)
      }
      match parsed.capability_report {
        Some(report) => {
          assert_eq(report.authority, "ratio://merkin/root")
          assert_eq(report.ticket_kind, "service")
          assert_eq(report.scope, "genius.write")
          assert_eq(report.status, "issued")
          assert_eq(report.count, 2U)
          assert_eq(report.store_ref, "store://app/tickets/root")
        }
        None => assert_true(false)
      }
    }
    None => assert_true(false)
  }
}

///|
test "Yata `.plan` strict parser flags missing solve report handler" {
  let raw = "kind: merkin.yata.plan\ntrack=program\nmode=full\ngenerator=chatgpt\nnote=parser\nmaterial_hash=blake3:abc\nsolve_report=1\nsolve_report_kind=repair\nsolve_report_status=queued\nsolve_report_offloaded_to=delegate-control\nsolve_report_count=1\n- a1b2 notes/repair.md resolved ready=true candidates=3 conf_floor=70 selected=impl_a provenance=2"
  let outcome = @model.YataPlan::parse_wire_strict(raw)
  assert_eq(outcome.ok, false)
  assert_eq(outcome.issues[0].code, "MISSING_SOLVE_REPORT_HANDLER")
}

///|
test "Yata `.plan` strict parser flags missing procsi fingerprint commitment" {
  let raw = "kind: merkin.yata.plan\ntrack=program\nmode=compact\ngenerator=codex\nnote=finger\nmaterial_hash=blake3:def\nprocsi_report=1\nprocsi_report_project=zpc-sh/merkin\nprocsi_report_ratio_loci=ratio://merkin/root\nprocsi_report_surface=codex\nprocsi_report_app_ref=app://repo/ai/codex\nprocsi_report_app_audience=ratio.loci.merkin\nprocsi_report_masked=true\n- a1b2 notes/finger.plan converging ready=true candidates=1 conf_floor=75 selected=none provenance=1"
  let outcome = @model.YataPlan::parse_wire_strict(raw)
  assert_eq(outcome.ok, false)
  assert_eq(outcome.issues[0].code, "MISSING_PROCSI_REPORT_FINGERPRINT")
}

///|
test "Yata `.plan` strict parser flags missing capability store ref" {
  let raw = "kind: merkin.yata.plan\ntrack=program\nmode=compact\ngenerator=codex\nnote=finger\nmaterial_hash=blake3:ghi\ncapability_report=1\ncapability_report_authority=ratio://merkin/root\ncapability_report_ticket_kind=service\ncapability_report_scope=genius.write\ncapability_report_status=issued\ncapability_report_count=2\n- a1b2 notes/finger.plan converging ready=true candidates=1 conf_floor=75 selected=none provenance=1"
  let outcome = @model.YataPlan::parse_wire_strict(raw)
  assert_eq(outcome.ok, false)
  assert_eq(outcome.issues[0].code, "MISSING_CAPABILITY_REPORT_STORE_REF")
}

///|
test "Yata `.plan` strict parser flags malformed git report fields" {
  let raw = "kind: merkin.yata.plan\ntrack=git\nmode=full\ngenerator=chatgpt\nnote=parser\nmaterial_hash=blake3:abc\ngit_report=1\ngit_report_remote=origin\n- a1b2 notes/git.plan resolved ready=true candidates=3 conf_floor=70 selected=impl_a provenance=2"
  let outcome = @model.YataPlan::parse_wire_strict(raw)
  assert_eq(outcome.ok, false)
  assert_eq(outcome.issues[0].code, "MISSING_GIT_REPORT_BRANCH")
}

///|
test "Yata `.plan` strict parser rejects bad git commit count" {
  let raw = "kind: merkin.yata.plan\ntrack=git\nmode=full\ngenerator=chatgpt\nnote=parser\nmaterial_hash=blake3:abc\ngit_report=1\ngit_report_branch=main\ngit_report_remote=origin\ngit_report_merge_base=abc\ngit_report_head=def\ngit_report_commit_count=not-a-number\ngit_report_refs=a,b,c\n- a1b2 notes/git.plan resolved ready=true candidates=3 conf_floor=70 selected=impl_a provenance=2"
  let outcome = @model.YataPlan::parse_wire_strict(raw)
  assert_eq(outcome.ok, false)
  assert_eq(outcome.issues[0].code, "BAD_HEADER_NUMBER")
}

///|
test "Yata git snapshot helper derives refs and commit count" {
  let snapshot : @model.YataGitSnapshot = {
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

///|
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
test "Yata `.plan` strict parser rejects unknown fields and reports issues" {
  let raw = "kind: merkin.yata.plan\ntrack=program\nmode=compact\ngenerator=chatgpt\nnote=manual\nentries=1\nmaterial_hash=blake3:abc\na=1\n- zzz anchor state ready=true candidates=1 conf_floor=10 selected=none provenance=0"
  let outcome = @model.YataPlan::parse_wire_strict(raw)
  assert_eq(outcome.ok, false)
  assert_eq(outcome.issues.length(), 1)
  assert_eq(outcome.issues[0].code, "UNRECOGNIZED_LINE")
}
