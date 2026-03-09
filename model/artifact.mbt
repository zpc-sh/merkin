///|
/// PayloadRef describes where the artifact bytes live.
/// v0 only supports inline storage; future: S3, IPFS, etc.
pub(all) enum PayloadRef {
  Inline(Bytes)
} derive(Show)

///|
/// Artifact: content-addressed immutable bytes (§1.1).
/// Represents raw bytes with a content hash.
pub(all) struct Artifact {
  content_hash : @hash.Hash
  size_bytes : UInt64
  mime : String?
  payload_ref : PayloadRef
} derive(Show)

///|
/// Create an Artifact from raw bytes.
/// Computes content_hash = H(bytes).
pub fn Artifact::from_bytes(data : Bytes) -> Artifact {
  let h = @hash.Hash::of_bytes(data)
  {
    content_hash: h,
    size_bytes: data.length().to_uint64(),
    mime: None,
    payload_ref: Inline(data),
  }
}

///|
/// Create an Artifact from raw bytes with a MIME type.
pub fn Artifact::from_bytes_with_mime(data : Bytes, mime : String) -> Artifact {
  let h = @hash.Hash::of_bytes(data)
  {
    content_hash: h,
    size_bytes: data.length().to_uint64(),
    mime: Some(mime),
    payload_ref: Inline(data),
  }
}

///|
/// Verify that the artifact's content_hash matches its payload.
pub fn Artifact::verify(self : Artifact) -> Bool {
  match self.payload_ref {
    Inline(data) => {
      let recomputed = @hash.Hash::of_bytes(data)
      self.content_hash == recomputed
    }
  }
}
