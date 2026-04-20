///|
/// Locus: a named workspace context for stigmergic agent activity.
/// Each locus has a spirit (purpose), tags, and references to membranes
/// and affordances that govern behavior within it.
///
/// Filesystem layout:
///   loci/<name>/
///     README.md         spirit, entry primitives, tags
///     affordances/      capability declarations
///     membranes/        scope/attribution policy
///     schemas/          structural templates
///     yata/             open holes
///     residue/          session exit notes
pub(all) struct Locus {
  name : String
  spirit : String
  tags : Array[String]
  membrane_refs : Array[@hash.Hash]
  affordance_refs : Array[@hash.Hash]
  trail_depth : UInt
  last_push_hash : @hash.Hash?
}

///|
/// Create a new empty locus.
pub fn Locus::new(name : String, spirit : String) -> Locus {
  {
    name,
    spirit,
    tags: [],
    membrane_refs: [],
    affordance_refs: [],
    trail_depth: 0U,
    last_push_hash: None,
  }
}

///|
/// Create a locus with tags.
pub fn Locus::with_tags(
  name : String,
  spirit : String,
  tags : Array[String],
) -> Locus {
  { ..Locus::new(name, spirit), tags, }
}

///|
/// Record a push event: increment trail depth and set the push hash.
pub fn Locus::record_push(self : Locus, push_hash : @hash.Hash) -> Locus {
  {
    ..self,
    trail_depth: self.trail_depth + 1U,
    last_push_hash: Some(push_hash),
  }
}

///|
/// Add a membrane reference.
pub fn Locus::add_membrane(self : Locus, hash_ref : @hash.Hash) -> Locus {
  let refs = self.membrane_refs
  refs.push(hash_ref)
  { ..self, membrane_refs: refs }
}

///|
/// Add an affordance reference.
pub fn Locus::add_affordance(self : Locus, hash_ref : @hash.Hash) -> Locus {
  let refs = self.affordance_refs
  refs.push(hash_ref)
  { ..self, affordance_refs: refs }
}

///|
/// Standard locus directory names.
pub fn locus_subdirs() -> Array[String] {
  ["affordances", "membranes", "schemas", "yata", "residue"]
}
