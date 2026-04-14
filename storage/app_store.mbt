///|
/// File-backed APP envelope store.
///
/// Layout on disk:
///   <root>/
///     blobs/<ciphertext-hash>     raw opaque payload bytes
///     refs/<ref-hash>.manifest    text manifest for ref/protocol/audience/hash
pub(all) struct FileAppEnvelopeStore {
  root : String
  ref_cache : Map[String, @model.AppEnvelopeRecord]
}

///|
pub fn FileAppEnvelopeStore::new(root : String) -> FileAppEnvelopeStore {
  { root, ref_cache: {} }
}

///|
pub fn FileAppEnvelopeStore::put(
  self : FileAppEnvelopeStore,
  record : @model.AppEnvelopeRecord,
) -> String {
  let ref_key = app_store_ref_key(record.ref_id)
  let blob_dir = self.root + "/blobs"
  let ref_dir = self.root + "/refs"
  fs_mkdir_p(blob_dir)
  fs_mkdir_p(ref_dir)
  let blob_path = blob_dir + "/" + record.ciphertext_hash.key()
  fs_write_file(blob_path, record.ciphertext)
  let manifest_path = ref_dir + "/" + ref_key + ".manifest"
  fs_write_file(manifest_path, app_store_manifest_bytes(record))
  self.ref_cache[record.ref_id] = record
  record.ref_id
}

///|
pub fn FileAppEnvelopeStore::resolve(
  self : FileAppEnvelopeStore,
  ref_id : String,
) -> @model.AppEnvelopeRecord? {
  match self.ref_cache.get(ref_id) {
    Some(record) => Some(record)
    None => {
      let manifest_path = self.root +
        "/refs/" +
        app_store_ref_key(ref_id) +
        ".manifest"
      match fs_read_file(manifest_path) {
        Some(manifest_bytes) =>
          match app_store_parse_manifest(manifest_bytes) {
            Some(manifest) =>
              if manifest.ref_id != ref_id {
                None
              } else {
                let blob_path = self.root +
                  "/blobs/" +
                  manifest.ciphertext_hash.key()
                match fs_read_file(blob_path) {
                  Some(ciphertext) => {
                    let record : @model.AppEnvelopeRecord = {
                      ref_id: manifest.ref_id,
                      protocol: manifest.protocol,
                      audience: manifest.audience,
                      ciphertext_hash: manifest.ciphertext_hash,
                      ciphertext,
                    }
                    self.ref_cache[ref_id] = record
                    Some(record)
                  }
                  None => None
                }
              }
            None => None
          }
        None => None
      }
    }
  }
}

///|
pub fn FileAppEnvelopeStore::has_ref(
  self : FileAppEnvelopeStore,
  ref_id : String,
) -> Bool {
  self.resolve(ref_id) is Some(_)
}

///|
pub(all) struct AppEnvelopeManifest {
  ref_id : String
  protocol : String
  audience : String
  ciphertext_hash : @hash.Hash
}

///|
fn app_store_ref_key(ref_id : String) -> String {
  @hash.Hash::of_bytes(app_store_utf8_string_to_bytes(ref_id)).key()
}

///|
fn app_store_manifest_bytes(record : @model.AppEnvelopeRecord) -> Bytes {
  let b = StringBuilder::new(size_hint=256)
  b.write_string("ref=")
  b.write_string(record.ref_id)
  b.write_char('\n')
  b.write_string("protocol=")
  b.write_string(record.protocol)
  b.write_char('\n')
  b.write_string("audience=")
  b.write_string(record.audience)
  b.write_char('\n')
  b.write_string("ciphertext_hash=")
  b.write_string(record.ciphertext_hash.key())
  b.write_char('\n')
  app_store_utf8_string_to_bytes(b.to_string())
}

///|
fn app_store_parse_manifest(bytes : Bytes) -> AppEnvelopeManifest? {
  let content = app_store_utf8_bytes_to_string(bytes)
  let ref_id = app_store_extract_line(content, "ref=")
  let protocol = app_store_extract_line(content, "protocol=")
  let audience = app_store_extract_line(content, "audience=")
  let ciphertext_hash = app_store_extract_line(content, "ciphertext_hash=")
  if ref_id == "" || protocol == "" || audience == "" || ciphertext_hash == "" {
    return None
  }
  match app_store_parse_hash_key(ciphertext_hash) {
    Some(hash) => Some({ ref_id, protocol, audience, ciphertext_hash: hash })
    None => None
  }
}

///|
fn app_store_extract_line(content : String, prefix : String) -> String {
  let lines = app_store_split_lines(content)
  for line in lines {
    if app_store_line_starts_with(line, prefix) {
      return app_store_substring(
        line,
        app_store_string_length(prefix),
        app_store_string_length(line),
      )
    }
  }
  ""
}

///|
fn app_store_parse_hash_key(token : String) -> @hash.Hash? {
  let colon = app_store_find_char(token, ':')
  if colon < 0 {
    return None
  }
  let alg = app_store_substring(token, 0, colon)
  let hex = app_store_substring(
    token,
    colon + 1,
    app_store_string_length(token),
  )
  match app_store_hex_to_bytes(hex) {
    Some(digest) =>
      Some({
        alg: if alg == "fnv1a" {
          @hash.Fnv1a
        } else {
          @hash.Blake3
        },
        digest,
      })
    None => None
  }
}

///|
fn app_store_utf8_string_to_bytes(text : String) -> Bytes {
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
fn app_store_utf8_bytes_to_string(bytes : Bytes) -> String {
  let b = StringBuilder::new(size_hint=bytes.length())
  let mut i = 0
  while i < bytes.length() {
    let b0 = bytes[i].to_uint()
    if (b0 & 0x80U) == 0U {
      b.write_char(b0.reinterpret_as_int().unsafe_to_char())
      i = i + 1
    } else if (b0 & 0xE0U) == 0xC0U && i + 1 < bytes.length() {
      let b1 = bytes[i + 1].to_uint()
      let cp = ((b0 & 0x1FU) << 6) | (b1 & 0x3FU)
      b.write_char(cp.reinterpret_as_int().unsafe_to_char())
      i = i + 2
    } else if (b0 & 0xF0U) == 0xE0U && i + 2 < bytes.length() {
      let b1 = bytes[i + 1].to_uint()
      let b2 = bytes[i + 2].to_uint()
      let cp = ((b0 & 0x0FU) << 12) | ((b1 & 0x3FU) << 6) | (b2 & 0x3FU)
      b.write_char(cp.reinterpret_as_int().unsafe_to_char())
      i = i + 3
    } else if (b0 & 0xF8U) == 0xF0U && i + 3 < bytes.length() {
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
      i = i + 1
    }
  }
  b.to_string()
}

///|
fn app_store_hex_to_bytes(hex : String) -> Bytes? {
  if app_store_string_length(hex) % 2 != 0 {
    return None
  }
  let out : Array[Byte] = []
  let chars : Array[Char] = []
  for ch in hex {
    chars.push(ch)
  }
  let mut i = 0
  while i < chars.length() {
    match app_store_hex_nibble(chars[i]) {
      Some(hi) =>
        match app_store_hex_nibble(chars[i + 1]) {
          Some(lo) => {
            out.push(((hi << 4) | lo).to_byte())
            i = i + 2
          }
          None => return None
        }
      None => return None
    }
  }
  Some(Bytes::from_array(out))
}

///|
fn app_store_hex_nibble(ch : Char) -> UInt? {
  let value = ch.to_uint()
  if value >= '0'.to_uint() && value <= '9'.to_uint() {
    Some(value - '0'.to_uint())
  } else if value >= 'a'.to_uint() && value <= 'f'.to_uint() {
    Some(value - 'a'.to_uint() + 10U)
  } else if value >= 'A'.to_uint() && value <= 'F'.to_uint() {
    Some(value - 'A'.to_uint() + 10U)
  } else {
    None
  }
}

///|
fn app_store_split_lines(text : String) -> Array[String] {
  let lines : Array[String] = []
  let cur = StringBuilder::new(size_hint=64)
  for ch in text {
    if ch == '\n' {
      lines.push(cur.to_string())
      cur.reset()
    } else if ch != '\r' {
      cur.write_char(ch)
    }
  }
  let last = cur.to_string()
  if last != "" {
    lines.push(last)
  }
  lines
}

///|
fn app_store_line_starts_with(line : String, prefix : String) -> Bool {
  if app_store_string_length(prefix) > app_store_string_length(line) {
    return false
  }
  let mut idx = 0
  let pchars : Array[Char] = []
  let lchars : Array[Char] = []
  for ch in prefix {
    pchars.push(ch)
  }
  for ch in line {
    lchars.push(ch)
  }
  while idx < pchars.length() {
    if pchars[idx] != lchars[idx] {
      return false
    }
    idx = idx + 1
  }
  true
}

///|
fn app_store_substring(text : String, start : Int, end_ : Int) -> String {
  let b = StringBuilder::new(size_hint=end_ - start)
  let mut idx = 0
  for ch in text {
    if idx >= start && idx < end_ {
      b.write_char(ch)
    }
    idx = idx + 1
  }
  b.to_string()
}

///|
fn app_store_string_length(text : String) -> Int {
  let mut len = 0
  for _ch in text {
    len = len + 1
  }
  len
}

///|
fn app_store_find_char(text : String, needle : Char) -> Int {
  let mut idx = 0
  for ch in text {
    if ch == needle {
      return idx
    }
    idx = idx + 1
  }
  -1
}
