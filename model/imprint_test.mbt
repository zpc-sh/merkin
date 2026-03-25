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
