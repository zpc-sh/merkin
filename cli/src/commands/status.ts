import { LociStore } from "../store.ts"
import { exists } from "fs/promises"
import { join } from "path"

export async function cmdStatus(store: LociStore): Promise<void> {
  const initialized = await exists(join(store.lociRoot, ".loci"))
  const names = await store.listLoci()

  console.log(`Loci root:   ${store.lociRoot}/  ${initialized ? "" : "(not initialized — run: loci init)"}`)
  console.log(`Store:       ${store.storePath}/`)
  console.log(`Loci count:  ${names.length}`)

  if (names.length === 0) {
    console.log(`\n  (empty — run: loci loci new <name>)`)
    return
  }

  console.log(`\n${"LOCUS".padEnd(20)} ${"SESSIONS".padEnd(10)} ${"LAST SESSION".padEnd(24)} OPEN THREADS`)
  for (const name of names) {
    const residues = await store.listResidues(name)
    const last = residues[0] ?? null
    const sessions = String(residues.length).padEnd(10)
    const lastTs = last ? last.timestamp.slice(0, 19).padEnd(24) : "—".padEnd(24)
    const open = last?.whatILeftOpen[0] ?? "—"
    console.log(`${name.padEnd(20)} ${sessions} ${lastTs} ${open}`)
  }
}
