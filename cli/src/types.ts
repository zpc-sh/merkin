// Mirrors the MoonBit model layer (model/residue.mbt, model/locus.mbt, locus/locus.mbt).
// All types are plain data — no methods — so they serialize trivially.

export type Tier = "haiku" | "sonnet" | "opus" | string

export interface Locus {
  name: string
  spirit: string
  tags: string[]
}

export interface Session {
  tier: Tier
  shortId: string
  locus: string
}

export interface Residue {
  locus: string
  tier: Tier
  sessionShortId: string
  timestamp: string          // ISO8601
  pickedUpFrom: string | null // filename of prior residue, or null for cold entry
  whatIDid: string[]
  whatILeftOpen: string[]
  recommendation: string | null
}

export interface LociConfig {
  lociRoot: string   // default: "loci"
  storePath: string  // default: ".merkin/store"
}

// Subdirectories created under each locus root. Mirrors model/locus.mbt locus_subdirs().
export const LOCUS_SUBDIRS = ["affordances", "membranes", "schemas", "yata", "residue"] as const
