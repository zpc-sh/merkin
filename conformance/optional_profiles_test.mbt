///|
/// Optional profile placeholders.
/// These are intentionally skipped until runtime interfaces exist.
#skip("Semantic profile runtime hooks not implemented in this repository")
test "Optional Semantic: embedding generation profile" {
  assert_true(true)
}

///|
#skip("Proof profile runtime hooks not implemented in this repository")
test "Optional Proof: proof round-trip profile" {
  assert_true(true)
}

///|
#skip("Batch profile runtime hooks not implemented in this repository")
test "Optional Batch: ordered batch execution profile" {
  assert_true(true)
}

///|
#skip("Offload profile runtime hooks not implemented in this repository")
test "Optional Offload: accumulate/offload/execute profile" {
  assert_true(true)
}
