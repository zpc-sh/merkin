///|
/// File-backed OCI registry — drop-in replacement for InMemoryOciRegistry.
///
/// Layout on disk:
///   <root>/
///     blobs/<digest>           raw blob bytes
///     tags/<repository>/<tag>  file containing digest string
///
/// This is OCI distribution spec compatible at the storage layer.
/// The same OciCasNode that works with InMemoryOciRegistry works with this.
pub(all) struct FileOciRegistry {
  root : String
  /// In-memory cache for hot path reads.
  blob_cache : Map[String, Bytes]
  tag_cache : Map[String, String]
}

///|
pub fn FileOciRegistry::new(root : String) -> FileOciRegistry {
  { root, blob_cache: {}, tag_cache: {} }
}

///|
pub fn FileOciRegistry::put_blob(
  self : FileOciRegistry,
  repository : String,
  payload : Bytes,
) -> String {
  let digest = @hash.Hash::of_bytes(payload).key()
  let key = repository + "|blob|" + digest
  // Write to disk
  let dir = self.root + "/blobs"
  fs_mkdir_p(dir)
  let path = dir + "/" + digest
  fs_write_file(path, payload)
  // Cache it
  self.blob_cache[key] = payload
  digest
}

///|
pub fn FileOciRegistry::has_blob(
  self : FileOciRegistry,
  repository : String,
  digest : String,
) -> Bool {
  let key = repository + "|blob|" + digest
  match self.blob_cache.get(key) {
    Some(_) => true
    None => {
      let path = self.root + "/blobs/" + digest
      let exists = fs_file_exists(path)
      exists
    }
  }
}

///|
pub fn FileOciRegistry::get_blob(
  self : FileOciRegistry,
  repository : String,
  digest : String,
) -> Bytes? {
  let key = repository + "|blob|" + digest
  match self.blob_cache.get(key) {
    Some(data) => Some(data)
    None => {
      let path = self.root + "/blobs/" + digest
      match fs_read_file(path) {
        Some(data) => {
          self.blob_cache[key] = data
          Some(data)
        }
        None => None
      }
    }
  }
}

///|
pub fn FileOciRegistry::put_tag(
  self : FileOciRegistry,
  repository : String,
  tag : String,
  digest : String,
) -> Unit {
  let key = repository + "|tag|" + tag
  // Write tag file — content is just the digest string
  let dir = self.root + "/tags/" + repository
  fs_mkdir_p(dir)
  let path = dir + "/" + tag
  fs_write_file(path, string_to_bytes_store(digest))
  // Cache it
  self.tag_cache[key] = digest
}

///|
pub fn FileOciRegistry::resolve_tag(
  self : FileOciRegistry,
  repository : String,
  tag : String,
) -> String? {
  let key = repository + "|tag|" + tag
  match self.tag_cache.get(key) {
    Some(digest) => Some(digest)
    None => {
      let path = self.root + "/tags/" + repository + "/" + tag
      match fs_read_file(path) {
        Some(data) => {
          let digest = bytes_to_string_store(data)
          self.tag_cache[key] = digest
          Some(digest)
        }
        None => None
      }
    }
  }
}

// --- Helpers ---

///|
fn string_to_bytes_store(s : String) -> Bytes {
  let chars : Array[Byte] = []
  for ch in s {
    let c = ch.to_uint()
    if c < 0x80U {
      chars.push(c.to_byte())
    }
  }
  Bytes::from_array(chars)
}

///|
fn bytes_to_string_store(data : Bytes) -> String {
  let b = StringBuilder::new(size_hint=data.length())
  for i = 0; i < data.length(); i = i + 1 {
    let byte = data[i].to_int()
    if byte == 0 || byte == 10 || byte == 13 { // null, LF, CR
      break
    }
    b.write_char(byte.unsafe_to_char())
  }
  b.to_string()
}
