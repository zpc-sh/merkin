///|
/// Address policy for cross-overlay and peer translation.
pub(all) struct YataAddressHint {
  overlay : String
  peer : String
  mode : String
  gap : UInt
  view : String
} derive(Show)

///|
/// Human-sized address view for protocol export.
pub(all) struct YataAddress {
  uri : String
  scheme : String
  authority : String
  anchor : String
  cas_alg : String
  cas_digest : String
  id_token : String
  hole_id : @hash.Hash
  overlay : String
  peer : String
  mode : String
  gap : UInt
  track : YataTrack
  view : String
} derive(Show)

///|
/// Address parser diagnostics.
pub(all) struct YataAddressParseIssue {
  /// 1-based line index.
  line : Int
  code : String
  message : String
} derive(Show)

///|
/// Strict parse outcome.
pub(all) struct YataAddressParseOutcome {
  address : YataAddress?
  issues : Array[YataAddressParseIssue]
  ok : Bool
} derive(Show)

///|
/// Relative parsing context.
pub(all) struct YataAddressContext {
  authority : String
  anchor : String
} derive(Show)

///|
/// Render a hole as a cognitive URI from the active perspective.
pub fn YataHole::to_cog_uri(
  self : YataHole,
  authority : String,
  hint : YataAddressHint,
  track : YataTrack,
) -> String {
  let b = StringBuilder::new()
  b.write_string("cog://")
  b.write_string(authority)
  b.write_string("/")
  b.write_string(normalize_anchor_path(self.anchor))
  b.write_string("?")
  b.write_string("overlay=")
  if hint.overlay.length() > 0 {
    b.write_string(hint.overlay)
  } else {
    b.write_string("program")
  }
  b.write_string("&peer=")
  b.write_string(hint.peer)
  b.write_string("&mode=")
  b.write_string(hint.mode)
  b.write_string("&gap=")
  b.write_string(hint.gap.to_string())
  b.write_string("&track=")
  b.write_string(yata_track_token(track))
  b.write_string("&id=")
  b.write_string(self.hole_id.key())
  if hint.view.length() > 0 {
    b.write_string("#")
    b.write_string(hint.view)
  } else {
    b.write_string("#overlay")
  }
  b.to_string()
}

///|
/// Render a hole as substrate URI (base layer equivalent).
pub fn YataHole::to_substrate_uri(
  self : YataHole,
  authority : String,
  hint : YataAddressHint,
  track : YataTrack,
) -> String {
  let b = StringBuilder::new()
  b.write_string("substrate://")
  b.write_string(authority)
  b.write_string("/")
  b.write_string(normalize_anchor_path(self.anchor))
  b.write_string("?")
  b.write_string("overlay=")
  if hint.overlay.length() > 0 {
    b.write_string(hint.overlay)
  } else {
    b.write_string("program")
  }
  b.write_string("&peer=")
  b.write_string(hint.peer)
  b.write_string("&mode=")
  b.write_string(hint.mode)
  b.write_string("&gap=")
  b.write_string(hint.gap.to_string())
  b.write_string("&track=")
  b.write_string(yata_track_token(track))
  b.write_string("&id=")
  b.write_string(self.hole_id.key())
  if hint.view.length() > 0 {
    b.write_string("#")
    b.write_string(hint.view)
  } else {
    b.write_string("#overlay")
  }
  b.to_string()
}

///|
/// Render a hole as content-addressed URI with optional anchor hint.
pub fn YataHole::to_cas_uri(
  self : YataHole,
  authority : String,
  hint : YataAddressHint,
  track : YataTrack,
  cas_alg : String,
) -> String {
  let mut alg = cas_alg
  if alg == "" {
    alg = "blake3"
  }
  let mut digest = self.hole_id.key()
  if digest.has_prefix("blake3:") {
    digest = split_after_raw(digest, "blake3:")
  } else if digest.has_prefix("0x") {
    digest = split_after_raw(digest, "0x")
  }
  let normalized_anchor = normalize_anchor_path(self.anchor)
  let b = StringBuilder::new()
  b.write_string("cas://")
  b.write_string(authority)
  b.write_string("/")
  b.write_string(alg)
  b.write_string("/")
  b.write_string(digest)
  b.write_string("?")
  b.write_string("overlay=")
  if hint.overlay.length() > 0 {
    b.write_string(hint.overlay)
  } else {
    b.write_string("program")
  }
  b.write_string("&peer=")
  b.write_string(hint.peer)
  b.write_string("&mode=")
  b.write_string(hint.mode)
  b.write_string("&gap=")
  b.write_string(hint.gap.to_string())
  b.write_string("&track=")
  b.write_string(yata_track_token(track))
  b.write_string("&id=")
  b.write_string(self.hole_id.key())
  if normalized_anchor != "" {
    b.write_string("&anchor=")
    b.write_string(normalized_anchor)
  }
  if hint.view.length() > 0 {
    b.write_string("#")
    b.write_string(hint.view)
  } else {
    b.write_string("#overlay")
  }
  b.to_string()
}

///|
/// Parse a minimal subset of cognitive URI back to address metadata.
pub fn YataAddress::parse(raw : String) -> YataAddress? {
  let outcome = YataAddress::parse_strict(raw)
  if outcome.ok {
    outcome.address
  } else {
    None
  }
}

///|
/// Re-emit this address in canonical wire form.
pub fn YataAddress::to_wire_canonical(self : YataAddress) -> String {
  build_canonical_uri(
    self.scheme,
    self.authority,
    self.anchor,
    self.cas_alg,
    self.cas_digest,
    self.overlay,
    self.peer,
    self.mode,
    self.gap,
    self.track,
    self.id_token,
    self.view,
  )
}

///|
/// Canonicalize a raw address if it parses.
pub fn YataAddress::canonicalize(raw : String) -> String? {
  match YataAddress::parse(raw) {
    Some(address) => Some(address.to_wire_canonical())
    None => None
  }
}

///|
/// Parse a relative URI against a perspective context.
pub fn YataAddress::parse_in_context(
  raw : String,
  context : YataAddressContext,
) -> YataAddress? {
  let outcome = YataAddress::parse_in_context_strict(raw, context)
  if outcome.ok {
    outcome.address
  } else {
    None
  }
}

///|
/// Strict parse for context-relative forms.
/// Supported forms:
/// - `./notes/foo.md?overlay=...`
/// - `../notes/foo.md?overlay=...`
/// - `?overlay=...`
/// - `id=...&overlay=...`
pub fn YataAddress::parse_in_context_strict(
  raw : String,
  context : YataAddressContext,
) -> YataAddressParseOutcome {
  if raw == "" {
    return {
      address: None,
      issues: [{ line: 1, code: "EMPTY_INPUT", message: "empty uri" }],
      ok: false,
    }
  }
  if context.authority == "" {
    return {
      address: None,
      issues: [
        {
          line: 1,
          code: "MISSING_CONTEXT",
          message: "context authority is required",
        },
      ],
      ok: false,
    }
  }

  if raw.has_prefix("cog://") ||
    raw.has_prefix("substrate://") ||
    raw.has_prefix("cas://") {
    return YataAddress::parse_strict(raw)
  }

  let hash_parts = str_split(raw, "#")
  let before_hash = hash_parts[0]
  let view = if hash_parts.length() > 1 { hash_parts[1] } else { "overlay" }
  if hash_parts.length() > 2 {
    return {
      address: None,
      issues: [
        { line: 1, code: "MULTI_HASH", message: "uri contains multiple `#`" },
      ],
      ok: false,
    }
  }

  let query_parts = str_split(before_hash, "?")
  let route = query_parts[0]
  let mut query = ""
  if query_parts.length() >= 2 {
    query = join_from_index(query_parts, 1, "?")
  }

  let mut normalized_anchor : String = normalize_anchor_path(context.anchor)
  if route != "" {
    if route.has_prefix("./") || route.has_prefix("../") {
      normalized_anchor = resolve_relative_anchor(normalized_anchor, route)
    } else if route.has_prefix("id=") && query == "" {
      query = route
    } else if route != "" {
      normalized_anchor = normalize_anchor_path(route)
    }
  }

  let mut normalized_uri = "cog://" +
    context.authority +
    "/" +
    normalized_anchor
  if query == "" {
    normalized_uri = normalized_uri + "?"
  } else {
    normalized_uri = normalized_uri + "?" + query
  }
  normalized_uri = normalized_uri + "#" + view
  YataAddress::parse_strict(normalized_uri)
}

///|
/// Strict parse with unknown-key reporting.
pub fn YataAddress::parse_strict(raw : String) -> YataAddressParseOutcome {
  let issues : Array[YataAddressParseIssue] = []

  let hashes = str_split(raw, "#")
  if hashes.length() == 0 {
    return {
      address: None,
      issues: [{ line: 1, code: "EMPTY_INPUT", message: "empty uri" }],
      ok: false,
    }
  }
  let before_hash = hashes[0]
  let view = if hashes.length() > 1 { hashes[1] } else { "overlay" }
  if hashes.length() > 2 {
    issues.push({
      line: 1,
      code: "MULTI_HASH",
      message: "uri contains multiple `#`",
    })
  }

  let before_and_query = str_split(before_hash, "?")
  if before_and_query.length() < 2 {
    issues.push({
      line: 1,
      code: "MISSING_QUERY",
      message: "missing `?` query separator",
    })
    return { address: None, issues, ok: false }
  }
  let before = before_and_query[0]
  let query_raw = join_from_index(before_and_query, 1, "?")

  let mut scheme = ""
  let mut authority = ""
  let mut anchor = ""
  let mut cas_alg = ""
  let mut cas_digest = ""
  if before.has_prefix("cog://") {
    scheme = "cog"
    let rem = split_after_raw(before, "cog://")
    let route = str_split(rem, "/")
    if route.length() >= 1 {
      authority = route[0]
      let segments : Array[String] = []
      let mut index = 1
      while index < route.length() {
        if route[index] != "" {
          segments.push(route[index])
        }
        index = index + 1
      }
      anchor = normalize_anchor_path(join_by(segments, "/"))
    }
    if authority == "" || anchor == "" {
      issues.push({
        line: 1,
        code: "BAD_ROUTE",
        message: "cog uri requires authority and anchor",
      })
    }
  } else if before.has_prefix("substrate://") {
    scheme = "substrate"
    let rem = split_after_raw(before, "substrate://")
    let route = str_split(rem, "/")
    if route.length() >= 1 {
      authority = route[0]
      let segments : Array[String] = []
      let mut index = 1
      while index < route.length() {
        if route[index] != "" {
          segments.push(route[index])
        }
        index = index + 1
      }
      anchor = normalize_anchor_path(join_by(segments, "/"))
    }
    if authority == "" || anchor == "" {
      issues.push({
        line: 1,
        code: "BAD_ROUTE",
        message: "substrate uri requires authority and anchor",
      })
    }
  } else if before.has_prefix("cas://") {
    scheme = "cas"
    let rem = split_after_raw(before, "cas://")
    let route = str_split(rem, "/")
    if route.length() >= 1 {
      authority = route[0]
      let segments : Array[String] = []
      let mut index = 1
      while index < route.length() {
        if route[index] != "" {
          segments.push(route[index])
        }
        index = index + 1
      }
      if segments.length() >= 2 {
        cas_alg = segments[0]
        cas_digest = segments[1]
        if segments.length() > 2 {
          let mut j = 2
          while j < segments.length() {
            cas_digest = cas_digest + "/" + segments[j]
            j = j + 1
          }
        }
      }
    }
    if authority == "" || cas_alg == "" || cas_digest == "" {
      issues.push({
        line: 1,
        code: "BAD_ROUTE",
        message: "cas uri requires authority, algorithm, and digest",
      })
    }
  } else {
    issues.push({
      line: 1,
      code: "BAD_SCHEME",
      message: "scheme must be `cog`, `substrate`, or `cas`",
    })
    return { address: None, issues, ok: false }
  }

  let mut overlay = ""
  let mut peer = ""
  let mut mode = ""
  let mut gap : UInt = 0U
  let mut track = Program
  let mut hash_token = ""

  let query_pairs = str_split(query_raw, "&")
  for pair in query_pairs {
    if pair.length() == 0 {
      continue
    }
    let pieces = str_split(pair, "=")
    if pieces.length() != 2 {
      issues.push({
        line: 1,
        code: "BAD_QUERY_PAIR",
        message: "query pairs must be `key=value`",
      })
      continue
    }
    let key = pieces[0]
    let value = pieces[1]
    if key == "overlay" {
      overlay = value
      continue
    }
    if key == "peer" {
      peer = value
      continue
    }
    if key == "mode" {
      mode = value
      continue
    }
    if key == "gap" {
      match parse_u32_opt(Some(value)) {
        Some(v) => gap = v
        None =>
          issues.push({
            line: 1,
            code: "BAD_GAP",
            message: "gap must be unsigned integer",
          })
      }
      continue
    }
    if key == "track" {
      if value == "git" {
        track = Git
      } else if value == "program" {
        track = Program
      } else {
        issues.push({
          line: 1,
          code: "BAD_TRACK",
          message: "track must be `program` or `git`",
        })
      }
      continue
    }
    if key == "id" {
      hash_token = value
      continue
    }
    if key == "anchor" {
      anchor = normalize_anchor_path(value)
      continue
    }
    if key == "cas_alg" {
      cas_alg = value
      continue
    }
    if key == "cas_digest" {
      cas_digest = value
      continue
    }
    issues.push({
      line: 1,
      code: "UNKNOWN_QUERY_KEY",
      message: "query key not recognized",
    })
  }

  if overlay == "" {
    issues.push({
      line: 1,
      code: "MISSING_OVERLAY",
      message: "overlay is recommended",
    })
  }
  if authority == "" {
    issues.push({
      line: 1,
      code: "MISSING_AUTHORITY",
      message: "authority is required",
    })
  }
  if scheme == "cas" && cas_alg == "" {
    issues.push({
      line: 1,
      code: "MISSING_CAS_ALG",
      message: "cas algorithm is required",
    })
  }
  if scheme == "cas" && cas_digest == "" {
    issues.push({
      line: 1,
      code: "MISSING_CAS_DIGEST",
      message: "cas digest is required",
    })
  }
  if hash_token == "" && cas_digest != "" {
    hash_token = cas_digest
  }
  if anchor == "" && hash_token == "" {
    issues.push({
      line: 1,
      code: "MISSING_TARGET",
      message: "anchor/path or id is required",
    })
  }

  if issues.length() > 0 {
    { address: None, issues, ok: false }
  } else {
    let canonical_uri = build_canonical_uri(
      scheme, authority, anchor, cas_alg, cas_digest, overlay, peer, mode, gap, track,
      hash_token, view,
    )
    let parsed = {
      uri: canonical_uri,
      scheme,
      authority,
      anchor,
      cas_alg,
      cas_digest,
      id_token: hash_token,
      hole_id: if hash_token == "" {
        @hash.Hash::of_bytes(string_to_bytes(""))
      } else {
        @hash.Hash::of_bytes(string_to_bytes(hash_token))
      },
      overlay,
      peer,
      mode,
      track,
      view,
      gap,
    }
    { address: Some(parsed), issues: [], ok: true }
  }
}

///|
fn join_from_index(
  parts : Array[String],
  index : Int,
  separator : String,
) -> String {
  if parts.length() <= index {
    ""
  } else {
    let mut out = parts[index]
    let mut i = index + 1
    while i < parts.length() {
      out = out + separator + parts[i]
      i = i + 1
    }
    out
  }
}

///|
fn build_canonical_uri(
  scheme : String,
  authority : String,
  anchor : String,
  cas_alg : String,
  cas_digest : String,
  overlay : String,
  peer : String,
  mode : String,
  gap : UInt,
  track : YataTrack,
  hash_token : String,
  view : String,
) -> String {
  let b = StringBuilder::new()
  b.write_string(scheme)
  b.write_string("://")
  b.write_string(authority)
  b.write_string("/")
  if scheme == "cas" {
    b.write_string(cas_alg)
    b.write_string("/")
    b.write_string(cas_digest)
  } else {
    b.write_string(anchor)
  }
  b.write_string("?overlay=")
  b.write_string(overlay)
  b.write_string("&peer=")
  b.write_string(peer)
  b.write_string("&mode=")
  b.write_string(mode)
  b.write_string("&gap=")
  b.write_string(gap.to_string())
  b.write_string("&track=")
  b.write_string(yata_track_token(track))
  if hash_token != "" {
    b.write_string("&id=")
    b.write_string(hash_token)
  }
  if scheme == "cas" && anchor != "" {
    b.write_string("&anchor=")
    b.write_string(anchor)
  }
  b.write_string("#")
  if view == "" {
    b.write_string("overlay")
  } else {
    b.write_string(view)
  }
  b.to_string()
}

///|
fn normalize_anchor_path(raw_anchor : String) -> String {
  if raw_anchor == "" {
    return ""
  }
  let parts = str_split(raw_anchor, "/")
  let mut resolved : Array[String] = []
  let mut i : Int = 0
  while i < parts.length() {
    let segment = parts[i]
    if segment == "" || segment == "." {
      i = i + 1
      continue
    }
    if segment == ".." {
      if resolved.length() > 0 {
        let trimmed : Array[String] = []
        let mut j : Int = 0
        while j < resolved.length() - 1 {
          trimmed.push(resolved[j])
          j = j + 1
        }
        resolved = trimmed
      }
      i = i + 1
      continue
    }
    resolved.push(segment)
    i = i + 1
  }
  if resolved.length() == 0 {
    ""
  } else {
    join_by(resolved, "/")
  }
}

///|
fn resolve_relative_anchor(base_anchor : String, route : String) -> String {
  let base_parts = str_split(base_anchor, "/")
  let mut keep : Int = base_parts.length()
  if keep > 0 {
    keep = keep - 1
  }

  let mut resolved : Array[String] = []
  let mut i : Int = 0
  while i < keep {
    if base_parts[i] != "" {
      resolved.push(base_parts[i])
    }
    i = i + 1
  }

  let route_parts = str_split(route, "/")
  let mut j : Int = 0
  while j < route_parts.length() {
    let segment = route_parts[j]
    if segment == "" || segment == "." {
      j = j + 1
      continue
    }
    if segment == ".." {
      if resolved.length() > 0 {
        let trimmed : Array[String] = []
        let mut k : Int = 0
        while k < resolved.length() - 1 {
          trimmed.push(resolved[k])
          k = k + 1
        }
        resolved = trimmed
      }
      j = j + 1
      continue
    }
    resolved.push(segment)
    j = j + 1
  }

  if resolved.length() == 0 {
    ""
  } else {
    let mut out = resolved[0]
    let mut r : Int = 1
    while r < resolved.length() {
      out = out + "/" + resolved[r]
      r = r + 1
    }
    out
  }
}

///|
fn split_after_raw(raw : String, prefix : String) -> String {
  if !raw.has_prefix(prefix) {
    return raw
  }
  let chunks = str_split(raw, prefix)
  if chunks.length() == 0 {
    return ""
  }
  if chunks.length() == 1 {
    return chunks[0]
  }
  let mut out = chunks[1]
  let mut i : Int = 2
  while i < chunks.length() {
    out = out + prefix + chunks[i]
    i = i + 1
  }
  out
}

///|
fn parse_u32_opt(raw : String?) -> UInt? {
  match raw {
    Some(text) => {
      if text.length() == 0 {
        return None
      }
      let bytes = string_to_bytes(text)
      let mut i : Int = 0
      let mut out : UInt = 0U
      while i < bytes.length() {
        let b = bytes[i].to_uint()
        if b < 48U || b > 57U {
          return None
        }
        out = out * 10U + (b - 48U)
        i = i + 1
      }
      Some(out)
    }
    None => None
  }
}

///|
fn yata_track_token(track : YataTrack) -> String {
  match track {
    Program => "program"
    Git => "git"
  }
}

///|
/// Split a string by a separator, returning Array[String].
/// This adapts String::split (which returns Iter[StringView]) into Array[String].
fn str_split(s : String, sep : String) -> Array[String] {
  s.split(sep).map(fn(sv) { sv.to_string() }).collect()
}
