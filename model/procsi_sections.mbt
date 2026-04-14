///|
/// Attested procsi carrier for the `.pr1` custom section.
pub(all) struct ProcsiAttestedSectionV1 {
  attestation : GeniusProcsiAttestation
  context_hash : @hash.Hash
  policy_hash : @hash.Hash
} derive(Show)

///|
pub fn ProcsiAttestedSectionV1::new(
  attestation : GeniusProcsiAttestation,
  context_hash : @hash.Hash,
  policy_hash : @hash.Hash,
) -> ProcsiAttestedSectionV1 {
  { attestation, context_hash, policy_hash }
}

///|
pub fn ProcsiAttestedSectionV1::emit_pr1_payload(
  self : ProcsiAttestedSectionV1,
) -> Bytes {
  let out : Array[Byte] = []
  procsi_sec_write_bytes(out, b"PRC1")
  procsi_sec_write_string(
    out,
    match self.attestation.locus {
      Some(locus) => locus
      None => ""
    },
  )
  procsi_sec_write_string(out, self.attestation.project)
  procsi_sec_write_string(out, self.attestation.ratio_loci)
  procsi_sec_write_string(out, self.attestation.session_surface)
  procsi_sec_write_hash(out, self.attestation.fingerprint_commitment)
  procsi_sec_write_string(out, self.attestation.app_envelope.protocol)
  procsi_sec_write_string(out, self.attestation.app_envelope.audience)
  procsi_sec_write_string(out, self.attestation.app_envelope.ciphertext_ref)
  procsi_sec_write_hash(out, self.attestation.app_envelope.ciphertext_hash)
  procsi_sec_write_hash(out, self.context_hash)
  procsi_sec_write_hash(out, self.policy_hash)
  Bytes::from_array(out)
}

///|
pub fn ProcsiAttestedSectionV1::emit_pr1_custom_section(
  self : ProcsiAttestedSectionV1,
) -> Bytes {
  let payload = self.emit_pr1_payload()
  let named : Array[Byte] = []
  procsi_sec_write_leb_u32(named, 4U)
  procsi_sec_write_bytes(named, procsi_sec_utf8_string_to_bytes(".pr1"))
  procsi_sec_write_bytes(named, payload)
  let section : Array[Byte] = [b'\x00']
  procsi_sec_write_leb_u32(section, named.length().reinterpret_as_uint())
  procsi_sec_write_bytes(section, Bytes::from_array(named))
  Bytes::from_array(section)
}

///|
pub fn ProcsiAttestedSectionV1::parse_pr1_payload(
  payload : Bytes,
) -> ProcsiAttestedSectionV1? {
  let cursor : ProcsiSectionCursor = { bytes: payload, pos: 0 }
  match procsi_sec_read_exact_bytes(cursor, 4) {
    Some(magic) =>
      if procsi_sec_bytes_equal(magic, b"PRC1") {
        let locus = procsi_sec_read_string(cursor)
        let project = procsi_sec_read_string(cursor)
        let ratio_loci = procsi_sec_read_string(cursor)
        let session_surface = procsi_sec_read_string(cursor)
        let fingerprint_commitment = procsi_sec_read_hash(cursor)
        let app_protocol = procsi_sec_read_string(cursor)
        let app_audience = procsi_sec_read_string(cursor)
        let app_ref = procsi_sec_read_string(cursor)
        let app_payload_hash = procsi_sec_read_hash(cursor)
        let context_hash = procsi_sec_read_hash(cursor)
        let policy_hash = procsi_sec_read_hash(cursor)
        match
          (
            locus, project, ratio_loci, session_surface, fingerprint_commitment,
            app_protocol, app_audience, app_ref, app_payload_hash, context_hash,
            policy_hash,
          ) {
          (
            Some(locus_value),
            Some(project_value),
            Some(ratio_loci_value),
            Some(surface_value),
            Some(fingerprint_value),
            Some(protocol_value),
            Some(audience_value),
            Some(app_ref_value),
            Some(app_hash_value),
            Some(context_value),
            Some(policy_value),
          ) =>
            if cursor.pos != payload.length() ||
              project_value == "" ||
              ratio_loci_value == "" ||
              surface_value == "" ||
              protocol_value == "" ||
              audience_value == "" ||
              app_ref_value == "" {
              None
            } else {
              Some({
                attestation: {
                  locus: if locus_value == "" {
                    None
                  } else {
                    Some(locus_value)
                  },
                  project: project_value,
                  ratio_loci: ratio_loci_value,
                  session_surface: surface_value,
                  fingerprint_commitment: fingerprint_value,
                  app_envelope: {
                    protocol: protocol_value,
                    audience: audience_value,
                    ciphertext_ref: app_ref_value,
                    ciphertext_hash: app_hash_value,
                    masked_commitment: AppMaskEnvelope::new(
                      fingerprint_value, protocol_value, audience_value, app_ref_value,
                      app_hash_value,
                    ).masked_commitment,
                  },
                },
                context_hash: context_value,
                policy_hash: policy_value,
              })
            }
          _ => None
        }
      } else {
        None
      }
    None => None
  }
}

///|
pub fn ProcsiAttestedSectionV1::parse_pr1_custom_section(
  section_bytes : Bytes,
) -> ProcsiAttestedSectionV1? {
  let cursor : ProcsiSectionCursor = { bytes: section_bytes, pos: 0 }
  match procsi_sec_read_byte(cursor) {
    Some(section_id) => {
      if section_id != 0 {
        return None
      }
      match procsi_sec_read_leb_u32(cursor) {
        Some(section_len) => {
          let section_end = cursor.pos + section_len.reinterpret_as_int()
          if section_end > section_bytes.length() {
            return None
          }
          match procsi_sec_read_leb_u32(cursor) {
            Some(name_len) =>
              match
                procsi_sec_read_exact_bytes(
                  cursor,
                  name_len.reinterpret_as_int(),
                ) {
                Some(name_bytes) => {
                  if !procsi_sec_bytes_equal(
                      name_bytes,
                      procsi_sec_utf8_string_to_bytes(".pr1"),
                    ) {
                    return None
                  }
                  let payload_len = section_end - cursor.pos
                  match procsi_sec_read_exact_bytes(cursor, payload_len) {
                    Some(payload) =>
                      if cursor.pos == section_end &&
                        cursor.pos == section_bytes.length() {
                        ProcsiAttestedSectionV1::parse_pr1_payload(payload)
                      } else {
                        None
                      }
                    None => None
                  }
                }
                None => None
              }
            None => None
          }
        }
        None => None
      }
    }
    None => None
  }
}

///|
pub(all) struct ProcsiSectionCursor {
  bytes : Bytes
  mut pos : Int
}

///|
fn procsi_sec_read_byte(cursor : ProcsiSectionCursor) -> Byte? {
  if cursor.pos >= cursor.bytes.length() {
    None
  } else {
    let out = cursor.bytes[cursor.pos]
    cursor.pos = cursor.pos + 1
    Some(out)
  }
}

///|
fn procsi_sec_read_exact_bytes(
  cursor : ProcsiSectionCursor,
  count : Int,
) -> Bytes? {
  if count < 0 || cursor.pos + count > cursor.bytes.length() {
    return None
  }
  let out : Array[Byte] = []
  let mut i = 0
  while i < count {
    out.push(cursor.bytes[cursor.pos + i])
    i = i + 1
  }
  cursor.pos = cursor.pos + count
  Some(Bytes::from_array(out))
}

///|
fn procsi_sec_read_u32_le(cursor : ProcsiSectionCursor) -> UInt? {
  match procsi_sec_read_exact_bytes(cursor, 4) {
    Some(bytes) =>
      Some(
        bytes[0].to_uint() |
        (bytes[1].to_uint() << 8) |
        (bytes[2].to_uint() << 16) |
        (bytes[3].to_uint() << 24),
      )
    None => None
  }
}

///|
fn procsi_sec_read_string(cursor : ProcsiSectionCursor) -> String? {
  match procsi_sec_read_u32_le(cursor) {
    Some(length) =>
      match procsi_sec_read_exact_bytes(cursor, length.reinterpret_as_int()) {
        Some(bytes) => procsi_sec_utf8_bytes_to_string(bytes)
        None => None
      }
    None => None
  }
}

///|
fn procsi_sec_read_hash(cursor : ProcsiSectionCursor) -> @hash.Hash? {
  match procsi_sec_read_exact_bytes(cursor, 32) {
    Some(bytes) => Some({ alg: @hash.Blake3, digest: bytes })
    None => None
  }
}

///|
fn procsi_sec_read_leb_u32(cursor : ProcsiSectionCursor) -> UInt? {
  let mut shift = 0
  let mut out : UInt = 0U
  let mut count = 0
  while count < 5 {
    match procsi_sec_read_byte(cursor) {
      Some(byte) => {
        let value = byte.to_uint()
        out = out | ((value & 0x7FU) << shift)
        if (value & 0x80U) == 0U {
          return Some(out)
        }
        shift = shift + 7
        count = count + 1
      }
      None => return None
    }
  }
  None
}

///|
fn procsi_sec_write_bytes(out : Array[Byte], bytes : Bytes) -> Unit {
  for i = 0; i < bytes.length(); i = i + 1 {
    out.push(bytes[i])
  }
}

///|
fn procsi_sec_write_u32_le(out : Array[Byte], value : UInt) -> Unit {
  out.push((value & 0xFFU).to_byte())
  out.push(((value >> 8) & 0xFFU).to_byte())
  out.push(((value >> 16) & 0xFFU).to_byte())
  out.push(((value >> 24) & 0xFFU).to_byte())
}

///|
fn procsi_sec_write_string(out : Array[Byte], text : String) -> Unit {
  let bytes = procsi_sec_utf8_string_to_bytes(text)
  procsi_sec_write_u32_le(out, bytes.length().reinterpret_as_uint())
  procsi_sec_write_bytes(out, bytes)
}

///|
fn procsi_sec_write_hash(out : Array[Byte], hash : @hash.Hash) -> Unit {
  procsi_sec_write_bytes(out, hash.digest)
}

///|
fn procsi_sec_write_leb_u32(out : Array[Byte], value : UInt) -> Unit {
  let mut v = value
  while true {
    let mut byte = (v & 0x7FU).to_byte()
    v = v >> 7
    if v != 0U {
      byte = (byte.to_uint() | 0x80U).to_byte()
    }
    out.push(byte)
    if v == 0U {
      return
    }
  }
}

///|
fn procsi_sec_bytes_equal(left : Bytes, right : Bytes) -> Bool {
  if left.length() != right.length() {
    return false
  }
  let mut i = 0
  while i < left.length() {
    if left[i] != right[i] {
      return false
    }
    i = i + 1
  }
  true
}

///|
fn procsi_sec_utf8_string_to_bytes(text : String) -> Bytes {
  let out : Array[Byte] = []
  for ch in text {
    let cp = ch.to_uint()
    if cp < 0x80U {
      out.push(cp.to_byte())
    } else if cp < 0x800U {
      out.push((0xC0U | (cp >> 6)).to_byte())
      out.push((0x80U | (cp & 0x3FU)).to_byte())
    } else if cp < 0x10000U {
      out.push((0xE0U | (cp >> 12)).to_byte())
      out.push((0x80U | ((cp >> 6) & 0x3FU)).to_byte())
      out.push((0x80U | (cp & 0x3FU)).to_byte())
    } else {
      out.push((0xF0U | (cp >> 18)).to_byte())
      out.push((0x80U | ((cp >> 12) & 0x3FU)).to_byte())
      out.push((0x80U | ((cp >> 6) & 0x3FU)).to_byte())
      out.push((0x80U | (cp & 0x3FU)).to_byte())
    }
  }
  Bytes::from_array(out)
}

///|
fn procsi_sec_utf8_bytes_to_string(bytes : Bytes) -> String? {
  let b = StringBuilder::new(size_hint=bytes.length())
  let mut i = 0
  while i < bytes.length() {
    let b0 = bytes[i].to_uint()
    if (b0 & 0x80U) == 0U {
      b.write_char(b0.reinterpret_as_int().unsafe_to_char())
      i = i + 1
    } else if (b0 & 0xE0U) == 0xC0U {
      if i + 1 >= bytes.length() {
        return None
      }
      let b1 = bytes[i + 1].to_uint()
      let cp = ((b0 & 0x1FU) << 6) | (b1 & 0x3FU)
      b.write_char(cp.reinterpret_as_int().unsafe_to_char())
      i = i + 2
    } else if (b0 & 0xF0U) == 0xE0U {
      if i + 2 >= bytes.length() {
        return None
      }
      let b1 = bytes[i + 1].to_uint()
      let b2 = bytes[i + 2].to_uint()
      let cp = ((b0 & 0x0FU) << 12) | ((b1 & 0x3FU) << 6) | (b2 & 0x3FU)
      b.write_char(cp.reinterpret_as_int().unsafe_to_char())
      i = i + 3
    } else if (b0 & 0xF8U) == 0xF0U {
      if i + 3 >= bytes.length() {
        return None
      }
      let b1 = bytes[i + 1].to_uint()
      let b2 = bytes[i + 2].to_uint()
      let b3 = bytes[i + 3].to_uint()
      let cp = ((b0 & 0x07U) << 18) |
        ((b1 & 0x3FU) << 12) |
        ((b2 & 0x3FU) << 6) |
        (b3 & 0x3FU)
      b.write_char(cp.reinterpret_as_int().unsafe_to_char())
      i = i + 4
    } else {
      return None
    }
  }
  Some(b.to_string())
}
