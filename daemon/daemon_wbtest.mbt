///|
test "daemon_string_to_bytes safe alloc limit" {
  let small_str = "a"
  let bytes = daemon_string_to_bytes(small_str)
  assert_eq(bytes.length(), 4)
}
