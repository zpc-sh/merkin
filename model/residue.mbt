///|
/// Residue: the fundamental stigmergic artifact.
/// Every agent session that enters a locus produces one on exit.
/// Format: loci/<name>/residue/<tier>-<session-short-id>-exit.md
///
/// The residue file is append-only in the working directory.
/// Merkin never modifies an existing residue. They are sealed into
/// the Provenance SMT layer on `merkin push`.
pub(all) struct Residue {
  /// Locus this residue belongs to.
  locus : String
  /// Session surface or tier: "haiku", "sonnet", "opus", "codex", etc.
  tier : String
  /// Short session identifier (e.g., "a7f3c").
  session_short_id : String
  /// ISO8601 timestamp of exit.
  timestamp : String
  /// Which prior residue was read on entry, or None for cold entry.
  picked_up_from : String?
  /// What this session accomplished.
  what_i_did : Array[String]
  /// What remains unfinished.
  what_i_left_open : Array[String]
  /// Optional recommendation for the next agent.
  recommendation : String?
} derive(Debug)

///|
/// Create a new residue record.
pub fn Residue::new(
  locus : String,
  tier : String,
  session_short_id : String,
  timestamp : String,
) -> Residue {
  {
    locus,
    tier,
    session_short_id,
    timestamp,
    picked_up_from: None,
    what_i_did: [],
    what_i_left_open: [],
    recommendation: None,
  }
}

///|
/// Canonical filename for this residue.
pub fn Residue::filename(self : Residue) -> String {
  self.tier + "-" + self.session_short_id + "-exit.md"
}

///|
/// Set what was picked up from prior session.
pub fn Residue::set_picked_up(self : Residue, from : String) -> Residue {
  { ..self, picked_up_from: Some(from) }
}

///|
/// Add an item to "what I did".
pub fn Residue::add_did(self : Residue, item : String) -> Residue {
  let items = self.what_i_did
  items.push(item)
  { ..self, what_i_did: items }
}

///|
/// Add an item to "what I left open".
pub fn Residue::add_left_open(self : Residue, item : String) -> Residue {
  let items = self.what_i_left_open
  items.push(item)
  { ..self, what_i_left_open: items }
}

///|
/// Set the recommendation for the next agent.
pub fn Residue::set_recommendation(self : Residue, rec : String) -> Residue {
  { ..self, recommendation: Some(rec) }
}

///|
/// Emit the residue as markdown content (the canonical wire format).
pub fn Residue::to_markdown(self : Residue) -> String {
  let b = StringBuilder::new(size_hint=512)
  b.write_string("# Residue: ")
  b.write_string(self.locus)
  b.write_char('\n')
  b.write_string("Filed by: ")
  b.write_string(self.tier)
  b.write_char('/')
  b.write_string(self.session_short_id)
  b.write_char('\n')
  b.write_string("Timestamp: ")
  b.write_string(self.timestamp)
  b.write_char('\n')
  b.write_string("Entry residue: ")
  match self.picked_up_from {
    Some(from) => b.write_string(from)
    None => b.write_string("cold")
  }
  b.write_char('\n')
  b.write_char('\n')
  b.write_string("## Picked up from\n")
  match self.picked_up_from {
    Some(from) => b.write_string(from)
    None => b.write_string("(cold entry — no prior residue)")
  }
  b.write_char('\n')
  b.write_char('\n')
  b.write_string("## What I did\n")
  for item in self.what_i_did {
    b.write_string("- ")
    b.write_string(item)
    b.write_char('\n')
  }
  b.write_char('\n')
  b.write_string("## What I left open\n")
  for item in self.what_i_left_open {
    b.write_string("- ")
    b.write_string(item)
    b.write_char('\n')
  }
  b.write_char('\n')
  b.write_string("## Recommendation for next AI\n")
  match self.recommendation {
    Some(rec) => b.write_string(rec)
    None => b.write_string("(none)")
  }
  b.write_char('\n')
  b.to_string()
}

///|
/// Parse a residue from markdown lines. Lenient parser — extracts
/// what it can, returns None only if the file is completely unparseable.
pub fn Residue::from_markdown(locus : String, content : String) -> Residue? {
  let tier = extract_field(content, "Filed by: ")
  let timestamp = extract_field(content, "Timestamp: ")
  if tier == "" {
    return None
  }
  // Parse tier/session_id from "sonnet/a7f3c" format
  let slash_pos = find_char(tier, '/')
  let parsed_tier = if slash_pos >= 0 {
    substring(tier, 0, slash_pos)
  } else {
    tier
  }
  let session_id = if slash_pos >= 0 {
    substring(tier, slash_pos + 1, string_length(tier))
  } else {
    "unknown"
  }
  let picked_up = extract_field(content, "Entry residue: ")
  let picked_up_from = if picked_up == "cold" || picked_up == "" {
    None
  } else {
    Some(picked_up)
  }
  let did = extract_list_section(content, "## What I did")
  let left_open = extract_list_section(content, "## What I left open")
  let rec = extract_recommendation_body(content)
  let recommendation = if rec == "" || rec == "(none)" {
    None
  } else {
    Some(rec)
  }
  Some({
    locus,
    tier: parsed_tier,
    session_short_id: session_id,
    timestamp,
    picked_up_from,
    what_i_did: did,
    what_i_left_open: left_open,
    recommendation,
  })
}

// --- Internal parsing helpers ---

///|
fn extract_field(content : String, prefix : String) -> String {
  let lines = split_lines(content)
  for line in lines {
    if line_starts_with(line, prefix) {
      return substring(line, string_length(prefix), string_length(line))
    }
  }
  ""
}

///|
fn extract_list_section(content : String, header : String) -> Array[String] {
  let lines = split_lines(content)
  let items : Array[String] = []
  let mut in_section = false
  for line in lines {
    if line_starts_with(line, header) {
      in_section = true
      continue
    }
    if in_section {
      if line_starts_with(line, "## ") {
        break
      }
      if line_starts_with(line, "- ") {
        items.push(substring(line, 2, string_length(line)))
      }
    }
  }
  items
}

///|
fn extract_section_body(content : String, header : String) -> String {
  let lines = split_lines(content)
  let b = StringBuilder::new(size_hint=256)
  let mut in_section = false
  let mut first = true
  for line in lines {
    if line_starts_with(line, header) {
      in_section = true
      continue
    }
    if in_section {
      if line_starts_with(line, "## ") {
        break
      }
      let trimmed = trim_line(line)
      if trimmed != "" {
        if !first {
          b.write_char('\n')
        }
        b.write_string(trimmed)
        first = false
      }
    }
  }
  b.to_string()
}

///|
fn extract_recommendation_body(content : String) -> String {
  let next_ai = extract_section_body(content, "## Recommendation for next AI")
  if next_ai != "" {
    next_ai
  } else {
    extract_section_body(content, "## Recommendation for next Claude")
  }
}

///|
fn split_lines(s : String) -> Array[String] {
  let lines : Array[String] = []
  let cur = StringBuilder::new(size_hint=128)
  for ch in s {
    if ch == '\n' {
      lines.push(cur.to_string())
      cur.reset()
    } else {
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
fn line_starts_with(line : String, prefix : String) -> Bool {
  let line_len = string_length(line)
  let prefix_len = string_length(prefix)
  if line_len < prefix_len {
    return false
  }
  substring(line, 0, prefix_len) == prefix
}

///|
fn find_char(s : String, target : Char) -> Int {
  let mut i = 0
  for ch in s {
    if ch == target {
      return i
    }
    i = i + 1
  }
  -1
}

///|
fn string_length(s : String) -> Int {
  let mut n = 0
  for _ch in s {
    n = n + 1
  }
  n
}

///|
fn substring(s : String, start : Int, end : Int) -> String {
  let b = StringBuilder::new(size_hint=end - start + 1)
  let mut i = 0
  for ch in s {
    if i >= start && i < end {
      b.write_char(ch)
    }
    i = i + 1
  }
  b.to_string()
}

///|
fn trim_line(s : String) -> String {
  let b = StringBuilder::new(size_hint=string_length(s))
  let mut started = false
  let chars : Array[Char] = []
  for ch in s {
    chars.push(ch)
  }
  // Find first non-space
  let mut first = 0
  while first < chars.length() && (chars[first] == ' ' || chars[first] == '\t') {
    first = first + 1
  }
  // Find last non-space
  let mut last = chars.length() - 1
  while last >= first && (chars[last] == ' ' || chars[last] == '\t') {
    last = last - 1
  }
  let mut i = first
  while i <= last {
    b.write_char(chars[i])
    i = i + 1
    started = true
  }
  ignore(started)
  b.to_string()
}
