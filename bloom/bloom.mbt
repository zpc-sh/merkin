///|
/// BloomSketch: bit-array Bloom filter for membership-ish routing (§3.2).
/// Used for machine pruning — "maybe contains token/object/feature".
pub(all) struct BloomSketch {
  bits : FixedArray[Bool]
  num_hashes : Int
} derive(Debug)

///|
/// Default BloomSketch size (bits) for v0.
let default_size : Int = 256

///|
/// Default number of hash functions for v0.
let default_num_hashes : Int = 3

///|
/// Create a new empty BloomSketch with default parameters.
pub fn BloomSketch::new() -> BloomSketch {
  {
    bits: FixedArray::make(default_size, false),
    num_hashes: default_num_hashes,
  }
}

///|
/// Create a BloomSketch with custom size and hash count.
pub fn BloomSketch::with_params(size : Int, num_hashes : Int) -> BloomSketch {
  { bits: FixedArray::make(size, false), num_hashes }
}

///|
/// Compute hash positions for a token using FNV-1a with seed mixing.
fn bloom_positions(token : String, size : Int, num_hashes : Int) -> Array[Int] {
  let positions : Array[Int] = []
  // Hash each character code point directly — simple, deterministic
  for k = 0; k < num_hashes; k = k + 1 {
    let offset_basis : UInt64 = 14695981039346656037UL
    let prime : UInt64 = 1099511628211UL
    let mut h = offset_basis ^ k.to_uint64()
    for ch in token {
      h = h ^ ch.to_uint().to_uint64()
      h = h * prime
    }
    let pos = (h % size.to_uint64()).to_int()
    positions.push(pos)
  }
  positions
}

///|
/// Add a token to the BloomSketch.
pub fn BloomSketch::add(self : BloomSketch, token : String) -> Unit {
  let positions = bloom_positions(token, self.bits.length(), self.num_hashes)
  for pos in positions {
    self.bits[pos] = true
  }
}

///|
/// Test if a token might be in the BloomSketch (probabilistic).
pub fn BloomSketch::maybe_contains(self : BloomSketch, token : String) -> Bool {
  let positions = bloom_positions(token, self.bits.length(), self.num_hashes)
  for pos in positions {
    if !self.bits[pos] {
      return false
    }
  }
  true
}

///|
/// Merge two BloomSketches (OR of bit arrays).
/// Both must have the same size and hash count.
pub fn BloomSketch::merge(
  self : BloomSketch,
  other : BloomSketch,
) -> BloomSketch {
  let size = self.bits.length()
  let merged = FixedArray::make(size, false)
  for i = 0; i < size; i = i + 1 {
    merged[i] = self.bits[i] || other.bits[i]
  }
  { bits: merged, num_hashes: self.num_hashes }
}

///|
/// Rebuild a BloomSketch from scratch with the given tokens.
/// Used during seal-time consolidation.
pub fn BloomSketch::rebuild(tokens : Array[String]) -> BloomSketch {
  let sketch = BloomSketch::new()
  for token in tokens {
    sketch.add(token)
  }
  sketch
}
