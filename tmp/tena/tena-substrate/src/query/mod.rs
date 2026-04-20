//! Query Layer — `sift` semantic query resolution
//!
//! sift "ZFS architecture" --era "tena-architecture" --after 2026-02-01

use crate::Coordinate;
use crate::smt::SubstrateStore;

pub struct SiftQuery {
    pub text: String,
    pub era: Option<String>,
    pub before: Option<chrono::DateTime<chrono::Utc>>,
    pub after: Option<chrono::DateTime<chrono::Utc>>,
    pub top_k: usize,
}

pub struct SiftResult {
    pub coordinate: Coordinate,
    pub similarity: f32,
    pub content_preview: String,
    pub era: Option<String>,
    pub heat: f32,
}

pub fn sift(_store: &SubstrateStore, _query: &SiftQuery) -> Vec<SiftResult> {
    // TODO: embed query → search Semantic SMT → filter → rank
    vec![]
}
