///|
test "Hash::of_bytes determinism" {
  let data = b"\x01\x02\x03\x04"
  let h1 = @hash.Hash::of_bytes(data)
  let h2 = @hash.Hash::of_bytes(data)
  assert_eq(h1, h2)
  assert_eq(h1.alg, @hash.Blake3)
}

///|
test "Hash::of_bytes different inputs differ" {
  let h1 = @hash.Hash::of_bytes(b"\x01\x02\x03")
  let h2 = @hash.Hash::of_bytes(b"\x04\x05\x06")
  assert_true(h1 != h2)
}

///|
test "Hash digest length is 32 bytes (blake3 width)" {
  let h = @hash.Hash::of_bytes(b"\xAA\xBB")
  assert_eq(h.digest_len(), 32)
}

///|
test "Hash::semantic produces dual hash" {
  let content = @hash.Hash::of_bytes(b"\x01\x02")
  let header = b"\x10\x20\x30\x40\x50\x60\x70\x80"
  let sem = @hash.Hash::semantic(content, header)
  // semantic hash should differ from plain content hash
  assert_true(sem != content)
  // deterministic
  let sem2 = @hash.Hash::semantic(content, header)
  assert_eq(sem, sem2)
}

///|
test "Hash::matches" {
  let h = @hash.Hash::of_bytes(b"\xFF")
  assert_true(h.matches(h))
}

///|
test "Hash::key includes algorithm prefix" {
  let h = @hash.Hash::of_bytes(b"\x01")
  assert_true(h.key().contains("blake3:"))
}
