///|
/// merkin/api: Wasm export surface for mulsp/Popcorn bridge.
///
/// This package is the only entry point from the outside world.
/// It imports only bloom + hash + tree — all packages that build
/// cleanly to wasm-gc today. model/daemon/storage are deliberately
/// excluded until their type errors are resolved.
///
/// Export strategy:
///   - Module-level state (tree + bloom) — single instance per wasm module.
///     For multi-tenant use, the host (mulsp) spawns one wasm instance per
///     LSP session. Wasm GC handles lifecycle.
///   - All functions use MoonBit native types. Popcorn marshals them.
///     On standard BEAM (wasmex), the caller wraps args via wasm linear mem.
///   - Return format for compound results: newline-delimited key=value.
///     Simple to parse in Elixir without JSON.
///
/// Popcorn (AtomVM) calling convention:
///   {:ok, result} = Popcorn.call_function(instance, "bloom_add", ["my_token"])
///
/// wasmex (standard BEAM) calling convention:
///   {:ok, result} = Wasmex.call_function(store, instance, "bloom_add", ["my_token"])

// Module-level tree and bloom — one instance per loaded module.
let g_tree : @tree.MerkinTree = @tree.MerkinTree::new()
let g_bloom : @bloom.BloomSketch = @bloom.BloomSketch::new()

// --- Bloom API ---

///|
/// Add a token to the bloom sketch.
/// Idempotent. Used at ingest time to register routing tokens.
pub fn bloom_add(token : String) -> Unit {
  g_bloom.add(token)
}

///|
/// Probabilistic membership test. Returns true if token MIGHT be present.
/// False positives possible. False negatives impossible.
/// mulsp uses this for DC offer filtering: skip peers whose bloom says no.
pub fn bloom_check(token : String) -> Bool {
  g_bloom.maybe_contains(token)
}

///|
/// Serialize bloom sketch as a hex string for DC wire transfer.
/// Format: "<num_bits>:<bit_hex>"
/// Receiving mulsp merges it via bloom_merge_hex().
pub fn bloom_serialize() -> String {
  let size = g_bloom.bits.length()
  let sb = StringBuilder::new(size_hint=size / 4 + 16)
  sb.write_string(size.to_string())
  sb.write_char(':')
  let mut i = 0
  while i + 3 < size {
    let nibble = (if g_bloom.bits[i] { 8 } else { 0 }) |
                 (if g_bloom.bits[i + 1] { 4 } else { 0 }) |
                 (if g_bloom.bits[i + 2] { 2 } else { 0 }) |
                 (if g_bloom.bits[i + 3] { 1 } else { 0 })
    sb.write_char(int_to_hex(nibble))
    i = i + 4
  }
  sb.to_string()
}

///|
/// Count tokens currently represented in bloom (approximate via popcount).
pub fn bloom_popcount() -> Int {
  let mut count = 0
  for bit in g_bloom.bits {
    if bit {
      count = count + 1
    }
  }
  count
}

// --- Tree API ---

///|
/// Ingest an envelope into the hot tree.
/// routing_tokens: comma-separated token list (e.g., "security,auth,scan")
/// envelope_id: hex string used as content address
/// Returns the new hot root hash key, or "" on failure.
pub fn tree_ingest(envelope_id : String, routing_tokens_csv : String) -> String {
  let tokens = csv_split(routing_tokens_csv)
  // Add routing tokens to bloom at ingest time
  for token in tokens {
    g_bloom.add(token)
  }
  let h = @hash.Hash::of_bytes(str_to_bytes(envelope_id))
  g_tree.ingest(h, tokens)
}

///|
/// Compute a sparse projection filtered by routing tokens.
/// tokens_csv: comma-separated routing tokens to filter by.
///   Empty string = include all nodes (full tree).
/// Returns "node_count=N\nroot=<hash>" or "node_count=0\nroot=none"
pub fn tree_sparse(tokens_csv : String) -> String {
  let tokens = if tokens_csv == "" { [] } else { csv_split(tokens_csv) }
  let sparse = g_tree.sparse(tokens)
  let sb = StringBuilder::new(size_hint=64)
  sb.write_string("node_count=")
  sb.write_string(sparse.node_count().to_string())
  sb.write_char('\n')
  sb.write_string("root=")
  match sparse.root() {
    Some(key) => sb.write_string(key)
    None => sb.write_string("none")
  }
  sb.to_string()
}

///|
/// Seal the current epoch. Freezes hot tree state.
/// Returns the sealed root hash key, or "" if tree is empty.
pub fn tree_seal() -> String {
  match g_tree.seal() {
    Some(key) => key
    None => ""
  }
}

///|
/// Current tree epoch counter.
pub fn tree_epoch() -> Int {
  g_tree.current_epoch().to_int()
}

///|
/// Node count in the live tree.
pub fn tree_node_count() -> Int {
  g_tree.nodes.length()
}

///|
/// Reset tree and bloom to empty state.
/// Called when a mulsp instance is recycled for a new session.
pub fn reset() -> Unit {
  // Re-initialise by clearing: MoonBit structs are mutable via Map fields
  // Bloom reset: set all bits to false
  for i = 0; i < g_bloom.bits.length(); i = i + 1 {
    g_bloom.bits[i] = false
  }
  // Tree reset: clear node map and hot root
  g_tree.nodes.clear()
  g_tree.hot_root_id = None
  g_tree.epoch = 0UL
}

// --- Hash API ---

///|
/// Hash an arbitrary byte string. Returns hex key.
/// Used by mulsp to verify content-addressed transfers.
pub fn hash_bytes(hex_input : String) -> String {
  let bytes = hex_to_bytes(hex_input)
  @hash.Hash::of_bytes(bytes).key()
}

// --- Internal helpers ---

///|
fn csv_split(s : String) -> Array[String] {
  if s == "" {
    return []
  }
  let parts : Array[String] = []
  let cur = StringBuilder::new(size_hint=32)
  for ch in s {
    if ch == ',' {
      let p = cur.to_string()
      if p != "" {
        parts.push(p)
      }
      cur.reset()
    } else {
      cur.write_char(ch)
    }
  }
  let last = cur.to_string()
  if last != "" {
    parts.push(last)
  }
  parts
}

///|
fn str_to_bytes(s : String) -> Bytes {
  let mut total = 0
  for _ch in s {
    total = total + 4
  }
  let buf = FixedArray::make(total, b'\x00')
  let mut pos = 0
  for ch in s {
    let code = ch.to_uint()
    buf[pos] = ((code >> 24) & 0xFFU).to_byte()
    buf[pos + 1] = ((code >> 16) & 0xFFU).to_byte()
    buf[pos + 2] = ((code >> 8) & 0xFFU).to_byte()
    buf[pos + 3] = (code & 0xFFU).to_byte()
    pos = pos + 4
  }
  Bytes::from_array(buf)
}

///|
fn hex_to_bytes(hex : String) -> Bytes {
  // Collect chars first (iteration is portable across wasm-gc and native)
  let chars : Array[Char] = []
  for ch in hex {
    chars.push(ch)
  }
  let byte_len = chars.length() / 2
  let buf = FixedArray::make(byte_len, b'\x00')
  for i = 0; i < byte_len; i = i + 1 {
    let hi = hex_char_val(chars[i * 2])
    let lo = hex_char_val(chars[i * 2 + 1])
    buf[i] = ((hi * 16 + lo) & 0xFF).to_byte()
  }
  Bytes::from_array(buf)
}

///|
fn hex_char_val(ch : Char) -> Int {
  let c = ch.to_uint().reinterpret_as_int()
  if c >= 48 && c <= 57 {
    c - 48
  } else if c >= 65 && c <= 70 {
    c - 55
  } else if c >= 97 && c <= 102 {
    c - 87
  } else {
    0
  }
}

///|
fn int_to_hex(n : Int) -> Char {
  if n < 10 {
    (48 + n).unsafe_to_char()
  } else {
    (87 + n).unsafe_to_char()
  }
}
