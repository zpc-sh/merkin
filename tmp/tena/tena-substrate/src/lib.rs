//! # tena-substrate: N-Merkle-FSM Runtime
//!
//! The living filesystem. 6 sparse merkle trees, unified node model,
//! FSM scheduler, and the bridge from TENA observation events into
//! semantic space operations.
//!
//! ## Architecture
//!
//! ```text
//! ObserveEvents (from tena-observe)
//!     │
//!     ▼
//! Ingest Layer (event → SLL ops)
//!     │
//!     ▼
//! ┌───────────────────────────────────┐
//! │         6 SMT Dimensions          │
//! │  Content | Temporal | Semantic    │
//! │  Era     | Shadow   | Dream      │
//! └───────────────┬───────────────────┘
//!                 │
//!     ┌───────────┼───────────┐
//!     │           │           │
//!     ▼           ▼           ▼
//!   Nodes      Scheduler    Heatmap
//!  (species,   (path exec,  (emergent
//!   genome,    traversal)   from activity)
//!   energy)
//! ```

pub mod smt;
pub mod node;
pub mod scheduler;
pub mod ingest;
pub mod query;
pub mod sll;
pub mod heat;
pub mod attention;

use thiserror::Error;

/// 32-byte content-addressed coordinate in semantic space
pub type Coordinate = [u8; 32];

/// Compute coordinate from arbitrary data via blake3
pub fn coordinate(data: &[u8]) -> Coordinate {
    *blake3::hash(data).as_bytes()
}

/// Compute coordinate from string (convenience)
pub fn coord_from_str(s: &str) -> Coordinate {
    coordinate(s.as_bytes())
}

#[derive(Error, Debug)]
pub enum SubstrateError {
    #[error("Coordinate not found: {0:?}")]
    NotFound(Coordinate),
    #[error("SMT error: {0}")]
    SMTError(String),
    #[error("Energy depleted for node")]
    EnergyDepleted,
    #[error("Shadow gate denied: signature mismatch")]
    ShadowDenied,
    #[error("Ingest error: {0}")]
    IngestError(String),
}
