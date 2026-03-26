///|
/// Minimal HTTP request representation for OCI registry calls.
pub(all) struct HttpRequest {
  http_method : String
  url : String
  headers : Map[String, String]
  body : Bytes?
} derive(Show)

///|
pub(all) struct HttpResponse {
  status : UInt
  headers : Map[String, String]
  body : Bytes?
} derive(Show)

///|
/// Pluggable round-tripper so runtime can use real HTTP implementation later.
pub(open) trait RegistryRoundTripper {
  round_trip(Self, HttpRequest) -> HttpResponse
}

///|
/// OCI Registry API transport over generic HTTP round-tripper.
pub(all) struct OciRegistryHttpTransport {
  base_url : String
  repository : String
  client : &RegistryRoundTripper
  tag_digest_cache : Map[String, String]
}

///|
pub fn OciRegistryHttpTransport::new(
  base_url : String,
  repository : String,
  client : &RegistryRoundTripper,
) -> OciRegistryHttpTransport {
  { base_url, repository, client, tag_digest_cache: {} }
}

///|
fn ensure_no_trailing_slash(url : String) -> String {
  if url.length() == 0 || url[url.length() - 1] != '/' {
    url
  } else {
    // Optimization: Use string slicing instead of O(n^2) loop concatenation
    url[:url.length() - 1].to_string()
  }
}

///|
fn OciRegistryHttpTransport::v2_repo_base(
  self : OciRegistryHttpTransport,
) -> String {
  ensure_no_trailing_slash(self.base_url) + "/v2/" + self.repository
}

///|
fn OciRegistryHttpTransport::blob_url(
  self : OciRegistryHttpTransport,
  digest : String,
) -> String {
  self.v2_repo_base() + "/blobs/" + digest
}

///|
fn OciRegistryHttpTransport::upload_start_url(
  self : OciRegistryHttpTransport,
) -> String {
  self.v2_repo_base() + "/blobs/uploads/"
}

///|
fn OciRegistryHttpTransport::manifest_url(
  self : OciRegistryHttpTransport,
  reference : String,
) -> String {
  self.v2_repo_base() + "/manifests/" + reference
}

///|
pub fn OciRegistryHttpTransport::put_blob(
  self : OciRegistryHttpTransport,
  payload : Bytes,
) -> String {
  let digest = @hash.Hash::of_bytes(payload).key()

  let start = self.client.round_trip({
    http_method: "POST",
    url: self.upload_start_url(),
    headers: {},
    body: None,
  })
  if start.status != 202U {
    abort("OCI upload start failed")
  }

  let location = match start.headers.get("Location") {
    Some(url) => url
    None => self.upload_start_url() + "session"
  }

  let separator = if location.contains("?") { "&" } else { "?" }
  let finalize_url = location + separator + "digest=" + digest
  let finalize = self.client.round_trip({
    http_method: "PUT",
    url: finalize_url,
    headers: { "Content-Type": "application/octet-stream" },
    body: Some(payload),
  })
  if finalize.status != 201U && finalize.status != 202U {
    abort("OCI upload finalize failed")
  }

  digest
}

///|
pub fn OciRegistryHttpTransport::has_blob(
  self : OciRegistryHttpTransport,
  digest : String,
) -> Bool {
  let resp = self.client.round_trip({
    http_method: "HEAD",
    url: self.blob_url(digest),
    headers: {},
    body: None,
  })
  resp.status == 200U
}

///|
pub fn OciRegistryHttpTransport::get_blob(
  self : OciRegistryHttpTransport,
  digest : String,
) -> Bytes? {
  let resp = self.client.round_trip({
    http_method: "GET",
    url: self.blob_url(digest),
    headers: {},
    body: None,
  })
  if resp.status == 200U {
    resp.body
  } else {
    None
  }
}

///|
pub fn OciRegistryHttpTransport::put_tag(
  self : OciRegistryHttpTransport,
  tag : String,
  digest : String,
) -> Unit {
  let body = oci_http_string_to_bytes(
    "{\"mediaType\":\"application/vnd.oci.image.manifest.v1+json\",\"config\":{\"digest\":\"" +
    digest +
    "\"}}",
  )
  let resp = self.client.round_trip({
    http_method: "PUT",
    url: self.manifest_url(tag),
    headers: { "Content-Type": "application/vnd.oci.image.manifest.v1+json" },
    body: Some(body),
  })
  if resp.status == 200U || resp.status == 201U || resp.status == 202U {
    self.tag_digest_cache[tag] = digest
    return
  }
  abort("OCI put tag failed")
}

///|
pub fn OciRegistryHttpTransport::resolve_tag(
  self : OciRegistryHttpTransport,
  tag : String,
) -> String? {
  let resp = self.client.round_trip({
    http_method: "GET",
    url: self.manifest_url(tag),
    headers: { "Accept": "application/vnd.oci.image.manifest.v1+json" },
    body: None,
  })
  if resp.status == 200U {
    match resp.headers.get("Docker-Content-Digest") {
      Some(digest) => Some(digest)
      None => self.tag_digest_cache.get(tag)
    }
  } else {
    None
  }
}

///|
/// Store node backed by OCI registry HTTP transport.
pub(all) struct OciHttpCasNode {
  id : String
  mut status : Availability
  tag_mode : OciTagMode
  mut epoch : UInt64
  transport : OciRegistryHttpTransport
  digest_map : Map[String, String] // merkin key -> oci digest
}

///|
pub fn OciHttpCasNode::new(
  id : String,
  transport : OciRegistryHttpTransport,
  tag_mode? : OciTagMode = DigestOnly,
  epoch? : UInt64 = 0UL,
  status? : Availability = Online,
) -> OciHttpCasNode {
  { id, status, tag_mode, epoch, transport, digest_map: {} }
}

///|
pub fn OciHttpCasNode::as_store_node(self : OciHttpCasNode) -> &StoreNode {
  self as &StoreNode
}

///|
pub fn OciHttpCasNode::set_availability(
  self : OciHttpCasNode,
  status : Availability,
) -> Unit {
  self.status = status
}

///|
fn OciHttpCasNode::publish_tag(self : OciHttpCasNode, digest : String) -> Unit {
  match self.tag_mode {
    DigestOnly => ()
    EpochTag =>
      self.transport.put_tag("epoch-" + self.epoch.to_string(), digest)
    LatestTag => self.transport.put_tag("latest", digest)
  }
}

///|
fn OciHttpCasNode::put_blob_inner(
  self : OciHttpCasNode,
  bytes : Bytes,
) -> @hash.Hash {
  let digest = @hash.Hash::of_bytes(bytes)
  let oci_digest = self.transport.put_blob(bytes)
  self.digest_map[digest.key()] = oci_digest
  self.publish_tag(oci_digest)
  digest
}

///|
fn OciHttpCasNode::has_blob_inner(
  self : OciHttpCasNode,
  digest : @hash.Hash,
) -> Bool {
  match self.digest_map.get(digest.key()) {
    Some(oci_digest) => self.transport.has_blob(oci_digest)
    None => false
  }
}

///|
fn OciHttpCasNode::get_blob_inner(
  self : OciHttpCasNode,
  digest : @hash.Hash,
) -> Bytes? {
  match self.digest_map.get(digest.key()) {
    Some(oci_digest) => self.transport.get_blob(oci_digest)
    None => None
  }
}

///|
pub fn OciHttpCasNode::put_blob(
  self : OciHttpCasNode,
  bytes : Bytes,
) -> @hash.Hash {
  self.put_blob_inner(bytes)
}

///|
pub fn OciHttpCasNode::has_blob(
  self : OciHttpCasNode,
  digest : @hash.Hash,
) -> Bool {
  self.has_blob_inner(digest)
}

///|
pub fn OciHttpCasNode::get_blob(
  self : OciHttpCasNode,
  digest : @hash.Hash,
) -> Bytes? {
  self.get_blob_inner(digest)
}

///|
impl StoreNode for OciHttpCasNode with node_id(self : OciHttpCasNode) -> String {
  self.id
}

///|
impl StoreNode for OciHttpCasNode with role(_self : OciHttpCasNode) -> StoreRole {
  Oci
}

///|
impl StoreNode for OciHttpCasNode with availability(self : OciHttpCasNode) -> Availability {
  self.status
}

///|
impl StoreNode for OciHttpCasNode with has_blob(
  self : OciHttpCasNode,
  digest : @hash.Hash,
) -> Bool {
  self.has_blob_inner(digest)
}

///|
impl StoreNode for OciHttpCasNode with get_blob(
  self : OciHttpCasNode,
  digest : @hash.Hash,
) -> Bytes? {
  self.get_blob_inner(digest)
}

///|
impl StoreNode for OciHttpCasNode with put_blob(
  self : OciHttpCasNode,
  bytes : Bytes,
) -> @hash.Hash {
  self.put_blob_inner(bytes)
}

///|
fn oci_http_string_to_bytes(s : String) -> Bytes {
  let total = s.length() * 4
  let buf = FixedArray::make(total, b'\x00')
  let mut pos = 0
  for ch in s {
    let code = ch.to_uint()
    buf[pos] = ((code >> 24) & 0xFFU).to_byte()
    buf[pos + 1] = ((code >> 16) & 0xFFU).to_byte()
    buf[pos + 2] = ((code >> 8) & 0xFFU).to_byte()
    buf[pos + 3] = (code & 0xFFU).to_byte()
    pos = pos + 4
  }
  Bytes::from_array(buf)
}
