///|
/// Freshness states for envelopes and nodes (§1.2, §3.4).
pub(all) enum Freshness {
  FRESH
  DIRTY
  DEFERRED
  SEALED
} derive(Eq, Show)

///|
/// Header encoding discriminated by length (Appendix A).
pub(all) enum HeaderEncoding {
  ArbyteGrin // len == 8
  ChainCoda // len != 8
} derive(Eq, Show)

///|
/// State attached to an Envelope.
pub(all) struct EnvelopeState {
  freshness : Freshness
  semantic_committed : Bool
} derive(Eq, Show)

///|
/// Envelope: metadata + semantics + execution promises (§1.2).
/// Wraps an Artifact with semantic meaning, policy refs, and lifecycle state.
pub(all) struct Envelope {
  envelope_id : @hash.Hash
  artifact_hash : @hash.Hash
  semantic_header : Array[String]
  header_encoding : HeaderEncoding
  semantic_hash : @hash.Hash?
  policy_ids : Array[@hash.Hash]
  lens_ids : Array[@hash.Hash]
  anchors : Array[@hash.Hash]
  provenance : String?
  work_refs : Array[@hash.Hash]
  state : EnvelopeState
} derive(Show)

///|
/// Discriminate header encoding by length per Appendix A.
fn discriminate_encoding(header : Array[String]) -> HeaderEncoding {
  if header.length() == 8 {
    ArbyteGrin
  } else {
    ChainCoda
  }
}

///|
/// Serialize a semantic header to canonical bytes for hashing.
/// v0: concatenate symbol code points separated by null byte.
fn header_to_bytes(header : Array[String]) -> Bytes {
  // First pass: compute total length needed
  let mut total = 0
  for i, sym in header {
    if i > 0 {
      total = total + 1 // null separator
    }
    total = total + sym.length() * 4 // UCS-4 encoding (4 bytes per char)
  }
  // Second pass: fill buffer
  let buf = FixedArray::make(total, b'\x00')
  let mut pos = 0
  for i, sym in header {
    if i > 0 {
      buf[pos] = b'\x00'
      pos = pos + 1
    }
    for ch in sym {
      let code = ch.to_uint()
      buf[pos] = ((code >> 24) & 0xFFU).to_byte()
      buf[pos + 1] = ((code >> 16) & 0xFFU).to_byte()
      buf[pos + 2] = ((code >> 8) & 0xFFU).to_byte()
      buf[pos + 3] = (code & 0xFFU).to_byte()
      pos = pos + 4
    }
  }
  Bytes::from_array(buf)
}

///|
/// Create a new Envelope from an artifact hash and semantic header.
/// Auto-discriminates encoding by header length.
/// Starts in FRESH state without semantic hash.
pub fn Envelope::new(
  artifact_hash : @hash.Hash,
  semantic_header : Array[String],
) -> Envelope {
  let encoding = discriminate_encoding(semantic_header)
  let header_bytes = header_to_bytes(semantic_header)
  // envelope_id = H(artifact_hash.digest ++ header_bytes)
  let envelope_id = @hash.Hash::semantic(artifact_hash, header_bytes)
  {
    envelope_id,
    artifact_hash,
    semantic_header,
    header_encoding: encoding,
    semantic_hash: None,
    policy_ids: [],
    lens_ids: [],
    anchors: [],
    provenance: None,
    work_refs: [],
    state: { freshness: FRESH, semantic_committed: false },
  }
}

///|
/// Compute and commit the semantic hash (Option C dual hash).
/// semantic_hash = H(content_hash || canonical(semantic_header))
pub fn Envelope::commit_semantic(self : Envelope) -> Envelope {
  if self.state.freshness == SEALED {
    // Sealed envelopes are immutable; semantic commitment must happen pre-seal.
    return self
  }
  let header_bytes = header_to_bytes(self.semantic_header)
  let sem = @hash.Hash::semantic(self.artifact_hash, header_bytes)
  {
    ..self,
    semantic_hash: Some(sem),
    state: { freshness: self.state.freshness, semantic_committed: true },
  }
}

///|
/// Seal the envelope. Once sealed, no further mutation is allowed.
/// Returns new sealed envelope.
pub fn Envelope::seal(self : Envelope) -> Envelope {
  {
    ..self,
    state: {
      freshness: SEALED,
      semantic_committed: self.state.semantic_committed,
    },
  }
}

///|
/// Returns the preferred subject hash for anchoring:
/// semantic_hash if present, else artifact (content) hash.
pub fn Envelope::subject_hash(self : Envelope) -> @hash.Hash {
  match self.semantic_hash {
    Some(h) => h
    None => self.artifact_hash
  }
}

///|
/// Check whether this envelope is sealed.
pub fn Envelope::is_sealed(self : Envelope) -> Bool {
  self.state.freshness == SEALED
}
