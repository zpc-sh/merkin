//! Sparse Merkle Tree implementations for the 6 dimensions.
//!
//! Each SMT is a separate tree with its own key space:
//! - Content: blake3(content) → leaf
//! - Temporal: chain of frame hashes (append-only)
//! - Semantic: embedding vector → hashed → leaf
//! - Era: era_name_hash → temporal range
//! - Shadow: gate_hash → (real_content, decoy, required_pattern)
//! - Dream: dream_hash → (pattern, mode, trigger)
//!
//! All trees share the same Coordinate type (32 bytes).
//! Trees are stored in ZFS datasets for snapshot integration.

use crate::Coordinate;
use std::collections::HashMap;

/// A sparse merkle tree dimension
pub struct SMT {
    /// In-memory leaf storage (TODO: persistent via ZFS)
    leaves: HashMap<Coordinate, Vec<u8>>,
    /// Root hash
    root: Coordinate,
    /// Dimension name
    pub dimension: Dimension,
}

#[derive(Debug, Clone, Copy)]
pub enum Dimension {
    Content,
    Temporal,
    Semantic,
    Era,
    Shadow,
    Dream,
}

impl SMT {
    pub fn new(dimension: Dimension) -> Self {
        Self {
            leaves: HashMap::new(),
            root: [0u8; 32],
            dimension,
        }
    }

    pub fn insert(&mut self, key: Coordinate, value: Vec<u8>) {
        self.leaves.insert(key, value);
        self.recompute_root();
    }

    pub fn get(&self, key: &Coordinate) -> Option<&Vec<u8>> {
        self.leaves.get(key)
    }

    pub fn contains(&self, key: &Coordinate) -> bool {
        self.leaves.contains_key(key)
    }

    pub fn root(&self) -> &Coordinate {
        &self.root
    }

    pub fn len(&self) -> usize {
        self.leaves.len()
    }

    fn recompute_root(&mut self) {
        // TODO: proper sparse merkle tree root computation
        // For now, hash all leaf keys together
        let mut hasher = blake3::Hasher::new();
        for key in self.leaves.keys() {
            hasher.update(key);
        }
        self.root = *hasher.finalize().as_bytes();
    }
}

/// The complete 6-dimensional substrate
pub struct SubstrateStore {
    pub content: SMT,
    pub temporal: SMT,
    pub semantic: SMT,
    pub era: SMT,
    pub shadow: SMT,
    pub dream: SMT,
}

impl SubstrateStore {
    pub fn new() -> Self {
        Self {
            content: SMT::new(Dimension::Content),
            temporal: SMT::new(Dimension::Temporal),
            semantic: SMT::new(Dimension::Semantic),
            era: SMT::new(Dimension::Era),
            shadow: SMT::new(Dimension::Shadow),
            dream: SMT::new(Dimension::Dream),
        }
    }

    /// Snapshot all 6 roots (for temporal consistency)
    pub fn snapshot_roots(&self) -> [Coordinate; 6] {
        [
            *self.content.root(),
            *self.temporal.root(),
            *self.semantic.root(),
            *self.era.root(),
            *self.shadow.root(),
            *self.dream.root(),
        ]
    }
}
