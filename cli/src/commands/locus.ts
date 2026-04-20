import { clack, renderWhere } from "../tui.ts"
import { LociStore } from "../store.ts"
import type { Locus } from "../types.ts"

export async function cmdLocusNew(store: LociStore, args: string[]): Promise<void> {
  const name = args[0]
  if (!name) {
    console.error("Usage: loci loci new <name> [--spirit \"...\"] [--tags t1,t2]")
    process.exit(1)
  }

  let spirit = flag(args, "--spirit")
  const tagsCsv = flag(args, "--tags") ?? ""
  const tags = tagsCsv ? tagsCsv.split(",").map(t => t.trim()).filter(Boolean) : []

  if (!spirit && process.stdin.isTTY) {
    clack.intro(`loci new: ${name}`)
    const entered = await clack.text({
      message: "Spirit (one-line purpose for this locus)",
      placeholder: "(fill: one-line description)",
    })
    if (clack.isCancel(entered)) { clack.cancel(); process.exit(0) }
    spirit = entered as string || "(fill: one-line description)"
  } else {
    spirit ??= "(fill: one-line description)"
    clack.intro(`loci new: ${name}`)
  }

  const locus: Locus = { name, spirit, tags }
  const paths = await store.initLocus(locus)
  for (const p of paths) clack.log.step(p)
  clack.outro(`Done. Start with: loci genius enter ${name}`)
}

export async function cmdLocusLs(store: LociStore): Promise<void> {
  const names = await store.listLoci()
  if (names.length === 0) {
    console.log("No loci yet. Try: loci loci new <name>")
    return
  }
  const entries = await Promise.all(names.map(async name => ({
    name,
    last: await store.latestResidue(name),
  })))
  renderWhere(entries)
}

function flag(args: string[], name: string): string | null {
  const i = args.indexOf(name)
  return i >= 0 && i + 1 < args.length ? args[i + 1] : null
}
