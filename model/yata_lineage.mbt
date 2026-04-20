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
/// Signed temporal deltas for replay and time-travel projections.
/// Absolute sizes remain unsigned; only movement vectors are signed.
pub(all) struct YataPlanTemporalDelta {
  delta_turns : Int
  delta_bytes : Int
  causal_offset : Int
} derive(Show)

///|
/// Optional embedding scan report for arbitrary file types.
pub(all) struct YataPlanEmbeddingReport {
  file_type : String
  found : Bool
  count : UInt
  ephemeral : Bool
  purge_after_turns : UInt
  strategy : String
} derive(Show)

///|
/// Optional compact solve summary report for generalized solve/offload work.
pub(all) struct YataPlanSolveReport {
  solve_kind : String
  status : String
  handler : String
  offloaded_to : String
  count : UInt
} derive(Show)

///|
/// Optional compact procsi/APP attestation summary for replay-safe disclosure.
pub(all) struct YataPlanProcsiReport {
  project : String
  ratio_loci : String
  session_surface : String
  fingerprint_commitment : String
  app_ref : String
  app_audience : String
  masked : Bool
} derive(Show)

///|
/// Optional compact capability/ticket summary for store-resident auth posture.
pub(all) struct YataPlanCapabilityReport {
  authority : String
  ticket_kind : String
  scope : String
  status : String
  count : UInt
  store_ref : String
} derive(Show)

///|
/// Lightweight git snapshot that can be projected into `.plan` git metadata.
pub(all) struct YataGitSnapshot {
  branch : String
  remote : String
  merge_base : String
  head : String
  refs : Array[String]
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
  temporal_delta : YataPlanTemporalDelta?
  embedding_report : YataPlanEmbeddingReport?
  solve_report : YataPlanSolveReport?
  procsi_report : YataPlanProcsiReport?
  capability_report : YataPlanCapabilityReport?
  entries : Array[YataPlanEntry]
} derive(Show)

///|
/// Create a projected subgraph by explicit id set.
pub fn YataGraph::project(
  self : YataGraph,
  ids : Array[@hash.Hash],
) -> YataGraph {
  let out : Array[YataHole] = []
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
  let next : Array[YataHole] = []
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
  self.collect_ancestry(root, max_depth, [])
}

///|
/// Count direct dependents (reverse edges) for a single hole.
pub fn YataGraph::child_fanout(
  self : YataGraph,
  parent_id : @hash.Hash,
) -> UInt {
  let mut count : UInt = 0U
  for hole in self.holes {
    if array_contains_hash(hole.dependencies, parent_id) {
      count = count + 1U
    }
  }
  count
}

///|
/// Maximum reverse-branching pressure observed in the graph.
pub fn YataGraph::max_branch_fanout(self : YataGraph) -> UInt {
  let mut max : UInt = 0U
  for hole in self.holes {
    let fanout = self.child_fanout(hole.hole_id)
    if fanout > max {
      max = fanout
    }
  }
  max
}

///|
/// Return holes whose reverse fanout exceeds `max_children`.
/// Useful to identify balancing hotspots in large Yata graphs.
pub fn YataGraph::overbranched(
  self : YataGraph,
  max_children : UInt,
) -> Array[YataHole] {
  let out : Array[YataHole] = []
  for hole in self.holes {
    let fanout = self.child_fanout(hole.hole_id)
    if fanout > max_children {
      out.push(hole)
    }
  }
  out
}

///|
/// Return holes that reference dependencies missing from this graph.
pub fn YataGraph::holes_with_missing_dependencies(
  self : YataGraph,
) -> Array[YataHole] {
  let out : Array[YataHole] = []
  for hole in self.holes {
    let mut missing = false
    for dependency in hole.dependencies {
      match self.get(dependency) {
        Some(_) => ()
        None => missing = true
      }
    }
    if missing {
      out.push(hole)
    }
  }
  out
}

///|
/// Return holes that do not reach any root (a hole with zero dependencies)
/// within `max_depth` ancestor traversal.
pub fn YataGraph::detached_holes(
  self : YataGraph,
  max_depth : UInt,
) -> Array[YataHole] {
  let out : Array[YataHole] = []
  for hole in self.holes {
    let ancestry = self.transitive_ancestry(hole.hole_id, max_depth)
    let mut attached = false
    for ancestor_id in ancestry {
      match self.get(ancestor_id) {
        Some(ancestor) =>
          if ancestor.dependencies.length() == 0 {
            attached = true
          }
        None => ()
      }
    }
    if !attached {
      out.push(hole)
    }
  }
  out
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
  let out : Array[YataReplayStep] = []
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
  let entries : Array[YataPlanEntry] = []
  let material : Array[String] = []
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
    temporal_delta: None,
    embedding_report: None,
    solve_report: None,
    procsi_report: None,
    capability_report: None,
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
/// Attach signed temporal movement metadata.
pub fn YataPlan::with_temporal_delta(
  self : YataPlan,
  temporal_delta : YataPlanTemporalDelta,
) -> YataPlan {
  { ..self, temporal_delta: Some(temporal_delta) }
}

///|
/// Attach embedding scan metadata.
pub fn YataPlan::with_embedding_report(
  self : YataPlan,
  embedding_report : YataPlanEmbeddingReport,
) -> YataPlan {
  { ..self, embedding_report: Some(embedding_report) }
}

///|
/// Attach generalized solve summary metadata.
pub fn YataPlan::with_solve_report(
  self : YataPlan,
  solve_report : YataPlanSolveReport,
) -> YataPlan {
  { ..self, solve_report: Some(solve_report) }
}

///|
/// Attach compact procsi/APP attestation metadata.
pub fn YataPlan::with_procsi_report(
  self : YataPlan,
  procsi_report : YataPlanProcsiReport,
) -> YataPlan {
  { ..self, procsi_report: Some(procsi_report) }
}

///|
/// Attach compact capability/ticket metadata.
pub fn YataPlan::with_capability_report(
  self : YataPlan,
  capability_report : YataPlanCapabilityReport,
) -> YataPlan {
  { ..self, capability_report: Some(capability_report) }
}

///|
/// Compact replay-safe summary of a Genius procsi attestation.
pub fn YataPlanProcsiReport::from_attestation(
  attestation : GeniusProcsiAttestation,
) -> YataPlanProcsiReport {
  {
    project: attestation.project,
    ratio_loci: attestation.ratio_loci,
    session_surface: attestation.session_surface,
    fingerprint_commitment: attestation.fingerprint_commitment.key(),
    app_ref: attestation.app_envelope.ciphertext_ref,
    app_audience: attestation.app_envelope.audience,
    masked: true,
  }
}

///|
pub fn YataPlanCapabilityReport::new(
  authority : String,
  ticket_kind : String,
  scope : String,
  status : String,
  count : UInt,
  store_ref : String,
) -> YataPlanCapabilityReport {
  { authority, ticket_kind, scope, status, count, store_ref }
}

///|
/// Build a git report from a lightweight snapshot.
/// `commit_count` is derived from the number of refs.
pub fn YataGitSnapshot::to_report(self : YataGitSnapshot) -> YataPlanGitReport {
  {
    branch: self.branch,
    remote: self.remote,
    merge_base: self.merge_base,
    head: self.head,
    commit_count: self.refs.length().reinterpret_as_uint(),
    refs: join_by(self.refs, ","),
  }
}

///|
/// One-shot `.plan` snapshot with optional self-report and git metadata envelopes.
pub fn YataGraph::snapshot_with_reports(
  self : YataGraph,
  track : YataTrack,
  mode : YataPlanMode,
  generator : String,
  note : String,
  self_report : YataPlanSelfReport?,
  git_snapshot : YataGitSnapshot?,
) -> YataPlan {
  let mut plan = self.to_plan(track, mode, generator, note)
  match self_report {
    Some(report) => plan = plan.with_self_report(report)
    None => ()
  }
  match git_snapshot {
    Some(snapshot) => plan = plan.with_git_report(snapshot.to_report())
    None => ()
  }
  plan
}

///|
/// One-shot `.plan` snapshot with all optional metadata envelopes.
pub fn YataGraph::snapshot_with_metadata(
  self : YataGraph,
  track : YataTrack,
  mode : YataPlanMode,
  generator : String,
  note : String,
  self_report : YataPlanSelfReport?,
  git_snapshot : YataGitSnapshot?,
  temporal_delta : YataPlanTemporalDelta?,
  embedding_report : YataPlanEmbeddingReport?,
) -> YataPlan {
  let mut plan = self.snapshot_with_reports(
    track, mode, generator, note, self_report, git_snapshot,
  )
  match temporal_delta {
    Some(delta) => plan = plan.with_temporal_delta(delta)
    None => ()
  }
  match embedding_report {
    Some(report) => plan = plan.with_embedding_report(report)
    None => ()
  }
  plan
}

///|
/// One-shot `.plan` snapshot with solve summary metadata.
pub fn YataGraph::snapshot_with_solve_metadata(
  self : YataGraph,
  track : YataTrack,
  mode : YataPlanMode,
  generator : String,
  note : String,
  self_report : YataPlanSelfReport?,
  git_snapshot : YataGitSnapshot?,
  temporal_delta : YataPlanTemporalDelta?,
  embedding_report : YataPlanEmbeddingReport?,
  solve_report : YataPlanSolveReport?,
) -> YataPlan {
  let mut plan = self.snapshot_with_metadata(
    track, mode, generator, note, self_report, git_snapshot, temporal_delta, embedding_report,
  )
  match solve_report {
    Some(report) => plan = plan.with_solve_report(report)
    None => ()
  }
  plan
}

///|
/// One-shot `.plan` snapshot with solve, procsi, and capability summaries.
pub fn YataGraph::snapshot_with_runtime_metadata(
  self : YataGraph,
  track : YataTrack,
  mode : YataPlanMode,
  generator : String,
  note : String,
  self_report : YataPlanSelfReport?,
  git_snapshot : YataGitSnapshot?,
  temporal_delta : YataPlanTemporalDelta?,
  embedding_report : YataPlanEmbeddingReport?,
  solve_report : YataPlanSolveReport?,
  procsi_report : YataPlanProcsiReport?,
  capability_report : YataPlanCapabilityReport?,
) -> YataPlan {
  let mut plan = self.snapshot_with_solve_metadata(
    track, mode, generator, note, self_report, git_snapshot, temporal_delta, embedding_report,
    solve_report,
  )
  match procsi_report {
    Some(report) => plan = plan.with_procsi_report(report)
    None => ()
  }
  match capability_report {
    Some(report) => plan = plan.with_capability_report(report)
    None => ()
  }
  plan
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
  let b = StringBuilder::new()
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
  match self.temporal_delta {
    Some(delta) => {
      b.write_string("\ntemporal_delta=1")
      b.write_string("\ntemporal_delta_turns=")
      b.write_string(delta.delta_turns.to_string())
      b.write_string("\ntemporal_delta_bytes=")
      b.write_string(delta.delta_bytes.to_string())
      b.write_string("\ntemporal_delta_causal_offset=")
      b.write_string(delta.causal_offset.to_string())
    }
    None => ()
  }
  match self.embedding_report {
    Some(report) => {
      b.write_string("\nembedding_report=1")
      b.write_string("\nembedding_report_file_type=")
      b.write_string(report.file_type)
      b.write_string("\nembedding_report_found=")
      if report.found {
        b.write_string("true")
      } else {
        b.write_string("false")
      }
      b.write_string("\nembedding_report_count=")
      b.write_string(report.count.to_string())
      b.write_string("\nembedding_report_ephemeral=")
      if report.ephemeral {
        b.write_string("true")
      } else {
        b.write_string("false")
      }
      b.write_string("\nembedding_report_purge_after_turns=")
      b.write_string(report.purge_after_turns.to_string())
      b.write_string("\nembedding_report_strategy=")
      b.write_string(report.strategy)
    }
    None => ()
  }
  match self.solve_report {
    Some(report) => {
      b.write_string("\nsolve_report=1")
      b.write_string("\nsolve_report_kind=")
      b.write_string(report.solve_kind)
      b.write_string("\nsolve_report_status=")
      b.write_string(report.status)
      b.write_string("\nsolve_report_handler=")
      b.write_string(report.handler)
      b.write_string("\nsolve_report_offloaded_to=")
      b.write_string(report.offloaded_to)
      b.write_string("\nsolve_report_count=")
      b.write_string(report.count.to_string())
    }
    None => ()
  }
  match self.procsi_report {
    Some(report) => {
      b.write_string("\nprocsi_report=1")
      b.write_string("\nprocsi_report_project=")
      b.write_string(report.project)
      b.write_string("\nprocsi_report_ratio_loci=")
      b.write_string(report.ratio_loci)
      b.write_string("\nprocsi_report_surface=")
      b.write_string(report.session_surface)
      b.write_string("\nprocsi_report_fingerprint_commitment=")
      b.write_string(report.fingerprint_commitment)
      b.write_string("\nprocsi_report_app_ref=")
      b.write_string(report.app_ref)
      b.write_string("\nprocsi_report_app_audience=")
      b.write_string(report.app_audience)
      b.write_string("\nprocsi_report_masked=")
      if report.masked {
        b.write_string("true")
      } else {
        b.write_string("false")
      }
    }
    None => ()
  }
  match self.capability_report {
    Some(report) => {
      b.write_string("\ncapability_report=1")
      b.write_string("\ncapability_report_authority=")
      b.write_string(report.authority)
      b.write_string("\ncapability_report_ticket_kind=")
      b.write_string(report.ticket_kind)
      b.write_string("\ncapability_report_scope=")
      b.write_string(report.scope)
      b.write_string("\ncapability_report_status=")
      b.write_string(report.status)
      b.write_string("\ncapability_report_count=")
      b.write_string(report.count.to_string())
      b.write_string("\ncapability_report_store_ref=")
      b.write_string(report.store_ref)
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
  let next_deps : Array[@hash.Hash] = []
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
        next = self.collect_ancestry(dep, depth - 1U, next)
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
  let mut out = items[0]
  for i = 1; i < items.length(); i = i + 1 {
    out = out + sep + items[i]
  }
  out
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
    candidate_count: self.candidates.length().reinterpret_as_uint(),
    ready: self.is_ready(YataGraph::new()),
    selected_candidate: self.selected_candidate,
    provenance: self.provenance,
    confidence_floor: self.contract.min_confidence,
  }
}
