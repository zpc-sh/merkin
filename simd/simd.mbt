///|
/// merkin/simd — AVX-VNNI + AVX-NE-CONVERT MoonBit bindings.
///
/// Native-only package. WASM builds do not include this package.
/// All exported functions have scalar fallbacks; call simd_caps() first
/// to know which hardware paths are active.
///
/// Capability bits:
///   bit 0  (1): AVX2
///   bit 1  (2): AVX-VNNI    — multi-hash FNV, bloom acceleration
///   bit 2  (4): AVX-NE-CONVERT — bf16 ↔ f32 (Granite Rapids+)

// ── runtime capability ──────────────────────────────────────────────────

///|
extern "C" fn merkin_simd_caps() -> Int = "merkin_simd_caps"

///|
pub fn simd_caps() -> Int {
  merkin_simd_caps()
}

///|
pub fn simd_has_vnni() -> Bool {
  (merkin_simd_caps() & 2) != 0
}

///|
pub fn simd_has_ne_convert() -> Bool {
  (merkin_simd_caps() & 4) != 0
}

// ── AVX-VNNI bindings ───────────────────────────────────────────────────

///|
/// Dot product of two 32-byte arrays: Σ a[i]*b[i], horizontal sum.
/// a: unsigned byte buffer (32 bytes)
/// b: signed byte buffer  (32 bytes)
/// Returns a single int32 sum.
/// Requires AVX-VNNI (simd_has_vnni()).
#borrow(a)
#borrow(b)
extern "C" fn merkin_vnni_dot32(a : Bytes, b : Bytes) -> Int = "merkin_vnni_dot32"

///|
pub fn vnni_dot32(a : Bytes, b : Bytes) -> Int {
  merkin_vnni_dot32(a, b)
}

///|
/// Dot product over 32 bytes, raw 8-lane output (no horizontal sum).
/// out must be a 32-byte (8 × int32) Bytes buffer — written in place.
#borrow(a)
#borrow(b)
#borrow(out)
extern "C" fn merkin_vnni_dot32_lanes(
  a : Bytes,
  b : Bytes,
  out : Bytes,
) -> Unit = "merkin_vnni_dot32_lanes"

///|
pub fn vnni_dot32_lanes(a : Bytes, b : Bytes, out : Bytes) -> Unit {
  merkin_vnni_dot32_lanes(a, b, out)
}

///|
/// Multi-block accumulate: accumulate `blocks` × 32-byte chunks.
/// acc: int32_t[8] as 32-byte Bytes — caller initialises (e.g. to seeds).
/// a, b: each must be blocks×32 bytes long.
#borrow(a)
#borrow(b)
#borrow(acc)
extern "C" fn merkin_vnni_accumulate(
  a : Bytes,
  b : Bytes,
  blocks : Int,
  acc : Bytes,
) -> Unit = "merkin_vnni_accumulate"

///|
pub fn vnni_accumulate(a : Bytes, b : Bytes, blocks : Int, acc : Bytes) -> Unit {
  merkin_vnni_accumulate(a, b, blocks, acc)
}

///|
/// 8-lane parallel FNV-1a hash over arbitrary-length byte data.
/// Returns a 32-byte Bytes buffer containing 8 × int32 hash values.
/// Each lane uses a different seed → 8 independent bloom positions.
/// Requires AVX-VNNI.
#borrow(data)
extern "C" fn merkin_vnni_fnv_x8(data : Bytes, len : Int, out : Bytes) -> Unit = "merkin_vnni_fnv_x8"

///|
pub fn vnni_fnv_x8(data : Bytes) -> Bytes {
  let out = Bytes::make(32, 0)
  merkin_vnni_fnv_x8(data, data.length(), out)
  out
}

///|
/// Extract 8 bloom bit positions from fnv_x8 output.
/// hashes: 32-byte buffer from vnni_fnv_x8
/// bit_count: total bits in bloom filter (must be power of 2, e.g. 256)
/// Returns 32-byte buffer of int32[8] positions, each in [0, bit_count).
#borrow(hashes)
#borrow(out)
extern "C" fn merkin_vnni_bloom_positions(
  hashes : Bytes,
  bit_count : Int,
  out : Bytes,
) -> Unit = "merkin_vnni_bloom_positions"

///|
pub fn vnni_bloom_positions(hashes : Bytes, bit_count : Int) -> Bytes {
  let out = Bytes::make(32, 0)
  merkin_vnni_bloom_positions(hashes, bit_count, out)
  out
}

// ── AVX-NE-CONVERT bindings ─────────────────────────────────────────────

///|
/// Convert 8 bfloat16 values (even-indexed from a 16-element src) to 8 floats.
/// src: 32-byte buffer of 16 × uint16 bf16 values
/// dst: 32-byte buffer for 8 × float32 output
/// Falls back to scalar shift on non-NE-CONVERT hardware.
#borrow(src)
#borrow(dst)
extern "C" fn merkin_ne_bf16_to_f32_even(src : Bytes, dst : Bytes) -> Unit = "merkin_ne_bf16_to_f32_even"

///|
pub fn ne_bf16_to_f32_even(src : Bytes, dst : Bytes) -> Unit {
  merkin_ne_bf16_to_f32_even(src, dst)
}

///|
/// Convert 8 bfloat16 values (odd-indexed) to 8 floats.
#borrow(src)
#borrow(dst)
extern "C" fn merkin_ne_bf16_to_f32_odd(src : Bytes, dst : Bytes) -> Unit = "merkin_ne_bf16_to_f32_odd"

///|
pub fn ne_bf16_to_f32_odd(src : Bytes, dst : Bytes) -> Unit {
  merkin_ne_bf16_to_f32_odd(src, dst)
}

///|
/// Broadcast a single bf16 scalar (low 16 bits of an Int) to 8 float32 values.
/// dst: 32-byte buffer for 8 × float32 output.
#borrow(dst)
extern "C" fn merkin_ne_broadcast_bf16(scalar : Int, dst : Bytes) -> Unit = "merkin_ne_broadcast_bf16"

///|
pub fn ne_broadcast_bf16(scalar : Int, dst : Bytes) -> Unit {
  merkin_ne_broadcast_bf16(scalar, dst)
}
