///|
/// Hash algorithm identifier.
/// v0 standardizes on blake3 naming.
/// The current implementation uses a deterministic software fallback while
/// keeping blake3-compatible digest shape (32 bytes).
pub(all) enum HashAlg {
  Fnv1a
  Blake3
} derive(Eq, Show)

///|
/// Content-addressed hash: algorithm tag + raw digest bytes.
pub(all) struct Hash {
  alg : HashAlg
  digest : Bytes
} derive(Eq, Show)

///|
/// Create a Hash by computing a blake3-shaped digest over the input bytes.
pub fn Hash::of_bytes(data : Bytes) -> Hash {
  let d = blake3_fallback(data)
  { alg: Blake3, digest: d }
}

///|
/// Compute the dual semantic hash per Option C:
///   semantic_hash = H(content_hash.digest ++ canonical(semantic_header))
pub fn Hash::semantic(content_hash : Hash, header_bytes : Bytes) -> Hash {
  let combined = bytes_concat(content_hash.digest, header_bytes)
  Hash::of_bytes(combined)
}

///|
/// Check if two hashes are identical (same algorithm and digest).
pub fn Hash::matches(self : Hash, other : Hash) -> Bool {
  self == other
}

///|
/// Return the digest length in bytes.
pub fn Hash::digest_len(self : Hash) -> Int {
  self.digest.length()
}

///|
/// Canonical map/storage key: `<alg>:<hex_digest>`.
pub fn Hash::key(self : Hash) -> String {
  let alg_name = match self.alg {
    Fnv1a => "fnv1a"
    Blake3 => "blake3"
  }
  alg_name + ":" + bytes_to_hex(self.digest)
}

///|
/// Deterministic fallback that emits 32 bytes to match blake3 digest width.
/// Each lane is seeded and mixed independently, then concatenated.
fn blake3_fallback(data : Bytes) -> Bytes {
  let lane0 = fnv1a_seed(data, 14695981039346656037UL)
  let lane1 = fnv1a_seed(data, 1099511628211UL)
  let lane2 = fnv1a_seed(data, 7809847782465536322UL)
  let lane3 = fnv1a_seed(data, 9650029242287828579UL)
  let out0 = uint64_to_bytes(lane0)
  let out1 = uint64_to_bytes(lane1)
  let out2 = uint64_to_bytes(lane2)
  let out3 = uint64_to_bytes(lane3)
  bytes_concat(bytes_concat(out0, out1), bytes_concat(out2, out3))
}

///|
/// FNV-1a helper with configurable seed.
fn fnv1a_seed(data : Bytes, seed : UInt64) -> UInt64 {
  let prime : UInt64 = 1099511628211UL
  let mut h = seed
  for i = 0; i < data.length(); i = i + 1 {
    h = h ^ data[i].to_uint64()
    h = h * prime
  }
  h
}

///|
/// Encode a UInt64 as 8 big-endian bytes.
fn uint64_to_bytes(v : UInt64) -> Bytes {
  let buf = FixedArray::make(8, b'\x00')
  buf[0] = ((v >> 56) & 0xFFUL).to_byte()
  buf[1] = ((v >> 48) & 0xFFUL).to_byte()
  buf[2] = ((v >> 40) & 0xFFUL).to_byte()
  buf[3] = ((v >> 32) & 0xFFUL).to_byte()
  buf[4] = ((v >> 24) & 0xFFUL).to_byte()
  buf[5] = ((v >> 16) & 0xFFUL).to_byte()
  buf[6] = ((v >> 8) & 0xFFUL).to_byte()
  buf[7] = (v & 0xFFUL).to_byte()
  Bytes::from_array(buf)
}

///|
/// Concatenate two Bytes values.
fn bytes_concat(a : Bytes, b : Bytes) -> Bytes {
  let buf = FixedArray::make(a.length() + b.length(), b'\x00')
  for i = 0; i < a.length(); i = i + 1 {
    buf[i] = a[i]
  }
  for i = 0; i < b.length(); i = i + 1 {
    buf[a.length() + i] = b[i]
  }
  Bytes::from_array(buf)
}

///|
/// Convert bytes to lowercase hex text.
fn bytes_to_hex(data : Bytes) -> String {
  let b = StringBuilder::new(size_hint=data.length() * 2)
  for i = 0; i < data.length(); i = i + 1 {
    let val = data[i].to_uint()
    let hi = val >> 4
    let lo = val & 0x0FU
    b.write_string(nibble_to_hex(hi))
    b.write_string(nibble_to_hex(lo))
  }
  b.to_string()
}

///|
fn nibble_to_hex(n : UInt) -> String {
  match n.reinterpret_as_int() {
    0 => "0"
    1 => "1"
    2 => "2"
    3 => "3"
    4 => "4"
    5 => "5"
    6 => "6"
    7 => "7"
    8 => "8"
    9 => "9"
    10 => "a"
    11 => "b"
    12 => "c"
    13 => "d"
    14 => "e"
    _ => "f"
  }
}
