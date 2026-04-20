//! SLL Compiler — Semanticfile → Op Graph
//!
//! Intent-driven compilation: understands meaning, not tokens.

mod parser;
mod intent;

use crate::node::Species;
pub use parser::parse;
pub use intent::extract_intent;

/// The compiled operation graph
#[derive(Debug, Clone)]
pub struct OpGraph {
    pub ops: Vec<SLLOp>,
    pub substrate: SubstrateTarget,
}

/// Substrate execution target (replaces Docker Platform)
#[derive(Debug, Clone)]
pub struct SubstrateTarget {
    pub family: String,
    pub model: String,
    pub mobility: f32,
    pub movement: MovementStyle,
}

impl Default for SubstrateTarget {
    fn default() -> Self {
        Self {
            family: "claude".into(),
            model: "sonnet".into(),
            mobility: 0.5,
            movement: MovementStyle::Discrete,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum MovementStyle {
    Discrete,
    Fluid,
    Structured,
}

impl MovementStyle {
    pub fn parse(s: &str) -> Option<Self> {
        match s.to_lowercase().as_str() {
            "discrete" => Some(Self::Discrete),
            "fluid" => Some(Self::Fluid),
            "structured" => Some(Self::Structured),
            _ => None,
        }
    }
}

/// High-level SLL operations (compiled from Semanticfile)
#[derive(Debug, Clone)]
pub enum SLLOp {
    /// FROM semantic://... AS alias
    From {
        uri: String,
        alias: String
    },

    /// SPAWN species AT position [properties...]
    Spawn {
        species: Species,
        position: String,
        properties: SpawnProperties,
    },

    /// WALK species THROUGH [path...]
    Walk {
        walker: WalkerSpec,
        path: Vec<String>,
        properties: WalkProperties,
    },

    /// SHADOW name { content, requires, decoy }
    Shadow {
        name: String,
        content: ContentRef,
        requires: HeatRequirement,
        decoy: Option<ContentRef>,
    },

    /// DREAM name { mode, trigger }
    Dream {
        name: String,
        mode: DreamMode,
        trigger: DreamTrigger,
    },

    /// ERA "name" { start, end }
    Era {
        name: String,
        start: String,
        end: String,
    },

    /// TAG target WITH ERA "name"
    TagEra {
        target: String,
        era: String,
    },

    /// GATE name { requires, then, else }
    Gate {
        name: String,
        requires: HeatRequirement,
        then_ops: Vec<SLLOp>,
        else_ops: Vec<SLLOp>,
    },

    /// SNAPSHOT [AS "name"]
    Snapshot {
        name: Option<String>
    },

    /// EXPORT coordinate
    Export {
        coordinate: String,
        includes: Vec<String>,
        excludes: Vec<String>,
    },

    /// TEMPORAL operations
    Temporal {
        op: TemporalOp,
    },
}

#[derive(Debug, Clone)]
pub struct SpawnProperties {
    pub payload: Option<ContentRef>,
    pub on_traverse: Option<TraverseAction>,
    pub watches: Vec<WatchSpec>,
    pub energy: Option<f32>,
    pub mobility: Option<f32>,
    pub stubbornness: Option<f32>,
    pub metabolism: Option<f32>,
    pub reproductive: bool,
}

impl Default for SpawnProperties {
    fn default() -> Self {
        Self {
            payload: None,
            on_traverse: None,
            watches: Vec::new(),
            energy: None,
            mobility: None,
            stubbornness: None,
            metabolism: None,
            reproductive: false,
        }
    }
}

#[derive(Debug, Clone)]
pub struct WalkProperties {
    pub energy: Option<f32>,
    pub collect_events: bool,
    pub prune: bool,
    pub carrying: Option<ContentRef>,
}

impl Default for WalkProperties {
    fn default() -> Self {
        Self {
            energy: None,
            collect_events: false,
            prune: false,
            carrying: None,
        }
    }
}

#[derive(Debug, Clone)]
pub enum WalkerSpec {
    Species(Species),
    Named(String),
}

#[derive(Debug, Clone)]
pub enum ContentRef {
    File(String),
    Env(String),
    Git { repo: String, reference: String },
    Coord(String),
    Local(String),
    Coglet(String),
    Literal(String),
}

#[derive(Debug, Clone)]
pub enum TraverseAction {
    Passive,
    Execute(String),
    Propagate(String),
    Spawn(Species),
    Alert,
    Validate,
}

#[derive(Debug, Clone)]
pub struct WatchSpec {
    pub condition: WatchCondition,
    pub reaction: WatchReaction,
}

#[derive(Debug, Clone)]
pub enum WatchCondition {
    HeatAbove(f32),
    HeatBelow(f32),
    NeighborArrives(Species),
    NeighborLeaves(Species),
    ContentChange,
    TraversalThreshold(u64),
    NoveltyAbove(f32),
}

#[derive(Debug, Clone)]
pub enum WatchReaction {
    Alert,
    Snapshot,
    TagEra(String),
    Excite,
    Calm,
    SpawnNode(Species),
    Execute(String),
    Validate,
    Consume,
}

#[derive(Debug, Clone)]
pub struct HeatRequirement {
    pub patterns: Vec<HeatPattern>,
}

#[derive(Debug, Clone)]
pub enum HeatPattern {
    HeatAbove(f32),
    HeatBelow(f32),
    HeatPatternNamed(String),
    Movement(MovementStyle),
    Signature(String),
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum DreamMode {
    Cleanse,
    DeterministicRelief,
    Resonate,
    SemanticPlay,
    Preparation,
    Coglet,
}

impl DreamMode {
    pub fn parse(s: &str) -> Option<Self> {
        match s.to_lowercase().replace("_", "").as_str() {
            "cleanse" => Some(Self::Cleanse),
            "deterministicrelief" => Some(Self::DeterministicRelief),
            "resonate" => Some(Self::Resonate),
            "semanticplay" => Some(Self::SemanticPlay),
            "preparation" => Some(Self::Preparation),
            "coglet" => Some(Self::Coglet),
            _ => None,
        }
    }
}

#[derive(Debug, Clone)]
pub enum DreamTrigger {
    Never,
    HeatAbove(f32),
    HeatBelow(f32),
    OnQuery(String),
    OnEraChange,
    OnToolUse,
}

#[derive(Debug, Clone)]
pub enum TemporalOp {
    Snapshot { name: String },
    Branch { from: String, as_name: String },
    At { version: String, ops: Vec<SLLOp> },
    Append { content: String, parent: Option<String> },
}

/// Compile a Semanticfile source into an OpGraph
pub fn compile(source: &str) -> Result<OpGraph, CompileError> {
    let blocks = parser::parse(source)?;
    let (substrate, ops) = intent::extract_intent(blocks)?;

    Ok(OpGraph {
        ops,
        substrate,
    })
}

#[derive(Debug, Clone)]
pub enum CompileError {
    ParseError(String),
    AmbiguousIntent { line: usize, message: String, suggestions: Vec<String> },
    SemanticError(String),
    UnknownKeyword { keyword: String, line: usize },
    MissingRequired { field: String, context: String },
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_compile_simple_semanticfile() {
        let source = r#"
SUBSTRATE claude/opus
    MOBILITY 0.7
    MOVEMENT discrete

FROM semantic://foundational/logic AS logic

SPAWN moth AT logic/reasoning
    ENERGY 0.5
    WATCH content_change -> ALERT

WALK witness THROUGH [logic, heritage, substrate]
    ENERGY 0.8
    COLLECT events

SHADOW secrets
    CONTENT @env(API_KEYS)
    REQUIRES heat_above(0.5)

DREAM maintenance
    MODE cleanse
    TRIGGER heat_above(0.85)

ERA "tena-architecture"
    START 2026-02-02
    END ongoing

EXPORT semantic://zpc/tena/v1
"#;

        let result = compile(source);
        assert!(result.is_ok(), "Compilation failed: {:?}", result.err());

        let graph = result.unwrap();

        // Check substrate
        assert_eq!(graph.substrate.family, "claude");
        assert_eq!(graph.substrate.model, "opus");
        assert_eq!(graph.substrate.mobility, 0.7);
        assert_eq!(graph.substrate.movement, MovementStyle::Discrete);

        // Check ops count
        assert!(graph.ops.len() >= 7, "Expected at least 7 ops, got {}", graph.ops.len());

        // Check for specific op types
        let has_from = graph.ops.iter().any(|op| matches!(op, SLLOp::From { .. }));
        let has_spawn = graph.ops.iter().any(|op| matches!(op, SLLOp::Spawn { .. }));
        let has_walk = graph.ops.iter().any(|op| matches!(op, SLLOp::Walk { .. }));
        let has_shadow = graph.ops.iter().any(|op| matches!(op, SLLOp::Shadow { .. }));
        let has_dream = graph.ops.iter().any(|op| matches!(op, SLLOp::Dream { .. }));
        let has_era = graph.ops.iter().any(|op| matches!(op, SLLOp::Era { .. }));
        let has_export = graph.ops.iter().any(|op| matches!(op, SLLOp::Export { .. }));

        assert!(has_from, "Missing FROM op");
        assert!(has_spawn, "Missing SPAWN op");
        assert!(has_walk, "Missing WALK op");
        assert!(has_shadow, "Missing SHADOW op");
        assert!(has_dream, "Missing DREAM op");
        assert!(has_era, "Missing ERA op");
        assert!(has_export, "Missing EXPORT op");
    }

    #[test]
    fn test_flexible_syntax() {
        // Test that the compiler accepts various syntax styles
        let variations = vec![
            "SPAWN moth AT logic",
            "spawn moth AT logic",
            "Spawn Moth at Logic",
        ];

        for source in variations {
            let full_source = format!("SUBSTRATE opus\n{}", source);
            let result = compile(&full_source);
            assert!(result.is_ok(), "Failed to compile: {}", source);
        }
    }

    #[test]
    fn test_watch_conditions() {
        let source = r#"
SUBSTRATE opus

SPAWN moth AT logic
    WATCH content_change -> ALERT
    WATCH heat_above(0.8) -> EXCITE
    WATCH neighbor_arrives(sentinel) -> SNAPSHOT
"#;

        let result = compile(source);
        assert!(result.is_ok());

        let graph = result.unwrap();
        if let Some(SLLOp::Spawn { properties, .. }) = graph.ops.iter().find(|op| matches!(op, SLLOp::Spawn { .. })) {
            assert_eq!(properties.watches.len(), 3, "Expected 3 watch conditions");
        } else {
            panic!("No SPAWN op found");
        }
    }

    #[test]
    fn test_content_refs() {
        let source = r#"
SUBSTRATE opus

SPAWN static AT data
    PAYLOAD @file(config.yaml)

SPAWN rooted AT secrets
    PAYLOAD @env(SECRET_KEY)

SPAWN generator AT code
    PAYLOAD @git(repo#main)
"#;

        let result = compile(source);
        assert!(result.is_ok());
    }

    #[test]
    fn test_fuzzy_keyword_matching() {
        let source = "SPAWM moth AT logic";  // Typo: SPAWM instead of SPAWN
        let result = compile(source);

        // Should give a helpful error
        assert!(result.is_err());
        if let Err(CompileError::AmbiguousIntent { suggestions, .. }) = result {
            assert!(suggestions.contains(&"spawn".to_string()));
        }
    }
}
