//! Semanticfile Parser
//!
//! Flexible, intent-driven parsing. Understands indentation, keywords, and structure.

use super::CompileError;

/// A parsed block from a Semanticfile
#[derive(Debug, Clone)]
pub struct Block {
    pub keyword: String,
    pub target: Option<String>,
    pub properties: Vec<Property>,
    pub line: usize,
}

#[derive(Debug, Clone)]
pub struct Property {
    pub key: String,
    pub value: String,
    pub line: usize,
}

/// Parse a Semanticfile into blocks
pub fn parse(source: &str) -> Result<Vec<Block>, CompileError> {
    let mut blocks = Vec::new();
    let lines: Vec<&str> = source.lines().collect();

    let mut i = 0;
    while i < lines.len() {
        let line = lines[i].trim();

        // Skip empty lines and comments
        if line.is_empty() || line.starts_with('#') {
            i += 1;
            continue;
        }

        // Check if this is a keyword line (no leading indentation in original)
        if !lines[i].starts_with(' ') && !lines[i].starts_with('\t') {
            let (block, next_i) = parse_block(&lines, i)?;
            blocks.push(block);
            i = next_i;
        } else {
            i += 1;
        }
    }

    Ok(blocks)
}

fn parse_block(lines: &[&str], start: usize) -> Result<(Block, usize), CompileError> {
    let line = lines[start].trim();
    let line_num = start + 1;

    // Parse the keyword line: "KEYWORD [target]"
    let parts: Vec<&str> = line.split_whitespace().collect();
    if parts.is_empty() {
        return Err(CompileError::ParseError(format!("Empty line at {}", line_num)));
    }

    let keyword = normalize_keyword(parts[0]);
    let target = if parts.len() > 1 {
        Some(parts[1..].join(" "))
    } else {
        None
    };

    // Parse properties (indented lines following the keyword)
    let mut properties = Vec::new();
    let mut i = start + 1;

    while i < lines.len() {
        let line = lines[i];

        // Skip empty lines
        if line.trim().is_empty() {
            i += 1;
            continue;
        }

        // If not indented, we've reached the next block
        if !line.starts_with(' ') && !line.starts_with('\t') {
            break;
        }

        // Skip comments
        let trimmed = line.trim();
        if trimmed.starts_with('#') {
            i += 1;
            continue;
        }

        // Parse property: "KEY value" or "KEY: value"
        if let Some(prop) = parse_property(trimmed, i + 1) {
            properties.push(prop);
        }

        i += 1;
    }

    Ok((
        Block {
            keyword,
            target,
            properties,
            line: line_num,
        },
        i,
    ))
}

fn parse_property(line: &str, line_num: usize) -> Option<Property> {
    // Handle "KEY: value" or "KEY value"
    if let Some(colon_pos) = line.find(':') {
        let key = line[..colon_pos].trim();
        let value = line[colon_pos + 1..].trim();
        Some(Property {
            key: normalize_keyword(key),
            value: value.to_string(),
            line: line_num,
        })
    } else {
        // Space-separated: "KEY value"
        let parts: Vec<&str> = line.splitn(2, ' ').collect();
        if parts.len() == 2 {
            Some(Property {
                key: normalize_keyword(parts[0]),
                value: parts[1].trim().to_string(),
                line: line_num,
            })
        } else {
            None
        }
    }
}

/// Normalize keywords to lowercase for flexible matching
fn normalize_keyword(s: &str) -> String {
    s.trim().to_lowercase()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_simple() {
        let source = r#"
SUBSTRATE claude/opus
    MOBILITY 0.7
    MOVEMENT discrete

SPAWN moth AT logic/reasoning
    ENERGY 0.5
    WATCH content_change -> ALERT
"#;

        let blocks = parse(source).unwrap();
        assert_eq!(blocks.len(), 2);

        assert_eq!(blocks[0].keyword, "substrate");
        assert_eq!(blocks[0].target.as_ref().unwrap(), "claude/opus");
        assert_eq!(blocks[0].properties.len(), 2);

        assert_eq!(blocks[1].keyword, "spawn");
        assert_eq!(blocks[1].target.as_ref().unwrap(), "moth AT logic/reasoning");
        assert_eq!(blocks[1].properties.len(), 2);
    }

    #[test]
    fn test_parse_with_comments() {
        let source = r#"
# This is a comment
SUBSTRATE opus
    # Another comment
    MOBILITY 0.8

# Block comment

SPAWN moth
    ENERGY 0.5
"#;

        let blocks = parse(source).unwrap();
        assert_eq!(blocks.len(), 2);
    }
}
