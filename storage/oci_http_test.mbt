///|
pub(all) struct FakeRoundTripper {
  requests : Array[@storage.HttpRequest]
  blobs : Map[String, Bytes]
  tag_to_digest : Map[String, String]
}

///|
pub fn FakeRoundTripper::new() -> FakeRoundTripper {
  { requests: [], blobs: {}, tag_to_digest: {} }
}

///|
fn find_substring(haystack : String, needle : String) -> Int? {
  if needle.length() == 0 {
    return Some(0)
  }
  if needle.length() > haystack.length() {
    return None
  }
  let last = haystack.length() - needle.length()
  for i = 0; i <= last; i = i + 1 {
    let mut ok = true
    for j = 0; j < needle.length(); j = j + 1 {
      if haystack[i + j] != needle[j] {
        ok = false
        break
      }
    }
    if ok {
      return Some(i)
    }
  }
  None
}

///|
fn parse_digest_from_url(url : String) -> String? {
  let marker = "digest="
  let idx = find_substring(url, marker)
  if idx is None {
    return None
  }
  let start = idx.unwrap() + marker.length()
  Some(url[start:].to_string())
}

///|
fn parse_tag_from_url(url : String) -> String? {
  let marker = "/manifests/"
  let idx = find_substring(url, marker)
  if idx is None {
    return None
  }
  let start = idx.unwrap() + marker.length()
  Some(url[start:].to_string())
}

///|
impl @storage.RegistryRoundTripper for FakeRoundTripper with round_trip(
  self : FakeRoundTripper,
  req : @storage.HttpRequest,
) -> @storage.HttpResponse {
  self.requests.push(req)

  match req.http_method {
    "POST" => {
      if req.url.contains("/blobs/uploads/") {
        return {
          status: 202U,
          headers: { "Location": "https://registry.test/upload/session-1" },
          body: None,
        }
      }
      { status: 404U, headers: {}, body: None }
    }
    "PUT" => {
      if req.url.contains("/upload/session-") {
        match parse_digest_from_url(req.url) {
          Some(digest) => {
            match req.body {
              Some(payload) => self.blobs[digest] = payload
              None => ()
            }
            return { status: 201U, headers: {}, body: None }
          }
          None => return { status: 400U, headers: {}, body: None }
        }
      }
      if req.url.contains("/manifests/") {
        match parse_tag_from_url(req.url) {
          Some(tag) => {
            self.tag_to_digest[tag] = "blake3:manifest-digest"
            return {
              status: 201U,
              headers: { "Docker-Content-Digest": "blake3:manifest-digest" },
              body: None,
            }
          }
          None => return { status: 400U, headers: {}, body: None }
        }
      }
      { status: 404U, headers: {}, body: None }
    }
    "HEAD" => {
      let marker = "/blobs/"
      match find_substring(req.url, marker) {
        Some(idx) => {
          let digest = req.url[idx + marker.length():].to_string()
          if self.blobs.get(digest) is Some(_) {
            { status: 200U, headers: {}, body: None }
          } else {
            { status: 404U, headers: {}, body: None }
          }
        }
        None => { status: 404U, headers: {}, body: None }
      }
    }
    "GET" =>
      if req.url.contains("/blobs/") {
        let marker = "/blobs/"
        match find_substring(req.url, marker) {
          Some(idx) => {
            let digest = req.url[idx + marker.length():].to_string()
            match self.blobs.get(digest) {
              Some(payload) =>
                { status: 200U, headers: {}, body: Some(payload) }
              None => { status: 404U, headers: {}, body: None }
            }
          }
          None => { status: 404U, headers: {}, body: None }
        }
      } else if req.url.contains("/manifests/") {
        match parse_tag_from_url(req.url) {
          Some(tag) =>
            match self.tag_to_digest.get(tag) {
              Some(digest) =>
                {
                  status: 200U,
                  headers: { "Docker-Content-Digest": digest },
                  body: Some(b"{}"),
                }
              None => { status: 404U, headers: {}, body: None }
            }
          None => { status: 404U, headers: {}, body: None }
        }
      } else {
        { status: 404U, headers: {}, body: None }
      }
    _ => { status: 405U, headers: {}, body: None }
  }
}

///|
test "OciRegistryHttpTransport put/get/has blob" {
  let client = FakeRoundTripper::new()
  let transport = @storage.OciRegistryHttpTransport::new(
    "https://registry.test",
    "merkin/repo",
    client as &@storage.RegistryRoundTripper,
  )

  let payload = b"http-blob"
  let digest = transport.put_blob(payload)
  assert_true(transport.has_blob(digest))
  match transport.get_blob(digest) {
    Some(bytes) => assert_eq(bytes, payload)
    None => assert_true(false)
  }
}

///|
test "OciRegistryHttpTransport tag operations" {
  let client = FakeRoundTripper::new()
  let transport = @storage.OciRegistryHttpTransport::new(
    "https://registry.test",
    "merkin/repo",
    client as &@storage.RegistryRoundTripper,
  )

  transport.put_tag("latest", "blake3:abc123")
  match transport.resolve_tag("latest") {
    Some(d) => assert_eq(d, "blake3:manifest-digest")
    None => assert_true(false)
  }
}

///|
test "OciHttpCasNode participates in StoreNode flow" {
  let client = FakeRoundTripper::new()
  let transport = @storage.OciRegistryHttpTransport::new(
    "https://registry.test",
    "merkin/repo",
    client as &@storage.RegistryRoundTripper,
  )
  let node = @storage.OciHttpCasNode::new("oci-http-1", transport)

  let digest = node.put_blob(b"oci-http-payload")
  assert_true(node.has_blob(digest))
  assert_true(node.get_blob(digest) is Some(_))
}
