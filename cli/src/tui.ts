// TUI primitives: thin wrappers over @clack/prompts + terminal renderers.
// Mirrors the format_* functions from locus/locus.mbt so output is consistent
// between the MoonBit CLI and the Bun TUI.
//
// Other Claudes: import clack for interactive prompts, use render* for display.

export * as clack from "@clack/prompts"

import type { Residue } from "./types.ts"
import { residueFilename } from "./residue.ts"

export function banner(title: string): void {
  console.log(`\n─────────────────────────────────────────────────────`)
  console.log(`  ${title}`)
  console.log(`─────────────────────────────────────────────────────\n`)
}

export function renderEnterPreamble(locusName: string, last: Residue | null): void {
  console.log(`─────────────────────────────────────────────────────`)
  console.log(`You are entering: ${locusName}`)
  if (last) {
    console.log(`Last Claude here: ${last.tier}/${last.sessionShortId}  (${last.timestamp})`)
    if (last.whatILeftOpen.length > 0) {
      console.log(`\nOpen threads from last residue:`)
      for (const item of last.whatILeftOpen) console.log(`  ! ${item}`)
    }
  } else {
    console.log(`First entry — no prior residue.`)
  }
  console.log(`─────────────────────────────────────────────────────\n`)
}

export function renderTrail(locusName: string, residues: Residue[]): void {
  console.log(`Trail for: ${locusName}  (${residues.length} sessions)\n`)
  let seq = residues.length
  for (const r of residues) {
    console.log(`╔══ [${seq}] ${r.tier}/${r.sessionShortId}  ${r.timestamp}  ${"═".repeat(40)}╗`)
    console.log(`║  Entry context: ${r.pickedUpFrom ?? "cold entry (no prior residue)"}`)
    for (const item of r.whatIDid) console.log(`║  ${item}`)
    console.log(`║  Exit residue: → residue/${residueFilename(r)}`)
    if (r.whatILeftOpen.length > 0) console.log(`║  Open threads: ${r.whatILeftOpen.join(", ")}`)
    console.log(`╚${"═".repeat(70)}╝\n`)
    seq--
  }
}

export function renderWhere(entries: Array<{ name: string; last: Residue | null }>): void {
  console.log(col("LOCUS", 16) + col("LAST VISIT", 20) + col("TIER", 10) + "OPEN THREADS")
  for (const { name, last } of entries) {
    if (last) {
      const open = last.whatILeftOpen[0] ?? "(none logged)"
      console.log(col(name, 16) + col(last.timestamp.slice(0, 19), 20) + col(last.tier, 10) + open)
    } else {
      console.log(col(name, 16) + col("—", 20) + col("—", 10) + "—")
    }
  }
}

export function renderResidue(r: Residue): void {
  const bar = "─".repeat(50)
  console.log(`── residue/${residueFilename(r)} ${bar}`)
  console.log(`Filed by: ${r.tier}/${r.sessionShortId}  at  ${r.timestamp}\n`)
  console.log(`Picked up from: ${r.pickedUpFrom ?? "(cold entry)"}\n`)
  console.log("What I did:")
  for (const item of r.whatIDid) console.log(`- ${item}`)
  console.log("\nWhat I left open:")
  for (const item of r.whatILeftOpen) console.log(`- ${item}`)
  if (r.recommendation) console.log(`\nNext Claude: ${r.recommendation}`)
  console.log("─".repeat(66))
}

function col(s: string, width: number): string {
  return s.length >= width ? s.slice(0, width) : s + " ".repeat(width - s.length)
}
