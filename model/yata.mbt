///|
/// Typed semantic gap model inspired by hole-driven synthesis.
///
/// A Yata is not a ticket to wait on another actor.
/// It is a local, probabilistic contract-bound placeholder
/// that can host many possible completions and rationale.
pub(all) enum YataState {
  /// Hole exists and has no admissible completion yet.
  Open
  /// Candidate proposals have arrived, but none are final.
  Converging
  /// A candidate was selected as the preferred completion.
  Sealed(String)
  /// Candidate is accepted and recorded with optional witness data.
  Resolved(String)
  /// Hole is intentionally abandoned as impossible or out of scope.
  Abandoned(String)
} derive(Eq, Show)

///|
/// Yata contract describes the type boundary for what this gap is meant to hold.
pub(all) struct YataContract {
  /// Expected static shape or type.
  expected_type : String
  /// Optional invariants (e.g. "sorted", "deterministic", "idempotent").
  invariants : Array[String]
  /// Optional effect budget/constraints expressed by convention.
  effect_bounds : Array[String]
  /// Optional minimum confidence threshold (0-100) accepted by consumers.
  min_confidence : UInt
} derive(Show)

///|
/// Refinement adds local, composable constraints inside the same abstraction.
pub(all) struct YataRefinement {
  /// Human/machine tag for this constraint.
  label : String
  /// Formal/loose expression string for predicate-level constraints.
  predicate : String
  /// Relative importance for synthesis ranking.
  weight : UInt
} derive(Show)

///|
/// Candidate is a potential synthesis output for a Yata.
pub(all) struct YataCandidate {
  /// Stable candidate identifier.
  candidate_id : String
  /// Minimal surface of the candidate proposal.
  surface : String
  /// Confidence value for this candidate.
  confidence : UInt
  /// Optional rationale, proof sketch, or external pointer.
  rationale : String
} derive(Show)

///|
/// Optional witness metadata attached to a resolved Yata.
pub(all) struct YataWitness {
  /// Who/what proposed the accepted completion.
  proposer : String
  /// Compact signature of proof/analysis evidence.
  proof_token : String
  /// Optional external artifact reference (log hash, proof file, ticket id).
  proof_artifact : String
} derive(Show)

///|
/// YataHole is the abstract unresolved semantic slot.
pub(all) struct YataHole {
  /// Deterministic identifier.
  hole_id : @hash.Hash
  /// Human anchor for diagnostics and remapping.
  anchor : String
  /// Contractual boundary for expected completion.
  contract : YataContract
  /// Context refinements that tighten admissibility.
  refinements : Array[YataRefinement]
  /// Dependency edges to other holes by stable id.
  dependencies : Array[@hash.Hash]
  /// Ordered candidate space.
  candidates : Array[YataCandidate]
  /// Chosen candidate id when sealed/resolved.
  selected_candidate : String?
  /// Lifecycle state.
  state : YataState
  /// Lightweight provenance tags (`"chatgpt:sha256"`, `"claude:..."`).
  provenance : Array[String]
} derive(Show)

///|
/// Lightweight graph view for holes and dependency traversal.
pub(all) struct YataGraph {
  holes : Array[YataHole]
} derive(Show)

///|
/// Create a contract boundary.
pub fn YataContract::new(
  expected_type : String,
  invariants : Array[String],
  effect_bounds : Array[String],
  min_confidence : UInt,
) -> YataContract {
  { expected_type, invariants, effect_bounds, min_confidence }
}

///|
/// Create a refinement predicate.
pub fn YataRefinement::new(
  label : String,
  predicate : String,
  weight : UInt,
) -> YataRefinement {
  { label, predicate, weight }
}

///|
/// Create a proposal candidate.
pub fn YataCandidate::new(
  candidate_id : String,
  surface : String,
  confidence : UInt,
  rationale : String,
) -> YataCandidate {
  { candidate_id, surface, confidence, rationale }
}

///|
/// Create a witness bundle.
pub fn YataWitness::new(
  proposer : String,
  proof_token : String,
  proof_artifact : String,
) -> YataWitness {
  { proposer, proof_token, proof_artifact }
}

///|
/// Create an open, local Yata hole.
pub fn YataHole::new(
  anchor : String,
  contract : YataContract,
  refinements : Array[YataRefinement],
  dependencies : Array[@hash.Hash],
  provenance : Array[String],
) -> YataHole {
  let material = hole_material(
    anchor, contract, refinements, dependencies, provenance,
  )
  let hole_id = @hash.Hash::of_bytes(string_to_bytes(material))
  {
    hole_id,
    anchor,
    contract,
    refinements,
    dependencies,
    candidates: [],
    selected_candidate: None,
    state: Open,
    provenance,
  }
}

///|
/// Add a refinement constraint.
pub fn YataHole::add_refinement(
  self : YataHole,
  refinement : YataRefinement,
) -> YataHole {
  let refinements = self.refinements
  refinements.push(refinement)
  { ..self, refinements, }
}

///|
/// Add a dependency edge.
pub fn YataHole::add_dependency(
  self : YataHole,
  dependency : @hash.Hash,
) -> YataHole {
  let dependencies = self.dependencies
  dependencies.push(dependency)
  { ..self, dependencies, }
}

///|
/// Add a candidate proposal.
pub fn YataHole::propose(
  self : YataHole,
  candidate : YataCandidate,
) -> YataHole {
  let candidates = self.candidates
  candidates.push(candidate)
  { ..self, candidates, state: Converging }
}

///|
/// Select a candidate and optional witness provenance.
pub fn YataHole::seal(
  self : YataHole,
  candidate_id : String,
  witness : YataWitness?,
) -> YataHole {
  match witness {
    Some(w) => {
      let next = self.provenance
      next.push(state_to_trace(w.proposer, w.proof_token))
      {
        ..self,
        selected_candidate: Some(candidate_id),
        state: Sealed(candidate_id),
        provenance: next,
      }
    }
    None =>
      {
        ..self,
        selected_candidate: Some(candidate_id),
        state: Sealed(candidate_id),
      }
  }
}

///|
/// Resolve a chosen candidate. Resolution can happen only after sealing.
pub fn YataHole::resolve(self : YataHole) -> YataHole {
  match self.selected_candidate {
    Some(candidate_id) => { ..self, state: Resolved(candidate_id) }
    None => self
  }
}

///|
/// Abandon unresolved work.
pub fn YataHole::abandon(self : YataHole, reason : String) -> YataHole {
  let next = self.provenance
  next.push(reason)
  { ..self, state: Abandoned(reason), provenance: next }
}

///|
/// Indicates if all dependencies are already resolved.
pub fn YataHole::is_ready(self : YataHole, graph : YataGraph) -> Bool {
  for dependency in self.dependencies {
    match graph.get(dependency) {
      Some(hole) =>
        match hole.state {
          Resolved(_) => continue
          _ => return false
        }
      None => return false
    }
  }
  true
}

///|
/// Best candidate currently selected (if any) by local heuristic.
pub fn YataHole::best_candidate(self : YataHole) -> YataCandidate? {
  let mut best : YataCandidate? = None
  let mut best_score : UInt = 0
  for candidate in self.candidates {
    let score = candidate.confidence
    match best {
      Some(current) =>
        if score >= current.confidence && score >= best_score {
          best = Some(candidate)
          best_score = score
        }
      None => {
        best = Some(candidate)
        best_score = score
      }
    }
  }
  best
}

///|
/// Check admissibility against contract confidence floor.
pub fn YataHole::admissible(self : YataHole) -> Bool {
  self.contract.min_confidence <= self.max_candidate_confidence()
}

///|
/// Create empty Yata graph.
pub fn YataGraph::new() -> YataGraph {
  { holes: [] }
}

///|
/// Append a hole.
pub fn YataGraph::add(self : YataGraph, hole : YataHole) -> YataGraph {
  let holes = self.holes
  holes.push(hole)
  { holes, }
}

///|
/// Lookup by id.
pub fn YataGraph::get(self : YataGraph, id : @hash.Hash) -> YataHole? {
  for hole in self.holes {
    if hole.hole_id == id {
      return Some(hole)
    }
  }
  None
}

///|
/// Replace/update matching hole by id.
pub fn YataGraph::upsert(self : YataGraph, hole : YataHole) -> YataGraph {
  let holes = self.holes
  let updated : Array[YataHole] = []
  let mut touched = false
  for existing in holes {
    if existing.hole_id == hole.hole_id {
      updated.push(hole)
      touched = true
    } else {
      updated.push(existing)
    }
  }
  if touched {
    { holes: updated }
  } else {
    updated.push(hole)
    { holes: updated }
  }
}

///|
/// Return holes whose dependencies are all resolved.
pub fn YataGraph::ready_set(self : YataGraph) -> Array[YataHole] {
  let out : Array[YataHole] = []
  for hole in self.holes {
    if hole.is_ready(self) {
      out.push(hole)
    }
  }
  out
}

///|
fn YataHole::max_candidate_confidence(self : YataHole) -> UInt {
  let mut max : UInt = 0
  for candidate in self.candidates {
    if candidate.confidence > max {
      max = candidate.confidence
    }
  }
  max
}

///|
fn state_to_trace(actor : String, proof_token : String) -> String {
  actor + ":" + proof_token
}

///|
fn hole_material(
  anchor : String,
  contract : YataContract,
  refinements : Array[YataRefinement],
  dependencies : Array[@hash.Hash],
  provenance : Array[String],
) -> String {
  let b = StringBuilder::new()
  b.write_string(anchor)
  b.write_string("|")
  b.write_string(contract.expected_type)
  b.write_string("|")
  b.write_string(contract.min_confidence.to_string())
  b.write_string("|")
  b.write_string(refinements.length().to_string())
  b.write_string("|")
  b.write_string(dependencies.length().to_string())
  b.write_string("|")
  b.write_string(provenance.length().to_string())
  b.to_string()
}
