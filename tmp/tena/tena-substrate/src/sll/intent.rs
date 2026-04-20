//! Intent Extraction — Understanding Semanticfile Blocks
//!
//! Maps parsed blocks to SLL operations by understanding intent.

use super::*;
use super::parser::{Block, Property};
use crate::node::Species;

/// Extract intent from parsed blocks
pub fn extract_intent(blocks: Vec<Block>) -> Result<(SubstrateTarget, Vec<SLLOp>), CompileError> {
    let mut substrate = SubstrateTarget::default();
    let mut ops = Vec::new();

    for block in blocks {
        match block.keyword.as_str() {
            "substrate" => {
                substrate = extract_substrate(&block)?;
            }
            "from" => {
                ops.push(extract_from(&block)?);
            }
            "spawn" => {
                ops.push(extract_spawn(&block)?);
            }
            "walk" => {
                ops.push(extract_walk(&block)?);
            }
            "shadow" => {
                ops.push(extract_shadow(&block)?);
            }
            "dream" => {
                ops.push(extract_dream(&block)?);
            }
            "era" => {
                ops.push(extract_era(&block)?);
            }
            "tag" => {
                ops.push(extract_tag(&block)?);
            }
            "gate" => {
                ops.push(extract_gate(&block)?);
            }
            "snapshot" => {
                ops.push(extract_snapshot(&block)?);
            }
            "export" => {
                ops.push(extract_export(&block)?);
            }
            "temporal" => {
                ops.push(extract_temporal(&block)?);
            }
            _ => {
                // Try fuzzy matching common typos
                let fuzzy_match = fuzzy_keyword(&block.keyword);
                if let Some(matched) = fuzzy_match {
                    return Err(CompileError::AmbiguousIntent {
                        line: block.line,
                        message: format!("Did you mean '{}'?", matched),
                        suggestions: vec![matched],
                    });
                } else {
                    return Err(CompileError::UnknownKeyword {
                        keyword: block.keyword.clone(),
                        line: block.line,
                    });
                }
            }
        }
    }

    Ok((substrate, ops))
}

fn extract_substrate(block: &Block) -> Result<SubstrateTarget, CompileError> {
    let target = block.target.as_ref()
        .ok_or_else(|| CompileError::MissingRequired {
            field: "substrate target".into(),
            context: "SUBSTRATE".into(),
        })?;

    // Parse "family/model" or just "model"
    let (family, model) = if target.contains('/') {
        let parts: Vec<&str> = target.split('/').collect();
        (parts[0].to_string(), parts[1].to_string())
    } else {
        // Infer family from model name
        let family = match target.to_lowercase().as_str() {
            "opus" | "sonnet" | "haiku" => "claude",
            "flash" | "pro" => "gemini",
            "gpt" => "openai",
            _ => "claude",
        };
        (family.to_string(), target.to_string())
    };

    let mut mobility = 0.5;
    let mut movement = MovementStyle::Discrete;

    for prop in &block.properties {
        match prop.key.as_str() {
            "mobility" => {
                mobility = prop.value.parse::<f32>()
                    .map_err(|_| CompileError::ParseError(
                        format!("Invalid mobility value: {}", prop.value)
                    ))?;
            }
            "movement" => {
                movement = MovementStyle::parse(&prop.value)
                    .ok_or_else(|| CompileError::ParseError(
                        format!("Invalid movement style: {}", prop.value)
                    ))?;
            }
            _ => {}
        }
    }

    Ok(SubstrateTarget {
        family,
        model,
        mobility,
        movement,
    })
}

fn extract_from(block: &Block) -> Result<SLLOp, CompileError> {
    let target = block.target.as_ref()
        .ok_or_else(|| CompileError::MissingRequired {
            field: "source".into(),
            context: "FROM".into(),
        })?;

    // Parse "source AS alias" or just "source"
    let (uri, alias) = if target.to_uppercase().contains(" AS ") {
        let parts: Vec<&str> = target.splitn(2, " AS ").collect();
        (parts[0].trim().to_string(), parts[1].trim().to_string())
    } else if target.to_lowercase().contains(" as ") {
        let parts: Vec<&str> = target.splitn(2, " as ").collect();
        (parts[0].trim().to_string(), parts[1].trim().to_string())
    } else {
        (target.clone(), target.clone())
    };

    // Expand shorthand URIs
    let expanded_uri = expand_uri(&uri);

    Ok(SLLOp::From {
        uri: expanded_uri,
        alias,
    })
}

fn extract_spawn(block: &Block) -> Result<SLLOp, CompileError> {
    let target = block.target.as_ref()
        .ok_or_else(|| CompileError::MissingRequired {
            field: "spawn target".into(),
            context: "SPAWN".into(),
        })?;

    // Parse "species AT position" (case-insensitive)
    let upper_target = target.to_uppercase();
    let (species_str, position) = if let Some(at_pos) = upper_target.find(" AT ") {
        let species_str = target[..at_pos].trim();
        let position = target[at_pos + 4..].trim().to_string();
        (species_str, position)
    } else {
        return Err(CompileError::ParseError(
            format!("SPAWN requires 'species AT position' format, got: {}", target)
        ));
    };

    let species = parse_species(species_str)?;
    let mut properties = SpawnProperties::default();

    for prop in &block.properties {
        match prop.key.as_str() {
            "payload" => {
                properties.payload = Some(parse_content_ref(&prop.value)?);
            }
            "on_traverse" | "ontraverse" => {
                properties.on_traverse = Some(parse_traverse_action(&prop.value)?);
            }
            "watch" => {
                properties.watches.push(parse_watch(&prop.value)?);
            }
            "energy" => {
                properties.energy = Some(prop.value.parse().map_err(|_| {
                    CompileError::ParseError(format!("Invalid energy: {}", prop.value))
                })?);
            }
            "mobility" => {
                properties.mobility = Some(prop.value.parse().map_err(|_| {
                    CompileError::ParseError(format!("Invalid mobility: {}", prop.value))
                })?);
            }
            "stubbornness" => {
                properties.stubbornness = Some(prop.value.parse().map_err(|_| {
                    CompileError::ParseError(format!("Invalid stubbornness: {}", prop.value))
                })?);
            }
            "metabolism" => {
                properties.metabolism = Some(prop.value.parse().map_err(|_| {
                    CompileError::ParseError(format!("Invalid metabolism: {}", prop.value))
                })?);
            }
            "reproductive" => {
                properties.reproductive = prop.value.to_lowercase() == "true";
            }
            _ => {}
        }
    }

    Ok(SLLOp::Spawn {
        species,
        position,
        properties,
    })
}

fn extract_walk(block: &Block) -> Result<SLLOp, CompileError> {
    let target = block.target.as_ref()
        .ok_or_else(|| CompileError::MissingRequired {
            field: "walk target".into(),
            context: "WALK".into(),
        })?;

    // Parse "walker THROUGH [path]" or "walker FROM a TO b" (case-insensitive)
    let upper_target = target.to_uppercase();
    let (walker, path) = if let Some(through_pos) = upper_target.find(" THROUGH ") {
        let walker_str = target[..through_pos].trim();
        let path_str = target[through_pos + 9..].trim();
        let walker = parse_walker(walker_str)?;
        let path = parse_path(path_str)?;
        (walker, path)
    } else if let (Some(from_pos), Some(to_pos)) = (upper_target.find(" FROM "), upper_target.find(" TO ")) {
        if from_pos < to_pos {
            let walker_str = target[..from_pos].trim();
            let from = target[from_pos + 6..to_pos].trim();
            let to = target[to_pos + 4..].trim();
            let walker = parse_walker(walker_str)?;
            (walker, vec![from.to_string(), to.to_string()])
        } else {
            return Err(CompileError::ParseError(
                format!("WALK requires 'walker THROUGH [path]' or 'walker FROM a TO b', got: {}", target)
            ));
        }
    } else {
        return Err(CompileError::ParseError(
            format!("WALK requires 'walker THROUGH [path]' or 'walker FROM a TO b', got: {}", target)
        ));
    };

    let mut properties = WalkProperties::default();

    for prop in &block.properties {
        match prop.key.as_str() {
            "energy" => {
                properties.energy = Some(prop.value.parse().map_err(|_| {
                    CompileError::ParseError(format!("Invalid energy: {}", prop.value))
                })?);
            }
            "collect" => {
                properties.collect_events = prop.value.to_lowercase().contains("event");
            }
            "prune" => {
                properties.prune = true;
            }
            "carrying" => {
                properties.carrying = Some(parse_content_ref(&prop.value)?);
            }
            _ => {}
        }
    }

    Ok(SLLOp::Walk {
        walker,
        path,
        properties,
    })
}

fn extract_shadow(block: &Block) -> Result<SLLOp, CompileError> {
    let name = block.target.as_ref()
        .ok_or_else(|| CompileError::MissingRequired {
            field: "shadow name".into(),
            context: "SHADOW".into(),
        })?
        .clone();

    let mut content = None;
    let mut requires = None;
    let mut decoy = None;

    for prop in &block.properties {
        match prop.key.as_str() {
            "content" => {
                content = Some(parse_content_ref(&prop.value)?);
            }
            "requires" => {
                requires = Some(parse_heat_requirement(&prop.value)?);
            }
            "threshold" => {
                // Handle threshold in requires
            }
            "decoy" => {
                decoy = Some(parse_content_ref(&prop.value)?);
            }
            _ => {}
        }
    }

    let content = content.ok_or_else(|| CompileError::MissingRequired {
        field: "content".into(),
        context: format!("SHADOW {}", name),
    })?;

    let requires = requires.ok_or_else(|| CompileError::MissingRequired {
        field: "requires".into(),
        context: format!("SHADOW {}", name),
    })?;

    Ok(SLLOp::Shadow {
        name,
        content,
        requires,
        decoy,
    })
}

fn extract_dream(block: &Block) -> Result<SLLOp, CompileError> {
    let name = block.target.as_ref()
        .ok_or_else(|| CompileError::MissingRequired {
            field: "dream name".into(),
            context: "DREAM".into(),
        })?
        .clone();

    let mut mode = None;
    let mut trigger = None;

    for prop in &block.properties {
        match prop.key.as_str() {
            "mode" => {
                mode = Some(DreamMode::parse(&prop.value)
                    .ok_or_else(|| CompileError::ParseError(
                        format!("Invalid dream mode: {}", prop.value)
                    ))?);
            }
            "trigger" => {
                trigger = Some(parse_dream_trigger(&prop.value)?);
            }
            _ => {}
        }
    }

    let mode = mode.ok_or_else(|| CompileError::MissingRequired {
        field: "mode".into(),
        context: format!("DREAM {}", name),
    })?;

    let trigger = trigger.unwrap_or(DreamTrigger::Never);

    Ok(SLLOp::Dream {
        name,
        mode,
        trigger,
    })
}

fn extract_era(block: &Block) -> Result<SLLOp, CompileError> {
    let name = block.target.as_ref()
        .ok_or_else(|| CompileError::MissingRequired {
            field: "era name".into(),
            context: "ERA".into(),
        })?
        .trim_matches('"')
        .to_string();

    let mut start = "".to_string();
    let mut end = "ongoing".to_string();

    for prop in &block.properties {
        match prop.key.as_str() {
            "start" => start = prop.value.clone(),
            "end" => end = prop.value.clone(),
            _ => {}
        }
    }

    Ok(SLLOp::Era { name, start, end })
}

fn extract_tag(block: &Block) -> Result<SLLOp, CompileError> {
    let target = block.target.as_ref()
        .ok_or_else(|| CompileError::MissingRequired {
            field: "tag target".into(),
            context: "TAG".into(),
        })?;

    // Parse "target WITH ERA name"
    if let Some(with_pos) = target.to_uppercase().find(" WITH ERA ") {
        let target_name = target[..with_pos].trim().to_string();
        let era_part = &target[with_pos + 10..];
        let era_name = era_part.trim().trim_matches('"').to_string();

        Ok(SLLOp::TagEra {
            target: target_name,
            era: era_name,
        })
    } else {
        Err(CompileError::ParseError(
            format!("TAG requires 'target WITH ERA name' format, got: {}", target)
        ))
    }
}

fn extract_gate(block: &Block) -> Result<SLLOp, CompileError> {
    let name = block.target.as_ref()
        .ok_or_else(|| CompileError::MissingRequired {
            field: "gate name".into(),
            context: "GATE".into(),
        })?
        .clone();

    let mut requires = None;

    for prop in &block.properties {
        match prop.key.as_str() {
            "requires" => {
                requires = Some(parse_heat_requirement(&prop.value)?);
            }
            _ => {}
        }
    }

    let requires = requires.ok_or_else(|| CompileError::MissingRequired {
        field: "requires".into(),
        context: format!("GATE {}", name),
    })?;

    // TODO: Parse THEN/ELSE blocks (nested ops)
    let then_ops = Vec::new();
    let else_ops = Vec::new();

    Ok(SLLOp::Gate {
        name,
        requires,
        then_ops,
        else_ops,
    })
}

fn extract_snapshot(block: &Block) -> Result<SLLOp, CompileError> {
    let name = block.target.as_ref()
        .filter(|t| t.to_uppercase().starts_with("AS "))
        .map(|t| t[3..].trim().trim_matches('"').to_string());

    Ok(SLLOp::Snapshot { name })
}

fn extract_export(block: &Block) -> Result<SLLOp, CompileError> {
    let coordinate = block.target.as_ref()
        .ok_or_else(|| CompileError::MissingRequired {
            field: "export target".into(),
            context: "EXPORT".into(),
        })?
        .clone();

    let mut includes = Vec::new();
    let mut excludes = Vec::new();

    for prop in &block.properties {
        match prop.key.as_str() {
            "include" => {
                includes = parse_list(&prop.value);
            }
            "exclude" => {
                excludes = parse_list(&prop.value);
            }
            _ => {}
        }
    }

    Ok(SLLOp::Export {
        coordinate,
        includes,
        excludes,
    })
}

fn extract_temporal(_block: &Block) -> Result<SLLOp, CompileError> {
    // TODO: Parse temporal operations
    Ok(SLLOp::Temporal {
        op: TemporalOp::Snapshot { name: "temp".into() },
    })
}

// ═══════════════════════════════════════════════════════════════
// Helper Parsers
// ═══════════════════════════════════════════════════════════════

fn parse_species(s: &str) -> Result<Species, CompileError> {
    match s.trim().to_lowercase().as_str() {
        "hummingbird" => Ok(Species::Hummingbird),
        "courier" => Ok(Species::Courier),
        "tidier" => Ok(Species::Tidier),
        "sentinel" => Ok(Species::Sentinel),
        "indexer" => Ok(Species::Indexer),
        "flocking" => Ok(Species::Flocking),
        "moth" => Ok(Species::Moth),
        "witness" => Ok(Species::Witness),
        "decomposer" => Ok(Species::Decomposer),
        "seed" => Ok(Species::Seed),
        "generator" => Ok(Species::Generator),
        "rooted" => Ok(Species::Rooted),
        "static" => Ok(Species::Static),
        _ => Err(CompileError::ParseError(format!("Unknown species: {}", s))),
    }
}

fn parse_walker(s: &str) -> Result<WalkerSpec, CompileError> {
    if let Ok(species) = parse_species(s) {
        Ok(WalkerSpec::Species(species))
    } else {
        Ok(WalkerSpec::Named(s.to_string()))
    }
}

fn parse_path(s: &str) -> Result<Vec<String>, CompileError> {
    // Handle [a, b, c] or just "a, b, c" or "path"
    let trimmed = s.trim();
    if trimmed.starts_with('[') && trimmed.ends_with(']') {
        let inner = &trimmed[1..trimmed.len() - 1];
        Ok(inner.split(',').map(|s| s.trim().to_string()).collect())
    } else if trimmed.contains(',') {
        Ok(trimmed.split(',').map(|s| s.trim().to_string()).collect())
    } else {
        Ok(vec![trimmed.to_string()])
    }
}

fn parse_content_ref(s: &str) -> Result<ContentRef, CompileError> {
    let trimmed = s.trim();

    if trimmed.starts_with("@file(") && trimmed.ends_with(')') {
        let path = &trimmed[6..trimmed.len() - 1];
        Ok(ContentRef::File(path.to_string()))
    } else if trimmed.starts_with("@env(") && trimmed.ends_with(')') {
        let var = &trimmed[5..trimmed.len() - 1];
        Ok(ContentRef::Env(var.to_string()))
    } else if trimmed.starts_with("@git(") && trimmed.ends_with(')') {
        let spec = &trimmed[5..trimmed.len() - 1];
        let parts: Vec<&str> = spec.split('#').collect();
        Ok(ContentRef::Git {
            repo: parts[0].to_string(),
            reference: parts.get(1).unwrap_or(&"main").to_string(),
        })
    } else if trimmed.starts_with("@coord(") && trimmed.ends_with(')') {
        let coord = &trimmed[7..trimmed.len() - 1];
        Ok(ContentRef::Coord(coord.to_string()))
    } else if trimmed.starts_with("@local(") && trimmed.ends_with(')') {
        let path = &trimmed[7..trimmed.len() - 1];
        Ok(ContentRef::Local(path.to_string()))
    } else if trimmed.starts_with("@coglet(") && trimmed.ends_with(')') {
        let name = &trimmed[8..trimmed.len() - 1];
        Ok(ContentRef::Coglet(name.to_string()))
    } else {
        Ok(ContentRef::Literal(trimmed.to_string()))
    }
}

fn parse_traverse_action(s: &str) -> Result<TraverseAction, CompileError> {
    let trimmed = s.trim().to_lowercase();

    if trimmed == "passive" {
        Ok(TraverseAction::Passive)
    } else if trimmed.starts_with("execute(") || trimmed.starts_with("execute ") {
        let target = extract_parens_or_after(&trimmed, "execute");
        Ok(TraverseAction::Execute(target))
    } else if trimmed.starts_with("propagate(") || trimmed.starts_with("propagate ") {
        let signal = extract_parens_or_after(&trimmed, "propagate");
        Ok(TraverseAction::Propagate(signal))
    } else if trimmed.starts_with("spawn(") || trimmed.starts_with("spawn ") {
        let species_str = extract_parens_or_after(&trimmed, "spawn");
        let species = parse_species(&species_str)?;
        Ok(TraverseAction::Spawn(species))
    } else if trimmed == "alert" {
        Ok(TraverseAction::Alert)
    } else if trimmed == "validate" {
        Ok(TraverseAction::Validate)
    } else {
        Err(CompileError::ParseError(format!("Unknown traverse action: {}", s)))
    }
}

fn parse_watch(s: &str) -> Result<WatchSpec, CompileError> {
    // Parse "condition -> reaction"
    let parts: Vec<&str> = s.split("->").collect();
    if parts.len() != 2 {
        return Err(CompileError::ParseError(format!("Invalid watch format: {}", s)));
    }

    let condition = parse_watch_condition(parts[0].trim())?;
    let reaction = parse_watch_reaction(parts[1].trim())?;

    Ok(WatchSpec { condition, reaction })
}

fn parse_watch_condition(s: &str) -> Result<WatchCondition, CompileError> {
    let trimmed = s.trim().to_lowercase();

    if trimmed.starts_with("heat_above(") {
        let val = extract_parens_or_after(&trimmed, "heat_above");
        let threshold = val.parse().map_err(|_| {
            CompileError::ParseError(format!("Invalid heat threshold: {}", val))
        })?;
        Ok(WatchCondition::HeatAbove(threshold))
    } else if trimmed.starts_with("heat_below(") {
        let val = extract_parens_or_after(&trimmed, "heat_below");
        let threshold = val.parse().map_err(|_| {
            CompileError::ParseError(format!("Invalid heat threshold: {}", val))
        })?;
        Ok(WatchCondition::HeatBelow(threshold))
    } else if trimmed.starts_with("neighbor_arrives(") {
        let species_str = extract_parens_or_after(&trimmed, "neighbor_arrives");
        let species = parse_species(&species_str)?;
        Ok(WatchCondition::NeighborArrives(species))
    } else if trimmed.starts_with("neighbor_leaves(") {
        let species_str = extract_parens_or_after(&trimmed, "neighbor_leaves");
        let species = parse_species(&species_str)?;
        Ok(WatchCondition::NeighborLeaves(species))
    } else if trimmed == "content_change" {
        Ok(WatchCondition::ContentChange)
    } else if trimmed.starts_with("novelty_above(") {
        let val = extract_parens_or_after(&trimmed, "novelty_above");
        let threshold = val.parse().map_err(|_| {
            CompileError::ParseError(format!("Invalid novelty threshold: {}", val))
        })?;
        Ok(WatchCondition::NoveltyAbove(threshold))
    } else {
        Err(CompileError::ParseError(format!("Unknown watch condition: {}", s)))
    }
}

fn parse_watch_reaction(s: &str) -> Result<WatchReaction, CompileError> {
    let trimmed = s.trim().to_uppercase();

    match trimmed.as_str() {
        "ALERT" => Ok(WatchReaction::Alert),
        "SNAPSHOT" => Ok(WatchReaction::Snapshot),
        "EXCITE" => Ok(WatchReaction::Excite),
        "CALM" => Ok(WatchReaction::Calm),
        "VALIDATE" => Ok(WatchReaction::Validate),
        "CONSUME" => Ok(WatchReaction::Consume),
        _ => {
            if trimmed.starts_with("EXECUTE(") {
                let target = extract_parens_or_after(&trimmed.to_lowercase(), "execute");
                Ok(WatchReaction::Execute(target))
            } else {
                Err(CompileError::ParseError(format!("Unknown watch reaction: {}", s)))
            }
        }
    }
}

fn parse_heat_requirement(s: &str) -> Result<HeatRequirement, CompileError> {
    // Parse heat patterns, potentially with AND/OR
    let patterns = s.split(" AND ")
        .map(|p| parse_heat_pattern(p.trim()))
        .collect::<Result<Vec<_>, _>>()?;

    Ok(HeatRequirement { patterns })
}

fn parse_heat_pattern(s: &str) -> Result<HeatPattern, CompileError> {
    let trimmed = s.trim().to_lowercase();

    if trimmed.starts_with("heat_above(") {
        let val = extract_parens_or_after(&trimmed, "heat_above");
        let threshold = val.parse().map_err(|_| {
            CompileError::ParseError(format!("Invalid heat threshold: {}", val))
        })?;
        Ok(HeatPattern::HeatAbove(threshold))
    } else if trimmed.starts_with("heat_below(") {
        let val = extract_parens_or_after(&trimmed, "heat_below");
        let threshold = val.parse().map_err(|_| {
            CompileError::ParseError(format!("Invalid heat threshold: {}", val))
        })?;
        Ok(HeatPattern::HeatBelow(threshold))
    } else if trimmed.starts_with("heat_pattern(") {
        let name = extract_parens_or_after(&trimmed, "heat_pattern");
        Ok(HeatPattern::HeatPatternNamed(name))
    } else if trimmed.starts_with("movement(") {
        let style_str = extract_parens_or_after(&trimmed, "movement");
        let style = MovementStyle::parse(&style_str)
            .ok_or_else(|| CompileError::ParseError(
                format!("Invalid movement style: {}", style_str)
            ))?;
        Ok(HeatPattern::Movement(style))
    } else if trimmed.starts_with("signature(") {
        let sig = extract_parens_or_after(&trimmed, "signature");
        Ok(HeatPattern::Signature(sig))
    } else {
        Err(CompileError::ParseError(format!("Unknown heat pattern: {}", s)))
    }
}

fn parse_dream_trigger(s: &str) -> Result<DreamTrigger, CompileError> {
    let trimmed = s.trim().to_lowercase();

    if trimmed == "never" {
        Ok(DreamTrigger::Never)
    } else if trimmed.starts_with("heat_above(") {
        let val = extract_parens_or_after(&trimmed, "heat_above");
        let threshold = val.parse().map_err(|_| {
            CompileError::ParseError(format!("Invalid heat threshold: {}", val))
        })?;
        Ok(DreamTrigger::HeatAbove(threshold))
    } else if trimmed.starts_with("heat_below(") {
        let val = extract_parens_or_after(&trimmed, "heat_below");
        let threshold = val.parse().map_err(|_| {
            CompileError::ParseError(format!("Invalid heat threshold: {}", val))
        })?;
        Ok(DreamTrigger::HeatBelow(threshold))
    } else if trimmed.starts_with("on_query(") {
        let symbol = extract_parens_or_after(&trimmed, "on_query");
        Ok(DreamTrigger::OnQuery(symbol))
    } else if trimmed == "on_era_change" {
        Ok(DreamTrigger::OnEraChange)
    } else if trimmed == "on_tool_use" {
        Ok(DreamTrigger::OnToolUse)
    } else {
        Err(CompileError::ParseError(format!("Unknown dream trigger: {}", s)))
    }
}

fn expand_uri(uri: &str) -> String {
    if uri.starts_with("semantic://") || uri.starts_with("@") {
        uri.to_string()
    } else {
        format!("semantic://foundational/{}", uri)
    }
}

fn parse_list(s: &str) -> Vec<String> {
    let trimmed = s.trim();
    if trimmed.starts_with('[') && trimmed.ends_with(']') {
        let inner = &trimmed[1..trimmed.len() - 1];
        inner.split(',').map(|s| s.trim().to_string()).collect()
    } else {
        vec![trimmed.to_string()]
    }
}

fn extract_parens_or_after(s: &str, prefix: &str) -> String {
    if let Some(start) = s.find('(') {
        if let Some(end) = s.rfind(')') {
            return s[start + 1..end].trim().to_string();
        }
    }
    // Fallback: just strip the prefix
    s.trim_start_matches(prefix).trim().to_string()
}

fn fuzzy_keyword(keyword: &str) -> Option<String> {
    // Simple fuzzy matching for common typos
    match keyword {
        "spawm" | "spwan" | "sapwn" => Some("spawn".into()),
        "wakl" | "wlak" | "wak" => Some("walk".into()),
        "shadw" | "shaodw" => Some("shadow".into()),
        "deram" | "draem" => Some("dream".into()),
        "substarte" | "substate" => Some("substrate".into()),
        _ => None,
    }
}
