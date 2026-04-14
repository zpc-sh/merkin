///|
/// Package-wide UTF-8 string encoder for hash and parser helpers.
fn string_to_bytes(text : String) -> Bytes {
  @utf8.encode(text)
}
