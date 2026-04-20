import { clack } from "../tui.ts"
import { LociStore } from "../store.ts"
import { mkdir, exists } from "fs/promises"
import { join } from "path"

export async function cmdInit(store: LociStore, args: string[]): Promise<void> {
  const marker = join(store.lociRoot, ".loci")

  clack.intro("loci init")

  if (await exists(marker)) {
    clack.outro(`Already initialized at ${store.lociRoot}/`)
    return
  }

  await mkdir(store.lociRoot, { recursive: true })
  await store.initStore()
  await Bun.write(marker, JSON.stringify({
    version: "0.1.0",
    storePath: store.storePath,
    created: new Date().toISOString(),
  }, null, 2))

  clack.outro([
    `Initialized.`,
    `  loci root: ${store.lociRoot}/`,
    `  store:     ${store.storePath}/`,
    ``,
    `Next: loci loci new <name>`,
  ].join("\n"))
}
