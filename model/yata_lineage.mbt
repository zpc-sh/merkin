///|
/// Track identity for emitted `.plan` artifacts.
pub(all) enum YataTrack {
  /// Semantic/program transformation track (in-progress reasoning + synthesis surface).
  Program
  /// Persistent VCS/auditable branch track.
  Git
} derive(Eq, Show)

///|
/// Plan emission density for consumers.
pub(all) enum YataPlanMode {
  Full
  Compact
} derive(Eq, Show)

///|
/// Serializable replay step for one Yata.
pub(all) struct YataReplayStep {
  sequence : UInt
  hole_id : @hash.Hash
  anchor : String
  state : String
  ready : Bool
  selected_candidate : String?
  is_admissible : Bool
} derive(Show)

///|
/// Public `.plan` line item for graph inspection.
pub(all) struct YataPlanEntry {
  hole_id : @hash.Hash
  anchor : String
  state : String
  candidate_count : UInt
  ready : Bool
  selected_candidate : String?
  provenance : Array[String]
  confidence_floor : UInt
} derive(Show)

///|
/// Optional self-report metadata for cross-layer replay and collaboration traceability.
pub(all) struct YataPlanSelfReport {
  /// Producing intelligence or subsystem tag.
  overlay : String
  /// Identity peer in a relay/collaboration context.
  peer : String
  /// Authority used for projection addressing.
  authority : String
  /// Anchor hint for relative replay.
  anchor_hint : String
  /// Reported gap requested at emit time.
  gap : UInt
  /// Optional view hint for projection (for example: overlay, sem, provenance).
  view_hint : String
} derive(Show)

///|
/// Optional git metadata for branch/merge provenance emitted as `.plan` overlays.
pub(all) struct YataPlanGitReport {
  branch : String
  remote : String
  merge_base : String
  head : String
  commit_count : UInt
  refs : String
} derive(Show)

///|
/// `.plan` payload that can be emitted without timestamps.
pub(all) struct YataPlan {
  track : YataTrack
  mode : YataPlanMode
  generator : String
  note : String
  material_hash : @hash.Hash
  self_report : YataPlanSelfReport?
  git_report : YataPlanGitReport?
  entries : Array[YataPlanEntry]
} derive(Show)

///|
/// Create a projected subgraph by explicit id set.
pub fn YataGraph::project(
  self : YataGraph,
  ids : Array[@hash.Hash],
) -> YataGraph {
  let mut out : Array[YataHole] = []
  for hole in self.holes {
    if array_contains_hash(ids, hole.hole_id) {
      out.push(hole)
    }
  }
  { holes: out }
}

///|
/// Reparent one dependency edge inside a specific Yata.
/// If `old_dep` is present, it is replaced with `new_dep`.
/// If `new_dep` is None, the dependency is removed.
/// If `old_dep` is not present and `new_dep` exists, append it.
pub fn YataGraph::reparent(
  self : YataGraph,
  hole_id : @hash.Hash,
  old_dep : @hash.Hash,
  new_dep : @hash.Hash?,
) -> YataGraph {
  let mut next : Array[YataHole] = []
  for hole in self.holes {
    if hole.hole_id == hole_id {
      next.push(reparent_hole_dependency(hole, old_dep, new_dep))
    } else {
      next.push(hole)
    }
  }
  { holes: next }
}

///|
/// Deterministic ancestry list for one hole. Great for replay-like lineage.
pub fn YataGraph::transitive_ancestry(
  self : YataGraph,
  root : @hash.Hash,
  max_depth : UInt,
) -> Array[@hash.Hash] {
  collect_ancestry(self, root, max_depth, [])
}

///|
/// Replay the causal chain that leads into this hole.
/// Returns dependencies-first order to permit deterministic forward processing.
pub fn YataGraph::lineage_replay(
  self : YataGraph,
  root : @hash.Hash,
  max_depth : UInt,
) -> Array[YataReplayStep] {
  let ids = self.transitive_ancestry(root, max_depth)
  let mut out : Array[YataReplayStep] = []
  let mut seq : UInt = 0U
  for hole_id in ids {
    match self.get(hole_id) {
      Some(hole) => {
        out.push({
          sequence: seq + 1U,
          hole_id: hole.hole_id,
          anchor: hole.anchor,
          state: yat_state_tag(hole.state),
          ready: hole.is_ready(self),
          selected_candidate: hole.selected_candidate,
          is_admissible: hole.admissible(),
        })
        seq = seq + 1U
      }
      None => ()
    }
  }
  out
}

///|
/// Build a `.plan` representation for cross-track reporting.
pub fn YataGraph::to_plan(
  self : YataGraph,
  track : YataTrack,
  mode : YataPlanMode,
  generator : String,
  note : String,
) -> YataPlan {
  let mut entries : Array[YataPlanEntry] = []
  let mut material : Array[String] = []
  for hole in self.holes {
    let entry = hole.to_plan_entry()
    material.push(entry.anchor)
    material.push(yat_state_tag(hole.state))
    material.push(entry.candidate_count.to_string())
    entries.push(entry)
  }
  let material_hash = @hash.Hash::of_bytes(
    string_to_bytes(join_by(material, ",")),
  )
  {
    track,
    mode,
    generator,
    note,
    material_hash,
    self_report: None,
    git_report: None,
    entries,
  }
}

///|
/// Attach a self-report envelope to a `.plan` for replay metadata.
pub fn YataPlan::with_self_report(
  self : YataPlan,
  self_report : YataPlanSelfReport,
) -> YataPlan {
  { ..self, self_report: Some(self_report) }
}

///|
/// Attach a git report envelope to a `.plan` for branch/merge provenance.
pub fn YataPlan::with_git_report(
  self : YataPlan,
  git_report : YataPlanGitReport,
) -> YataPlan {
  { ..self, git_report: Some(git_report) }
}

///|
/// Emit `.plan` wire format.
pub fn YataGraph::emit_plan(
  self : YataGraph,
  track : YataTrack,
  mode : YataPlanMode,
  generator : String,
  note : String,
) -> String {
  let plan = self.to_plan(track, mode, generator, note)
  plan.to_wire()
}

///|
/// Stable wire format for `.plan`.
pub fn YataPlan::to_wire(self : YataPlan) -> String {
  let mut b = StringBuilder::new()
  b.write_string("kind: merkin.yata.plan")
  b.write_string("\ntrack=")
  b.write_string(yat_track_tag(self.track))
  b.write_string("\nmode=")
  b.write_string(yat_mode_tag(self.mode))
  b.write_string("\ngenerator=")
  b.write_string(self.generator)
  b.write_string("\nnote=")
  b.write_string(self.note)
  b.write_string("\nmaterial_hash=")
  b.write_string(self.material_hash.key())
  match self.self_report {
    Some(report) => {
      b.write_string("\nself_report=1")
      b.write_string("\nself_report_overlay=")
      b.write_string(report.overlay)
      b.write_string("\nself_report_peer=")
      b.write_string(report.peer)
      b.write_string("\nself_report_authority=")
      b.write_string(report.authority)
      b.write_string("\nself_report_anchor=")
      b.write_string(report.anchor_hint)
      b.write_string("\nself_report_gap=")
      b.write_string(report.gap.to_string())
      b.write_string("\nself_report_view=")
      b.write_string(report.view_hint)
    }
    None => ()
  }
  match self.git_report {
    Some(report) => {
      b.write_string("\ngit_report=1")
      b.write_string("\ngit_report_branch=")
      b.write_string(report.branch)
      b.write_string("\ngit_report_remote=")
      b.write_string(report.remote)
      b.write_string("\ngit_report_merge_base=")
      b.write_string(report.merge_base)
      b.write_string("\ngit_report_head=")
      b.write_string(report.head)
      b.write_string("\ngit_report_commit_count=")
      b.write_string(report.commit_count.to_string())
      b.write_string("\ngit_report_refs=")
      b.write_string(report.refs)
    }
    None => ()
  }
  b.write_string("\n")
  for entry in self.entries {
    b.write_string("- ")
    b.write_string(entry.hole_id.key())
    b.write_string(" ")
    b.write_string(entry.anchor)
    b.write_string(" ")
    b.write_string(entry.state)
    b.write_string(" ready=")
    if entry.ready {
      b.write_string("true")
    } else {
      b.write_string("false")
    }
    b.write_string(" candidates=")
    b.write_string(entry.candidate_count.to_string())
    b.write_string(" conf_floor=")
    b.write_string(entry.confidence_floor.to_string())
    b.write_string(" selected=")
    match entry.selected_candidate {
      Some(candidate_id) => b.write_string(candidate_id)
      None => b.write_string("none")
    }
    b.write_string(" provenance=")
    b.write_string(entry.provenance.length().to_string())
    b.write_string("\n")
  }
  b.to_string()
}

///|
fn reparent_hole_dependency(
  hole : YataHole,
  old_dep : @hash.Hash,
  new_dep : @hash.Hash?,
) -> YataHole {
  let mut next_deps : Array[@hash.Hash] = []
  let mut replaced = false
  for dep in hole.dependencies {
    if dep == old_dep {
      replaced = true
      match new_dep {
        Some(next) =>
          if !array_contains_hash(next_deps, next) {
            next_deps.push(next)
          }
        None => ()
      }
    } else if !array_contains_hash(next_deps, dep) {
      next_deps.push(dep)
    }
  }
  if !replaced {
    match new_dep {
      Some(next) =>
        if !array_contains_hash(next_deps, next) {
          next_deps.push(next)
        }
      None => ()
    }
  }
  { ..hole, dependencies: next_deps }
}

///|
fn YataGraph::collect_ancestry(
  self : YataGraph,
  cursor : @hash.Hash,
  depth : UInt,
  visited : Array[@hash.Hash],
) -> Array[@hash.Hash] {
  if depth == 0U {
    return visited
  }
  match self.get(cursor) {
    Some(hole) => {
      if array_contains_hash(visited, cursor) {
        return visited
      }
      let mut next = visited
      for dep in hole.dependencies {
        next = collect_ancestry(self, dep, depth - 1U, next)
      }
      if !array_contains_hash(next, cursor) {
        next.push(cursor)
      }
      next
    }
    None => visited
  }
}

///|
fn join_by(items : Array[String], sep : String) -> String {
  if items.length() == 0 {
    return ""
  }
  let mut b = StringBuilder::new()
  b.write_string(items[0])
  for i = 1; i < items.length(); i = i + 1 {
    b.write_string(sep)
    b.write_string(items[i])
  }
  b.to_string()
}

///|
fn yat_state_tag(state : YataState) -> String {
  match state {
    Open => "open"
    Converging => "converging"
    Sealed(_) => "sealed"
    Resolved(_) => "resolved"
    Abandoned(_) => "abandoned"
  }
}

///|
fn yat_track_tag(track : YataTrack) -> String {
  match track {
    Program => "program"
    Git => "git"
  }
}

///|
fn yat_mode_tag(mode : YataPlanMode) -> String {
  match mode {
    Full => "full"
    Compact => "compact"
  }
}

///|
fn array_contains_hash(items : Array[@hash.Hash], target : @hash.Hash) -> Bool {
  for item in items {
    if item == target {
      return true
    }
  }
  false
}

///|
fn YataHole::to_plan_entry(self : YataHole) -> YataPlanEntry {
  {
    hole_id: self.hole_id,
    anchor: self.anchor,
    state: yat_state_tag(self.state),
    candidate_count: self.candidates.length(),
    ready: self.is_ready(self),
    selected_candidate: self.selected_candidate,
    provenance: self.provenance,
    confidence_floor: self.contract.min_confidence,
  }
}
