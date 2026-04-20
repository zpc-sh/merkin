// Residue serialization: mirrors model/residue.mbt to_markdown / from_markdown exactly.
// Kept in its own file so it can be imported by store.ts and commands alike.

import type { Residue, Locus } from "./types.ts"

export function residueFilename(r: Residue): string {
  const ts = r.timestamp.replace(/[:.]/g, "-").replace("T", "_").slice(0, 19)
  return `${ts}_${r.tier}_${r.sessionShortId}.md`
}

export function toMarkdown(r: Residue): string {
  return [
    `# Residue: ${r.locus}`,
    `Filed by: ${r.tier}/${r.sessionShortId}`,
    `Timestamp: ${r.timestamp}`,
    `Entry residue: ${r.pickedUpFrom ?? "cold"}`,
    "",
    "## Picked up from",
    r.pickedUpFrom ?? "(cold entry — no prior residue)",
    "",
    "## What I did",
    ...r.whatIDid.map(x => `- ${x}`),
    "",
    "## What I left open",
    ...r.whatILeftOpen.map(x => `- ${x}`),
    "",
    "## Recommendation for next AI",
    r.recommendation ?? "(none)",
    "",
  ].join("\n")
}

export function fromMarkdown(locus: string, content: string): Residue | null {
  const lines = content.split("\n")

  const field = (prefix: string): string => {
    const line = lines.find(l => l.startsWith(prefix))
    return line ? line.slice(prefix.length).trim() : ""
  }

  const section = (header: string): string[] => {
    const start = lines.findIndex(l => l.startsWith(header))
    if (start === -1) return []
    const items: string[] = []
    for (let i = start + 1; i < lines.length; i++) {
      if (lines[i].startsWith("## ")) break
      if (lines[i].startsWith("- ")) items.push(lines[i].slice(2))
    }
    return items
  }

  const filedBy = field("Filed by: ")
  if (!filedBy) return null

  const slash = filedBy.indexOf("/")
  const tier = slash >= 0 ? filedBy.slice(0, slash) : filedBy
  const sessionShortId = slash >= 0 ? filedBy.slice(slash + 1) : "unknown"
  const entryResidue = field("Entry residue: ")
  const recLines = section("## Recommendation for next AI")
  const rec = recLines.join("\n").trim()

  return {
    locus,
    tier,
    sessionShortId,
    timestamp: field("Timestamp: "),
    pickedUpFrom: !entryResidue || entryResidue === "cold" ? null : entryResidue,
    whatIDid: section("## What I did"),
    whatILeftOpen: section("## What I left open"),
    recommendation: rec && rec !== "(none)" ? rec : null,
  }
}

export function scaffoldReadme(locus: Locus): string {
  const tagLine = locus.tags.length > 0 ? `**Tags**: ${locus.tags.join(", ")}\n\n` : ""
  return [
    `# ${locus.name}`,
    "",
    `**Spirit**: ${locus.spirit}`,
    "",
    tagLine + "## Entry Primitives",
    "",
    "(fill: what a new agent should know before entering)",
    "",
    "## Membranes",
    "",
    "(none configured)",
    "",
    "## Affordances",
    "",
    "(none configured)",
    "",
  ].join("\n")
}
