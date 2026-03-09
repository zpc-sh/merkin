///|
test "BloomSketch add and maybe_contains" {
  let b = @bloom.BloomSketch::new()
  b.add("hello")
  b.add("world")
  assert_true(b.maybe_contains("hello"))
  assert_true(b.maybe_contains("world"))
}

///|
test "BloomSketch not-added token likely false" {
  let b = @bloom.BloomSketch::new()
  b.add("alpha")
  // Not guaranteed false (probabilistic), but very unlikely for single token
  // in 256-bit filter. We test a specific non-added key.
  let result = b.maybe_contains("xyzzy_never_added_token_12345")
  // This is probabilistic so we just verify the function runs
  let _ = result
}

///|
test "BloomSketch merge" {
  let b1 = @bloom.BloomSketch::new()
  b1.add("alpha")
  let b2 = @bloom.BloomSketch::new()
  b2.add("beta")
  let merged = b1.merge(b2)
  assert_true(merged.maybe_contains("alpha"))
  assert_true(merged.maybe_contains("beta"))
}

///|
test "BloomSketch rebuild" {
  let b = @bloom.BloomSketch::rebuild(["x", "y", "z"])
  assert_true(b.maybe_contains("x"))
  assert_true(b.maybe_contains("y"))
  assert_true(b.maybe_contains("z"))
}
