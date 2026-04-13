///|
test "is_valid_digest rejects injection" {
  assert_true(is_valid_digest("sha256:abc"))
  assert_true(is_valid_digest("blake3:123.456_789-0"))
  assert_false(is_valid_digest("sha256:abc\"}"))
  assert_false(is_valid_digest("sha256:abc,"))
  assert_false(is_valid_digest("sha256:abc "))
  assert_false(is_valid_digest("sha256:abc\n"))
}
