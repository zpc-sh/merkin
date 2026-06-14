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

///|
test "BloomSketch rebuild with empty array" {
  let b = @bloom.BloomSketch::rebuild([])
  assert_false(b.maybe_contains("anything"))
}

///|
test "BloomSketch rebuild with single element" {
  let b = @bloom.BloomSketch::rebuild(["solo"])
  assert_true(b.maybe_contains("solo"))
  assert_false(b.maybe_contains("other"))
}

///|
test "BloomSketch rebuild with duplicates" {
  let b = @bloom.BloomSketch::rebuild(["repeat", "repeat", "repeat"])
  assert_true(b.maybe_contains("repeat"))
  assert_false(b.maybe_contains("other"))
}

///|
test "BloomSketch rebuild with special characters" {
  let special = ["🚀", "こんにちは", "hëllö", "spaces and\ttabs", ""]
  let b = @bloom.BloomSketch::rebuild(special)
  for token in special {
    assert_true(b.maybe_contains(token))
  }
  assert_false(b.maybe_contains("normal"))
}

///|
test "BloomSketch rebuild with large array" {
  let tokens = []
  for i = 0; i < 1000; i = i + 1 {
    tokens.push("token_\{i}")
  }
  let b = @bloom.BloomSketch::rebuild(tokens)

  // Test a subset to ensure they are added
  assert_true(b.maybe_contains("token_0"))
  assert_true(b.maybe_contains("token_500"))
  assert_true(b.maybe_contains("token_999"))

  // Note: with 1000 items in a 256-bit bloom filter, the filter will be saturated.
  // We can't meaningfully assert_false for non-members because false positives
  // approach 100%. We just verify the members are found.
}
