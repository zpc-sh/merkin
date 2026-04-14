///|
/// In-memory OCI registry transport for tests and local daemon mode.
pub(all) struct InMemoryOciRegistry {
  blobs : Map[String, Bytes]
  tags : Map[String, String]
}

///|
pub fn InMemoryOciRegistry::new() -> InMemoryOciRegistry {
  { blobs: {}, tags: {} }
}

///|
fn blob_key(repository : String, digest : String) -> String {
  repository + "|blob|" + digest
}

///|
fn tag_key(repository : String, tag : String) -> String {
  repository + "|tag|" + tag
}

///|
pub fn InMemoryOciRegistry::put_blob(
  self : InMemoryOciRegistry,
  repository : String,
  payload : Bytes,
) -> String {
  let digest = @hash.Hash::of_bytes(payload).key()
  self.blobs[blob_key(repository, digest)] = payload
  digest
}

///|
pub fn InMemoryOciRegistry::has_blob(
  self : InMemoryOciRegistry,
  repository : String,
  digest : String,
) -> Bool {
  self.blobs.get(blob_key(repository, digest)) is Some(_)
}

///|
pub fn InMemoryOciRegistry::get_blob(
  self : InMemoryOciRegistry,
  repository : String,
  digest : String,
) -> Bytes? {
  self.blobs.get(blob_key(repository, digest))
}

///|
pub fn InMemoryOciRegistry::put_tag(
  self : InMemoryOciRegistry,
  repository : String,
  tag : String,
  digest : String,
) -> Unit {
  self.tags[tag_key(repository, tag)] = digest
}

///|
pub fn InMemoryOciRegistry::resolve_tag(
  self : InMemoryOciRegistry,
  repository : String,
  tag : String,
) -> String? {
  self.tags.get(tag_key(repository, tag))
}

///|
fn manifest_key(repository : String, digest : String) -> String {
  repository + "|manifest|" + digest
}

///|
/// Store an OCI manifest blob (JSON or binary).
pub fn InMemoryOciRegistry::put_manifest(
  self : InMemoryOciRegistry,
  repository : String,
  tag : String,
  manifest : Bytes,
) -> String {
  let digest = @hash.Hash::of_bytes(manifest).key()
  self.blobs[manifest_key(repository, digest)] = manifest
  self.tags[tag_key(repository, tag)] = digest
  digest
}

///|
/// Retrieve an OCI manifest by tag.
pub fn InMemoryOciRegistry::get_manifest(
  self : InMemoryOciRegistry,
  repository : String,
  tag : String,
) -> Bytes? {
  match self.resolve_tag(repository, tag) {
    Some(digest) => self.blobs.get(manifest_key(repository, digest))
    None => None
  }
}

///|
/// Retrieve an OCI manifest by digest.
pub fn InMemoryOciRegistry::get_manifest_by_digest(
  self : InMemoryOciRegistry,
  repository : String,
  digest : String,
) -> Bytes? {
  self.blobs.get(manifest_key(repository, digest))
}

///|
/// Store node backed by OCI-compatible registry behavior.
pub(all) struct OciCasNode {
  id : String
  mut status : Availability
  repository : String
  media_type : String
  tag_mode : OciTagMode
  mut epoch : UInt64
  registry : InMemoryOciRegistry
  digest_map : Map[String, String] // merkin key -> oci digest
}

///|
pub fn OciCasNode::new(
  id : String,
  repository : String,
  registry : InMemoryOciRegistry,
  media_type? : String = "application/vnd.merkin.artifact.v1+octet-stream",
  tag_mode? : OciTagMode = DigestOnly,
  epoch? : UInt64 = 0UL,
  status? : Availability = Online,
) -> OciCasNode {
  {
    id,
    status,
    repository,
    media_type,
    tag_mode,
    epoch,
    registry,
    digest_map: {},
  }
}

///|
pub fn OciCasNode::as_store_node(self : OciCasNode) -> &StoreNode {
  self as &StoreNode
}

///|
pub fn OciCasNode::set_availability(
  self : OciCasNode,
  status : Availability,
) -> Unit {
  self.status = status
}

///|
pub fn OciCasNode::set_epoch(self : OciCasNode, epoch : UInt64) -> Unit {
  self.epoch = epoch
}

///|
fn OciCasNode::resolve_oci_digest(
  self : OciCasNode,
  hash : @hash.Hash,
) -> String? {
  self.digest_map.get(hash.key())
}

///|
fn OciCasNode::maybe_publish_tag(
  self : OciCasNode,
  oci_digest : String,
) -> Unit {
  match self.tag_mode {
    DigestOnly => ()
    EpochTag =>
      self.registry.put_tag(
        self.repository,
        "epoch-" + self.epoch.to_string(),
        oci_digest,
      )
    LatestTag => self.registry.put_tag(self.repository, "latest", oci_digest)
  }
}

///|
fn OciCasNode::put_blob_inner(self : OciCasNode, bytes : Bytes) -> @hash.Hash {
  let digest = @hash.Hash::of_bytes(bytes)
  let oci_digest = self.registry.put_blob(self.repository, bytes)
  self.digest_map[digest.key()] = oci_digest
  self.maybe_publish_tag(oci_digest)
  digest
}

///|
fn OciCasNode::has_blob_inner(self : OciCasNode, digest : @hash.Hash) -> Bool {
  match self.resolve_oci_digest(digest) {
    Some(oci_digest) => self.registry.has_blob(self.repository, oci_digest)
    None => false
  }
}

///|
fn OciCasNode::get_blob_inner(self : OciCasNode, digest : @hash.Hash) -> Bytes? {
  match self.resolve_oci_digest(digest) {
    Some(oci_digest) => self.registry.get_blob(self.repository, oci_digest)
    None => None
  }
}

///|
pub fn OciCasNode::put_blob(self : OciCasNode, bytes : Bytes) -> @hash.Hash {
  self.put_blob_inner(bytes)
}

///|
pub fn OciCasNode::has_blob(self : OciCasNode, digest : @hash.Hash) -> Bool {
  self.has_blob_inner(digest)
}

///|
pub fn OciCasNode::get_blob(self : OciCasNode, digest : @hash.Hash) -> Bytes? {
  self.get_blob_inner(digest)
}

///|
impl StoreNode for OciCasNode with node_id(self : OciCasNode) -> String {
  self.id
}

///|
impl StoreNode for OciCasNode with role(_self : OciCasNode) -> StoreRole {
  Oci
}

///|
impl StoreNode for OciCasNode with availability(self : OciCasNode) -> Availability {
  self.status
}

///|
impl StoreNode for OciCasNode with has_blob(
  self : OciCasNode,
  digest : @hash.Hash,
) -> Bool {
  self.has_blob_inner(digest)
}

///|
impl StoreNode for OciCasNode with get_blob(
  self : OciCasNode,
  digest : @hash.Hash,
) -> Bytes? {
  self.get_blob_inner(digest)
}

///|
impl StoreNode for OciCasNode with put_blob(self : OciCasNode, bytes : Bytes) -> @hash.Hash {
  self.put_blob_inner(bytes)
}
