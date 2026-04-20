///|
/// WASM library link boundary for WasmEdge, wasmex, and AtomVM (non-main).
///
/// This package produces the canonical merkin.wasm for host runtimes that
/// call exports by name (WasmEdge CLI, wasmex NIF, Popcorn on AtomVM).
///
/// All logic lives in zpc/merkin/api. This package is the link surface only.
///
/// Build:
///   moon build --target wasm-gc --release --package zpc/merkin/wasm_lib
///   moon build --target wasm   --release --package zpc/merkin/wasm_lib

// --- Bloom ---

///|
pub fn bloom_add(token : String) -> Unit {
  @api.bloom_add(token)
}

///|
pub fn bloom_check(token : String) -> Bool {
  @api.bloom_check(token)
}

///|
pub fn bloom_serialize() -> String {
  @api.bloom_serialize()
}

///|
pub fn bloom_popcount() -> Int {
  @api.bloom_popcount()
}

// --- Tree ---

///|
pub fn tree_ingest(envelope_id : String, routing_tokens_csv : String) -> String {
  @api.tree_ingest(envelope_id, routing_tokens_csv)
}

///|
pub fn tree_sparse(tokens_csv : String) -> String {
  @api.tree_sparse(tokens_csv)
}

///|
pub fn tree_seal() -> String {
  @api.tree_seal()
}

///|
pub fn tree_epoch() -> Int {
  @api.tree_epoch()
}

///|
pub fn tree_node_count() -> Int {
  @api.tree_node_count()
}

// --- Drift / Triad ---

///|
pub fn plan_finger_wasm(tokens_csv : String, peer_refs_csv : String) -> String {
  @api.plan_finger_wasm(tokens_csv, peer_refs_csv)
}

///|
pub fn plan_drift_commitment(
  tokens_csv : String,
  peer_refs_csv : String,
) -> String {
  @api.plan_drift_commitment(tokens_csv, peer_refs_csv)
}

///|
pub fn triad_abi_status(wasm_exports_csv : String) -> String {
  @api.triad_abi_status(wasm_exports_csv)
}

///|
pub fn triad_contract_wasm(
  tokens_csv : String,
  peer_refs_csv : String,
  merkin_head : String,
  mu_head : String,
  lang_head : String,
  merkin_branch_raw : String,
  mu_branch_raw : String,
  lang_branch_raw : String,
  wasm_exports_csv : String,
  generated_at_utc : String,
  contract_version : String,
) -> String {
  @api.triad_contract_wasm(
    tokens_csv, peer_refs_csv, merkin_head, mu_head, lang_head, merkin_branch_raw,
    mu_branch_raw, lang_branch_raw, wasm_exports_csv, generated_at_utc, contract_version,
  )
}

// --- Hash ---

///|
pub fn hash_bytes(hex_input : String) -> String {
  @api.hash_bytes(hex_input)
}

// --- Lifecycle ---

///|
pub fn reset() -> Unit {
  @api.reset()
}
