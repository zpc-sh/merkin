//! Ingest Layer — The Marriage Point
//!
//! Transforms TENA ObserveEvents and StreamFrames into N-Merkle-FSM
//! operations across the 6 SMT dimensions.
//!
//! This is where the physical world (keystrokes, file opens, terminal commands)
//! becomes movement through semantic space.
//!
//! ```text
//! StreamFrame {
//!     events: [FileWrite, WindowFocus, TerminalCommand, ...],
//!     annotation: { phase: DeepDive, topics: ["ZFS"], novelty: 0.8 }
//! }
//!     │
//!     ├──→ ContentOp::Store (file contents → Content SMT)
//!     ├──→ TemporalOp::Append (frame → Temporal SMT chain)
//!     ├──→ SemanticOp::Embed (topics → Semantic SMT coordinates)
//!     ├──→ EraOp::Tag (phase → Era SMT)
//!     ├──→ ShadowOp (behavioral signature → Shadow SMT)
//!     └──→ DreamOp (reflection periods → Dream SMT)
//! ```

use tena_protocol::observe::*;
use crate::{Coordinate, coordinate, coord_from_str, SubstrateError};
use crate::node::{Node, Species, WatchCondition};

/// Operations generated from ingesting an observation frame
#[derive(Debug)]
pub struct IngestResult {
    /// Content operations (file writes, creates)
    pub content_ops: Vec<ContentIngestOp>,
    /// Temporal operation (frame appended to chain)
    pub temporal_op: TemporalIngestOp,
    /// Semantic operations (topic embeddings)
    pub semantic_ops: Vec<SemanticIngestOp>,
    /// Era operations (phase transitions)
    pub era_ops: Vec<EraIngestOp>,
    /// Shadow operations (behavioral signature updates)
    pub shadow_ops: Vec<ShadowIngestOp>,
    /// Dream operations (reflection periods)
    pub dream_ops: Vec<DreamIngestOp>,
    /// Heat generation events
    pub heat_events: Vec<HeatEvent>,
    /// Nodes to spawn (from watch triggers)
    pub spawn_requests: Vec<SpawnRequest>,
}

#[derive(Debug)]
pub struct ContentIngestOp {
    pub coordinate: Coordinate,
    pub path: String,
    pub size_bytes: u64,
}

#[derive(Debug)]
pub struct TemporalIngestOp {
    pub frame_coordinate: Coordinate,
    pub parent_coordinate: Option<Coordinate>,
    pub timestamp: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug)]
pub struct SemanticIngestOp {
    pub text_to_embed: String,
    pub topics: Vec<String>,
    pub novelty: f32,
}

#[derive(Debug)]
pub struct EraIngestOp {
    pub era_name: String,
    pub transition_type: EraTransitionType,
}

#[derive(Debug)]
pub enum EraTransitionType {
    Define { start: chrono::DateTime<chrono::Utc> },
    Transition { from: String },
    Tag { content: Coordinate },
}

#[derive(Debug)]
pub struct ShadowIngestOp {
    /// Typing cadence signature
    pub wpm: Option<f32>,
    /// Correction rate
    pub corrections: Option<u32>,
    /// Navigation pattern
    pub nav_pattern: Option<String>,
    /// Active tools (app names)
    pub active_tools: Vec<String>,
}

#[derive(Debug)]
pub struct DreamIngestOp {
    pub duration_ms: u64,
    pub trigger: DreamTrigger,
}

#[derive(Debug)]
pub enum DreamTrigger {
    ReflectionDetected,
    IdleTimeout,
    ExplicitRequest,
}

#[derive(Debug)]
pub struct HeatEvent {
    /// Which coordinate gets heat
    pub coordinate: Coordinate,
    /// How much heat (based on event intensity)
    pub intensity: f32,
    /// Source of heat
    pub source: String,
}

#[derive(Debug)]
pub struct SpawnRequest {
    pub species: Species,
    pub position: Coordinate,
    pub reason: String,
}

/// The ingest engine — stateful, tracks previous frame for temporal chaining
pub struct IngestEngine {
    /// Previous frame coordinate (for temporal chain)
    previous_frame: Option<Coordinate>,
    /// Current era
    current_era: Option<String>,
    /// Previous research phase (for transition detection)
    previous_phase: Option<String>,
    /// Behavioral signature accumulator (for shadow)
    signature_buffer: SignatureBuffer,
}

struct SignatureBuffer {
    wpm_samples: Vec<f32>,
    correction_rates: Vec<f32>,
    nav_patterns: Vec<String>,
    tool_sequences: Vec<Vec<String>>,
}

impl IngestEngine {
    pub fn new() -> Self {
        Self {
            previous_frame: None,
            current_era: None,
            previous_phase: None,
            signature_buffer: SignatureBuffer {
                wpm_samples: Vec::new(),
                correction_rates: Vec::new(),
                nav_patterns: Vec::new(),
                tool_sequences: Vec::new(),
            },
        }
    }

    /// Ingest a StreamFrame, producing N-Merkle operations
    pub fn ingest(&mut self, frame: &StreamFrame) -> IngestResult {
        let frame_coord = coordinate(&bincode::serialize(frame).unwrap_or_default());

        let mut result = IngestResult {
            content_ops: Vec::new(),
            temporal_op: TemporalIngestOp {
                frame_coordinate: frame_coord,
                parent_coordinate: self.previous_frame,
                timestamp: frame.timestamp,
            },
            semantic_ops: Vec::new(),
            era_ops: Vec::new(),
            shadow_ops: Vec::new(),
            dream_ops: Vec::new(),
            heat_events: Vec::new(),
            spawn_requests: Vec::new(),
        };

        // Process each raw event
        for event in &frame.events {
            self.process_event(event, &mut result);
        }

        // Process the semantic annotation
        self.process_annotation(&frame.annotation, &mut result);

        // Update temporal chain
        self.previous_frame = Some(frame_coord);

        result
    }

    fn process_event(&mut self, event: &ObserveEvent, result: &mut IngestResult) {
        match &event.event {
            // ── Content SMT feeds ──────────────────────────
            EventData::FileWrite { path, bytes_written } => {
                let coord = coord_from_str(path);
                result.content_ops.push(ContentIngestOp {
                    coordinate: coord,
                    path: path.clone(),
                    size_bytes: *bytes_written,
                });
                result.heat_events.push(HeatEvent {
                    coordinate: coord,
                    intensity: (*bytes_written as f32 / 10000.0).min(1.0),
                    source: "file_write".into(),
                });
            }
            EventData::FileCreate { path } => {
                let coord = coord_from_str(path);
                result.content_ops.push(ContentIngestOp {
                    coordinate: coord,
                    path: path.clone(),
                    size_bytes: 0,
                });
                result.heat_events.push(HeatEvent {
                    coordinate: coord,
                    intensity: 0.5,
                    source: "file_create".into(),
                });
            }

            // ── Heat generation from activity ──────────────
            EventData::FileOpen { path, app } => {
                result.heat_events.push(HeatEvent {
                    coordinate: coord_from_str(path),
                    intensity: 0.3,
                    source: format!("file_open:{}", app),
                });
            }
            EventData::WindowFocus { app_name, window_title, previous_dwell_ms, .. } => {
                // Heat at the semantic coordinate of the focused content
                let focus_coord = coord_from_str(&format!("{}:{}", app_name, window_title));
                result.heat_events.push(HeatEvent {
                    coordinate: focus_coord,
                    intensity: (*previous_dwell_ms as f32 / 60000.0).min(1.0),
                    source: format!("window_focus:{}", app_name),
                });
            }
            EventData::TerminalCommand { command, cwd, .. } => {
                let cmd_coord = coord_from_str(&format!("{}:{}", cwd, command));
                result.heat_events.push(HeatEvent {
                    coordinate: cmd_coord,
                    intensity: 0.6,
                    source: "terminal_command".into(),
                });
            }

            // ── Shadow SMT feeds (behavioral biometrics) ───
            EventData::TypedText { wpm, corrections, text, .. } => {
                self.signature_buffer.wpm_samples.push(*wpm);
                self.signature_buffer.correction_rates.push(*corrections as f32);
                
                result.shadow_ops.push(ShadowIngestOp {
                    wpm: Some(*wpm),
                    corrections: Some(*corrections),
                    nav_pattern: None,
                    active_tools: vec![],
                });

                // Also generates heat at whatever coordinate we're typing at
                result.heat_events.push(HeatEvent {
                    coordinate: coord_from_str(text),
                    intensity: 0.4,
                    source: "typed_text".into(),
                });
            }

            // ── Semantic events feed directly ──────────────
            EventData::ResearchPhase(phase) => {
                let phase_name = format!("{:?}", phase);
                
                // Check for phase transition → era boundary
                if let Some(ref prev) = self.previous_phase {
                    if *prev != phase_name {
                        result.era_ops.push(EraIngestOp {
                            era_name: phase_name.clone(),
                            transition_type: EraTransitionType::Transition {
                                from: prev.clone(),
                            },
                        });
                    }
                }
                self.previous_phase = Some(phase_name);
            }

            EventData::NavigationPattern(pattern) => {
                self.signature_buffer.nav_patterns.push(format!("{:?}", pattern));
            }

            // ── Everything else generates base-level heat ──
            _ => {
                result.heat_events.push(HeatEvent {
                    coordinate: coord_from_str(&format!("{:?}", event.source)),
                    intensity: 0.1,
                    source: "generic_activity".into(),
                });
            }
        }
    }

    fn process_annotation(&mut self, annotation: &SemanticAnnotation, result: &mut IngestResult) {
        // Semantic embedding from annotation
        result.semantic_ops.push(SemanticIngestOp {
            text_to_embed: annotation.activity_summary.clone(),
            topics: annotation.topics.clone(),
            novelty: annotation.novelty,
        });

        // High novelty → spawn a moth drawn to this area
        if annotation.novelty > 0.8 {
            result.spawn_requests.push(SpawnRequest {
                species: Species::Moth,
                position: coord_from_str(&annotation.activity_summary),
                reason: format!("High novelty event: {}", annotation.novelty),
            });
        }

        // Navigation pattern feeds shadow signature
        if let Some(ref nav) = annotation.navigation {
            result.shadow_ops.push(ShadowIngestOp {
                wpm: None,
                corrections: None,
                nav_pattern: Some(format!("{:?}", nav)),
                active_tools: annotation.active_tools.clone(),
            });
        }

        // Detect reflection → dream trigger
        if let ResearchPhase::Reflection { duration_ms } = &annotation.phase {
            if *duration_ms > 10_000 {  // >10s of reflection
                result.dream_ops.push(DreamIngestOp {
                    duration_ms: *duration_ms,
                    trigger: DreamTrigger::ReflectionDetected,
                });
            }
        }

        // Update tool sequence for behavioral signature
        self.signature_buffer.tool_sequences.push(annotation.active_tools.clone());
    }
}
