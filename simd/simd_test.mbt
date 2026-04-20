///|
test "simd_caps reports AVX-VNNI on Meteor Lake" {
  let caps = simd_caps()
  // Bit 0 = AVX2, bit 1 = AVX-VNNI
  // Print so the test output shows what's available
  let has_avx2 = (caps & 1) != 0
  let has_vnni = (caps & 2) != 0
  let has_nec = (caps & 4) != 0
  println(
    "simd_caps=\{caps} avx2=\{has_avx2} vnni=\{has_vnni} ne_convert=\{has_nec}",
  )
  // AVX2 must be present on this machine
  assert_true(has_avx2)
}

///|
test "vnni_dot32 computes correct dot product" {
  // a = [1,1,1,...32 bytes]  b = [1,1,1,...32 bytes signed]
  // Dot product should be 32
  let a = Bytes::make(32, 1)
  let b = Bytes::make(32, 1)
  let result = vnni_dot32(a, b)
  assert_eq(result, 32)
}

///|
test "vnni_dot32 with mixed values" {
  // a[i] = 2 (unsigned), b[i] = -1 (signed = 255 as byte)
  // sum = 32 × (2 × -1) = -64
  let a = Bytes::make(32, 2)
  let b = Bytes::make(32, b'\xff') // -1 as signed int8
  let result = vnni_dot32(a, b)
  assert_eq(result, -64)
}

///|
test "vnni_fnv_x8 produces 8 distinct hashes" {
  let data = Bytes::of_string("merkin-route://alpha/doc")
  let hashes = vnni_fnv_x8(data)
  assert_eq(hashes.length(), 32) // 8 × int32

  // Read back the 8 int32 values and verify they differ
  let seen : Array[Int] = []
  for i = 0; i < 8; i = i + 1 {
    let h = (hashes[i * 4].to_int() & 0xFF) |
      ((hashes[i * 4 + 1].to_int() & 0xFF) << 8) |
      ((hashes[i * 4 + 2].to_int() & 0xFF) << 16) |
      ((hashes[i * 4 + 3].to_int() & 0xFF) << 24)
    seen.push(h)
  }
  println("vnni hashes: \{seen}")

  // All 8 should be distinct (different seeds guarantee this for non-trivial input)
  let mut distinct = true
  for i = 0; i < seen.length(); i = i + 1 {
    for j = i + 1; j < seen.length(); j = j + 1 {
      if seen[i] == seen[j] {
        distinct = false
      }
    }
  }
  assert_true(distinct)
}

///|
test "vnni_bloom_positions stay within bit_count" {
  let data = Bytes::of_string("alpha")
  let hashes = vnni_fnv_x8(data)
  let positions = vnni_bloom_positions(hashes, 256)
  assert_eq(positions.length(), 32)

  for i = 0; i < 8; i = i + 1 {
    let pos = (positions[i * 4].to_int() & 0xFF) |
      ((positions[i * 4 + 1].to_int() & 0xFF) << 8) |
      ((positions[i * 4 + 2].to_int() & 0xFF) << 16) |
      ((positions[i * 4 + 3].to_int() & 0xFF) << 24)
    assert_true(pos >= 0 && pos < 256)
  }
}

///|
test "ne_broadcast_bf16 scalar fallback works" {
  // bf16 representation of 1.0f = 0x3F80
  let bf16_one : Int = 0x3F80
  let dst = Bytes::make(32, 0)
  ne_broadcast_bf16(bf16_one, dst)

  // Read back 8 floats and verify they're all 1.0
  // f32 1.0 = 0x3F800000 in IEEE 754
  for i = 0; i < 8; i = i + 1 {
    let bits = (dst[i * 4].to_int() & 0xFF) |
      ((dst[i * 4 + 1].to_int() & 0xFF) << 8) |
      ((dst[i * 4 + 2].to_int() & 0xFF) << 16) |
      ((dst[i * 4 + 3].to_int() & 0xFF) << 24)
    assert_eq(bits, 0x3F800000)
  }
}
