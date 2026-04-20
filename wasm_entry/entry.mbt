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

///|
/// bloom_add: register a routing token.
pub fn bloom_add(token : String) -> Unit {
  @api.bloom_add(token)
}

///|
/// bloom_check: probabilistic membership test.
pub fn bloom_check(token : String) -> Bool {
  @api.bloom_check(token)
}

///|
/// bloom_serialize: hex-encoded bit array for DC wire transfer.
pub fn bloom_serialize() -> String {
  @api.bloom_serialize()
}

///|
/// bloom_popcount: approximate population count.
pub fn bloom_popcount() -> Int {
  @api.bloom_popcount()
}

// --- Tree ---

///|
/// tree_ingest: add an envelope to the hot tree.
pub fn tree_ingest(envelope_id : String, routing_tokens_csv : String) -> String {
  @api.tree_ingest(envelope_id, routing_tokens_csv)
}

///|
/// tree_sparse: bloom-filtered tree projection.
pub fn tree_sparse(tokens_csv : String) -> String {
  @api.tree_sparse(tokens_csv)
}

///|
/// plan_finger_wasm: compact `.plan` wire with drift coordination fields.
/// slot 1: sparse tokens csv
/// slot 2: peer refs csv (for example: `mu:abc,muyata:def`)
pub fn plan_finger_wasm(tokens_csv : String, peer_refs_csv : String) -> String {
  @api.plan_finger_wasm(tokens_csv, peer_refs_csv)
}

///|
/// Deterministic drift commitment from sparse-tree projection + peers.
pub fn plan_drift_commitment(
  tokens_csv : String,
  peer_refs_csv : String,
) -> String {
  @api.plan_drift_commitment(tokens_csv, peer_refs_csv)
}

///|
/// triad_abi_status: checks required Mu-facing WASM exports.
/// Returns `ok` or `missing:<csv>`.
pub fn triad_abi_status(wasm_exports_csv : String) -> String {
  @api.triad_abi_status(wasm_exports_csv)
}

///|
/// triad_contract_wasm: emits canonical triad drift contract JSON.
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

///|
/// tree_seal: freeze current epoch, return root hash.
pub fn tree_seal() -> String {
  @api.tree_seal()
}

///|
/// tree_epoch: current epoch counter.
pub fn tree_epoch() -> Int {
  @api.tree_epoch()
}

///|
/// tree_node_count: number of nodes in live tree.
pub fn tree_node_count() -> Int {
  @api.tree_node_count()
}

// --- Hash ---

///|
/// hash_bytes: content-address a hex-encoded byte string.
pub fn hash_bytes(hex_input : String) -> String {
  @api.hash_bytes(hex_input)
}

// --- Lifecycle ---

///|
/// reset: clear tree and bloom for session recycling.
pub fn reset() -> Unit {
  @api.reset()
}

// ---------------------------------------------------------------------------
// Integer-ABI bridge (lm_* exports) for wasmex on standard BEAM.
//
// wasmex can call wasm-gc exports whose params/returns are i32/void.
// It cannot directly pass Elixir binaries to MoonBit's GC String refs.
// This bridge exposes a shared byte-slot protocol:
//
//   host writes UTF-8 bytes into slot 1 or 2 via lm_slot{1,2}_put(i, b)
//   host sets length via lm_slot{1,2}_len(n)
//   host calls lm_<op>()
//   host reads result bytes via lm_out_len() + lm_out_get(i)
//
// All parameters and return values are Int (i32) or Unit (void).
// This matches wasmex's calling convention without requiring string ABI.
//
// Elixir caller pattern:
//   wasmex_write_slot(state, 1, token)
//   {:ok, [result]} = Wasmex.call_function(store, instance, "lm_bloom_check", [])
// ---------------------------------------------------------------------------

// Slot 1 — primary string argument

///|
let lm_s1 : Array[Byte] = Array::make(4096, b'\x00')

///|
let lm_s1_len : Ref[Int] = Ref::new(0)

// Slot 2 — secondary string argument (for two-arg calls like tree_ingest)

///|
let lm_s2 : Array[Byte] = Array::make(4096, b'\x00')

///|
let lm_s2_len : Ref[Int] = Ref::new(0)

// Output buffer — holds the UTF-8 result of string-returning calls

///|
let lm_out : Array[Byte] = Array::make(8192, b'\x00')

///|
let g_lm_out_len : Ref[Int] = Ref::new(0)

///|
/// Write one byte at position i into slot 1.
pub fn lm_slot1_put(i : Int, b : Int) -> Unit {
  lm_s1[i] = b.land(0xFF).to_byte()
}

///|
/// Set the valid byte count in slot 1.
pub fn lm_slot1_len(n : Int) -> Unit {
  lm_s1_len.val = n
}

///|
/// Write one byte at position i into slot 2.
pub fn lm_slot2_put(i : Int, b : Int) -> Unit {
  lm_s2[i] = b.land(0xFF).to_byte()
}

///|
/// Set the valid byte count in slot 2.
pub fn lm_slot2_len(n : Int) -> Unit {
  lm_s2_len.val = n
}

///|
/// Return the number of valid bytes in the output buffer.
pub fn lm_out_len() -> Int {
  g_lm_out_len.val
}

///|
/// Return the byte at position i in the output buffer.
pub fn lm_out_get(i : Int) -> Int {
  lm_out[i].to_int()
}

// Internal: decode a UTF-8 byte slice from a slot buffer into a String.

///|
fn lm_decode(buf : Array[Byte], len : Int) -> String {
  let sb = StringBuilder::new()
  let mut i = 0
  while i < len {
    let b0 = buf[i].to_int()
    if (b0 & 0x80) == 0 {
      sb.write_char(b0.unsafe_to_char())
      i = i + 1
    } else if (b0 & 0xE0) == 0xC0 && i + 1 < len {
      let b1 = buf[i + 1].to_int()
      let cp = ((b0 & 0x1F) << 6) | (b1 & 0x3F)
      sb.write_char(cp.unsafe_to_char())
      i = i + 2
    } else if (b0 & 0xF0) == 0xE0 && i + 2 < len {
      let b1 = buf[i + 1].to_int()
      let b2 = buf[i + 2].to_int()
      let cp = ((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F)
      sb.write_char(cp.unsafe_to_char())
      i = i + 3
    } else {
      sb.write_char('\u{FFFD}')
      i = i + 1
    }
  }
  sb.to_string()
}

// Internal: encode a String as UTF-8 into lm_out, set lm_out_len.

///|
fn lm_encode(s : String) -> Unit {
  let mut i = 0
  for ch in s {
    let cp = ch.to_int()
    if cp < 0x80 {
      lm_out[i] = cp.to_byte()
      i = i + 1
    } else if cp < 0x800 {
      lm_out[i] = (0xC0 | (cp >> 6)).to_byte()
      lm_out[i + 1] = (0x80 | (cp & 0x3F)).to_byte()
      i = i + 2
    } else {
      lm_out[i] = (0xE0 | (cp >> 12)).to_byte()
      lm_out[i + 1] = (0x80 | ((cp >> 6) & 0x3F)).to_byte()
      lm_out[i + 2] = (0x80 | (cp & 0x3F)).to_byte()
      i = i + 3
    }
  }
  g_lm_out_len.val = i
}

// --- lm_* API ---

///|
/// Slot-based bloom_add. Reads token from slot 1.
pub fn lm_bloom_add() -> Unit {
  @api.bloom_add(lm_decode(lm_s1, lm_s1_len.val))
}

///|
/// Slot-based bloom_check. Reads token from slot 1. Returns 1=true 0=false.
pub fn lm_bloom_check() -> Int {
  if @api.bloom_check(lm_decode(lm_s1, lm_s1_len.val)) {
    1
  } else {
    0
  }
}

///|
/// Slot-based bloom_serialize. Writes result to output buffer.
pub fn lm_bloom_serialize() -> Unit {
  lm_encode(@api.bloom_serialize())
}

///|
/// Slot-based tree_ingest. envelope_id in slot 1, tokens_csv in slot 2.
///  Writes returned root key to output buffer.
pub fn lm_tree_ingest() -> Unit {
  let id = lm_decode(lm_s1, lm_s1_len.val)
  let csv = lm_decode(lm_s2, lm_s2_len.val)
  lm_encode(@api.tree_ingest(id, csv))
}

///|
/// Slot-based tree_sparse. tokens_csv in slot 1.
///  Writes "node_count=N\nroot=<key>" to output buffer.
pub fn lm_tree_sparse() -> Unit {
  lm_encode(@api.tree_sparse(lm_decode(lm_s1, lm_s1_len.val)))
}

///|
/// plan_finger_wasm — tokens_csv in slot 1, peer_refs_csv in slot 2.
/// Writes `.plan` wire to output buffer.
pub fn lm_plan_finger_wasm() -> Unit {
  let tokens_csv = lm_decode(lm_s1, lm_s1_len.val)
  let peer_refs_csv = lm_decode(lm_s2, lm_s2_len.val)
  lm_encode(@api.plan_finger_wasm(tokens_csv, peer_refs_csv))
}

///|
/// plan_drift_commitment — tokens_csv in slot 1, peer_refs_csv in slot 2.
/// Writes deterministic drift hash key to output buffer.
pub fn lm_plan_drift_commitment() -> Unit {
  let tokens_csv = lm_decode(lm_s1, lm_s1_len.val)
  let peer_refs_csv = lm_decode(lm_s2, lm_s2_len.val)
  lm_encode(@api.plan_drift_commitment(tokens_csv, peer_refs_csv))
}

///|
/// tree_seal — no string input needed. Writes root key to output buffer.
pub fn lm_tree_seal() -> Unit {
  lm_encode(@api.tree_seal())
}

///|
/// lm_reset — stateless, same as reset().
pub fn lm_reset() -> Unit {
  @api.reset()
}
