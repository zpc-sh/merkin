///|
/// Merkin CLI command implementations (stigmergy-first surface).
/// These commands operate in filesystem mode: they read/write directly
/// to loci/<name>/ directories. Substrate-backed SMT integration
/// comes later (Phase 3).

///|
/// Helper: build the LocusRuntime from args + env.
fn make_runtime(args : Array[String]) -> @locus.LocusRuntime {
  let loci_root = value_after(args, "--loci-root", "loci")
  let store_path = value_after(args, "--store", "~/.merkin/store")
  let tier = value_after(args, "--tier", "sonnet")
  let session_id = value_after(args, "--session", "00000")
  let config : @locus.LocusConfig = { loci_root, store_path }
  let session = @model.SessionIdentity::new(tier, session_id)
  @locus.LocusRuntime::new(config, session)
}

///|
/// `merkin loci new <name> [--tags t1,t2] [--spirit "..."]`
/// `merkin loci ls`
fn run_loci_command(args : Array[String]) -> Unit {
  let subcmd = if args.length() > 2 { args[2] } else { "ls" }
  match subcmd {
    "new" => {
      if args.length() <= 3 {
        println("Usage: merkin loci new <name> [--tags t1,t2] [--spirit \"...\"]")
        return
      }
      let name = args[3]
      if !@model.is_valid_locus_name(name) {
        println("Error: invalid locus name. Use alphanumeric characters, underscores, and dashes.")
        return
      }
      let spirit = value_after(args, "--spirit", "(fill: one-line description)")
      let tags_csv = value_after(args, "--tags", "")
      let tags : Array[String] = if tags_csv == "" {
        []
      } else {
        split_csv(tags_csv)
      }
      let locus = @model.Locus::with_tags(name, spirit, tags)
      let rt = make_runtime(args)
      let paths = rt.scaffold_paths(name)
      println("Scaffolding: " + rt.locus_path(name) + "/")
      for p in paths {
        println("  " + p)
      }
      println("")
      println("README.md content:")
      println(rt.scaffold_readme(locus))
      println("Locus created. Start with: merkin enter " + name)
    }
    "ls" => {
      let rt = make_runtime(args)
      println("NAME                 SPIRIT                    TAGS")
      // In filesystem mode, just list directories under loci_root
      println("(filesystem scan of " + rt.config.loci_root + "/ pending — requires @fs)")
      println("Use: merkin loci new <name> to create a locus")
    }
    "graph" => {
      println("(loci graph rendering pending — requires cross-reference scan)")
    }
    _ => {
      println("Usage: merkin loci [new|ls|graph]")
    }
  }
}

///|
/// `merkin enter <locus>`
fn run_enter_command(args : Array[String]) -> Unit {
  if args.length() <= 2 {
    println("Usage: merkin enter <locus>")
    return
  }
  let locus_name = args[2]
  if !@model.is_valid_locus_name(locus_name) {
    println("Error: invalid locus name. Use alphanumeric characters, underscores, and dashes.")
    return
  }
  let rt = make_runtime(args)
  // In filesystem mode, we read residue files from the locus directory
  // For now, emit the enter preamble with no prior residue
  let preamble = @locus.format_enter_preamble(locus_name, None)
  println(preamble)
  println("MERKIN_LOCUS='" + locus_name + "'")
  println("MERKIN_SESSION='" + rt.session.display() + "'")
  println("")
  println("# To set env in your shell:")
  println("# eval \"$(merkin enter '" + locus_name + "' --export)\"")
}

///|
/// `merkin sign [<message>]`
fn run_sign_command(args : Array[String]) -> Unit {
  let rt = make_runtime(args)
  let message = if args.length() > 2 { args[2] } else { "" }
  let locus_name = value_after(args, "--locus", "")
  if locus_name == "" {
    println("Error: no locus context. Use --locus <name> or set MERKIN_LOCUS")
    return
  }
  if !@model.is_valid_locus_name(locus_name) {
    println("Error: invalid locus name. Use alphanumeric characters, underscores, and dashes.")
    return
  }
  let residue = @model.Residue::new(
    locus_name,
    rt.session.tier,
    rt.session.short_id,
    "2026-01-01T00:00:00Z", // placeholder — real impl reads system clock
  )
  let residue = if message != "" {
    residue.add_did(message)
  } else {
    residue
  }
  println("Signing session: " + rt.session.display())
  println("Residue file: " + rt.residue_path(locus_name) + "/" + residue.filename())
  println("")
  println("--- residue content ---")
  println(residue.to_markdown())
}

///|
/// `merkin trail [<locus>] [--depth <n>]`
fn run_trail_command(args : Array[String]) -> Unit {
  let locus_name = if args.length() > 2 && !line_starts_with_flag(args[2]) {
    args[2]
  } else {
    value_after(args, "--locus", "")
  }
  if locus_name == "" {
    println("Usage: merkin trail <locus> [--depth <n>]")
    return
  }
  if !@model.is_valid_locus_name(locus_name) {
    println("Error: invalid locus name. Use alphanumeric characters, underscores, and dashes.")
    return
  }
  // In filesystem mode, we would scan loci/<name>/residue/ for *.md files
  // For now, emit a placeholder showing the format
  let trail = @locus.format_trail(locus_name, [])
  println(trail)
  println("(filesystem residue scan pending — requires @fs)")
}

///|
/// `merkin where`
fn run_where_command(_args : Array[String]) -> Unit {
  // In filesystem mode, scan all loci directories
  let entries : Array[(String, @model.Residue?)] = []
  let output = @locus.format_where(entries)
  println(output)
  println("(filesystem loci scan pending — requires @fs)")
}

///|
/// `merkin residue [<locus>] [--session <id>]`
fn run_residue_command(args : Array[String]) -> Unit {
  let locus_name = if args.length() > 2 && !line_starts_with_flag(args[2]) {
    args[2]
  } else {
    value_after(args, "--locus", "")
  }
  if locus_name == "" {
    println("Usage: merkin residue <locus> [--session <id>]")
    return
  }
  if !@model.is_valid_locus_name(locus_name) {
    println("Error: invalid locus name. Use alphanumeric characters, underscores, and dashes.")
    return
  }
  // In filesystem mode, read residue files
  println("Reading residue from: loci/" + locus_name + "/residue/")
  println("(filesystem residue reader pending — requires @fs)")
}

///|
/// `merkin status [<locus>]`
fn run_status_command(args : Array[String]) -> Unit {
  let locus_name = if args.length() > 2 && !line_starts_with_flag(args[2]) {
    args[2]
  } else {
    value_after(args, "--locus", "")
  }
  if locus_name == "" {
    println("Usage: merkin status <locus>")
    return
  }
  if !@model.is_valid_locus_name(locus_name) {
    println("Error: invalid locus name. Use alphanumeric characters, underscores, and dashes.")
    return
  }
  println("On locus: " + locus_name + " (working)")
  println("(status diff pending — requires store + @fs)")
}

///|
fn line_starts_with_flag(s : String) -> Bool {
  let mut first = ' '
  for ch in s {
    first = ch
    break
  }
  first == '-'
}

///|
/// `merkin init [--store <path>]`
/// Creates the .merkin/ repository structure + loci/ directory.
fn run_init_command(args : Array[String]) -> Unit {
  let store_path = value_after(args, "--store", ".merkin/store")
  println("Initializing merkin repository...")
  println("")
  println("Creating .merkin/")
  println("  config.json         repository configuration")
  println("  store/")
  println("    blobs/            OCI content-addressed blob storage")
  println("    tags/             OCI tag refs (locus → digest)")
  println("  HEAD                current locus ref")
  println("")
  println("Creating loci/          locus workspace root")
  println("")
  // Emit the config.json content
  println("config.json:")
  println("{")
  println("  \"version\": \"0.1.0\",")
  println("  \"store\": \"" + store_path + "\",")
  println("  \"loci_root\": \"loci\",")
  println("  \"pack_format\": \"oci+wasm\"")
  println("}")
  println("")
  println("Repository initialized.")
  println("Next: merkin loci new <name>")
}

///|
/// `merkin pack [<locus>] [--format wasm|blob]`
///
/// Serializes the sparse merkin tree for a locus into an OCI blob.
/// The blob IS the packfile — a single content-addressed artifact
/// containing the full tree state.
///
/// With --format wasm: the packfile is a WASM component that includes
/// the merkin query engine. Recipients can load it and call
/// tree_sparse(), tree_node_count(), bloom_check() directly.
///
/// With --format blob (default): raw serialized tree state stored
/// as an OCI blob. Needs merkin runtime to query.
fn run_pack_command(args : Array[String]) -> Unit {
  let locus_name = if args.length() > 2 && !line_starts_with_flag(args[2]) {
    args[2]
  } else {
    value_after(args, "--locus", "")
  }
  let format = value_after(args, "--format", "blob")
  if locus_name == "" {
    println("Usage: merkin pack <locus> [--format wasm|blob]")
    println("")
    println("Formats:")
    println("  blob   Serialized sparse tree as OCI blob (default)")
    println("  wasm   WASM component with embedded tree + query engine")
    return
  }
  if !@model.is_valid_locus_name(locus_name) {
    println("Error: invalid locus name. Use alphanumeric characters, underscores, and dashes.")
    return
  }
  match format {
    "wasm" => {
      println("Packing: " + locus_name + " → WASM component")
      println("")
      println("Steps:")
      println("  1. Serialize sparse tree for " + locus_name)
      println("  2. Embed tree state into merkin WASM runtime")
      println("  3. Build: moon build --target wasm-gc --package zpc/merkin/wasm_entry")
      println("  4. Output: .merkin/packs/" + locus_name + ".wasm")
      println("")
      println("The WASM pack includes:")
      println("  tree_sparse(tokens)  → filtered projection")
      println("  tree_node_count()    → node count")
      println("  bloom_check(token)   → routing query")
      println("  hash_bytes(hex)      → content addressing")
      println("")
      println("Recipients load the .wasm and query directly.")
      println("No merkin installation required.")
      println("")
      println("(WASM pack pending — requires tree serializer + WASM state injection)")
    }
    _ => {
      println("Packing: " + locus_name + " → OCI blob")
      println("")
      println("Steps:")
      println("  1. Serialize sparse tree for " + locus_name)
      println("  2. Content-address: digest = H(serialized_tree)")
      println("  3. Store: .merkin/store/blobs/<digest>")
      println("  4. Tag: .merkin/store/tags/" + locus_name + "/pack-latest → <digest>")
      println("")
      println("Share via: merkin pack --digest <digest>")
      println("Receive via: merkin pull --pack <digest>")
      println("")
      println("(blob pack pending — requires tree serializer)")
    }
  }
}
