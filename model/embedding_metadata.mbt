///|
/// Embedding action used for ahead-of-time AI sanitization workflows.
pub(all) enum EmbeddingAction {
  Observe
  FlipAot
  Purge
} derive(Eq, Show)

///|
/// One detector hit over an arbitrary file payload.
pub(all) struct EmbeddingFinding {
  detector : String
  signature : String
  offset_start : UInt
  offset_end : UInt
  confidence : UInt
} derive(Show)

///|
/// File-level embedding metadata surface.
/// This is filetype-agnostic and can annotate any payload.
pub(all) struct EmbeddingMetadata {
  file_ref : String
  file_type : String
  mime_type : String
  found : Bool
  findings : Array[EmbeddingFinding]
  action : EmbeddingAction
  ephemeral : Bool
  purge_after_turns : UInt
  note : String
} derive(Show)

///|
pub fn EmbeddingMetadata::new(
  file_ref : String,
  file_type : String,
  mime_type : String,
) -> EmbeddingMetadata {
  {
    file_ref,
    file_type,
    mime_type,
    found: false,
    findings: [],
    action: Observe,
    ephemeral: true,
    purge_after_turns: 1U,
    note: "",
  }
}

///|
pub fn EmbeddingMetadata::mark_found(
  self : EmbeddingMetadata,
  finding : EmbeddingFinding,
) -> EmbeddingMetadata {
  let findings = self.findings
  findings.push(finding)
  { ..self, found: true, findings }
}

///|
pub fn EmbeddingMetadata::with_action(
  self : EmbeddingMetadata,
  action : EmbeddingAction,
  ephemeral : Bool,
  purge_after_turns : UInt,
  note : String,
) -> EmbeddingMetadata {
  { ..self, action, ephemeral, purge_after_turns, note }
}

///|
pub fn EmbeddingMetadata::should_purge(
  self : EmbeddingMetadata,
  turn_age : UInt,
) -> Bool {
  if !self.ephemeral {
    return false
  }
  turn_age >= self.purge_after_turns
}
