import { clack, renderEnterPreamble, renderTrail, renderResidue } from "../tui.ts"
import { LociStore } from "../store.ts"
import type { Residue } from "../types.ts"
import { residueFilename } from "../residue.ts"
import { randomBytes } from "crypto"

export async function cmdEnter(locusName: string, store: LociStore, args: string[]): Promise<void> {
  if (!locusName) {
    console.error("Usage: loci genius enter <locus>")
    process.exit(1)
  }
  const last = await store.latestResidue(locusName)
  renderEnterPreamble(locusName, last)

  const tier = process.env.LOCI_TIER ?? flag(args, "--tier") ?? "sonnet"
  const shortId = randomBytes(3).toString("hex")

  if (hasFlag(args, "--export")) {
    console.log(`export LOCI_LOCUS=${locusName}`)
    console.log(`export LOCI_TIER=${tier}`)
    console.log(`export LOCI_SESSION=${tier}/${shortId}`)
  } else {
    console.log(`LOCI_LOCUS=${locusName}`)
    console.log(`LOCI_TIER=${tier}`)
    console.log(`LOCI_SESSION=${tier}/${shortId}`)
    console.log(`\n# eval $(loci genius enter ${locusName} --export)`)
  }
}

export async function cmdSign(store: LociStore, args: string[]): Promise<void> {
  const locusName = inferLocus(args)
  if (!locusName) {
    console.error("No locus context. Use --locus <name> or set LOCI_LOCUS")
    process.exit(1)
  }

  const sessionEnv = process.env.LOCI_SESSION ?? ""
  const [envTier, envShortId] = sessionEnv.split("/")
  const tier = envTier || flag(args, "--tier") || process.env.LOCI_TIER || "sonnet"
  const shortId = envShortId || randomBytes(3).toString("hex")
  const last = await store.latestResidue(locusName)

  // Positional message (first non-flag arg)
  const positional = args.find(a => !a.startsWith("-") && a !== locusName)

  let residue: Residue = {
    locus: locusName,
    tier,
    sessionShortId: shortId,
    timestamp: new Date().toISOString(),
    pickedUpFrom: last ? residueFilename(last) : null,
    whatIDid: positional ? [positional] : [],
    whatILeftOpen: [],
    recommendation: null,
  }

  if (process.stdin.isTTY) {
    clack.intro(`loci sign: ${locusName}`)

    const did = await clack.text({ message: "What did you do?", placeholder: "implemented X, fixed Y" })
    if (clack.isCancel(did)) { clack.cancel(); process.exit(0) }
    if (did) residue = { ...residue, whatIDid: [did as string] }

    const left = await clack.text({ message: "What's left open?", placeholder: "(none)" })
    if (!clack.isCancel(left) && left && left !== "(none)") {
      residue = { ...residue, whatILeftOpen: [left as string] }
    }

    const rec = await clack.text({ message: "Recommendation for next AI?", placeholder: "(skip)" })
    if (!clack.isCancel(rec) && rec && rec !== "(skip)") {
      residue = { ...residue, recommendation: rec as string }
    }
  }

  const path = await store.writeResidue(residue)
  if (process.stdin.isTTY) {
    clack.outro(`Residue filed: ${path}`)
  } else {
    console.log(path)
  }
}

export async function cmdTrail(locusName: string, store: LociStore, args: string[]): Promise<void> {
  if (!locusName) {
    console.error("Usage: loci genius trail <locus> [--depth N]")
    process.exit(1)
  }
  const depth = parseInt(flag(args, "--depth") ?? "10", 10)
  const residues = (await store.listResidues(locusName)).slice(0, depth)
  renderTrail(locusName, residues)
}

export async function cmdResidue(locusName: string, store: LociStore): Promise<void> {
  const last = await store.latestResidue(locusName || inferLocus([]) || "")
  if (!last) { console.log("No residue found."); return }
  renderResidue(last)
}

export async function cmdWhere(store: LociStore): Promise<void> {
  const names = await store.listLoci()
  const entries = await Promise.all(names.map(async name => ({
    name,
    last: await store.latestResidue(name),
  })))
  const { renderWhere } = await import("../tui.ts")
  renderWhere(entries)
}

function inferLocus(args: string[]): string | null {
  return process.env.LOCI_LOCUS ?? flag(args, "--locus") ?? null
}

function flag(args: string[], name: string): string | null {
  const i = args.indexOf(name)
  return i >= 0 && i + 1 < args.length ? args[i + 1] : null
}

function hasFlag(args: string[], name: string): boolean {
  return args.includes(name)
}
