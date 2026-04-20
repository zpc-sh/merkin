// LociCore: delegate logic ops to the native merkin binary (moon run).
//
// Upgrade path: when ~/ratio/lang produces a stable WASM surface, replace
// the Bun.spawn calls here with WebAssembly.instantiate + the wasm_entry exports
// (bloom_add, tree_ingest, tree_sparse, plan_finger_wasm, etc.).
//
// Other Claudes: call core.run([...args]) for daemon/tree/bloom ops.
// The host-side storage (LociStore) handles all actual disk writes.

export class LociCore {
  constructor(
    readonly merkinRoot: string,
    readonly moonArgs: string[] = [],
  ) {}

  static discover(): LociCore {
    const fromEnv = process.env.LOCI_MERKIN_ROOT
    if (fromEnv) return new LociCore(fromEnv)
    // cli/ lives inside the merkin repo root — walk up one level
    return new LociCore(new URL("../../", import.meta.url).pathname.replace(/\/$/, ""))
  }

  async run(args: string[]): Promise<{ out: string; err: string; code: number }> {
    const proc = Bun.spawn(
      ["moon", "run", "--directory", this.merkinRoot, "zpc/merkin/cmd/main", "--", ...args],
      { stdout: "pipe", stderr: "pipe" },
    )
    const [out, err, code] = await Promise.all([
      new Response(proc.stdout).text(),
      new Response(proc.stderr).text(),
      proc.exited,
    ])
    return { out, err, code }
  }

  async runPrint(args: string[]): Promise<number> {
    const { out, err, code } = await this.run(args)
    if (out) process.stdout.write(out)
    if (err) process.stderr.write(err)
    return code
  }
}
