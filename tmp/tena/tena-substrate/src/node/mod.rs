//! Unified Node Model
//!
//! There is only movement in semantic space.
//! "FSM" = node with high mobility, low payload
//! "Content" = node with low mobility, high payload
//! All nodes. All on the same spectrum.

use serde::{Deserialize, Serialize};
use crate::Coordinate;

/// A node in semantic space — the universal primitive
#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct Node {
    pub id: Coordinate,
    /// Where in semantic space
    pub position: Coordinate,
    /// Content carried (if any)
    pub payload: Option<Coordinate>,
    /// Default behavior template
    pub species: Species,
    /// Customizable behavior
    pub genome: Genome,
    /// Fuel for movement (0.0 = dead, 1.0 = full)
    pub energy: f32,
    /// Lifecycle state (0.0 = decomposing, 1.0 = thriving)
    pub vitality: f32,
    /// ALWAYS TRANSPARENT metadata
    pub metadata: NodeMetadata,
}

/// Species define baseline behavior on the mobility spectrum
#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq)]
pub enum Species {
    /// 1.0 — Must always move, dies if stopped
    Hummingbird,
    /// 0.8 — Moves content between backends
    Courier,
    /// 0.7 — Seeks cold regions, prunes dead nodes
    Tidier,
    /// 0.6 — Patrols for anomalies
    Sentinel,
    /// 0.6 — Re-embeds on semantic drift
    Indexer,
    /// 0.6 — Follows others of same species
    Flocking,
    /// 0.5 — Wanders toward semantic heat
    Moth,
    /// 0.5 — Follows temporal edges, records history
    Witness,
    /// 0.4 — Consumes dead nodes, recycles
    Decomposer,
    /// 0.3 — Seeks cold regions to settle
    Seed,
    /// 0.2 — Spawns new nodes from content
    Generator,
    /// 0.1 — Anchored but can be pushed
    Rooted,
    /// 0.0 — Traditional content, doesn't move
    Static,
}

impl Species {
    /// Base mobility for this species
    pub fn base_mobility(&self) -> f32 {
        match self {
            Self::Hummingbird => 1.0,
            Self::Courier => 0.8,
            Self::Tidier => 0.7,
            Self::Sentinel => 0.6,
            Self::Indexer => 0.6,
            Self::Flocking => 0.6,
            Self::Moth => 0.5,
            Self::Witness => 0.5,
            Self::Decomposer => 0.4,
            Self::Seed => 0.3,
            Self::Generator => 0.2,
            Self::Rooted => 0.1,
            Self::Static => 0.0,
        }
    }
}

/// Genome: customizable behavior that overrides species defaults
#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct Genome {
    /// Override species mobility
    pub mobility: Option<f32>,
    /// Energy consumption per step
    pub metabolism: f32,
    /// How it behaves in collisions (0.0 = yields, 1.0 = immovable)
    pub stubbornness: f32,
    /// Can this node spawn offspring?
    pub reproductive: bool,
    /// What signals this node propagates when traversed
    pub propagates: Vec<Coordinate>,
    /// What happens when another node crosses this one
    pub on_traverse: TraverseAction,
    /// Reactive triggers
    pub watches: Vec<WatchCondition>,
}

impl Default for Genome {
    fn default() -> Self {
        Self {
            mobility: None,
            metabolism: 0.01,
            stubbornness: 0.5,
            reproductive: false,
            propagates: vec![],
            on_traverse: TraverseAction::Passive,
            watches: vec![],
        }
    }
}

/// What happens when a node is traversed (crossed by another node)
#[derive(Serialize, Deserialize, Debug, Clone)]
pub enum TraverseAction {
    /// Nothing happens
    Passive,
    /// Execute logic at this coordinate
    Execute(Coordinate),
    /// Spread a signal to neighbors
    Propagate(Coordinate),
    /// Birth a new node of this species
    Spawn(Species),
    /// Modify the traversing node's genome
    Transform(Box<Genome>),
}

/// Reactive conditions that trigger behavior
#[derive(Serialize, Deserialize, Debug, Clone)]
pub enum WatchCondition {
    /// Region heat exceeds threshold
    HeatAbove(f32),
    /// Region heat drops below threshold
    HeatBelow(f32),
    /// A specific species arrives in neighborhood
    NeighborArrives(Species),
    /// A specific species leaves neighborhood
    NeighborLeaves(Species),
    /// Payload content changes
    ContentChange,
    /// Traversal count exceeds threshold
    TraversalThreshold(u64),
    /// Phase transition detected (from TENA observe)
    PhaseChange(String),
    /// Novelty spike detected (from TENA observe)
    NoveltyAbove(f32),
}

/// Watch reaction: what to do when condition triggers
#[derive(Serialize, Deserialize, Debug, Clone)]
pub enum WatchReaction {
    Alert,
    Snapshot,
    TagEra(String),
    Excite,    // increase local heat
    Calm,      // decrease local heat
    SpawnNode(Species),
    Execute(Coordinate),
}

/// Transparent metadata — all behavior is visible, no hidden execution
#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct NodeMetadata {
    /// What signals flow through this node
    pub propagation_channels: Vec<Coordinate>,
    /// Traverse action (duplicate of genome for visibility)
    pub on_traverse: TraverseAction,
    /// Active watches
    pub watches: Vec<(WatchCondition, WatchReaction)>,
    /// Last action performed
    pub last_action: Option<String>,
    /// How often this node has been visited
    pub traverse_count: u64,
    /// When this node was created
    pub created_at: chrono::DateTime<chrono::Utc>,
    /// Last activity timestamp
    pub last_active: chrono::DateTime<chrono::Utc>,
}

impl Node {
    /// Effective mobility (genome override or species default)
    pub fn mobility(&self) -> f32 {
        self.genome.mobility.unwrap_or(self.species.base_mobility())
    }

    /// Is this node alive? (has energy and vitality)
    pub fn is_alive(&self) -> bool {
        self.energy > 0.0 && self.vitality > 0.0
    }

    /// Consume energy for one step of movement
    pub fn step(&mut self) -> bool {
        self.energy -= self.genome.metabolism;
        if self.energy <= 0.0 {
            self.energy = 0.0;
            // Hummingbirds die when they stop
            if self.species == Species::Hummingbird {
                self.vitality = 0.0;
            }
            false
        } else {
            true
        }
    }
}
