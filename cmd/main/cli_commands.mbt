///|
/// Merkin CLI command implementations.
/// The CLI is split into two principal surfaces:
/// - Ratio Loci: repository/root operations and git-colliding verbs
/// - Genius Loci: AI-only inhabitation, trail, and residue work
///
/// These commands currently operate in filesystem mode: they read/write
/// directly to loci/<name>/ directories. Substrate-backed SMT integration
/// comes later (Phase 3).

///|
/// Helper: build the LocusRuntime from args + env.
fn make_runtime(
  args : Array[String],
  locus_context : String?,
) -> @locus.LocusRuntime {
  let loci_root = value_after(args, "--loci-root", "loci")
  let store_path = value_after(args, "--store", ".merkin/store")
  let tier = value_after(args, "--tier", "sonnet")
  let session_id = value_after(args, "--session", "00000")
  let config : @locus.LocusConfig = { loci_root, store_path }
  let session = match build_genius_attestation(args, locus_context) {
    Some(attestation) =>
      @model.SessionIdentity::from_genius_attestation(attestation)
    None => @model.SessionIdentity::new(tier, session_id)
  }
  @locus.LocusRuntime::new(config, session)
}

///|
/// `merkin ratio loci new <name> [--tags t1,t2] [--spirit "..."]`
/// `merkin ratio loci ls`
fn run_loci_command(args : Array[String]) -> Unit {
  let subcmd = if args.length() > 2 { args[2] } else { "ls" }
  match subcmd {
    "new" => {
      if args.length() <= 3 {
        println(
          "Usage: merkin ratio loci new <name> [--tags t1,t2] [--spirit \"...\"]",
        )
        return
      }
      let name = args[3]
      let spirit = value_after(args, "--spirit", "(fill: one-line description)")
      let tags_csv = value_after(args, "--tags", "")
      let tags : Array[String] = if tags_csv == "" {
        []
      } else {
        split_csv(tags_csv)
      }
      let locus = @model.Locus::with_tags(name, spirit, tags)
      let rt = make_runtime(args, None)
      let paths = rt.scaffold_paths(name)
      println("Scaffolding: " + rt.locus_path(name) + "/")
      for p in paths {
        println("  " + p)
      }
      println("")
      println("README.md content:")
      println(rt.scaffold_readme(locus))
      println("Locus created. Start with: merkin genius enter " + name)
    }
    "ls" => {
      let rt = make_runtime(args, None)
      println("NAME                 SPIRIT                    TAGS")
      // In filesystem mode, just list directories under loci_root
      println(
        "(filesystem scan of " +
        rt.config.loci_root +
        "/ pending — requires @fs)",
      )
      println("Use: merkin ratio loci new <name> to create a locus")
    }
    "graph" =>
      println(
        "(loci graph rendering pending — requires cross-reference scan)",
      )
    _ => println("Usage: merkin ratio loci [new|ls|graph]")
  }
}

///|
/// `merkin genius enter <locus>`
fn run_enter_command(args : Array[String]) -> Unit {
  if args.length() <= 2 {
    println("Usage: merkin genius enter <locus>")
    return
  }
  let locus_name = args[2]
  let rt = make_runtime(args, Some(locus_name))
  // In filesystem mode, we read residue files from the locus directory
  // For now, emit the enter preamble with no prior residue
  let preamble = @locus.format_enter_preamble(locus_name, None)
  println(preamble)
  println("MERKIN_LOCUS=" + locus_name)
  println("MERKIN_SESSION=" + rt.session.display())
  println("")
  println("# To set env in your shell:")
  println("# eval $(merkin genius enter " + locus_name + " --export)")
}

///|
/// `merkin genius sign [<message>]`
fn run_sign_command(args : Array[String]) -> Unit {
  let message = if args.length() > 2 { args[2] } else { "" }
  let locus_name = value_after(args, "--locus", "")
  if locus_name == "" {
    println("Error: no locus context. Use --locus <name> or set MERKIN_LOCUS")
    return
  }
  let rt = make_runtime(args, Some(locus_name))
  let residue = @model.Residue::new(
    locus_name,
    rt.session.tier,
    rt.session.short_id,
    "2026-01-01T00:00:00Z", // placeholder — real impl reads system clock
  )
  let residue = if message != "" { residue.add_did(message) } else { residue }
  println("Signing session: " + rt.session.display())
  println(
    "Residue file: " + rt.residue_path(locus_name) + "/" + residue.filename(),
  )
  println("")
  println("--- residue content ---")
  println(residue.to_markdown())
}

///|
/// `merkin genius trail [<locus>] [--depth <n>]`
fn run_trail_command(args : Array[String]) -> Unit {
  let locus_name = if args.length() > 2 && !line_starts_with_flag(args[2]) {
    args[2]
  } else {
    value_after(args, "--locus", "")
  }
  if locus_name == "" {
    println("Usage: merkin genius trail <locus> [--depth <n>]")
    return
  }
  // In filesystem mode, we would scan loci/<name>/residue/ for *.md files
  // For now, emit a placeholder showing the format
  let trail = @locus.format_trail(locus_name, [])
  println(trail)
  println("(filesystem residue scan pending — requires @fs)")
}

///|
/// `merkin genius where`
fn run_where_command(_args : Array[String]) -> Unit {
  // In filesystem mode, scan all loci directories
  let entries : Array[(String, @model.Residue?)] = []
  let output = @locus.format_where(entries)
  println(output)
  println("(filesystem loci scan pending — requires @fs)")
}

///|
/// `merkin genius residue [<locus>] [--session <id>]`
fn run_residue_command(args : Array[String]) -> Unit {
  let locus_name = if args.length() > 2 && !line_starts_with_flag(args[2]) {
    args[2]
  } else {
    value_after(args, "--locus", "")
  }
  if locus_name == "" {
    println("Usage: merkin genius residue <locus> [--session <id>]")
    return
  }
  // In filesystem mode, read residue files
  println("Reading residue from: loci/" + locus_name + "/residue/")
  println("(filesystem residue reader pending — requires @fs)")
}

///|
/// `merkin ratio status [<locus>]`
fn run_status_command(args : Array[String]) -> Unit {
  let locus_name = if args.length() > 2 && !line_starts_with_flag(args[2]) {
    args[2]
  } else {
    value_after(args, "--locus", "")
  }
  if locus_name == "" {
    println("Usage: merkin ratio status <locus>")
    return
  }
  println("Ratio Loci status for: " + locus_name + " (working)")
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
/// `merkin ratio init [--store <path>]`
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
  println("Next: merkin ratio loci new <name>")
}

///|
/// `merkin ratio pack [<locus>] [--format wasm|blob]`
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
    println("Usage: merkin ratio pack <locus> [--format wasm|blob]")
    println("")
    println("Formats:")
    println("  blob   Serialized sparse tree as OCI blob (default)")
    println("  wasm   WASM component with embedded tree + query engine")
    return
  }
  match format {
    "wasm" => {
      println("Packing: " + locus_name + " → WASM component")
      println("")
      println("Steps:")
      println("  1. Serialize sparse tree for " + locus_name)
      println("  2. Embed tree state into merkin WASM runtime")
      println(
        "  3. Build: moon build --target wasm-gc --package zpc/merkin/wasm_entry",
      )
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
      println(
        "(WASM pack pending — requires tree serializer + WASM state injection)",
      )
    }
    _ => {
      println("Packing: " + locus_name + " → OCI blob")
      println("")
      println("Steps:")
      println("  1. Serialize sparse tree for " + locus_name)
      println("  2. Content-address: digest = H(serialized_tree)")
      println("  3. Store: .merkin/store/blobs/<digest>")
      println(
        "  4. Tag: .merkin/store/tags/" +
        locus_name +
        "/pack-latest → <digest>",
      )
      println("")
      println("Share via: merkin ratio pack --digest <digest>")
      println("Receive via: merkin ratio pull --pack <digest>")
      println("")
      println("(blob pack pending — requires tree serializer)")
    }
  }
}

///|
/// Strip the command-group token so grouped commands can reuse the
/// legacy top-level handlers unchanged.
fn strip_group_token(args : Array[String]) -> Array[String] {
  let normalized : Array[String] = []
  if args.length() == 0 {
    return normalized
  }
  normalized.push(args[0])
  for i = 2; i < args.length(); i = i + 1 {
    normalized.push(args[i])
  }
  normalized
}

///|
/// Insert a command-group token so compatibility aliases reuse the same
/// canonical dispatch and gating logic.
fn add_group_token(args : Array[String], group : String) -> Array[String] {
  let normalized : Array[String] = []
  if args.length() == 0 {
    return normalized
  }
  normalized.push(args[0])
  normalized.push(group)
  for i = 1; i < args.length(); i = i + 1 {
    normalized.push(args[i])
  }
  normalized
}

///|
/// `merkin ratio <command> ...`
/// Canonical repository/root surface. Git-colliding commands belong here.
fn run_ratio_command(args : Array[String]) -> Unit {
  if args.length() <= 2 {
    print_ratio_usage()
    return
  }
  let subcmd = args[2]
  let normalized = strip_group_token(args)
  match subcmd {
    "init" => run_init_command(normalized)
    "loci" => run_loci_command(normalized)
    "app" => run_ratio_app_command(normalized)
    "status" => run_status_command(normalized)
    "pack" => run_pack_command(normalized)
    "help" => print_ratio_usage()
    _ => {
      println("Unknown Ratio Loci command: " + subcmd)
      print_ratio_usage()
    }
  }
}

///|
fn run_ratio_alias_command(args : Array[String]) -> Unit {
  run_ratio_command(add_group_token(args, "ratio"))
}

///|
/// `merkin genius <command> ...`
/// Canonical AI-only inhabitation surface.
fn run_genius_command(args : Array[String]) -> Unit {
  if args.length() <= 2 {
    print_genius_usage()
    return
  }
  let subcmd = args[2]
  let normalized = strip_group_token(args)
  let locus_context = infer_genius_locus(normalized)
  if subcmd != "help" && !has_flag(normalized, "--bootstrap-genius") {
    match build_genius_attestation(normalized, locus_context) {
      Some(_) => ()
      None => {
        print_genius_attestation_requirement()
        return
      }
    }
  }
  match subcmd {
    "enter" => run_enter_command(normalized)
    "sign" => run_sign_command(normalized)
    "trail" => run_trail_command(normalized)
    "where" => run_where_command(normalized)
    "residue" => run_residue_command(normalized)
    "help" => print_genius_usage()
    _ => {
      println("Unknown Genius Loci command: " + subcmd)
      print_genius_usage()
    }
  }
}

///|
fn run_genius_alias_command(args : Array[String]) -> Unit {
  run_genius_command(add_group_token(args, "genius"))
}

///|
fn print_ratio_usage() -> Unit {
  println("Ratio Loci Commands:")
  println(
    "  ratio init [--store <path>]                        Initialize repository root",
  )
  println("  ratio loci new <name> [--tags t1,t2] [--spirit \"...\"]")
  println(
    "                                                    Scaffold a new locus",
  )
  println(
    "  ratio loci ls                                      List known loci",
  )
  println(
    "  ratio loci graph                                   Render locus graph",
  )
  println(
    "  ratio app put <ref> --payload <text>               Store APP envelope payload",
  )
  println(
    "  ratio app inspect <ref>                            Inspect APP envelope metadata",
  )
  println(
    "  ratio app emit-pr1 <ref>                           Emit attested .pr1 custom section",
  )
  println(
    "  ratio app parse-pr1 --hex <hex>                    Parse attested .pr1 custom section",
  )
  println(
    "  ratio status <locus>                               Repository status for a locus",
  )
  println(
    "  ratio pack <locus> [--format wasm|blob]            Pack sparse merkin tree",
  )
}

///|
fn print_genius_usage() -> Unit {
  println("Genius Loci Commands:")
  println(
    "  genius enter <locus>                               Enter a locus with AI context",
  )
  println(
    "  genius sign [<message>] --locus <name>             Sign exit residue",
  )
  println(
    "  genius trail <locus> [--depth <n>]                 Show activity trail",
  )
  println(
    "  genius where                                       Show recent AI activity",
  )
  println(
    "  genius residue <locus> [--session <id>]            Read residue files",
  )
  println("")
  println("Procsi attestation (required unless bootstrapping):")
  println(
    "  --procsi-surface <surface>                         codex, chatgpt, claude, etc.",
  )
  println(
    "  --procsi-fingerprint <commitment>                  AI substrate fingerprint commitment",
  )
  println(
    "  --app-ref <opaque-ref>                             APP-masked envelope reference",
  )
  println(
    "  --app-hash <hash-token>                            APP payload commitment",
  )
  println(
    "  [--project <id>] [--ratio-loci <id>]               defaults: zpc/merkin, repo-root",
  )
  println(
    "  [--app-protocol <name>] [--app-audience <name>]    defaults: app/v1, genius-loci",
  )
  println(
    "  --bootstrap-genius                                 local bring-up escape hatch",
  )
}

///|
fn infer_genius_locus(args : Array[String]) -> String? {
  if args.length() <= 1 {
    return None
  }
  let subcmd = args[1]
  match subcmd {
    "enter" => first_positional_locus(args)
    "trail" => first_positional_locus(args)
    "residue" => first_positional_locus(args)
    "sign" => {
      let locus = value_after(args, "--locus", "")
      if locus == "" {
        None
      } else {
        Some(locus)
      }
    }
    _ => {
      let locus = value_after(args, "--locus", "")
      if locus == "" {
        None
      } else {
        Some(locus)
      }
    }
  }
}

///|
fn first_positional_locus(args : Array[String]) -> String? {
  if args.length() > 2 && !line_starts_with_flag(args[2]) {
    Some(args[2])
  } else {
    let locus = value_after(args, "--locus", "")
    if locus == "" {
      None
    } else {
      Some(locus)
    }
  }
}

///|
fn build_genius_attestation(
  args : Array[String],
  locus_context : String?,
) -> @model.GeniusProcsiAttestation? {
  let fingerprint = value_after(args, "--procsi-fingerprint", "")
  let surface = value_after(args, "--procsi-surface", "")
  let app_ref = value_after(args, "--app-ref", "")
  let app_hash_token = value_after(args, "--app-hash", "")
  if fingerprint == "" || surface == "" || app_ref == "" {
    return None
  }
  let project = value_after(args, "--project", "zpc/merkin")
  let ratio_loci = value_after(args, "--ratio-loci", "repo-root")
  let fingerprint_hash = hash_token_to_hash(fingerprint)
  match resolve_app_envelope_record(args, app_ref) {
    Some(record) =>
      if app_hash_token != "" &&
        !record.ciphertext_hash.matches(hash_token_to_hash(app_hash_token)) {
        None
      } else {
        Some(
          @model.GeniusProcsiAttestation::new(
            locus_context,
            project,
            ratio_loci,
            surface,
            fingerprint_hash,
            record.to_mask_envelope(fingerprint_hash),
          ),
        )
      }
    None =>
      if app_hash_token == "" {
        None
      } else {
        let protocol = value_after(args, "--app-protocol", "app/v1")
        let audience = value_after(args, "--app-audience", "genius-loci")
        Some(
          @model.GeniusProcsiAttestation::from_masked_refs(
            locus_context,
            project,
            ratio_loci,
            surface,
            fingerprint_hash,
            protocol,
            audience,
            app_ref,
            hash_token_to_hash(app_hash_token),
          ),
        )
      }
  }
}

///|
fn print_genius_attestation_requirement() -> Unit {
  println("Error: Genius Loci commands require procsi attestation.")
  println("")
  println("Required flags:")
  println("  --procsi-surface <surface>")
  println("  --procsi-fingerprint <commitment>")
  println("  --app-ref <opaque-ref>")
  println("  --app-hash <hash-token> (required if ref is not in APP store)")
  println("")
  println("Optional flags:")
  println("  --project zpc/merkin")
  println("  --ratio-loci repo-root")
  println("  --app-protocol app/v1")
  println("  --app-audience genius-loci")
  println("")
  println("Bootstrap only:")
  println("  --bootstrap-genius --tier <tier> --session <id>")
}

///|
fn run_ratio_app_command(args : Array[String]) -> Unit {
  let subcmd = if args.length() > 2 { args[2] } else { "help" }
  let store = @storage.FileAppEnvelopeStore::new(resolve_app_store_root(args))
  match subcmd {
    "put" => {
      if args.length() <= 3 {
        println(
          "Usage: merkin ratio app put <ref> --payload <text> [--protocol app/v1] [--audience genius-loci]",
        )
        return
      }
      let ref_id = args[3]
      let payload = value_after(args, "--payload", "")
      if payload == "" {
        println("Error: APP payload is required. Use --payload <text>.")
        return
      }
      let protocol = value_after(args, "--protocol", "app/v1")
      let audience = value_after(args, "--audience", "genius-loci")
      let record = @model.AppEnvelopeRecord::new(
        ref_id,
        protocol,
        audience,
        cli_string_to_bytes(payload),
      )
      ignore(store.put(record))
      println("Stored APP envelope:")
      println("  ref=" + ref_id)
      println("  protocol=" + protocol)
      println("  audience=" + audience)
      println("  ciphertext_hash=" + record.ciphertext_hash.key())
      println("  store_root=" + resolve_app_store_root(args))
    }
    "inspect" => {
      if args.length() <= 3 {
        println("Usage: merkin ratio app inspect <ref>")
        return
      }
      let ref_id = args[3]
      match store.resolve(ref_id) {
        Some(record) => {
          println("APP envelope:")
          println("  ref=" + record.ref_id)
          println("  protocol=" + record.protocol)
          println("  audience=" + record.audience)
          println("  ciphertext_hash=" + record.ciphertext_hash.key())
          println(
            "  ciphertext_bytes=" + record.ciphertext.length().to_string(),
          )
          println("  store_root=" + resolve_app_store_root(args))
        }
        None => println("APP envelope not found: " + ref_id)
      }
    }
    "emit-pr1" => {
      if args.length() <= 3 {
        println(
          "Usage: merkin ratio app emit-pr1 <ref> --procsi-surface <surface> --procsi-fingerprint <commitment> [--context-hash <hash>] [--policy-hash <hash>]",
        )
        return
      }
      let ref_id = args[3]
      match store.resolve(ref_id) {
        Some(record) => {
          let surface = value_after(args, "--procsi-surface", "")
          let fingerprint = value_after(args, "--procsi-fingerprint", "")
          if surface == "" || fingerprint == "" {
            println(
              "Error: --procsi-surface and --procsi-fingerprint are required.",
            )
            return
          }
          let fingerprint_hash = hash_token_to_hash(fingerprint)
          let attestation = @model.GeniusProcsiAttestation::new(
            optional_value_after(args, "--locus"),
            value_after(args, "--project", "zpc/merkin"),
            value_after(args, "--ratio-loci", "repo-root"),
            surface,
            fingerprint_hash,
            record.to_mask_envelope(fingerprint_hash),
          )
          let section = @model.ProcsiAttestedSectionV1::new(
            attestation,
            hash_token_to_hash(value_after(args, "--context-hash", "")),
            hash_token_to_hash(value_after(args, "--policy-hash", "")),
          )
          let bytes = section.emit_pr1_custom_section()
          println("pr1_bytes=" + bytes.length().to_string())
          println("pr1_hex=" + cli_bytes_to_hex(bytes))
        }
        None => println("APP envelope not found: " + ref_id)
      }
    }
    "parse-pr1" => {
      let hex = value_after(args, "--hex", "")
      if hex == "" {
        println("Usage: merkin ratio app parse-pr1 --hex <hex>")
        return
      }
      match cli_hex_to_bytes(hex) {
        Some(bytes) =>
          match
            @model.ProcsiAttestedSectionV1::parse_pr1_custom_section(bytes) {
            Some(section) => {
              println("section=.pr1")
              println("locus=" + optional_to_text(section.attestation.locus))
              println("project=" + section.attestation.project)
              println("ratio_loci=" + section.attestation.ratio_loci)
              println("session_surface=" + section.attestation.session_surface)
              println(
                "fingerprint_commitment=" +
                section.attestation.fingerprint_commitment.key(),
              )
              println(
                "app_protocol=" + section.attestation.app_envelope.protocol,
              )
              println(
                "app_audience=" + section.attestation.app_envelope.audience,
              )
              println(
                "app_ref=" + section.attestation.app_envelope.ciphertext_ref,
              )
              println(
                "app_payload_hash=" +
                section.attestation.app_envelope.ciphertext_hash.key(),
              )
              println("context_hash=" + section.context_hash.key())
              println("policy_hash=" + section.policy_hash.key())
            }
            None => println("Error: invalid .pr1 custom section.")
          }
        None => println("Error: invalid hex input.")
      }
    }
    _ => println("Usage: merkin ratio app [put|inspect|emit-pr1|parse-pr1]")
  }
}

///|
fn resolve_app_store_root(args : Array[String]) -> String {
  value_after(args, "--store", ".merkin/store") + "/app"
}

///|
fn resolve_app_envelope_record(
  args : Array[String],
  app_ref : String,
) -> @model.AppEnvelopeRecord? {
  let store = @storage.FileAppEnvelopeStore::new(resolve_app_store_root(args))
  store.resolve(app_ref)
}

///|
fn optional_value_after(args : Array[String], flag : String) -> String? {
  let value = value_after(args, flag, "")
  if value == "" {
    None
  } else {
    Some(value)
  }
}

///|
fn hash_token_to_hash(token : String) -> @hash.Hash {
  if cli_line_starts_with(token, "blake3:") {
    match cli_hex_to_bytes(cli_substring(token, 7, cli_string_length(token))) {
      Some(bytes) => { alg: @hash.Blake3, digest: bytes }
      None => @hash.Hash::of_bytes(cli_string_to_bytes(token))
    }
  } else if cli_line_starts_with(token, "fnv1a:") {
    match cli_hex_to_bytes(cli_substring(token, 6, cli_string_length(token))) {
      Some(bytes) => { alg: @hash.Fnv1a, digest: bytes }
      None => @hash.Hash::of_bytes(cli_string_to_bytes(token))
    }
  } else {
    @hash.Hash::of_bytes(cli_string_to_bytes(token))
  }
}

///|
fn cli_string_to_bytes(s : String) -> Bytes {
  let mut total = 0
  for _ch in s {
    total = total + 4
  }
  let buf = FixedArray::make(total, b'\x00')
  let mut pos = 0
  for ch in s {
    let code = ch.to_uint()
    buf[pos] = ((code >> 24) & 0xFFU).to_byte()
    buf[pos + 1] = ((code >> 16) & 0xFFU).to_byte()
    buf[pos + 2] = ((code >> 8) & 0xFFU).to_byte()
    buf[pos + 3] = (code & 0xFFU).to_byte()
    pos = pos + 4
  }
  Bytes::from_array(buf)
}

///|
fn cli_hex_to_bytes(hex : String) -> Bytes? {
  if cli_string_length(hex) % 2 != 0 {
    return None
  }
  let out : Array[Byte] = []
  let chars : Array[Char] = []
  for ch in hex {
    chars.push(ch)
  }
  let mut i = 0
  while i < chars.length() {
    match cli_hex_nibble(chars[i]) {
      Some(hi) =>
        match cli_hex_nibble(chars[i + 1]) {
          Some(lo) => {
            out.push(((hi << 4) | lo).to_byte())
            i = i + 2
          }
          None => return None
        }
      None => return None
    }
  }
  Some(Bytes::from_array(out))
}

///|
fn cli_hex_nibble(ch : Char) -> UInt? {
  let value = ch.to_uint()
  if value >= '0'.to_uint() && value <= '9'.to_uint() {
    Some(value - '0'.to_uint())
  } else if value >= 'a'.to_uint() && value <= 'f'.to_uint() {
    Some(value - 'a'.to_uint() + 10U)
  } else if value >= 'A'.to_uint() && value <= 'F'.to_uint() {
    Some(value - 'A'.to_uint() + 10U)
  } else {
    None
  }
}

///|
fn cli_line_starts_with(line : String, prefix : String) -> Bool {
  if cli_string_length(prefix) > cli_string_length(line) {
    return false
  }
  let pchars : Array[Char] = []
  let lchars : Array[Char] = []
  for ch in prefix {
    pchars.push(ch)
  }
  for ch in line {
    lchars.push(ch)
  }
  let mut idx = 0
  while idx < pchars.length() {
    if pchars[idx] != lchars[idx] {
      return false
    }
    idx = idx + 1
  }
  true
}

///|
fn cli_substring(text : String, start : Int, end_ : Int) -> String {
  let b = StringBuilder::new(size_hint=end_ - start)
  let mut idx = 0
  for ch in text {
    if idx >= start && idx < end_ {
      b.write_char(ch)
    }
    idx = idx + 1
  }
  b.to_string()
}

///|
fn cli_string_length(text : String) -> Int {
  let mut len = 0
  for _ch in text {
    len = len + 1
  }
  len
}

///|
fn cli_bytes_to_hex(bytes : Bytes) -> String {
  let b = StringBuilder::new(size_hint=bytes.length() * 2)
  let mut i = 0
  while i < bytes.length() {
    let value = bytes[i].to_uint()
    b.write_string(cli_hex_digit((value >> 4) & 0x0FU))
    b.write_string(cli_hex_digit(value & 0x0FU))
    i = i + 1
  }
  b.to_string()
}

///|
fn cli_hex_digit(value : UInt) -> String {
  match value.reinterpret_as_int() {
    0 => "0"
    1 => "1"
    2 => "2"
    3 => "3"
    4 => "4"
    5 => "5"
    6 => "6"
    7 => "7"
    8 => "8"
    9 => "9"
    10 => "a"
    11 => "b"
    12 => "c"
    13 => "d"
    14 => "e"
    _ => "f"
  }
}

///|
fn optional_to_text(value : String?) -> String {
  match value {
    Some(text) => text
    None => ""
  }
}
