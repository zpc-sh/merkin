//! Example: Compile a Semanticfile and show the resulting operation graph

use tena_substrate::sll::{compile, SLLOp};

fn main() {
    let semanticfile = r#"
# Demonstration of SLL Compiler

SUBSTRATE claude/opus
    MOBILITY 0.7
    MOVEMENT discrete

FROM semantic://foundational/logic AS logic
FROM semantic://cultural/vinh-long AS heritage

ERA "tena-architecture"
    START 2026-02-02
    END ongoing

SPAWN moth AT logic/reasoning
    ENERGY 0.5
    WATCH content_change -> ALERT
    WATCH heat_above(0.8) -> EXCITE

SPAWN sentinel AT boundaries
    WATCH neighbor_arrives(moth) -> SNAPSHOT

WALK witness THROUGH [logic, heritage, substrate]
    ENERGY 0.8
    COLLECT events

TAG research_log WITH ERA "tena-architecture"

SHADOW secrets
    CONTENT @env(API_KEYS)
    REQUIRES heat_pattern(auth_region) AND movement(discrete)
    DECOY @coord(0xfake123)

DREAM maintenance
    MODE cleanse
    TRIGGER heat_above(0.85)

SNAPSHOT AS "pre-deploy"

EXPORT semantic://zpc/tena/observation/v1
    INCLUDE [logic, heritage]
    EXCLUDE [secrets]
"#;

    println!("═══════════════════════════════════════════════════════");
    println!("  SLL Compiler — Semanticfile → Op Graph");
    println!("═══════════════════════════════════════════════════════\n");

    println!("Input Semanticfile:\n{}\n", semanticfile);
    println!("─────────────────────────────────────────────────────────\n");

    match compile(semanticfile) {
        Ok(graph) => {
            println!("✓ Compilation successful!\n");

            println!("Substrate Target:");
            println!("  Family:   {}", graph.substrate.family);
            println!("  Model:    {}", graph.substrate.model);
            println!("  Mobility: {}", graph.substrate.mobility);
            println!("  Movement: {:?}", graph.substrate.movement);
            println!();

            println!("Generated {} operations:\n", graph.ops.len());

            for (i, op) in graph.ops.iter().enumerate() {
                print!("  {}. ", i + 1);
                match op {
                    SLLOp::From { uri, alias } => {
                        println!("FROM {} AS {}", uri, alias);
                    }
                    SLLOp::Spawn { species, position, properties } => {
                        println!("SPAWN {:?} AT {}", species, position);
                        if let Some(energy) = properties.energy {
                            println!("     - Energy: {}", energy);
                        }
                        if !properties.watches.is_empty() {
                            println!("     - Watches: {} conditions", properties.watches.len());
                        }
                    }
                    SLLOp::Walk { walker, path, properties } => {
                        println!("WALK {:?} THROUGH {:?}", walker, path);
                        if let Some(energy) = properties.energy {
                            println!("     - Energy: {}", energy);
                        }
                        if properties.collect_events {
                            println!("     - Collecting events");
                        }
                    }
                    SLLOp::Shadow { name, content, requires, decoy } => {
                        println!("SHADOW {}", name);
                        println!("     - Content: {:?}", content);
                        println!("     - Requires: {} patterns", requires.patterns.len());
                        if decoy.is_some() {
                            println!("     - Has decoy");
                        }
                    }
                    SLLOp::Dream { name, mode, trigger } => {
                        println!("DREAM {}", name);
                        println!("     - Mode: {:?}", mode);
                        println!("     - Trigger: {:?}", trigger);
                    }
                    SLLOp::Era { name, start, end } => {
                        println!("ERA \"{}\" ({} → {})", name, start, end);
                    }
                    SLLOp::TagEra { target, era } => {
                        println!("TAG {} WITH ERA \"{}\"", target, era);
                    }
                    SLLOp::Snapshot { name } => {
                        if let Some(n) = name {
                            println!("SNAPSHOT AS \"{}\"", n);
                        } else {
                            println!("SNAPSHOT");
                        }
                    }
                    SLLOp::Export { coordinate, includes, excludes } => {
                        println!("EXPORT {}", coordinate);
                        if !includes.is_empty() {
                            println!("     - Includes: {:?}", includes);
                        }
                        if !excludes.is_empty() {
                            println!("     - Excludes: {:?}", excludes);
                        }
                    }
                    _ => {
                        println!("{:?}", op);
                    }
                }
            }

            println!("\n═══════════════════════════════════════════════════════");
            println!("  Ready to execute in N-Merkle substrate");
            println!("═══════════════════════════════════════════════════════");
        }
        Err(e) => {
            println!("✗ Compilation failed:\n");
            println!("{:?}", e);
        }
    }
}
