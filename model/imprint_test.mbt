///|
test "Router imprint is deterministic and has a stable ID" {
  let route = ["ingest", "index", "normalize"]
  let contracts = ["policy:read-only", "contract:timeline"]
  let a = @model.lift_router_imprint("router://ingest", route, contracts, None)
  let b = @model.lift_router_imprint("router://ingest", route, contracts, None)
  assert_eq(a.imprint_id, b.imprint_id)
  assert_eq(a.source, "router://ingest")
  assert_eq(a.kind, @model.Router)
}

///|
test "Mirage is hollow and traceable" {
  let route = ["observe", "summarize"]
  let contracts = ["contract:defense", "contract:projection"]
  let imprint = @model.lift_router_imprint(
    "router://defense",
    route,
    contracts,
    None,
  )
  let mirage = imprint.to_mirage()
  assert_true(mirage.has_private_payload == false)
  assert_eq(mirage.source_imprint, imprint.imprint_id)
  assert_eq(mirage.kind, imprint.kind)
  assert_eq(mirage.source, imprint.source)
  assert_true(mirage.appearance.length() >= imprint.surface_projection.length())
}

///|
test "Parent lineage is preserved across lifted imprints" {
  let parent = @model.Imprint::new(
    "router://parent",
    @model.Router,
    ["root"],
    [],
    [],
    None,
    1U,
    @model.Defense,
  )
  let child = @model.lift_router_imprint(
    "router://child",
    ["route", "step"],
    [],
    Some(parent.imprint_id),
  )
  match child.parent_imprint {
    Some(parent_ref) => assert_eq(parent_ref, parent.imprint_id)
    None => assert_true(false)
  }
}

///|
test "Mirage mapping translates all fields correctly" {
  let parent_hash = @hash.Hash::of_bytes(b"\x01\x02\x03\x04")
  let surface = ["tag1", "tag2"]
  let route = ["route1", "route2"]
  let contracts = ["contract1"]

  let imprint = @model.Imprint::new(
    "router://test_source",
    @model.Router,
    surface,
    route,
    contracts,
    Some(parent_hash),
    5U,
    @model.Temporal,
  )

  let mirage = imprint.to_mirage()

  assert_eq(mirage.mirage_id, imprint.imprint_id)
  assert_eq(mirage.source_imprint, imprint.imprint_id)
  assert_eq(mirage.source, "router://test_source")
  assert_eq(mirage.kind, @model.Router)

  // appearance includes mode + surface_projection
  assert_eq(mirage.appearance.length(), 3)
  assert_eq(mirage.appearance[0], "mode:temporal")
  assert_eq(mirage.appearance[1], "tag1")
  assert_eq(mirage.appearance[2], "tag2")

  assert_eq(mirage.route_projection.length(), 2)
  assert_eq(mirage.route_projection[0], "route1")
  assert_eq(mirage.route_projection[1], "route2")

  assert_eq(mirage.contract_graph.length(), 1)
  assert_eq(mirage.contract_graph[0], "contract1")

  assert_eq(mirage.horizon, 5U)
  assert_eq(mirage.mode, @model.Temporal)
  assert_eq(mirage.confidence, imprint.confidence)
  assert_eq(mirage.has_private_payload, false)
}
