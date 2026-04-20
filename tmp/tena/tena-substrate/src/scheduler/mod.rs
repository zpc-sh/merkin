//! FSM Scheduler — executes paths through semantic space.
//!
//! Movement IS execution. The scheduler processes observation events
//! as implicit paths through the substrate.

use crate::node::{Node, TraverseAction};
use crate::heat::Heatmap;
use crate::Coordinate;
use std::collections::HashMap;

pub struct Scheduler {
    pub nodes: HashMap<Coordinate, Node>,
    pub heatmap: Heatmap,
    pub tick: u64,
}

impl Scheduler {
    pub fn new() -> Self {
        Self {
            nodes: HashMap::new(),
            heatmap: Heatmap::new(300.0),
            tick: 0,
        }
    }

    pub fn execute_path(&mut self, _walker_id: &Coordinate, _path: &[Coordinate]) -> Vec<TraversalEvent> {
        // TODO: implement full path execution
        vec![]
    }

    pub fn tick(&mut self) {
        self.tick += 1;
        // TODO: advance all mobile nodes
    }
}

#[derive(Debug)]
pub struct TraversalEvent {
    pub walker: Coordinate,
    pub position: Coordinate,
    pub action: TraverseAction,
    pub heat_generated: f32,
    pub tick: u64,
}
