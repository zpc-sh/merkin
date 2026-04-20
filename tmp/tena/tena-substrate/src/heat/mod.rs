//! Heatmap — Emergent from Activity
//!
//! Heat(coordinate) = Σ(recent_visits × intensity × time_decay)
//!
//! The heatmap is NOT computed separately. It IS the accumulated trail
//! of observation events and FSM activity. When TENA observes a file open,
//! that coordinate gets warmer. When nothing happens, it cools.
//!
//! Heat drives:
//! - Backend optimization (hot content → fast storage)
//! - Moth attraction (moths wander toward heat)
//! - Shadow gating (signatures match against heat patterns)
//! - Anomaly detection (unexpected heat = something interesting)
//! - Era detection (sustained heat = active era)
//! - Dream triggers (cold periods = time to dream)

use std::collections::HashMap;
use chrono::{DateTime, Utc, Duration};
use crate::Coordinate;
use crate::ingest::HeatEvent;

/// The heatmap: coordinate → accumulated heat with time decay
pub struct Heatmap {
    /// Heat entries: coordinate → (intensity, last_update)
    entries: HashMap<Coordinate, HeatEntry>,
    /// Decay rate: heat halves every `half_life` seconds
    half_life_secs: f64,
    /// Minimum heat threshold (below this, entry is pruned)
    prune_threshold: f32,
}

struct HeatEntry {
    /// Current heat intensity (0.0 - unbounded, but typically 0.0-10.0)
    intensity: f32,
    /// When this was last updated
    last_update: DateTime<Utc>,
    /// Cumulative visit count (never decays)
    total_visits: u64,
    /// Source breakdown: what's generating heat here
    sources: HashMap<String, f32>,
}

impl Heatmap {
    pub fn new(half_life_secs: f64) -> Self {
        Self {
            entries: HashMap::new(),
            half_life_secs,
            prune_threshold: 0.001,
        }
    }

    /// Apply a heat event from the ingest layer
    pub fn apply(&mut self, event: &HeatEvent) {
        let now = Utc::now();

        let entry = self.entries.entry(event.coordinate).or_insert(HeatEntry {
            intensity: 0.0,
            last_update: now,
            total_visits: 0,
            sources: HashMap::new(),
        });

        // Decay existing heat before adding new
        let elapsed = (now - entry.last_update).num_milliseconds() as f64 / 1000.0;
        let decay_factor = (0.5_f64).powf(elapsed / self.half_life_secs);
        entry.intensity *= decay_factor as f32;

        // Add new heat
        entry.intensity += event.intensity;
        entry.last_update = now;
        entry.total_visits += 1;

        // Track source breakdown
        *entry.sources.entry(event.source.clone()).or_insert(0.0) += event.intensity;
    }

    /// Get current heat at a coordinate (with decay applied)
    pub fn heat_at(&self, coord: &Coordinate) -> f32 {
        match self.entries.get(coord) {
            Some(entry) => {
                let now = Utc::now();
                let elapsed = (now - entry.last_update).num_milliseconds() as f64 / 1000.0;
                let decay_factor = (0.5_f64).powf(elapsed / self.half_life_secs);
                entry.intensity * decay_factor as f32
            }
            None => 0.0,
        }
    }

    /// Get total visit count (never decays — for long-term patterns)
    pub fn visits_at(&self, coord: &Coordinate) -> u64 {
        self.entries.get(coord).map(|e| e.total_visits).unwrap_or(0)
    }

    /// Find hottest N coordinates
    pub fn hottest(&self, n: usize) -> Vec<(Coordinate, f32)> {
        let now = Utc::now();
        let mut heated: Vec<(Coordinate, f32)> = self.entries.iter()
            .map(|(coord, entry)| {
                let elapsed = (now - entry.last_update).num_milliseconds() as f64 / 1000.0;
                let decay_factor = (0.5_f64).powf(elapsed / self.half_life_secs);
                (*coord, entry.intensity * decay_factor as f32)
            })
            .filter(|(_, heat)| *heat > self.prune_threshold)
            .collect();
        heated.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(std::cmp::Ordering::Equal));
        heated.truncate(n);
        heated
    }

    /// Find coldest coordinates (candidates for garbage collection / decomposer)
    pub fn coldest(&self, n: usize) -> Vec<(Coordinate, f32)> {
        let now = Utc::now();
        let mut cold: Vec<(Coordinate, f32)> = self.entries.iter()
            .map(|(coord, entry)| {
                let elapsed = (now - entry.last_update).num_milliseconds() as f64 / 1000.0;
                let decay_factor = (0.5_f64).powf(elapsed / self.half_life_secs);
                (*coord, entry.intensity * decay_factor as f32)
            })
            .collect();
        cold.sort_by(|a, b| a.1.partial_cmp(&b.1).unwrap_or(std::cmp::Ordering::Equal));
        cold.truncate(n);
        cold
    }

    /// Compute a heat signature from a set of coordinates
    /// This is used for shadow gating / Sambal authentication
    pub fn signature(&self, coordinates: &[Coordinate]) -> HeatSignature {
        let heats: Vec<f32> = coordinates.iter()
            .map(|c| self.heat_at(c))
            .collect();

        let mean = if heats.is_empty() { 0.0 } else {
            heats.iter().sum::<f32>() / heats.len() as f32
        };
        let variance = if heats.is_empty() { 0.0 } else {
            heats.iter().map(|h| (h - mean).powi(2)).sum::<f32>() / heats.len() as f32
        };
        let peak = heats.iter().cloned().fold(0.0_f32, f32::max);

        let hot_regions: Vec<Coordinate> = coordinates.iter()
            .zip(heats.iter())
            .filter(|(_, h)| **h > mean)
            .map(|(c, _)| *c)
            .collect();

        HeatSignature {
            hot_regions,
            mean_energy: mean,
            variance,
            peak_energy: peak,
            observed_at: Utc::now(),
        }
    }

    /// Match a signature against an expected pattern
    pub fn signature_matches(observed: &HeatSignature, expected: &HeatSignature, threshold: f32) -> bool {
        // Compare hot region overlap
        let overlap = observed.hot_regions.iter()
            .filter(|r| expected.hot_regions.contains(r))
            .count();
        let max_regions = observed.hot_regions.len().max(expected.hot_regions.len()).max(1);
        let region_score = overlap as f32 / max_regions as f32;

        // Compare energy distribution
        let energy_diff = (observed.mean_energy - expected.mean_energy).abs();
        let energy_score = 1.0 - (energy_diff / expected.mean_energy.max(0.001)).min(1.0);

        // Combined score
        let score = region_score * 0.6 + energy_score * 0.4;
        score >= threshold
    }

    /// Prune entries below threshold (garbage collection)
    pub fn prune(&mut self) {
        let now = Utc::now();
        self.entries.retain(|_, entry| {
            let elapsed = (now - entry.last_update).num_milliseconds() as f64 / 1000.0;
            let decay_factor = (0.5_f64).powf(elapsed / self.half_life_secs);
            entry.intensity * decay_factor as f32 > self.prune_threshold
        });
    }
}

/// A heat signature — behavioral fingerprint captured at a point in time
#[derive(Debug, Clone)]
pub struct HeatSignature {
    pub hot_regions: Vec<Coordinate>,
    pub mean_energy: f32,
    pub variance: f32,
    pub peak_energy: f32,
    pub observed_at: DateTime<Utc>,
}
