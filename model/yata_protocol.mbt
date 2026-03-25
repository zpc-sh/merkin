///|
/// Structured parse diagnostics for `.plan`.
pub(all) struct YataParseIssue {
  /// 1-based line index.
  line : Int
  /// Machine-oriented issue code.
  code : String
  /// Human description.
  message : String
} derive(Show)

///|
/// Parse result for strict `.plan` wire ingestion.
pub(all) struct YataParseOutcome {
  /// Parsed `.plan` if structurally valid.
  plan : YataPlan?
  /// Diagnostic list (errors and warnings).
  issues : Array[YataParseIssue]
  /// `false` when parse errors prevent materialization.
  ok : Bool
} derive(Show)

///|
/// Surface schema for `.plan`.
pub(all) struct YataPlanCursor {
  /// Declared number of entries in the plan payload.
  expected_entries : UInt
  /// Count of entries currently readable from materialization.
  observed_entries : UInt
  /// Count of entries in ready state.
  ready_count : UInt
  /// Count of unresolved entries.
  unresolved_count : UInt
  /// Parse warnings captured by consumer.
  warnings : Array[YataParseIssue]
} derive(Show)

///|
/// Parse `.plan` wire in strict mode.
pub fn YataPlan::parse_wire_strict(raw : String) -> YataParseOutcome {
  let lines = raw.split("\n")
  let mut issues : Array[YataParseIssue] = []
  if lines.length() == 0 || (lines.length() == 1 && lines[0] == "") {
    return {
      plan: None,
      issues: [{ line: 1, code: "EMPTY_INPUT", message: "empty `.plan` input" }],
      ok: false,
    }
  }

  let mut seen_kind = false
  let mut track : YataTrack = Program
  let mut mode : YataPlanMode = Full
  let mut generator = ""
  let mut note = ""
  let mut expected_entries : UInt = 0U
  let mut material_hash : String? = None
  let mut entries : Array[YataPlanEntry] = []
  let mut self_report_enabled = false
  let mut self_report_overlay = ""
  let mut self_report_peer = ""
  let mut self_report_authority = ""
  let mut self_report_anchor_hint = ""
  let mut self_report_gap : UInt = 0U
  let mut self_report_view_hint = ""
  let mut git_report_enabled = false
  let mut git_report_branch = ""
  let mut git_report_remote = ""
  let mut git_report_merge_base = ""
  let mut git_report_head = ""
  let mut git_report_commit_count : UInt = 0U
  let mut git_report_refs = ""

  let mut line_no : Int = 0
  let mut i : Int = 0
  while i < lines.length() {
    let line = lines[i]
    line_no = line_no + 1
    if line == "kind: merkin.yata.plan" {
      seen_kind = true
      i = i + 1
      continue
    }
    if line.starts_with("kind:") {
      issues.push({
        line: line_no,
        code: "BAD_KIND",
        message: "expected `kind: merkin.yata.plan`",
      })
      i = i + 1
      continue
    }
    if line.starts_with("track=") {
      match parse_value(line, "track=") {
        Some(value) =>
          if value == "program" {
            track = Program
          } else if value == "git" {
            track = Git
          } else {
            issues.push({
              line: line_no,
              code: "BAD_TRACK",
              message: "track must be `program` or `git`",
            })
          }
        None =>
          issues.push({
            line: line_no,
            code: "MALFORMED_HEADER",
            message: "could not parse `track=` field",
          })
      }
      i = i + 1
      continue
    }
    if line.starts_with("mode=") {
      match parse_value(line, "mode=") {
        Some(value) =>
          if value == "compact" {
            mode = Compact
          } else if value == "full" {
            mode = Full
          } else {
            issues.push({
              line: line_no,
              code: "BAD_MODE",
              message: "mode must be `full` or `compact`",
            })
          }
        None =>
          issues.push({
            line: line_no,
            code: "MALFORMED_HEADER",
            message: "could not parse `mode=` field",
          })
      }
      i = i + 1
      continue
    }
    if line.starts_with("generator=") {
      match parse_value(line, "generator=") {
        Some(value) => generator = value
        None =>
          issues.push({
            line: line_no,
            code: "MALFORMED_HEADER",
            message: "could not parse `generator=` field",
          })
      }
      i = i + 1
      continue
    }
    if line.starts_with("note=") {
      match parse_value(line, "note=") {
        Some(value) => note = value
        None =>
          issues.push({
            line: line_no,
            code: "MALFORMED_HEADER",
            message: "could not parse `note=` field",
          })
      }
      i = i + 1
      continue
    }
    if line.starts_with("entries=") {
      match parse_u32_opt(parse_value(line, "entries=")) {
        Some(value) => expected_entries = value
        None =>
          issues.push({
            line: line_no,
            code: "BAD_HEADER_NUMBER",
            message: "entries must be an unsigned integer",
          })
      }
      i = i + 1
      continue
    }
    if line.starts_with("material_hash=") {
      material_hash = parse_value(line, "material_hash=")
      if material_hash == None {
        issues.push({
          line: line_no,
          code: "MALFORMED_HEADER",
          message: "could not parse `material_hash=`",
        })
      }
      i = i + 1
      continue
    }
    if line.starts_with("self_report=") {
      match parse_value(line, "self_report=") {
        Some(value) =>
          if value == "1" {
            self_report_enabled = true
          } else {
            issues.push({
              line: line_no,
              code: "BAD_SELF_REPORT_FLAG",
              message: "self_report must be `1` to enable report metadata",
            })
          }
        None =>
          issues.push({
            line: line_no,
            code: "MALFORMED_HEADER",
            message: "could not parse `self_report=` field",
          })
      }
      i = i + 1
      continue
    }
    if line.starts_with("self_report_overlay=") {
      match parse_value(line, "self_report_overlay=") {
        Some(value) => self_report_overlay = value
        None =>
          issues.push({
            line: line_no,
            code: "MALFORMED_HEADER",
            message: "could not parse `self_report_overlay=`",
          })
      }
      i = i + 1
      continue
    }
    if line.starts_with("self_report_peer=") {
      match parse_value(line, "self_report_peer=") {
        Some(value) => self_report_peer = value
        None =>
          issues.push({
            line: line_no,
            code: "MALFORMED_HEADER",
            message: "could not parse `self_report_peer=`",
          })
      }
      i = i + 1
      continue
    }
    if line.starts_with("self_report_authority=") {
      match parse_value(line, "self_report_authority=") {
        Some(value) => self_report_authority = value
        None =>
          issues.push({
            line: line_no,
            code: "MALFORMED_HEADER",
            message: "could not parse `self_report_authority=`",
          })
      }
      i = i + 1
      continue
    }
    if line.starts_with("self_report_anchor=") {
      match parse_value(line, "self_report_anchor=") {
        Some(value) => self_report_anchor_hint = value
        None =>
          issues.push({
            line: line_no,
            code: "MALFORMED_HEADER",
            message: "could not parse `self_report_anchor=`",
          })
      }
      i = i + 1
      continue
    }
    if line.starts_with("self_report_gap=") {
      match parse_u32_opt(parse_value(line, "self_report_gap=")) {
        Some(value) => self_report_gap = value
        None =>
          issues.push({
            line: line_no,
            code: "BAD_HEADER_NUMBER",
            message: "self_report_gap must be an unsigned integer",
          })
      }
      i = i + 1
      continue
    }
    if line.starts_with("self_report_view=") {
      match parse_value(line, "self_report_view=") {
        Some(value) => self_report_view_hint = value
        None =>
          issues.push({
            line: line_no,
            code: "MALFORMED_HEADER",
            message: "could not parse `self_report_view=`",
          })
      }
      i = i + 1
      continue
    }
    if line.starts_with("git_report=") {
      match parse_value(line, "git_report=") {
        Some(value) =>
          if value == "1" {
            git_report_enabled = true
          } else {
            issues.push({
              line: line_no,
              code: "BAD_GIT_REPORT_FLAG",
              message: "git_report must be `1` to enable report metadata",
            })
          }
        None =>
          issues.push({
            line: line_no,
            code: "MALFORMED_HEADER",
            message: "could not parse `git_report=` field",
          })
      }
      i = i + 1
      continue
    }
    if line.starts_with("git_report_branch=") {
      match parse_value(line, "git_report_branch=") {
        Some(value) => git_report_branch = value
        None =>
          issues.push({
            line: line_no,
            code: "MALFORMED_HEADER",
            message: "could not parse `git_report_branch=`",
          })
      }
      i = i + 1
      continue
    }
    if line.starts_with("git_report_remote=") {
      match parse_value(line, "git_report_remote=") {
        Some(value) => git_report_remote = value
        None =>
          issues.push({
            line: line_no,
            code: "MALFORMED_HEADER",
            message: "could not parse `git_report_remote=`",
          })
      }
      i = i + 1
      continue
    }
    if line.starts_with("git_report_merge_base=") {
      match parse_value(line, "git_report_merge_base=") {
        Some(value) => git_report_merge_base = value
        None =>
          issues.push({
            line: line_no,
            code: "MALFORMED_HEADER",
            message: "could not parse `git_report_merge_base=`",
          })
      }
      i = i + 1
      continue
    }
    if line.starts_with("git_report_head=") {
      match parse_value(line, "git_report_head=") {
        Some(value) => git_report_head = value
        None =>
          issues.push({
            line: line_no,
            code: "MALFORMED_HEADER",
            message: "could not parse `git_report_head=`",
          })
      }
      i = i + 1
      continue
    }
    if line.starts_with("git_report_commit_count=") {
      match parse_u32_opt(parse_value(line, "git_report_commit_count=")) {
        Some(value) => git_report_commit_count = value
        None =>
          issues.push({
            line: line_no,
            code: "BAD_HEADER_NUMBER",
            message: "git_report_commit_count must be an unsigned integer",
          })
      }
      i = i + 1
      continue
    }
    if line.starts_with("git_report_refs=") {
      match parse_value(line, "git_report_refs=") {
        Some(value) => git_report_refs = value
        None =>
          issues.push({
            line: line_no,
            code: "MALFORMED_HEADER",
            message: "could not parse `git_report_refs=`",
          })
      }
      i = i + 1
      continue
    }
    if line.starts_with("- ") {
      match parse_entry_line_strict(line) {
        Some(entry) => entries.push(entry)
        None =>
          issues.push({
            line: line_no,
            code: "BAD_ENTRY",
            message: "invalid `.plan` entry format",
          })
      }
      i = i + 1
      continue
    }
    if line.length() > 0 {
      issues.push({
        line: line_no,
        code: "UNRECOGNIZED_LINE",
        message: "could not classify line",
      })
    }
    i = i + 1
  }

  if !seen_kind {
    issues.push({
      line: 1,
      code: "MISSING_KIND",
      message: "missing `kind: merkin.yata.plan`",
    })
  }
  if material_hash == None {
    issues.push({
      line: 1,
      code: "MISSING_MATERIAL_HASH",
      message: "expected `material_hash=` field",
    })
  }
  if expected_entries > 0U && entries.length() != expected_entries {
    issues.push({
      line: 0,
      code: "ENTRY_COUNT_MISMATCH",
      message: "observed entry count does not equal declared `entries=`",
    })
  }
  if self_report_enabled && self_report_overlay == "" {
    issues.push({
      line: 1,
      code: "MISSING_SELF_REPORT_OVERLAY",
      message: "self_report enabled but `self_report_overlay=` is required",
    })
  }
  if git_report_enabled && git_report_branch == "" {
    issues.push({
      line: 1,
      code: "MISSING_GIT_REPORT_BRANCH",
      message: "git_report enabled but `git_report_branch=` is required",
    })
  }

  let self_report = if self_report_enabled {
    Some({
      overlay: self_report_overlay,
      peer: self_report_peer,
      authority: self_report_authority,
      anchor_hint: self_report_anchor_hint,
      gap: self_report_gap,
      view_hint: self_report_view_hint,
    })
  } else {
    None
  }
  let git_report = if git_report_enabled {
    Some({
      branch: git_report_branch,
      remote: git_report_remote,
      merge_base: git_report_merge_base,
      head: git_report_head,
      commit_count: git_report_commit_count,
      refs: git_report_refs,
    })
  } else {
    None
  }

  if issues.length() > 0 {
    { plan: None, issues, ok: false }
  } else {
    let material = match material_hash {
      Some(raw_hash) =>
        if raw_hash.starts_with("blake3:") {
          @hash.Hash::of_bytes(
            string_to_bytes(split_after(raw_hash, "blake3:")),
          )
        } else if raw_hash.starts_with("0x") {
          @hash.Hash::of_bytes(string_to_bytes(split_after(raw_hash, "0x")))
        } else {
          @hash.Hash::of_bytes(string_to_bytes(raw_hash))
        }
      None => @hash.Hash::of_bytes(string_to_bytes(""))
    }
    {
      plan: Some({
        track,
        mode,
        generator,
        note,
        material_hash: material,
        self_report,
        git_report,
        entries,
      }),
      issues: [],
      ok: true,
    }
  }
}

///|
/// Backward-compatible parse path.
pub fn YataPlan::parse_wire(raw : String) -> YataPlan? {
  let parsed = YataPlan::parse_wire_strict(raw)
  if parsed.ok {
    parsed.plan
  } else {
    None
  }
}

///|
/// Replay helper that keeps plan semantics consumable for downstream readers.
pub fn YataPlan::to_cursor(self : YataPlan) -> YataPlanCursor {
  self.validate()
}

///|
/// Validate `.plan` content consistency.
pub fn YataPlan::validate(self : YataPlan) -> YataPlanCursor {
  let mut warnings : Array[YataParseIssue] = []
  let expected = self.entries.length()
  let mut observed : UInt = 0U
  let mut ready_count : UInt = 0U
  let mut unresolved_count : UInt = 0U
  for entry in self.entries {
    observed = observed + 1U
    if entry.ready {
      ready_count = ready_count + 1U
    } else {
      unresolved_count = unresolved_count + 1U
    }
    if entry.hole_id == @hash.Hash::of_bytes(string_to_bytes("")) {
      warnings.push({
        line: 0,
        code: "EMPTY_HOLE_ID",
        message: "entry has empty hole_id",
      })
    }
    if entry.state == "" {
      warnings.push({
        line: 0,
        code: "EMPTY_STATE",
        message: "entry has empty state",
      })
    }
  }
  {
    expected_entries: expected,
    observed_entries: observed,
    ready_count,
    unresolved_count,
    warnings,
  }
}

///|
fn parse_entry_line_strict(line : String) -> YataPlanEntry? {
  let tokens = line.split(" ")
  if tokens.length() != 9 {
    return None
  }
  if tokens[0] != "-" {
    return None
  }
  let hole_id_token = tokens[1]
  let anchor_token = tokens[2]
  let state_token = tokens[3]

  let ready_token = tokens[4]
  let candidates_token = tokens[5]
  let conf_token = tokens[6]
  let selected_field = tokens[7]
  let provenance_field = tokens[8]

  if !ready_token.starts_with("ready=") {
    return None
  }
  if !candidates_token.starts_with("candidates=") {
    return None
  }
  if !conf_token.starts_with("conf_floor=") {
    return None
  }
  if !selected_field.starts_with("selected=") {
    return None
  }
  if !provenance_field.starts_with("provenance=") {
    return None
  }

  let maybe_ready = parse_bool_opt(parse_value(ready_token, "ready="))
  let maybe_candidate_count = parse_u32_opt(
    parse_value(candidates_token, "candidates="),
  )
  let maybe_confidence = parse_u32_opt(parse_value(conf_token, "conf_floor="))
  match parse_value(provenance_field, "provenance=") {
    Some(p) => if parse_u32_opt(Some(p)) == None { return None }
    None => return None
  }
  match maybe_ready {
    Some(ready) => {
      let selected = parse_value(selected_field, "selected=")
      match maybe_candidate_count {
        Some(candidate_count) =>
          match maybe_confidence {
            Some(confidence_floor) => {
              let mut selected_candidate : String? = None
              match selected {
                Some(value) =>
                  if value != "none" {
                    selected_candidate = Some(value)
                  }
                None => return None
              }
              Some({
                hole_id: parse_hash_token(hole_id_token),
                anchor: anchor_token,
                state: state_token,
                candidate_count,
                ready,
                selected_candidate,
                provenance: [],
                confidence_floor,
              })
            }
            None => None
          }
        None => None
      }
    }
    None => None
  }
}

///|
fn parse_value(raw : String, prefix : String) -> String? {
  if raw.starts_with(prefix) {
    Some(split_after(raw, prefix))
  } else {
    None
  }
}

///|
fn parse_u32_opt(raw : String?) -> UInt? {
  match raw {
    Some(text) => {
      if text == "" {
        return None
      }
      let bytes = string_to_bytes(text)
      let mut out : UInt = 0U
      let mut i : Int = 0
      while i < bytes.length() {
        let b = bytes[i].to_int()
        if b < 48 || b > 57 {
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
fn parse_bool_opt(raw : String?) -> Bool? {
  match raw {
    Some(value) =>
      if value == "true" {
        Some(true)
      } else if value == "false" {
        Some(false)
      } else {
        None
      }
    None => None
  }
}

///|
fn split_after(raw : String, prefix : String) -> String {
  let chunks = raw.split(prefix)
  if chunks.length() < 2 {
    ""
  } else {
    chunks[1]
  }
}

///|
fn parse_hash_token(token : String) -> @hash.Hash {
  if token.starts_with("blake3:") {
    @hash.Hash::of_bytes(string_to_bytes(split_after(token, "blake3:")))
  } else if token.starts_with("0x") {
    @hash.Hash::of_bytes(string_to_bytes(split_after(token, "0x")))
  } else {
    @hash.Hash::of_bytes(string_to_bytes(token))
  }
}
