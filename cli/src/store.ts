// LociStore: host-side OCI blob/tag store + locus directory ops + residue persistence.
//
// This is the "last-leg touching the surface" that the MoonBit layer defers to the host.
// Mirrors FileOciRegistry (storage/fs_store.mbt) and the LocusRuntime scaffold
// (locus/locus.mbt), but implemented with Bun-native FS so it actually writes to disk.
//
// Other Claudes: import LociStore, call store.initLocus / store.writeResidue / store.putBlob.
// The OCI layout is: <storePath>/blobs/sha256-<hex>, <storePath>/tags/<repo>/<tag>.

import { join } from "path"
import { mkdir, readdir, exists } from "fs/promises"
import type { Locus, Residue, LociConfig } from "./types.ts"
import { LOCUS_SUBDIRS } from "./types.ts"
import { toMarkdown, fromMarkdown, residueFilename, scaffoldReadme } from "./residue.ts"

export class LociStore {
  readonly lociRoot: string
  readonly storePath: string

  constructor(config: LociConfig) {
    this.lociRoot = config.lociRoot
    this.storePath = config.storePath
  }

  static fromCwd(overrides: Partial<LociConfig> = {}): LociStore {
    return new LociStore({
      lociRoot: overrides.lociRoot ?? "loci",
      storePath: overrides.storePath ?? ".merkin/store",
    })
  }

  // --- Locus directory ops ---

  locusPath(name: string): string {
    return join(this.lociRoot, name)
  }

  residueDir(name: string): string {
    return join(this.locusPath(name), "residue")
  }

  async initLocus(locus: Locus): Promise<string[]> {
    const root = this.locusPath(locus.name)
    const paths: string[] = [root, ...LOCUS_SUBDIRS.map(s => join(root, s))]
    for (const p of paths) await mkdir(p, { recursive: true })
    const readmePath = join(root, "README.md")
    await Bun.write(readmePath, scaffoldReadme(locus))
    return [...paths, readmePath]
  }

  async listLoci(): Promise<string[]> {
    if (!await exists(this.lociRoot)) return []
    const entries = await readdir(this.lociRoot, { withFileTypes: true })
    return entries.filter(e => e.isDirectory()).map(e => e.name).sort()
  }

  async readReadme(name: string): Promise<string | null> {
    const p = join(this.locusPath(name), "README.md")
    return await exists(p) ? Bun.file(p).text() : null
  }

  // --- Residue ops ---

  async writeResidue(r: Residue): Promise<string> {
    const dir = this.residueDir(r.locus)
    await mkdir(dir, { recursive: true })
    const path = join(dir, residueFilename(r))
    await Bun.write(path, toMarkdown(r))
    return path
  }

  async listResidues(locusName: string): Promise<Residue[]> {
    const dir = this.residueDir(locusName)
    if (!await exists(dir)) return []
    const files = (await readdir(dir)).filter(f => f.endsWith(".md")).sort().reverse()
    const residues: Residue[] = []
    for (const f of files) {
      const r = fromMarkdown(locusName, await Bun.file(join(dir, f)).text())
      if (r) residues.push(r)
    }
    return residues
  }

  async latestResidue(locusName: string): Promise<Residue | null> {
    return (await this.listResidues(locusName))[0] ?? null
  }

  // --- OCI blob/tag store (mirrors storage/fs_store.mbt FileOciRegistry) ---

  blobPath(hex: string): string {
    return join(this.storePath, "blobs", `sha256-${hex}`)
  }

  tagPath(repo: string, tag: string): string {
    return join(this.storePath, "tags", repo, tag)
  }

  async initStore(): Promise<void> {
    await mkdir(join(this.storePath, "blobs"), { recursive: true })
    await mkdir(join(this.storePath, "refs"), { recursive: true })
  }

  async putBlob(data: Uint8Array): Promise<string> {
    await this.initStore()
    const h = new Bun.CryptoHasher("sha256")
    h.update(data)
    const hex = h.digest("hex")
    const path = this.blobPath(hex)
    if (!await exists(path)) await Bun.write(path, data)
    return hex
  }

  async getBlob(hex: string): Promise<Uint8Array | null> {
    const path = this.blobPath(hex)
    return await exists(path)
      ? new Uint8Array(await Bun.file(path).arrayBuffer())
      : null
  }

  async putTag(repo: string, tag: string, hex: string): Promise<void> {
    await mkdir(join(this.storePath, "tags", repo), { recursive: true })
    await Bun.write(this.tagPath(repo, tag), `sha256:${hex}`)
  }

  async resolveTag(repo: string, tag: string): Promise<string | null> {
    const path = this.tagPath(repo, tag)
    if (!await exists(path)) return null
    const raw = await Bun.file(path).text()
    return raw.trim().split(":")[1] ?? null
  }
}
