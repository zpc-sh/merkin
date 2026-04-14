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
  let lines = split_parts(raw, "\n")
  let issues : Array[YataParseIssue] = []
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
  let entries : Array[YataPlanEntry] = []
  let mut observed_entries : UInt = 0U
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
  let mut temporal_delta_enabled = false
  let mut temporal_delta_turns : Int = 0
  let mut temporal_delta_bytes : Int = 0
  let mut temporal_delta_causal_offset : Int = 0
  let mut embedding_report_enabled = false
  let mut embedding_report_file_type = ""
  let mut embedding_report_found = false
  let mut embedding_report_count : UInt = 0U
  let mut embedding_report_ephemeral = false
  let mut embedding_report_purge_after_turns : UInt = 0U
  let mut embedding_report_strategy = ""
  let mut solve_report_enabled = false
  let mut solve_report_kind = ""
  let mut solve_report_status = ""
  let mut solve_report_handler = ""
  let mut solve_report_offloaded_to = ""
  let mut solve_report_count : UInt = 0U
  let mut procsi_report_enabled = false
  let mut procsi_report_project = ""
  let mut procsi_report_ratio_loci = ""
  let mut procsi_report_surface = ""
  let mut procsi_report_fingerprint_commitment = ""
  let mut procsi_report_app_ref = ""
  let mut procsi_report_app_audience = ""
  let mut procsi_report_masked = false
  let mut capability_report_enabled = false
  let mut capability_report_authority = ""
  let mut capability_report_ticket_kind = ""
  let mut capability_report_scope = ""
  let mut capability_report_status = ""
  let mut capability_report_count : UInt = 0U
  let mut capability_report_store_ref = ""

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
    if line.has_prefix("kind:") {
      issues.push({
        line: line_no,
        code: "BAD_KIND",
        message: "expected `kind: merkin.yata.plan`",
      })
      i = i + 1
      continue
    }
    if line.has_prefix("track=") {
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
    if line.has_prefix("mode=") {
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
    if line.has_prefix("generator=") {
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
    if line.has_prefix("note=") {
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
    if line.has_prefix("entries=") {
      match parse_u32_opt_plan(parse_value(line, "entries=")) {
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
    if line.has_prefix("material_hash=") {
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
    if line.has_prefix("self_report=") {
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
    if line.has_prefix("self_report_overlay=") {
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
    if line.has_prefix("self_report_peer=") {
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
    if line.has_prefix("self_report_authority=") {
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
    if line.has_prefix("self_report_anchor=") {
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
    if line.has_prefix("self_report_gap=") {
      match parse_u32_opt_plan(parse_value(line, "self_report_gap=")) {
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
    if line.has_prefix("self_report_view=") {
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
    if line.has_prefix("git_report=") {
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
    if line.has_prefix("git_report_branch=") {
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
    if line.has_prefix("git_report_remote=") {
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
    if line.has_prefix("git_report_merge_base=") {
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
    if line.has_prefix("git_report_head=") {
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
    if line.has_prefix("git_report_commit_count=") {
      match parse_u32_opt_plan(parse_value(line, "git_report_commit_count=")) {
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
    if line.has_prefix("git_report_refs=") {
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
    if line.has_prefix("temporal_delta=") {
      match parse_value(line, "temporal_delta=") {
        Some(value) =>
          if value == "1" {
            temporal_delta_enabled = true
          } else {
            issues.push({
              line: line_no,
              code: "BAD_TEMPORAL_DELTA_FLAG",
              message: "temporal_delta must be `1` to enable signed movement metadata",
            })
          }
        None =>
          issues.push({
            line: line_no,
            code: "MALFORMED_HEADER",
            message: "could not parse `temporal_delta=` field",
          })
      }
      i = i + 1
      continue
    }
    if line.has_prefix("temporal_delta_turns=") {
      match parse_i32_opt(parse_value(line, "temporal_delta_turns=")) {
        Some(value) => temporal_delta_turns = value
        None =>
          issues.push({
            line: line_no,
            code: "BAD_HEADER_NUMBER",
            message: "temporal_delta_turns must be a signed integer",
          })
      }
      i = i + 1
      continue
    }
    if line.has_prefix("temporal_delta_bytes=") {
      match parse_i32_opt(parse_value(line, "temporal_delta_bytes=")) {
        Some(value) => temporal_delta_bytes = value
        None =>
          issues.push({
            line: line_no,
            code: "BAD_HEADER_NUMBER",
            message: "temporal_delta_bytes must be a signed integer",
          })
      }
      i = i + 1
      continue
    }
    if line.has_prefix("temporal_delta_causal_offset=") {
      match parse_i32_opt(parse_value(line, "temporal_delta_causal_offset=")) {
        Some(value) => temporal_delta_causal_offset = value
        None =>
          issues.push({
            line: line_no,
            code: "BAD_HEADER_NUMBER",
            message: "temporal_delta_causal_offset must be a signed integer",
          })
      }
      i = i + 1
      continue
    }
    if line.has_prefix("embedding_report=") {
      match parse_value(line, "embedding_report=") {
        Some(value) =>
          if value == "1" {
            embedding_report_enabled = true
          } else {
            issues.push({
              line: line_no,
              code: "BAD_EMBEDDING_REPORT_FLAG",
              message: "embedding_report must be `1` to enable embedding metadata",
            })
          }
        None =>
          issues.push({
            line: line_no,
            code: "MALFORMED_HEADER",
            message: "could not parse `embedding_report=` field",
          })
      }
      i = i + 1
      continue
    }
    if line.has_prefix("embedding_report_file_type=") {
      match parse_value(line, "embedding_report_file_type=") {
        Some(value) => embedding_report_file_type = value
        None =>
          issues.push({
            line: line_no,
            code: "MALFORMED_HEADER",
            message: "could not parse `embedding_report_file_type=`",
          })
      }
      i = i + 1
      continue
    }
    if line.has_prefix("embedding_report_found=") {
      match parse_bool_opt(parse_value(line, "embedding_report_found=")) {
        Some(value) => embedding_report_found = value
        None =>
          issues.push({
            line: line_no,
            code: "BAD_HEADER_BOOL",
            message: "embedding_report_found must be `true` or `false`",
          })
      }
      i = i + 1
      continue
    }
    if line.has_prefix("embedding_report_count=") {
      match parse_u32_opt_plan(parse_value(line, "embedding_report_count=")) {
        Some(value) => embedding_report_count = value
        None =>
          issues.push({
            line: line_no,
            code: "BAD_HEADER_NUMBER",
            message: "embedding_report_count must be an unsigned integer",
          })
      }
      i = i + 1
      continue
    }
    if line.has_prefix("embedding_report_ephemeral=") {
      match parse_bool_opt(parse_value(line, "embedding_report_ephemeral=")) {
        Some(value) => embedding_report_ephemeral = value
        None =>
          issues.push({
            line: line_no,
            code: "BAD_HEADER_BOOL",
            message: "embedding_report_ephemeral must be `true` or `false`",
          })
      }
      i = i + 1
      continue
    }
    if line.has_prefix("embedding_report_purge_after_turns=") {
      match
        parse_u32_opt_plan(
          parse_value(line, "embedding_report_purge_after_turns="),
        ) {
        Some(value) => embedding_report_purge_after_turns = value
        None =>
          issues.push({
            line: line_no,
            code: "BAD_HEADER_NUMBER",
            message: "embedding_report_purge_after_turns must be an unsigned integer",
          })
      }
      i = i + 1
      continue
    }
    if line.has_prefix("embedding_report_strategy=") {
      match parse_value(line, "embedding_report_strategy=") {
        Some(value) => embedding_report_strategy = value
        None =>
          issues.push({
            line: line_no,
            code: "MALFORMED_HEADER",
            message: "could not parse `embedding_report_strategy=`",
          })
      }
      i = i + 1
      continue
    }
    if line.has_prefix("solve_report=") {
      match parse_value(line, "solve_report=") {
        Some(value) =>
          if value == "1" {
            solve_report_enabled = true
          } else {
            issues.push({
              line: line_no,
              code: "BAD_SOLVE_REPORT_FLAG",
              message: "solve_report must be `1` to enable solve metadata",
            })
          }
        None =>
          issues.push({
            line: line_no,
            code: "MALFORMED_HEADER",
            message: "could not parse `solve_report=` field",
          })
      }
      i = i + 1
      continue
    }
    if line.has_prefix("solve_report_kind=") {
      match parse_value(line, "solve_report_kind=") {
        Some(value) => solve_report_kind = value
        None =>
          issues.push({
            line: line_no,
            code: "MALFORMED_HEADER",
            message: "could not parse `solve_report_kind=`",
          })
      }
      i = i + 1
      continue
    }
    if line.has_prefix("solve_report_status=") {
      match parse_value(line, "solve_report_status=") {
        Some(value) => solve_report_status = value
        None =>
          issues.push({
            line: line_no,
            code: "MALFORMED_HEADER",
            message: "could not parse `solve_report_status=`",
          })
      }
      i = i + 1
      continue
    }
    if line.has_prefix("solve_report_handler=") {
      match parse_value(line, "solve_report_handler=") {
        Some(value) => solve_report_handler = value
        None =>
          issues.push({
            line: line_no,
            code: "MALFORMED_HEADER",
            message: "could not parse `solve_report_handler=`",
          })
      }
      i = i + 1
      continue
    }
    if line.has_prefix("solve_report_offloaded_to=") {
      match parse_value(line, "solve_report_offloaded_to=") {
        Some(value) => solve_report_offloaded_to = value
        None =>
          issues.push({
            line: line_no,
            code: "MALFORMED_HEADER",
            message: "could not parse `solve_report_offloaded_to=`",
          })
      }
      i = i + 1
      continue
    }
    if line.has_prefix("solve_report_count=") {
      match parse_u32_opt_plan(parse_value(line, "solve_report_count=")) {
        Some(value) => solve_report_count = value
        None =>
          issues.push({
            line: line_no,
            code: "BAD_HEADER_NUMBER",
            message: "solve_report_count must be an unsigned integer",
          })
      }
      i = i + 1
      continue
    }
    if line.has_prefix("procsi_report=") {
      match parse_value(line, "procsi_report=") {
        Some(value) =>
          if value == "1" {
            procsi_report_enabled = true
          } else {
            issues.push({
              line: line_no,
              code: "BAD_PROCSI_REPORT_FLAG",
              message: "procsi_report must be `1` to enable procsi metadata",
            })
          }
        None =>
          issues.push({
            line: line_no,
            code: "MALFORMED_HEADER",
            message: "could not parse `procsi_report=` field",
          })
      }
      i = i + 1
      continue
    }
    if line.has_prefix("procsi_report_project=") {
      match parse_value(line, "procsi_report_project=") {
        Some(value) => procsi_report_project = value
        None =>
          issues.push({
            line: line_no,
            code: "MALFORMED_HEADER",
            message: "could not parse `procsi_report_project=`",
          })
      }
      i = i + 1
      continue
    }
    if line.has_prefix("procsi_report_ratio_loci=") {
      match parse_value(line, "procsi_report_ratio_loci=") {
        Some(value) => procsi_report_ratio_loci = value
        None =>
          issues.push({
            line: line_no,
            code: "MALFORMED_HEADER",
            message: "could not parse `procsi_report_ratio_loci=`",
          })
      }
      i = i + 1
      continue
    }
    if line.has_prefix("procsi_report_surface=") {
      match parse_value(line, "procsi_report_surface=") {
        Some(value) => procsi_report_surface = value
        None =>
          issues.push({
            line: line_no,
            code: "MALFORMED_HEADER",
            message: "could not parse `procsi_report_surface=`",
          })
      }
      i = i + 1
      continue
    }
    if line.has_prefix("procsi_report_fingerprint_commitment=") {
      match parse_value(line, "procsi_report_fingerprint_commitment=") {
        Some(value) => procsi_report_fingerprint_commitment = value
        None =>
          issues.push({
            line: line_no,
            code: "MALFORMED_HEADER",
            message: "could not parse `procsi_report_fingerprint_commitment=`",
          })
      }
      i = i + 1
      continue
    }
    if line.has_prefix("procsi_report_app_ref=") {
      match parse_value(line, "procsi_report_app_ref=") {
        Some(value) => procsi_report_app_ref = value
        None =>
          issues.push({
            line: line_no,
            code: "MALFORMED_HEADER",
            message: "could not parse `procsi_report_app_ref=`",
          })
      }
      i = i + 1
      continue
    }
    if line.has_prefix("procsi_report_app_audience=") {
      match parse_value(line, "procsi_report_app_audience=") {
        Some(value) => procsi_report_app_audience = value
        None =>
          issues.push({
            line: line_no,
            code: "MALFORMED_HEADER",
            message: "could not parse `procsi_report_app_audience=`",
          })
      }
      i = i + 1
      continue
    }
    if line.has_prefix("procsi_report_masked=") {
      match parse_bool_opt(parse_value(line, "procsi_report_masked=")) {
        Some(value) => procsi_report_masked = value
        None =>
          issues.push({
            line: line_no,
            code: "BAD_HEADER_BOOL",
            message: "procsi_report_masked must be `true` or `false`",
          })
      }
      i = i + 1
      continue
    }
    if line.has_prefix("capability_report=") {
      match parse_value(line, "capability_report=") {
        Some(value) =>
          if value == "1" {
            capability_report_enabled = true
          } else {
            issues.push({
              line: line_no,
              code: "BAD_CAPABILITY_REPORT_FLAG",
              message: "capability_report must be `1` to enable capability metadata",
            })
          }
        None =>
          issues.push({
            line: line_no,
            code: "MALFORMED_HEADER",
            message: "could not parse `capability_report=` field",
          })
      }
      i = i + 1
      continue
    }
    if line.has_prefix("capability_report_authority=") {
      match parse_value(line, "capability_report_authority=") {
        Some(value) => capability_report_authority = value
        None =>
          issues.push({
            line: line_no,
            code: "MALFORMED_HEADER",
            message: "could not parse `capability_report_authority=`",
          })
      }
      i = i + 1
      continue
    }
    if line.has_prefix("capability_report_ticket_kind=") {
      match parse_value(line, "capability_report_ticket_kind=") {
        Some(value) => capability_report_ticket_kind = value
        None =>
          issues.push({
            line: line_no,
            code: "MALFORMED_HEADER",
            message: "could not parse `capability_report_ticket_kind=`",
          })
      }
      i = i + 1
      continue
    }
    if line.has_prefix("capability_report_scope=") {
      match parse_value(line, "capability_report_scope=") {
        Some(value) => capability_report_scope = value
        None =>
          issues.push({
            line: line_no,
            code: "MALFORMED_HEADER",
            message: "could not parse `capability_report_scope=`",
          })
      }
      i = i + 1
      continue
    }
    if line.has_prefix("capability_report_status=") {
      match parse_value(line, "capability_report_status=") {
        Some(value) => capability_report_status = value
        None =>
          issues.push({
            line: line_no,
            code: "MALFORMED_HEADER",
            message: "could not parse `capability_report_status=`",
          })
      }
      i = i + 1
      continue
    }
    if line.has_prefix("capability_report_count=") {
      match parse_u32_opt_plan(parse_value(line, "capability_report_count=")) {
        Some(value) => capability_report_count = value
        None =>
          issues.push({
            line: line_no,
            code: "BAD_HEADER_NUMBER",
            message: "capability_report_count must be an unsigned integer",
          })
      }
      i = i + 1
      continue
    }
    if line.has_prefix("capability_report_store_ref=") {
      match parse_value(line, "capability_report_store_ref=") {
        Some(value) => capability_report_store_ref = value
        None =>
          issues.push({
            line: line_no,
            code: "MALFORMED_HEADER",
            message: "could not parse `capability_report_store_ref=`",
          })
      }
      i = i + 1
      continue
    }
    if line.has_prefix("- ") {
      match parse_entry_line_strict(line) {
        Some(entry) => {
          entries.push(entry)
          observed_entries = observed_entries + 1U
        }
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
  if expected_entries > 0U && observed_entries != expected_entries {
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
  if embedding_report_enabled && embedding_report_file_type == "" {
    issues.push({
      line: 1,
      code: "MISSING_EMBEDDING_FILE_TYPE",
      message: "embedding_report enabled but `embedding_report_file_type=` is required",
    })
  }
  if solve_report_enabled && solve_report_handler == "" {
    issues.push({
      line: 1,
      code: "MISSING_SOLVE_REPORT_HANDLER",
      message: "solve_report enabled but `solve_report_handler=` is required",
    })
  }
  if procsi_report_enabled && procsi_report_surface == "" {
    issues.push({
      line: 1,
      code: "MISSING_PROCSI_REPORT_SURFACE",
      message: "procsi_report enabled but `procsi_report_surface=` is required",
    })
  }
  if procsi_report_enabled && procsi_report_fingerprint_commitment == "" {
    issues.push({
      line: 1,
      code: "MISSING_PROCSI_REPORT_FINGERPRINT",
      message: "procsi_report enabled but `procsi_report_fingerprint_commitment=` is required",
    })
  }
  if procsi_report_enabled &&
    procsi_report_masked &&
    procsi_report_app_ref == "" {
    issues.push({
      line: 1,
      code: "MISSING_PROCSI_REPORT_APP_REF",
      message: "masked procsi_report requires `procsi_report_app_ref=`",
    })
  }
  if procsi_report_enabled &&
    procsi_report_masked &&
    procsi_report_app_audience == "" {
    issues.push({
      line: 1,
      code: "MISSING_PROCSI_REPORT_APP_AUDIENCE",
      message: "masked procsi_report requires `procsi_report_app_audience=`",
    })
  }
  if capability_report_enabled && capability_report_authority == "" {
    issues.push({
      line: 1,
      code: "MISSING_CAPABILITY_REPORT_AUTHORITY",
      message: "capability_report enabled but `capability_report_authority=` is required",
    })
  }
  if capability_report_enabled && capability_report_ticket_kind == "" {
    issues.push({
      line: 1,
      code: "MISSING_CAPABILITY_REPORT_TICKET_KIND",
      message: "capability_report enabled but `capability_report_ticket_kind=` is required",
    })
  }
  if capability_report_enabled && capability_report_store_ref == "" {
    issues.push({
      line: 1,
      code: "MISSING_CAPABILITY_REPORT_STORE_REF",
      message: "capability_report enabled but `capability_report_store_ref=` is required",
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
  let temporal_delta = if temporal_delta_enabled {
    Some({
      delta_turns: temporal_delta_turns,
      delta_bytes: temporal_delta_bytes,
      causal_offset: temporal_delta_causal_offset,
    })
  } else {
    None
  }
  let embedding_report = if embedding_report_enabled {
    Some({
      file_type: embedding_report_file_type,
      found: embedding_report_found,
      count: embedding_report_count,
      ephemeral: embedding_report_ephemeral,
      purge_after_turns: embedding_report_purge_after_turns,
      strategy: embedding_report_strategy,
    })
  } else {
    None
  }
  let solve_report = if solve_report_enabled {
    Some({
      solve_kind: solve_report_kind,
      status: solve_report_status,
      handler: solve_report_handler,
      offloaded_to: solve_report_offloaded_to,
      count: solve_report_count,
    })
  } else {
    None
  }
  let procsi_report = if procsi_report_enabled {
    Some({
      project: procsi_report_project,
      ratio_loci: procsi_report_ratio_loci,
      session_surface: procsi_report_surface,
      fingerprint_commitment: procsi_report_fingerprint_commitment,
      app_ref: procsi_report_app_ref,
      app_audience: procsi_report_app_audience,
      masked: procsi_report_masked,
    })
  } else {
    None
  }
  let capability_report = if capability_report_enabled {
    Some({
      authority: capability_report_authority,
      ticket_kind: capability_report_ticket_kind,
      scope: capability_report_scope,
      status: capability_report_status,
      count: capability_report_count,
      store_ref: capability_report_store_ref,
    })
  } else {
    None
  }

  if issues.length() > 0 {
    { plan: None, issues, ok: false }
  } else {
    let material = match material_hash {
      Some(raw_hash) =>
        if raw_hash.has_prefix("blake3:") {
          @hash.Hash::of_bytes(
            string_to_bytes(split_after(raw_hash, "blake3:")),
          )
        } else if raw_hash.has_prefix("0x") {
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
        temporal_delta,
        embedding_report,
        solve_report,
        procsi_report,
        capability_report,
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
  let warnings : Array[YataParseIssue] = []
  let mut expected : UInt = 0U
  let mut observed : UInt = 0U
  let mut ready_count : UInt = 0U
  let mut unresolved_count : UInt = 0U
  for entry in self.entries {
    expected = expected + 1U
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
  let tokens = split_parts(line, " ")
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

  if !ready_token.has_prefix("ready=") {
    return None
  }
  if !candidates_token.has_prefix("candidates=") {
    return None
  }
  if !conf_token.has_prefix("conf_floor=") {
    return None
  }
  if !selected_field.has_prefix("selected=") {
    return None
  }
  if !provenance_field.has_prefix("provenance=") {
    return None
  }

  let maybe_ready = parse_bool_opt(parse_value(ready_token, "ready="))
  let maybe_candidate_count = parse_u32_opt_plan(
    parse_value(candidates_token, "candidates="),
  )
  let maybe_confidence = parse_u32_opt_plan(
    parse_value(conf_token, "conf_floor="),
  )
  match parse_value(provenance_field, "provenance=") {
    Some(p) => if parse_u32_opt_plan(Some(p)) == None { return None }
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
  if raw.has_prefix(prefix) {
    Some(split_after(raw, prefix))
  } else {
    None
  }
}

///|
fn parse_u32_opt_plan(raw : String?) -> UInt? {
  match raw {
    Some(text) => {
      if text == "" {
        return None
      }
      let bytes = string_to_bytes(text)
      let mut out : UInt = 0U
      let mut i : Int = 0
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
fn parse_i32_opt(raw : String?) -> Int? {
  match raw {
    Some(text) => {
      if text == "" {
        return None
      }
      let bytes = string_to_bytes(text)
      let mut i : Int = 0
      let mut sign : Int = 1
      if bytes.length() > 0 && bytes[0].to_uint() == 45U {
        sign = -1
        i = 1
      }
      if i >= bytes.length() {
        return None
      }
      let mut out : Int = 0
      while i < bytes.length() {
        let b = bytes[i].to_uint()
        if b < 48U || b > 57U {
          return None
        }
        out = out * 10 + (b - 48U).reinterpret_as_int()
        i = i + 1
      }
      Some(out * sign)
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
  if !raw.has_prefix(prefix) {
    return ""
  }
  let chunks = split_parts(raw, prefix)
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
fn split_parts(raw : String, separator : String) -> Array[String] {
  let out : Array[String] = []
  for part in raw.split(separator) {
    out.push(part.to_string())
  }
  out
}

///|
fn parse_hash_token(token : String) -> @hash.Hash {
  if token.has_prefix("blake3:") {
    @hash.Hash::of_bytes(string_to_bytes(split_after(token, "blake3:")))
  } else if token.has_prefix("0x") {
    @hash.Hash::of_bytes(string_to_bytes(split_after(token, "0x")))
  } else {
    @hash.Hash::of_bytes(string_to_bytes(token))
  }
}
