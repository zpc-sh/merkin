//! AttentionRouter — decides which node(s) receive operator input.
//!
//! The router is the "brain" that maps:
//! - AttentionEvents flowing UP from agents → focus decisions
//! - HID intents flowing DOWN from operator/Claude → the right Pi Zero
//!
//! It consumes:
//! - Substrate heatmap (all nodes, real-time)
//! - AttentionEvents from agents on each target
//! - Node scores (heat × urgency × relevance)
//!
//! And produces:
//! - Focus decisions (which node gets keyboard input)
//! - AttentionRouteDecision audit trail

use std::collections::{HashMap, VecDeque};
use std::sync::atomic::{AtomicU64, Ordering};
use chrono::{DateTime, Utc};
use tokio::sync::RwLock;
use tracing::info;
use uuid::Uuid;

use tena_protocol::attention::{
    AttentionEvent, AttentionEventType, AttentionRouteDecision,
    NodeScore, RouteReason,
};

/// Node identifier (hostname or device id)
pub type NodeId = String;

/// Configuration for the attention router
#[derive(Debug, Clone)]
pub struct AttentionConfig {
    /// Cooldown between focus shifts in milliseconds (prevents thrashing)
    pub cooldown_ms: u64,
    /// Maximum number of focus events to keep in history
    pub history_size: usize,
    /// Weight for heat in scoring (0.0 - 1.0)
    pub heat_weight: f64,
    /// Weight for urgency in scoring (0.0 - 1.0)
    pub urgency_weight: f64,
    /// Weight for relevance in scoring (0.0 - 1.0)
    pub relevance_weight: f64,
}

impl Default for AttentionConfig {
    fn default() -> Self {
        Self {
            cooldown_ms: 200,
            history_size: 100,
            heat_weight: 0.3,
            urgency_weight: 0.5,
            relevance_weight: 0.2,
        }
    }
}

/// A record of when focus shifted and why
#[derive(Debug, Clone)]
pub struct FocusEvent {
    pub node_id: NodeId,
    pub timestamp: DateTime<Utc>,
    pub reason: RouteReason,
    pub score: f64,
}

/// Per-node state tracked by the router
#[derive(Debug, Clone)]
struct NodeState {
    /// Current heat (from substrate heatmap)
    heat: f64,
    /// Pending urgency (from attention events)
    urgency: f64,
    /// Whether the node is available for input
    available: bool,
    /// Last attention event from this node
    last_event: Option<AttentionEvent>,
}

impl Default for NodeState {
    fn default() -> Self {
        Self {
            heat: 0.0,
            urgency: 0.0,
            available: true,
            last_event: None,
        }
    }
}

/// The AttentionRouter — routes operator focus across N compute nodes.
pub struct AttentionRouter {
    /// Per-node state
    nodes: RwLock<HashMap<NodeId, NodeState>>,
    /// Currently focused node (receives keyboard input)
    current_focus: RwLock<Option<NodeId>>,
    /// Focus history for pattern analysis
    focus_history: RwLock<VecDeque<FocusEvent>>,
    /// Timestamp of last focus shift (nanoseconds since epoch)
    last_shift_ns: AtomicU64,
    /// Configuration
    config: AttentionConfig,
}

impl AttentionRouter {
    pub fn new(config: AttentionConfig) -> Self {
        Self {
            nodes: RwLock::new(HashMap::new()),
            current_focus: RwLock::new(None),
            focus_history: RwLock::new(VecDeque::new()),
            last_shift_ns: AtomicU64::new(0),
            config,
        }
    }

    /// Register a node that can receive attention
    pub async fn register_node(&self, node_id: NodeId) {
        let mut nodes = self.nodes.write().await;
        nodes.entry(node_id.clone()).or_default();
        info!(node = %node_id, "Node registered with attention router");
    }

    /// Remove a node from attention routing
    pub async fn unregister_node(&self, node_id: &str) {
        let mut nodes = self.nodes.write().await;
        nodes.remove(node_id);

        // If this was the focused node, clear focus
        let mut focus = self.current_focus.write().await;
        if focus.as_deref() == Some(node_id) {
            *focus = None;
            info!(node = %node_id, "Focused node unregistered, focus cleared");
        }
    }

    /// Process an attention event from an agent.
    /// Updates node urgency and may trigger a focus shift.
    pub async fn handle_attention_event(&self, event: AttentionEvent) -> Option<AttentionRouteDecision> {
        let node_id = event.source_node.clone();
        let priority = event.priority;

        // Update node state
        {
            let mut nodes = self.nodes.write().await;
            let state = nodes.entry(node_id.clone()).or_default();
            state.urgency = priority as f64;
            state.last_event = Some(event.clone());
        }

        // Critical events force immediate focus shift (bypassing cooldown)
        if matches!(event.event_type, AttentionEventType::Critical { .. }) {
            return Some(self.shift_focus(
                node_id,
                RouteReason::AttentionEvent { event_id: event.id },
            ).await);
        }

        // High-priority events trigger focus shift if cooldown elapsed
        if priority > 50 && self.cooldown_elapsed() {
            return Some(self.shift_focus(
                node_id,
                RouteReason::AttentionEvent { event_id: event.id },
            ).await);
        }

        None
    }

    /// Explicitly set focus to a specific node (user/Claude requested)
    pub async fn set_focus(&self, node_id: NodeId) -> AttentionRouteDecision {
        self.shift_focus(node_id, RouteReason::Explicit).await
    }

    /// Get the currently focused node
    pub async fn current_focus(&self) -> Option<NodeId> {
        self.current_focus.read().await.clone()
    }

    /// Score all nodes and return sorted scores.
    /// Called by tick() and by route_intent() to find the best target.
    pub async fn score_all_nodes(&self) -> Vec<NodeScore> {
        let nodes = self.nodes.read().await;
        let current = self.current_focus.read().await;

        nodes.iter().map(|(node_id, state)| {
            let relevance = if current.as_ref() == Some(node_id) {
                1.0 // Current focus gets relevance bonus
            } else {
                0.5
            };

            let total = if state.available && self.cooldown_elapsed() {
                state.heat * self.config.heat_weight
                    + state.urgency * self.config.urgency_weight
                    + relevance * self.config.relevance_weight
            } else if state.available {
                // During cooldown, only score but don't allow shift
                state.heat * self.config.heat_weight
                    + state.urgency * self.config.urgency_weight
                    + relevance * self.config.relevance_weight
            } else {
                0.0
            };

            NodeScore {
                node_id: node_id.clone(),
                heat: state.heat,
                urgency: state.urgency,
                relevance,
                total,
                available: state.available,
            }
        }).collect()
    }

    /// Periodic tick — check if attention should shift based on scores.
    /// Call this every 100ms from the substrate's main loop.
    pub async fn tick(&self) -> Option<AttentionRouteDecision> {
        if !self.cooldown_elapsed() {
            return None;
        }

        let scores = self.score_all_nodes().await;
        let current = self.current_focus.read().await.clone();

        // Find highest scoring available node
        let best = scores.iter()
            .filter(|s| s.available)
            .max_by(|a, b| a.total.partial_cmp(&b.total).unwrap_or(std::cmp::Ordering::Equal));

        if let Some(best) = best {
            // Only shift if the best node is different from current and significantly better
            let should_shift = match &current {
                Some(current_id) => {
                    *current_id != best.node_id && best.total > 0.0 && {
                        let current_score = scores.iter()
                            .find(|s| s.node_id == *current_id)
                            .map(|s| s.total)
                            .unwrap_or(0.0);
                        // Require 20% improvement to shift (hysteresis)
                        best.total > current_score * 1.2
                    }
                }
                None => best.total > 0.0,
            };

            if should_shift {
                return Some(self.shift_focus(
                    best.node_id.clone(),
                    RouteReason::HighestScore,
                ).await);
            }
        }

        None
    }

    /// Update a node's heat value (called from substrate heatmap integration)
    pub async fn update_heat(&self, node_id: &str, heat: f64) {
        let mut nodes = self.nodes.write().await;
        if let Some(state) = nodes.get_mut(node_id) {
            state.heat = heat;
        }
    }

    /// Mark a node as available/unavailable for input
    pub async fn set_available(&self, node_id: &str, available: bool) {
        let mut nodes = self.nodes.write().await;
        if let Some(state) = nodes.get_mut(node_id) {
            state.available = available;
        }
    }

    /// Get focus history
    pub async fn focus_history(&self) -> Vec<FocusEvent> {
        self.focus_history.read().await.iter().cloned().collect()
    }

    // ── Internal ──────────────────────────────────────────

    /// Shift focus to a new node, recording the decision
    async fn shift_focus(&self, target: NodeId, reason: RouteReason) -> AttentionRouteDecision {
        let previous = {
            let mut focus = self.current_focus.write().await;
            let prev = focus.clone();
            *focus = Some(target.clone());
            prev
        };

        // Update cooldown timestamp
        let now_ns = Utc::now().timestamp_nanos_opt().unwrap_or(0) as u64;
        self.last_shift_ns.store(now_ns, Ordering::Relaxed);

        let scores = self.score_all_nodes().await;

        let decision = AttentionRouteDecision {
            id: Uuid::new_v4(),
            timestamp: Utc::now(),
            target_node: target.clone(),
            previous_node: previous.clone(),
            reason: reason.clone(),
            scores,
        };

        // Record in history
        {
            let mut history = self.focus_history.write().await;
            history.push_back(FocusEvent {
                node_id: target.clone(),
                timestamp: Utc::now(),
                reason,
                score: 0.0,
            });
            while history.len() > self.config.history_size {
                history.pop_front();
            }
        }

        info!(
            target = %target,
            previous = ?previous,
            "Attention focus shifted"
        );

        decision
    }

    /// Check if cooldown has elapsed since last focus shift
    fn cooldown_elapsed(&self) -> bool {
        let last = self.last_shift_ns.load(Ordering::Relaxed);
        if last == 0 {
            return true;
        }
        let now_ns = Utc::now().timestamp_nanos_opt().unwrap_or(0) as u64;
        let elapsed_ms = (now_ns.saturating_sub(last)) / 1_000_000;
        elapsed_ms >= self.config.cooldown_ms
    }
}
