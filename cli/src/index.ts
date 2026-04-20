#!/usr/bin/env bun
// loci — L-OCI content-addressed locus CLI/TUI
//
// Architecture:
//   LociStore (store.ts)   — host-side OCI blob/tag + residue persistence (the "last leg")
//   LociCore  (core.ts)    — delegates tree/bloom/daemon ops to native merkin binary
//   commands/ (commands/)  — one concern per file; each command imports only what it needs
//   tui.ts                 — @clack/prompts + terminal renderers matching locus/locus.mbt output
//
// Adding a new command: add a file to src/commands/, export an async function, wire it below.

import { LociStore } from "./store.ts"
import { LociCore } from "./core.ts"
import { cmdInit } from "./commands/init.ts"
import { cmdLocusNew, cmdLocusLs } from "./commands/locus.ts"
import { cmdEnter, cmdSign, cmdTrail, cmdResidue, cmdWhere } from "./commands/genius.ts"
import { cmdStatus } from "./commands/status.ts"

const argv = process.argv.slice(2)
const cmd = argv[0]
const rest = argv.slice(1)

const store = LociStore.fromCwd({
  lociRoot: flag(argv, "--loci-root") ?? "loci",
  storePath: flag(argv, "--store") ?? ".merkin/store",
})
const core = LociCore.discover()

async function main(): Promise<void> {
  switch (cmd) {
    case "init":
      return cmdInit(store, rest)

    case "loci":
    case "ratio": {
      const sub = rest[0]
      const subRest = rest.slice(1)
      if (sub === "new") return cmdLocusNew(store, subRest)
      if (sub === "ls" || !sub) return cmdLocusLs(store)
      console.error(`Unknown loci subcommand: ${sub}`); usage(); process.exit(1)
    }

    case "genius": {
      const sub = rest[0]
      const subRest = rest.slice(1)
      if (sub === "enter") return cmdEnter(subRest[0], store, subRest.slice(1))
      if (sub === "sign") return cmdSign(store, subRest)
      if (sub === "trail") return cmdTrail(subRest[0], store, subRest.slice(1))
      if (sub === "residue") return cmdResidue(subRest[0], store)
      if (sub === "where") return cmdWhere(store)
      console.error(`Unknown genius subcommand: ${sub}`); usage(); process.exit(1)
    }

    // Short aliases — drop the group token so you can type `loci enter foo`
    case "enter":   return cmdEnter(rest[0], store, rest.slice(1))
    case "sign":    return cmdSign(store, rest)
    case "trail":   return cmdTrail(rest[0], store, rest.slice(1))
    case "residue": return cmdResidue(rest[0], store)
    case "where":   return cmdWhere(store)
    case "status":  return cmdStatus(store)

    // Delegate to native merkin binary (tree / bloom / OCI daemon ops)
    case "daemon":
    case "pack":
    case "app": {
      const code = await core.runPrint([cmd, ...rest])
      process.exit(code)
    }

    case "help":
    case "--help":
    case "-h":
      usage(); return

    default:
      if (cmd) console.error(`Unknown command: ${cmd}\n`)
      usage()
      process.exit(cmd ? 1 : 0)
  }
}

function usage(): void {
  console.log(`
loci — L-OCI content-addressed locus CLI

USAGE
  loci init                               Initialize loci root in current directory
  loci loci new <name> [opts]             Create a new locus
  loci loci ls                            List all loci with last session
  loci genius enter <locus> [--export]    Print enter preamble + session env
  loci genius sign [message]              File a residue for the current session
  loci genius trail <locus> [--depth N]   Show session trail
  loci genius residue <locus>             Show latest residue
  loci genius where                       Overview of all loci + last sessions
  loci status                             Repository overview
  loci daemon <subcmd>                    Delegate to native merkin (tree/bloom/OCI)

  Short aliases: loci enter|sign|trail|residue|where|status

OPTIONS
  --loci-root <path>  Loci directory root       (default: loci/)
  --store <path>      OCI blob store path        (default: .merkin/store/)
  --locus <name>      Override current locus     (or set LOCI_LOCUS)
  --tier <tier>       Claude tier for signing    (default: sonnet)
  --depth <n>         Trail depth limit          (default: 10)
  --export            Print eval-able export lines for enter

ENV
  LOCI_LOCUS          Current locus name (set via: eval \$(loci enter <name> --export))
  LOCI_TIER           Claude tier for this session
  LOCI_SESSION        tier/shortId for signing
  LOCI_MERKIN_ROOT    Path to merkin source root (for daemon delegation)
`.trim())
}

function flag(args: string[], name: string): string | null {
  const i = args.indexOf(name)
  return i >= 0 && i + 1 < args.length ? args[i + 1] : null
}

main().catch(e => { console.error(e); process.exit(1) })
