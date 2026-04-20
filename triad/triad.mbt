///|
/// Triad package: import-friendly wrapper for Merkin/Mu/lang contract emission.
///
/// This package provides typed inputs around the low-level API CSV/string
/// surface so downstream projects can consume triad contract generation as a
/// normal MoonBit library.

///|
/// Required Merkin WASM export names for triad compatibility.
pub fn abi_expected_exports() -> Array[String] {
  ["plan_finger_wasm", "plan_drift_commitment", "triad_contract_wasm"]
}

///|
/// Pinned heads + raw branches for the three synchronized repos.
pub(all) struct TriadRepoPins {
  merkin_head : String
  mu_head : String
  lang_head : String
  merkin_branch_raw : String
  mu_branch_raw : String
  lang_branch_raw : String
} derive(Debug)

///|
pub fn TriadRepoPins::new(
  merkin_head : String,
  mu_head : String,
  lang_head : String,
  merkin_branch_raw : String,
  mu_branch_raw : String,
  lang_branch_raw : String,
) -> TriadRepoPins {
  {
    merkin_head,
    mu_head,
    lang_head,
    merkin_branch_raw,
    mu_branch_raw,
    lang_branch_raw,
  }
}

///|
pub fn TriadRepoPins::unknown() -> TriadRepoPins {
  TriadRepoPins::new(
    "unknown", "unknown", "unknown", "unknown", "unknown", "unknown",
  )
}

///|
/// Triad emission request.
pub(all) struct TriadContractInput {
  tokens : Array[String]
  peer_refs : Array[String]
  wasm_exports : Array[String]
  generated_at_utc : String
  contract_version : String
  pins : TriadRepoPins
} derive(Debug)

///|
pub fn TriadContractInput::new(
  tokens : Array[String],
  peer_refs : Array[String],
  wasm_exports : Array[String],
  generated_at_utc : String,
  contract_version : String,
  pins : TriadRepoPins,
) -> TriadContractInput {
  { tokens, peer_refs, wasm_exports, generated_at_utc, contract_version, pins }
}

///|
pub fn TriadContractInput::default() -> TriadContractInput {
  TriadContractInput::new(
    ["alpha"],
    ["mu:unknown", "lang:unknown"],
    abi_expected_exports(),
    "unknown",
    "v0.1",
    TriadRepoPins::unknown(),
  )
}

///|
/// Check ABI status for a provided list of wasm export names.
/// Returns `ok` or `missing:<csv>`.
pub fn abi_status(exports : Array[String]) -> String {
  @api.triad_abi_status(join_csv(exports))
}

///|
/// Emit the canonical triad contract JSON.
///
/// Note:
/// The contract root/node/epoch section is derived from the current in-memory
/// Merkin API tree state. Callers can seed that state via `seed_sparse_tree`.
pub fn emit_contract(input : TriadContractInput) -> String {
  @api.triad_contract_wasm(
    join_csv(input.tokens),
    join_csv(input.peer_refs),
    input.pins.merkin_head,
    input.pins.mu_head,
    input.pins.lang_head,
    input.pins.merkin_branch_raw,
    input.pins.mu_branch_raw,
    input.pins.lang_branch_raw,
    join_csv(input.wasm_exports),
    input.generated_at_utc,
    input.contract_version,
  )
}

///|
/// Seed deterministic sparse tree state used by triad contract emission.
pub fn seed_sparse_tree(routes : Array[Array[String]], seal : Bool) -> Unit {
  @api.reset()
  for i = 0; i < routes.length(); i = i + 1 {
    let route = routes[i]
    let route_path = path_to_slash(route)
    let envelope_id = "route:\{i}:\{route_path}"
    ignore(@api.tree_ingest(envelope_id, join_csv(route)))
  }
  if seal {
    ignore(@api.tree_seal())
  }
}

///|
fn join_csv(values : Array[String]) -> String {
  let out = StringBuilder::new(size_hint=64)
  for i = 0; i < values.length(); i = i + 1 {
    if i > 0 {
      out.write_char(',')
    }
    out.write_string(values[i])
  }
  out.to_string()
}

///|
fn path_to_slash(path : Array[String]) -> String {
  let out = StringBuilder::new(size_hint=64)
  for i = 0; i < path.length(); i = i + 1 {
    if i > 0 {
      out.write_char('/')
    }
    out.write_string(path[i])
  }
  out.to_string()
}
