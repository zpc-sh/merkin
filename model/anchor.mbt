///|
/// Anchor state for existence proof lifecycle (§1.3).
pub(all) enum AnchorState {
  UNANCHORED
  PENDING
  ANCHORED
  FAILED
} derive(Eq, Show)

///|
/// Anchor: existence proof + optional time imprint (§1.3).
pub(all) struct Anchor {
  anchor_id : @hash.Hash
  subject_hash : @hash.Hash
  anchor_state : AnchorState
  akash_leaf_index : UInt64?
  akash_root_hash : @hash.Hash?
  mmr_proof_ref : String?
  temporash_ref : String?
  anchored_at : String? // RFC3339 timestamp, optional/lazy
  replication_vector : Array[String]
} derive(Show)

///|
/// Create a new unanchored Anchor from a subject hash.
pub fn Anchor::new(subject_hash : @hash.Hash) -> Anchor {
  // anchor_id = H(subject_hash) for uniqueness
  let anchor_id = @hash.Hash::of_bytes(subject_hash.digest)
  {
    anchor_id,
    subject_hash,
    anchor_state: UNANCHORED,
    akash_leaf_index: None,
    akash_root_hash: None,
    mmr_proof_ref: None,
    temporash_ref: None,
    anchored_at: None,
    replication_vector: [],
  }
}

///|
/// Transition to PENDING state.
pub fn Anchor::mark_pending(self : Anchor) -> Anchor {
  { ..self, anchor_state: PENDING }
}

///|
/// Transition to ANCHORED state with Akash proof data.
pub fn Anchor::mark_anchored(
  self : Anchor,
  leaf_index : UInt64,
  root_hash : @hash.Hash,
) -> Anchor {
  {
    ..self,
    anchor_state: ANCHORED,
    akash_leaf_index: Some(leaf_index),
    akash_root_hash: Some(root_hash),
  }
}

///|
/// Transition to FAILED state.
pub fn Anchor::mark_failed(self : Anchor) -> Anchor {
  { ..self, anchor_state: FAILED }
}

///|
/// Set the resolved timestamp (lazy fill).
pub fn Anchor::set_time(self : Anchor, rfc3339 : String) -> Anchor {
  { ..self, anchored_at: Some(rfc3339) }
}

///|
/// Set an external MMR proof reference.
pub fn Anchor::set_mmr_proof_ref(self : Anchor, proof_ref : String) -> Anchor {
  { ..self, mmr_proof_ref: Some(proof_ref) }
}

///|
/// Set external Tempora/Temporash reference.
pub fn Anchor::set_temporash_ref(self : Anchor, time_ref : String) -> Anchor {
  { ..self, temporash_ref: Some(time_ref) }
}

///|
/// Record one replica endpoint/id in the replication vector.
pub fn Anchor::add_replica(self : Anchor, replica : String) -> Anchor {
  let refs = self.replication_vector
  refs.push(replica)
  { ..self, replication_vector: refs }
}
