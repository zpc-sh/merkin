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

///|
let g_bloom : @bloom.BloomSketch = @bloom.BloomSketch::new()

///|
/// Required Merkin WASM exports expected by Mu/lang integration.
let triad_expected_wasm_exports : Array[String] = [
  "plan_finger_wasm", "plan_drift_commitment", "triad_contract_wasm",
]

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
/// Compact drift snapshot used by finger.plan.wasm emission.
priv struct WasmPlanDriftSnapshot {
  root_key : String
  node_count : Int
  epoch : UInt64
  peer_a : String
  peer_b : String
  drift_commitment : @hash.Hash
}

///|
/// Byte-level branch audit used by triad contract generation.
priv struct BranchGhostAudit {
  raw : String
  canonical : String
  raw_hex : String
  has_u200b : Bool
  has_u200c : Bool
  has_ufeff : Bool
  void_detected : Bool
}

///|
/// Emit a compact `.plan` wire for WASM consumers.
///
/// `tokens_csv` controls sparse projection.
/// `peer_refs_csv` carries two peer references for drift coordination:
/// `<peer-a>,<peer-b>` (for example: `mu:abc,muyata:def`).
pub fn plan_finger_wasm(tokens_csv : String, peer_refs_csv : String) -> String {
  let snapshot = build_wasm_plan_drift_snapshot(tokens_csv, peer_refs_csv)
  let material_key = snapshot.drift_commitment.key()
  let hole_id = @hash.Hash::of_bytes(
    str_to_bytes("finger.plan.wasm|hole|" + material_key),
  ).key()

  let peer_count = count_non_none_peers(snapshot.peer_a, snapshot.peer_b)
  let raw_peers = csv_split(peer_refs_csv)
  let raw_peer_a = if 0 < raw_peers.length() { raw_peers[0] } else { "none" }
  let raw_peer_b = if 1 < raw_peers.length() { raw_peers[1] } else { "none" }
  let boundary_fsm = @model.BoundaryWalkerFsm::new(
      "finger.plan.wasm", "ratio://merkin/api",
    )
    .walk_scalars([("peer_a", raw_peer_a), ("peer_b", raw_peer_b)])
    .mark()
  let refs_sanitized = boundary_fsm.sanitized_scalars
  let ghost_u200b = boundary_fsm.ghost_u200b
  let ghost_u200c = boundary_fsm.ghost_u200c
  let ghost_ufeff = boundary_fsm.ghost_ufeff
  let bidi_controls = boundary_fsm.bidi_controls
  let ascii_controls = boundary_fsm.ascii_controls
  let boundary_ticks = boundary_fsm.attention_ticks()
  let boundary_attention_score = boundary_fsm.attention_score()
  let boundary_attention_gradient = boundary_fsm.attention_gradient()
  let boundary_attention_saturated = boundary_fsm.attention_saturated()
  let boundary_status = boundary_status_scalar(boundary_fsm.status())
  let refs = "peer_a:" +
    snapshot.peer_a +
    ",peer_b:" +
    snapshot.peer_b +
    ",root:" +
    snapshot.root_key +
    ",epoch:" +
    snapshot.epoch.to_string() +
    ",nodes:" +
    snapshot.node_count.to_string() +
    ",drift:" +
    material_key

  let out = StringBuilder::new(size_hint=512)
  out.write_string("kind: merkin.yata.plan")
  out.write_string("\ntrack=program")
  out.write_string("\nmode=compact")
  out.write_string("\ngenerator=merkin.wasm.finger")
  out.write_string("\nnote=finger.plan.wasm")
  out.write_string("\nmaterial_hash=")
  out.write_string(material_key)
  out.write_string("\ngit_report=1")
  out.write_string("\ngit_report_branch=merkin")
  out.write_string("\ngit_report_remote=drift-sync")
  out.write_string("\ngit_report_merge_base=")
  out.write_string(snapshot.peer_a)
  out.write_string("\ngit_report_head=")
  out.write_string(snapshot.peer_b)
  out.write_string("\ngit_report_commit_count=")
  out.write_string(peer_count.to_string())
  out.write_string("\ngit_report_refs=")
  out.write_string(refs)
  out.write_string("\nboundary_mode=sanitize")
  out.write_string("\nboundary_cognitive=1")
  out.write_string("\nboundary_domain=ratio_loci")
  out.write_string("\nboundary_refs_total=2")
  out.write_string("\nboundary_refs_sanitized=")
  out.write_string(refs_sanitized.to_string())
  out.write_string("\nboundary_refs_quarantined=0")
  out.write_string("\nboundary_ghost_u200b=")
  out.write_string(ghost_u200b.to_string())
  out.write_string("\nboundary_ghost_u200c=")
  out.write_string(ghost_u200c.to_string())
  out.write_string("\nboundary_ghost_ufeff=")
  out.write_string(ghost_ufeff.to_string())
  out.write_string("\nboundary_bidi_controls=")
  out.write_string(bidi_controls.to_string())
  out.write_string("\nboundary_ascii_controls=")
  out.write_string(ascii_controls.to_string())
  out.write_string("\nboundary_ticks=")
  out.write_string(boundary_ticks.to_string())
  out.write_string("\nboundary_attention_score=")
  out.write_string(boundary_attention_score.to_string())
  out.write_string("\nboundary_attention_gradient=")
  out.write_string(boundary_attention_gradient)
  out.write_string("\nboundary_attention_saturated=")
  out.write_string(if boundary_attention_saturated { "1" } else { "0" })
  out.write_string("\nboundary_status=")
  out.write_string(boundary_status)
  out.write_string("\n- ")
  out.write_string(hole_id)
  out.write_string(
    " wasm/finger.plan.wasm converging ready=true candidates=1 conf_floor=100 selected=none provenance=1",
  )
  out.write_char('\n')
  out.to_string()
}

///|
/// Deterministic drift commitment for sparse-tree + peer coordination.
pub fn plan_drift_commitment(
  tokens_csv : String,
  peer_refs_csv : String,
) -> String {
  build_wasm_plan_drift_snapshot(tokens_csv, peer_refs_csv).drift_commitment.key()
}

///|
/// ABI status for required Mu-facing Merkin WASM exports.
/// Returns:
/// - `ok`
/// - `missing:<comma-separated-export-names>`
pub fn triad_abi_status(wasm_exports_csv : String) -> String {
  let provided_exports = dedupe_non_empty_scalars(csv_split(wasm_exports_csv))
  let missing_exports = expected_wasm_missing_exports(provided_exports)
  if missing_exports.length() == 0 {
    "ok"
  } else {
    "missing:" + join_csv(missing_exports)
  }
}

///|
/// Emit canonical triad contract JSON that coordinates Merkin/Mu/lang drift.
///
/// This contract is designed for `finger.plan.wasm`-first coordination:
/// - sparse Merkin drift commitment + finger plan hash
/// - pinned repo heads for all three repos
/// - byte-level branch ghost audit (`U+200B`, `U+200C`, `U+FEFF`)
/// - required wasm ABI surface for Mu/lang integration
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
  let snapshot = build_wasm_plan_drift_snapshot(tokens_csv, peer_refs_csv)
  let finger_plan = plan_finger_wasm(tokens_csv, peer_refs_csv)
  let finger_plan_hash = @hash.Hash::of_bytes(str_to_bytes(finger_plan)).key()

  let merkin_head_clean = sanitize_or_unknown(merkin_head)
  let mu_head_clean = sanitize_or_unknown(mu_head)
  let lang_head_clean = sanitize_or_unknown(lang_head)

  let merkin_branch = build_branch_ghost_audit(merkin_branch_raw)
  let mu_branch = build_branch_ghost_audit(mu_branch_raw)
  let lang_branch = build_branch_ghost_audit(lang_branch_raw)

  let refs_byte_clean = !branch_has_ghost(merkin_branch) &&
    !branch_has_ghost(mu_branch) &&
    !branch_has_ghost(lang_branch) &&
    !has_ghost_scalar(merkin_head_clean) &&
    !has_ghost_scalar(mu_head_clean) &&
    !has_ghost_scalar(lang_head_clean) &&
    !has_ghost_scalar(peer_refs_csv)

  let provided_exports = dedupe_non_empty_scalars(csv_split(wasm_exports_csv))
  let missing_exports = expected_wasm_missing_exports(provided_exports)
  let abi_status = if missing_exports.length() == 0 { "ok" } else { "missing" }
  let compatibility_breaks = if missing_exports.length() == 0 {
    "none"
  } else {
    "abi-missing-exports"
  }

  let version = sanitize_or_default(contract_version, "v0.1")
  let generated = sanitize_or_default(generated_at_utc, "unknown")

  let seal_material = "triad_contract|" +
    "version=" +
    version +
    "|generated_at_utc=" +
    generated +
    "|drift_commitment=" +
    snapshot.drift_commitment.key() +
    "|finger_plan_hash=" +
    finger_plan_hash +
    "|root_key=" +
    snapshot.root_key +
    "|node_count=" +
    snapshot.node_count.to_string() +
    "|epoch=" +
    snapshot.epoch.to_string() +
    "|peer_a=" +
    snapshot.peer_a +
    "|peer_b=" +
    snapshot.peer_b +
    "|merkin_head=" +
    merkin_head_clean +
    "|mu_head=" +
    mu_head_clean +
    "|lang_head=" +
    lang_head_clean +
    "|merkin_branch=" +
    merkin_branch.canonical +
    "|mu_branch=" +
    mu_branch.canonical +
    "|lang_branch=" +
    lang_branch.canonical +
    "|abi_status=" +
    abi_status +
    "|abi_expected=" +
    join_csv(triad_expected_wasm_exports) +
    "|abi_provided=" +
    join_csv(provided_exports) +
    "|abi_missing=" +
    join_csv(missing_exports)
  let seal = @hash.Hash::of_bytes(str_to_bytes(seal_material)).key()

  let out = StringBuilder::new(size_hint=4096)
  out.write_string("{")
  out.write_string("\n  \"kind\": \"merkin.triad.contract\",")
  out.write_string("\n  \"version\": \"")
  out.write_string(json_escape(version))
  out.write_string("\",")
  out.write_string("\n  \"generated_at_utc\": \"")
  out.write_string(json_escape(generated))
  out.write_string("\",")
  out.write_string("\n  \"ratio_loci\": \"git-replacement\",")
  out.write_string("\n  \"drift\": {")
  out.write_string("\n    \"surface\": \"finger.plan.wasm\",")
  out.write_string("\n    \"tokens_csv\": \"")
  out.write_string(json_escape(sanitize_json_scalar(tokens_csv, "none")))
  out.write_string("\",")
  out.write_string("\n    \"peer_refs_csv\": \"")
  out.write_string(json_escape(sanitize_json_scalar(peer_refs_csv, "none")))
  out.write_string("\",")
  out.write_string("\n    \"root_key\": \"")
  out.write_string(json_escape(snapshot.root_key))
  out.write_string("\",")
  out.write_string("\n    \"node_count\": ")
  out.write_string(snapshot.node_count.to_string())
  out.write_string(",")
  out.write_string("\n    \"epoch\": ")
  out.write_string(snapshot.epoch.to_string())
  out.write_string(",")
  out.write_string("\n    \"drift_commitment\": \"")
  out.write_string(json_escape(snapshot.drift_commitment.key()))
  out.write_string("\",")
  out.write_string("\n    \"finger_plan_hash\": \"")
  out.write_string(json_escape(finger_plan_hash))
  out.write_string("\"\n  },")
  out.write_string("\n  \"repos\": {")
  write_triad_repo_json(out, "merkin", merkin_head_clean, merkin_branch, true)
  write_triad_repo_json(out, "mu", mu_head_clean, mu_branch, true)
  write_triad_repo_json(out, "lang", lang_head_clean, lang_branch, false)
  out.write_string("\n  },")
  out.write_string("\n  \"refs_byte_clean\": ")
  out.write_string(bool_to_json(refs_byte_clean))
  out.write_string(",")
  out.write_string("\n  \"abi\": {")
  out.write_string("\n    \"expected\": ")
  write_json_string_array(out, triad_expected_wasm_exports)
  out.write_string(",")
  out.write_string("\n    \"provided\": ")
  write_json_string_array(out, provided_exports)
  out.write_string(",")
  out.write_string("\n    \"missing\": ")
  write_json_string_array(out, missing_exports)
  out.write_string(",")
  out.write_string("\n    \"status\": \"")
  out.write_string(abi_status)
  out.write_string("\",")
  out.write_string("\n    \"hook_target\": \"../lang/wasm_iface/iface.mbt\"")
  out.write_string("\n  },")
  out.write_string("\n  \"compatibility\": {")
  out.write_string("\n    \"requires\": \"finger.plan.wasm\",")
  out.write_string("\n    \"breaks\": \"")
  out.write_string(compatibility_breaks)
  out.write_string("\",")
  out.write_string("\n    \"min_versions\": {")
  out.write_string("\n      \"merkin_head\": \"")
  out.write_string(json_escape(merkin_head_clean))
  out.write_string("\",")
  out.write_string("\n      \"mu_head\": \"")
  out.write_string(json_escape(mu_head_clean))
  out.write_string("\",")
  out.write_string("\n      \"lang_head\": \"")
  out.write_string(json_escape(lang_head_clean))
  out.write_string("\"\n    }")
  out.write_string("\n  },")
  out.write_string("\n  \"seal\": \"")
  out.write_string(json_escape(seal))
  out.write_string("\"\n}")
  out.to_string()
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
fn count_non_none_peers(peer_a : String, peer_b : String) -> UInt {
  let mut out : UInt = 0U
  if peer_a != "none" {
    out = out + 1U
  }
  if peer_b != "none" {
    out = out + 1U
  }
  out
}

///|
fn expected_wasm_missing_exports(
  provided_exports : Array[String],
) -> Array[String] {
  let missing : Array[String] = []
  for expected in triad_expected_wasm_exports {
    if !string_array_contains(provided_exports, expected) {
      missing.push(expected)
    }
  }
  missing
}

///|
fn dedupe_non_empty_scalars(values : Array[String]) -> Array[String] {
  let out : Array[String] = []
  for value in values {
    let clean = sanitize_plan_scalar(value)
    if clean != "none" && !string_array_contains(out, clean) {
      out.push(clean)
    }
  }
  out
}

///|
fn string_array_contains(values : Array[String], target : String) -> Bool {
  for value in values {
    if value == target {
      return true
    }
  }
  false
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
fn branch_has_ghost(audit : BranchGhostAudit) -> Bool {
  audit.has_u200b || audit.has_u200c || audit.has_ufeff
}

///|
fn has_ghost_scalar(value : String) -> Bool {
  for ch in value {
    let code = ch.to_uint().reinterpret_as_int()
    if code == 0x200B || code == 0x200C || code == 0xFEFF {
      return true
    }
  }
  false
}

///|
fn build_branch_ghost_audit(raw_branch : String) -> BranchGhostAudit {
  let raw = sanitize_or_default(raw_branch, "none")
  let canonical_builder = StringBuilder::new(size_hint=raw.length())
  let mut has_u200b = false
  let mut has_u200c = false
  let mut has_ufeff = false

  for ch in raw {
    let code = ch.to_uint().reinterpret_as_int()
    if code == 0x200B {
      has_u200b = true
    } else if code == 0x200C {
      has_u200c = true
    } else if code == 0xFEFF {
      has_ufeff = true
    } else {
      canonical_builder.write_char(ch)
    }
  }

  let canonical_raw = canonical_builder.to_string()
  let canonical = if canonical_raw == "" { "none" } else { canonical_raw }
  let has_any_ghost = has_u200b || has_u200c || has_ufeff
  {
    raw,
    canonical,
    raw_hex: scalar_hex(raw),
    has_u200b,
    has_u200c,
    has_ufeff,
    void_detected: has_any_ghost && canonical == "main",
  }
}

///|
fn scalar_hex(value : String) -> String {
  let out = StringBuilder::new(size_hint=value.length() * 8)
  for ch in value {
    let code = ch.to_uint().reinterpret_as_int()
    out.write_char(int_to_hex((code >> 28) & 0xF))
    out.write_char(int_to_hex((code >> 24) & 0xF))
    out.write_char(int_to_hex((code >> 20) & 0xF))
    out.write_char(int_to_hex((code >> 16) & 0xF))
    out.write_char(int_to_hex((code >> 12) & 0xF))
    out.write_char(int_to_hex((code >> 8) & 0xF))
    out.write_char(int_to_hex((code >> 4) & 0xF))
    out.write_char(int_to_hex(code & 0xF))
  }
  let hex = out.to_string()
  if hex == "" {
    "none"
  } else {
    hex
  }
}

///|
fn write_json_u16_escape(out : StringBuilder, code : Int) -> Unit {
  let code_u16 = if code < 0 {
    0
  } else if code > 0xFFFF {
    0xFFFD
  } else {
    code
  }
  out.write_string("\\u")
  out.write_char(int_to_hex((code_u16 >> 12) & 0xF))
  out.write_char(int_to_hex((code_u16 >> 8) & 0xF))
  out.write_char(int_to_hex((code_u16 >> 4) & 0xF))
  out.write_char(int_to_hex(code_u16 & 0xF))
}

///|
fn json_escape(value : String) -> String {
  let out = StringBuilder::new(size_hint=value.length() + 16)
  for ch in value {
    let code = ch.to_uint().reinterpret_as_int()
    if ch == '"' {
      out.write_string("\\\"")
    } else if ch == '\\' {
      out.write_string("\\\\")
    } else if ch == '\n' {
      out.write_string("\\n")
    } else if ch == '\r' {
      out.write_string("\\r")
    } else if ch == '\t' {
      out.write_string("\\t")
    } else if code < 32 || code == 0x200B || code == 0x200C || code == 0xFEFF {
      write_json_u16_escape(out, code)
    } else {
      out.write_char(ch)
    }
  }
  out.to_string()
}

///|
fn bool_to_json(value : Bool) -> String {
  if value {
    "true"
  } else {
    "false"
  }
}

///|
fn write_json_string_array(out : StringBuilder, values : Array[String]) -> Unit {
  out.write_char('[')
  for i = 0; i < values.length(); i = i + 1 {
    if i > 0 {
      out.write_string(", ")
    }
    out.write_char('"')
    out.write_string(json_escape(values[i]))
    out.write_char('"')
  }
  out.write_char(']')
}

///|
fn write_triad_repo_json(
  out : StringBuilder,
  name : String,
  head : String,
  branch : BranchGhostAudit,
  trailing_comma : Bool,
) -> Unit {
  out.write_string("\n    \"")
  out.write_string(name)
  out.write_string("\": {")
  out.write_string("\n      \"head\": \"")
  out.write_string(json_escape(head))
  out.write_string("\",")
  out.write_string("\n      \"branch_raw\": \"")
  out.write_string(json_escape(branch.raw))
  out.write_string("\",")
  out.write_string("\n      \"branch\": \"")
  out.write_string(json_escape(branch.canonical))
  out.write_string("\",")
  out.write_string("\n      \"branch_raw_hex\": \"")
  out.write_string(json_escape(branch.raw_hex))
  out.write_string("\",")
  out.write_string("\n      \"branch_byte_clean\": ")
  out.write_string(bool_to_json(!branch_has_ghost(branch)))
  out.write_string(",")
  out.write_string("\n      \"void_detected\": ")
  out.write_string(bool_to_json(branch.void_detected))
  out.write_string(",")
  out.write_string("\n      \"ghost\": {")
  out.write_string("\n        \"u200b\": ")
  out.write_string(bool_to_json(branch.has_u200b))
  out.write_string(",")
  out.write_string("\n        \"u200c\": ")
  out.write_string(bool_to_json(branch.has_u200c))
  out.write_string(",")
  out.write_string("\n        \"ufeff\": ")
  out.write_string(bool_to_json(branch.has_ufeff))
  out.write_string("\n      }")
  if trailing_comma {
    out.write_string("\n    },")
  } else {
    out.write_string("\n    }")
  }
}

///|
fn sanitize_or_default(value : String, fallback : String) -> String {
  let clean = sanitize_plan_scalar(value)
  if clean == "none" {
    fallback
  } else {
    clean
  }
}

///|
fn sanitize_or_unknown(value : String) -> String {
  sanitize_or_default(value, "unknown")
}

///|
fn sanitize_json_scalar(value : String, fallback : String) -> String {
  let out = StringBuilder::new(size_hint=32)
  for ch in value {
    if ch == '\n' || ch == '\r' {
      out.write_char('_')
    } else {
      out.write_char(ch)
    }
  }
  let text = out.to_string()
  if text == "" {
    fallback
  } else {
    text
  }
}

///|
fn build_wasm_plan_drift_snapshot(
  tokens_csv : String,
  peer_refs_csv : String,
) -> WasmPlanDriftSnapshot {
  let tokens = if tokens_csv == "" { [] } else { csv_split(tokens_csv) }
  let sparse = g_tree.sparse(tokens)
  let root_key = match sparse.root() {
    Some(key) => key
    None => "none"
  }
  let node_count = sparse.node_count()
  let epoch = g_tree.current_epoch()
  let peers = csv_split(peer_refs_csv)
  let peer_a = peer_ref_or_none(peers, 0)
  let peer_b = peer_ref_or_none(peers, 1)
  let material = "finger.plan.wasm|root=" +
    root_key +
    "|nodes=" +
    node_count.to_string() +
    "|epoch=" +
    epoch.to_string() +
    "|peer_a=" +
    peer_a +
    "|peer_b=" +
    peer_b
  {
    root_key,
    node_count,
    epoch,
    peer_a,
    peer_b,
    drift_commitment: @hash.Hash::of_bytes(str_to_bytes(material)),
  }
}

///|
fn peer_ref_or_none(peers : Array[String], index : Int) -> String {
  if index < peers.length() {
    sanitize_boundary_scalar(peers[index])
  } else {
    "none"
  }
}

///|
fn sanitize_plan_scalar(value : String) -> String {
  let out = StringBuilder::new(size_hint=32)
  for ch in value {
    if ch == '\n' || ch == '\r' {
      out.write_char('_')
    } else if ch == ',' {
      out.write_char(';')
    } else {
      out.write_char(ch)
    }
  }
  let text = out.to_string()
  if text == "" {
    "none"
  } else {
    text
  }
}

///|
fn boundary_status_scalar(status : @model.BoundaryStatus) -> String {
  match status {
    @model.Clean => "clean"
    @model.Attention => "attention"
    @model.Containment => "containment"
  }
}

///|
fn sanitize_boundary_scalar(value : String) -> String {
  let out = StringBuilder::new(size_hint=32)
  for ch in value {
    let code = ch.to_uint().reinterpret_as_int()
    if code == 0x200B || code == 0x200C || code == 0xFEFF {
      ()
    } else if ch == '\n' || ch == '\r' {
      out.write_char('_')
    } else if ch == ',' {
      out.write_char(';')
    } else {
      out.write_char(ch)
    }
  }
  let text = out.to_string()
  if text == "" {
    "none"
  } else {
    text
  }
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
