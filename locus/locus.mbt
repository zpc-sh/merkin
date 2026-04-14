///|
/// LocusRuntime: the agent's view of a locus.
/// Bridges filesystem operations with substrate storage.
///
/// In filesystem mode, the LocusRuntime reads and writes directly
/// to loci/<name>/ directories. In substrate mode, it seals into
/// MerkinTree envelopes on push and queries SMT layers.
///
/// Filesystem mode → SMT mode migration is transparent:
/// same residue format, same commands, different backend.

///|
/// Configuration for the locus runtime.
pub(all) struct LocusConfig {
  /// Root directory containing all loci (default: "loci")
  loci_root : String
  /// Store path (default: "~/.merkin/store")
  store_path : String
} derive(Show)

///|
pub fn LocusConfig::default() -> LocusConfig {
  { loci_root: "loci", store_path: "~/.merkin/store" }
}

///|
/// The runtime context for locus operations.
pub(all) struct LocusRuntime {
  config : LocusConfig
  session : @model.SessionIdentity
} derive(Show)

///|
/// Create a new LocusRuntime.
pub fn LocusRuntime::new(
  config : LocusConfig,
  session : @model.SessionIdentity,
) -> LocusRuntime {
  { config, session }
}

///|
/// Create with defaults.
pub fn LocusRuntime::default(session : @model.SessionIdentity) -> LocusRuntime {
  { config: LocusConfig::default(), session }
}

///|
/// Resolve the filesystem path for a locus.
pub fn LocusRuntime::locus_path(self : LocusRuntime, name : String) -> String {
  self.config.loci_root + "/" + name
}

///|
/// Resolve the residue directory for a locus.
pub fn LocusRuntime::residue_path(self : LocusRuntime, name : String) -> String {
  self.locus_path(name) + "/residue"
}

///|
/// Emit the directory scaffold for `merkin loci new`.
/// Returns the list of paths that should be created.
pub fn LocusRuntime::scaffold_paths(
  self : LocusRuntime,
  name : String,
) -> Array[String] {
  let root = self.locus_path(name)
  let paths : Array[String] = []
  paths.push(root)
  for sub in @model.locus_subdirs() {
    paths.push(root + "/" + sub)
  }
  paths.push(root + "/README.md")
  paths
}

///|
/// Generate the README.md content for a new locus.
pub fn LocusRuntime::scaffold_readme(
  self : LocusRuntime,
  locus : @model.Locus,
) -> String {
  let b = StringBuilder::new(size_hint=256)
  b.write_string("# ")
  b.write_string(locus.name)
  b.write_char('\n')
  b.write_char('\n')
  b.write_string("**Spirit**: ")
  b.write_string(locus.spirit)
  b.write_char('\n')
  b.write_char('\n')
  if locus.tags.length() > 0 {
    b.write_string("**Tags**: ")
    let mut first = true
    for tag in locus.tags {
      if !first {
        b.write_string(", ")
      }
      b.write_string(tag)
      first = false
    }
    b.write_char('\n')
    b.write_char('\n')
  }
  b.write_string("## Entry Primitives\n\n")
  b.write_string("(fill: what a new agent should know before entering)\n\n")
  b.write_string("## Membranes\n\n")
  b.write_string("(none configured)\n\n")
  b.write_string("## Affordances\n\n")
  b.write_string("(none configured)\n")
  ignore(self)
  b.to_string()
}

///|
/// Format a trail display for output.
/// Takes an array of residues (most recent first) and formats
/// the trail panel output matching the CLI spec.
pub fn format_trail(
  locus_name : String,
  residues : Array[@model.Residue],
) -> String {
  let b = StringBuilder::new(size_hint=1024)
  b.write_string("Trail for: ")
  b.write_string(locus_name)
  b.write_string("  (")
  b.write_string(residues.length().to_string())
  b.write_string(" sessions)\n\n")
  let mut seq = residues.length()
  for r in residues {
    b.write_string("╔══ [")
    b.write_string(seq.to_string())
    b.write_string("] ")
    b.write_string(r.tier)
    b.write_char('/')
    b.write_string(r.session_short_id)
    b.write_string("  ")
    b.write_string(r.timestamp)
    b.write_string("  ")
    // Pad to box width
    let pad_count = 40
    let mut p = 0
    while p < pad_count {
      b.write_char('═')
      p = p + 1
    }
    b.write_string("╗\n")
    // Entry context
    b.write_string("║  Entry context: ")
    match r.picked_up_from {
      Some(from) => b.write_string(from)
      None => b.write_string("cold entry (no prior residue)")
    }
    b.write_char('\n')
    // What I did
    for item in r.what_i_did {
      b.write_string("║  ")
      b.write_string(item)
      b.write_char('\n')
    }
    // Exit residue
    b.write_string("║  Exit residue: → residue/")
    b.write_string(r.filename())
    b.write_char('\n')
    // Open threads
    if r.what_i_left_open.length() > 0 {
      b.write_string("║  Open threads: ")
      let mut first = true
      for item in r.what_i_left_open {
        if !first {
          b.write_string(", ")
        }
        b.write_string(item)
        first = false
      }
      b.write_char('\n')
    }
    b.write_char('╚')
    let mut w = 0
    while w < 70 {
      b.write_char('═')
      w = w + 1
    }
    b.write_string("╝\n\n")
    seq = seq - 1
  }
  b.to_string()
}

///|
/// Format the `merkin where` output.
/// Takes a list of (locus_name, most_recent_residue) pairs.
pub fn format_where(entries : Array[(String, @model.Residue?)]) -> String {
  let b = StringBuilder::new(size_hint=512)
  b.write_string("LOCUS           LAST VISIT        TIER    OPEN THREADS\n")
  for entry in entries {
    let name = entry.0
    b.write_string(pad_right(name, 16))
    match entry.1 {
      Some(r) => {
        b.write_string(pad_right(r.timestamp, 18))
        b.write_string(pad_right(r.tier, 8))
        if r.what_i_left_open.length() > 0 {
          b.write_string(r.what_i_left_open[0])
        } else {
          b.write_string("(none logged)")
        }
      }
      None => {
        b.write_string(pad_right("—", 18))
        b.write_string(pad_right("—", 8))
        b.write_string("—")
      }
    }
    b.write_char('\n')
  }
  b.to_string()
}

///|
/// Format the `merkin enter` preamble.
pub fn format_enter_preamble(
  locus_name : String,
  last_residue : @model.Residue?,
) -> String {
  let b = StringBuilder::new(size_hint=512)
  b.write_string(
    "─────────────────────────────────────────────────────\n",
  )
  b.write_string("You are entering: ")
  b.write_string(locus_name)
  b.write_char('\n')
  match last_residue {
    Some(r) => {
      b.write_string("Last Claude here: ")
      b.write_string(r.tier)
      b.write_char('/')
      b.write_string(r.session_short_id)
      b.write_string("  (")
      b.write_string(r.timestamp)
      b.write_string(")\n\n")
      if r.what_i_left_open.length() > 0 {
        b.write_string("Open threads from last residue:\n")
        for item in r.what_i_left_open {
          b.write_string("  ! ")
          b.write_string(item)
          b.write_char('\n')
        }
      }
    }
    None => b.write_string("First entry — no prior residue.\n")
  }
  b.write_string(
    "─────────────────────────────────────────────────────\n",
  )
  b.to_string()
}

///|
/// Format a single residue for `merkin residue` display.
pub fn format_residue(r : @model.Residue) -> String {
  let b = StringBuilder::new(size_hint=512)
  b.write_string("── residue/")
  b.write_string(r.filename())
  b.write_char(' ')
  let mut d = 0
  while d < 50 {
    b.write_char('─')
    d = d + 1
  }
  b.write_char('\n')
  b.write_string("Filed by: ")
  b.write_string(r.tier)
  b.write_char('/')
  b.write_string(r.session_short_id)
  b.write_string("  at  ")
  b.write_string(r.timestamp)
  b.write_string("\n\n")
  match r.picked_up_from {
    Some(from) => {
      b.write_string("Picked up from: ")
      b.write_string(from)
      b.write_string("\n\n")
    }
    None => b.write_string("Picked up from: (cold entry)\n\n")
  }
  b.write_string("What I did:\n")
  for item in r.what_i_did {
    b.write_string("- ")
    b.write_string(item)
    b.write_char('\n')
  }
  b.write_string("\nWhat I left open:\n")
  for item in r.what_i_left_open {
    b.write_string("- ")
    b.write_string(item)
    b.write_char('\n')
  }
  match r.recommendation {
    Some(rec) => {
      b.write_string("\nNext Claude: ")
      b.write_string(rec)
      b.write_char('\n')
    }
    None => ()
  }
  let mut e = 0
  while e < 66 {
    b.write_char('─')
    e = e + 1
  }
  b.write_char('\n')
  b.to_string()
}

// --- Internal helpers ---

///|
fn pad_right(s : String, width : Int) -> String {
  let b = StringBuilder::new(size_hint=width)
  let mut len = 0
  for ch in s {
    b.write_char(ch)
    len = len + 1
  }
  while len < width {
    b.write_char(' ')
    len = len + 1
  }
  b.to_string()
}
