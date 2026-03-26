test "string_to_bytes handles emojis without out of bounds panic" {
  let s = "hello 😊 world"
  let b = string_to_bytes(s)
  assert_eq!(b.length(), 13 * 4) // 13 code points
}
