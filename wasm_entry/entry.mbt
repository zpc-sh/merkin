///|
/// Wasm entry point for Popcorn/wasmex bridge.
///
/// This package exists solely to produce a linked merkin.wasm binary.
/// All real logic lives in zpc/merkin/api.
///
/// Functions are re-exported by delegation so they appear as wasm exports
/// at the top level of the binary. The host (mulsp via Popcorn or wasmex)
/// calls these by name.
///
/// Build:
///   cd merkin && moon build --target wasm-gc --package zpc/merkin/wasm_entry
///   cp _build/wasm-gc/release/build/wasm_entry/wasm_entry.wasm \
///      ../lang/mulsp/priv/merkin.wasm

// Required by is-main: true
fn main {
  // Intentionally empty. Module-level state (g_tree, g_bloom) is
  // initialised on first function call. No side effects at load time.
}

// --- Bloom ---

///| bloom_add: register a routing token.
pub fn bloom_add(token : String) -> Unit {
  @api.bloom_add(token)
}

///| bloom_check: probabilistic membership test.
pub fn bloom_check(token : String) -> Bool {
  @api.bloom_check(token)
}

///| bloom_serialize: hex-encoded bit array for DC wire transfer.
pub fn bloom_serialize() -> String {
  @api.bloom_serialize()
}

///| bloom_popcount: approximate population count.
pub fn bloom_popcount() -> Int {
  @api.bloom_popcount()
}

// --- Tree ---

///| tree_ingest: add an envelope to the hot tree.
pub fn tree_ingest(envelope_id : String, routing_tokens_csv : String) -> String {
  @api.tree_ingest(envelope_id, routing_tokens_csv)
}

///| tree_sparse: bloom-filtered tree projection.
pub fn tree_sparse(tokens_csv : String) -> String {
  @api.tree_sparse(tokens_csv)
}

///| tree_seal: freeze current epoch, return root hash.
pub fn tree_seal() -> String {
  @api.tree_seal()
}

///| tree_epoch: current epoch counter.
pub fn tree_epoch() -> Int {
  @api.tree_epoch()
}

///| tree_node_count: number of nodes in live tree.
pub fn tree_node_count() -> Int {
  @api.tree_node_count()
}

// --- Hash ---

///| hash_bytes: content-address a hex-encoded byte string.
pub fn hash_bytes(hex_input : String) -> String {
  @api.hash_bytes(hex_input)
}

// --- Lifecycle ---

///| reset: clear tree and bloom for session recycling.
pub fn reset() -> Unit {
  @api.reset()
}
