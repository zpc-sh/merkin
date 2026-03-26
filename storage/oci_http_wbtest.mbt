
test "oci_http_string_to_bytes handles emojis without out of bounds panic" {
  let s = "hello 😊 world"
  let b = oci_http_string_to_bytes(s)
  // Each ascii char is 4 bytes in the UTF-32 big endian encoding
  // Emojis are outside BMP, they use 1 code point but take 2 code units in UTF-16
  // This test passes if it does not panic.
  assert_eq!(b.length(), 13 * 4) // 5 + 1 + 1 + 1 + 5 = 13 code points
}
