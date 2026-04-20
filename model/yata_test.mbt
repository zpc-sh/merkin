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
  let candidate = @model.YataCandidate::new(
    "c1", "candidate summary", 50U, "rough draft",
  )
  let active = hole.propose(candidate)
  assert_eq(active.state, @model.Converging)
  assert_eq(active.candidates.length(), 1)
  let sealed_hole = active.seal("c1", None)
  assert_eq(sealed_hole.state, @model.Sealed("c1"))
  let resolved = sealed_hole.resolve()
  assert_eq(resolved.state, @model.Resolved("c1"))
}

///|
test "Yata admissibility uses confidence floor against candidates" {
  let contract = @model.YataContract::new("TreeShape", [], [], 80U)
  let hole = @model.YataHole::new("notes/plan.md", contract, [], [], [])
  let first = hole.propose(
    @model.YataCandidate::new("low", "low confidence", 12U, "temp"),
  )
  assert_eq(first.admissible(), false)
  let admitted = first.propose(
    @model.YataCandidate::new("high", "high confidence", 95U, "good"),
  )
  assert_eq(admitted.admissible(), true)
  match admitted.best_candidate() {
    Some(top) => assert_eq(top.candidate_id, "high")
    None => assert_true(false)
  }
}

///|
test "Yata dependency readiness is explicit and local" {
  let contract = @model.YataContract::new("BinaryBlob", [], [], 0U)
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
  dependent = dependent.propose(
    @model.YataCandidate::new("child", "child value", 99U, "c1"),
  )
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
  let plan = @model.YataGraph::new()
    .add(hole)
    .to_plan(@model.Program, @model.Full, "chatgpt", "unit")
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
  let child = @model.YataHole::new(
    "notes/child.md",
    contract,
    [],
    [root.hole_id],
    [],
  )
  let grandchild = @model.YataHole::new(
    "notes/grand.md",
    contract,
    [],
    [child.hole_id],
    [],
  )
  let graph = @model.YataGraph::new().add(root).add(child).add(grandchild)
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
  let parent = @model.YataHole::new(
    "notes/parent.md",
    contract,
    [],
    [root.hole_id],
    [],
  )
  let target = @model.YataHole::new(
    "notes/target.md",
    contract,
    [],
    [parent.hole_id],
    [],
  )
  let graph = @model.YataGraph::new().add(root).add(parent).add(target)
  let steps = graph.lineage_replay(target.hole_id, 8U)
  assert_eq(steps.length(), 3)
  assert_eq(steps[0].state, "open")
  assert_eq(steps[2].hole_id, target.hole_id)
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
  let attached = @model.YataHole::new(
    "notes/attached.md",
    contract,
    [],
    [root.hole_id],
    [],
  )

  let orphan_dep = @hash.Hash::of_bytes(b"missing-dependency")
  let orphan = @model.YataHole::new(
    "notes/orphan.md",
    contract,
    [],
    [orphan_dep],
    [],
  )

  let cycle_a_seed = @model.YataHole::new(
    "notes/cycle-a.md",
    contract,
    [],
    [],
    [],
  )
  let cycle_b_seed = @model.YataHole::new(
    "notes/cycle-b.md",
    contract,
    [],
    [cycle_a_seed.hole_id],
    [],
  )
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

///|
test "Yata hole can be abandoned" {
  let contract = @model.YataContract::new(
    "TextSummary",
    ["sorted", "total"],
    ["read"],
    42U,
  )
  let hole = @model.YataHole::new("notes/overview.md", contract, [], [], [])
  let abandoned_hole = hole.abandon("Too complex")
  assert_eq(abandoned_hole.state, @model.Abandoned("Too complex"))
  assert_eq(
    abandoned_hole.provenance[abandoned_hole.provenance.length() - 1],
    "Too complex",
  )
}
