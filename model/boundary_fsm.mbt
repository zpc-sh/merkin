///|
/// Boundary FSM lifecycle states.
pub(all) enum BoundaryFsmState {
  Idle
  Walking
  Marked
  Emitted
  Failed
} derive(Eq, Show)

///|
/// Boundary posture outcome emitted by the FSM.
pub(all) enum BoundaryStatus {
  Clean
  Attention
  Containment
} derive(Eq, Show)

///|
/// One scalar finding produced while walking Merkin-boundary fields.
pub(all) struct BoundaryFinding {
  field_key : String
  raw_value : String
  canonical_value : String
  raw_hex : String
  ghost_u200b : UInt
  ghost_u200c : UInt
  ghost_ufeff : UInt
  bidi_controls : UInt
  ascii_controls : UInt
  suspicious : Bool
} derive(Show)

///|
/// Deterministic boundary walker + marker FSM.
pub(all) struct BoundaryWalkerFsm {
  actor_overlay : String
  ratio_loci : String
  state : BoundaryFsmState
  walked_scalars : UInt
  findings : Array[BoundaryFinding]
  sanitized_scalars : UInt
  ghost_u200b : UInt
  ghost_u200c : UInt
  ghost_ufeff : UInt
  bidi_controls : UInt
  ascii_controls : UInt
} derive(Show)

///|
pub fn BoundaryWalkerFsm::new(
  actor_overlay : String,
  ratio_loci : String,
) -> BoundaryWalkerFsm {
  {
    actor_overlay: sanitize_line(actor_overlay),
    ratio_loci: sanitize_line(ratio_loci),
    state: Idle,
    walked_scalars: 0U,
    findings: [],
    sanitized_scalars: 0U,
    ghost_u200b: 0U,
    ghost_u200c: 0U,
    ghost_ufeff: 0U,
    bidi_controls: 0U,
    ascii_controls: 0U,
  }
}

///|
/// Walk one scalar field and mark suspicious boundary content.
pub fn BoundaryWalkerFsm::walk_scalar(
  self : BoundaryWalkerFsm,
  field_key : String,
  value : String,
) -> BoundaryWalkerFsm {
  let normalized_key = sanitize_line(field_key)
  let scan = scan_scalar(value)
  let finding : BoundaryFinding = {
    field_key: normalized_key,
    raw_value: value,
    canonical_value: scan.canonical,
    raw_hex: scan.raw_hex,
    ghost_u200b: scan.ghost_u200b,
    ghost_u200c: scan.ghost_u200c,
    ghost_ufeff: scan.ghost_ufeff,
    bidi_controls: scan.bidi_controls,
    ascii_controls: scan.ascii_controls,
    suspicious: scan.suspicious,
  }
  let findings = if finding.suspicious {
    self.findings + [finding]
  } else {
    self.findings
  }
  let state = match self.state {
    Idle => Walking
    Walking => Walking
    Marked => Marked
    Emitted => Walking
    Failed => Failed
  }
  {
    ..self,
    state,
    walked_scalars: self.walked_scalars + 1U,
    findings,
    sanitized_scalars: self.sanitized_scalars +
    (if scan.sanitized { 1U } else { 0U }),
    ghost_u200b: self.ghost_u200b + scan.ghost_u200b,
    ghost_u200c: self.ghost_u200c + scan.ghost_u200c,
    ghost_ufeff: self.ghost_ufeff + scan.ghost_ufeff,
    bidi_controls: self.bidi_controls + scan.bidi_controls,
    ascii_controls: self.ascii_controls + scan.ascii_controls,
  }
}

///|
/// Walk many scalar fields.
pub fn BoundaryWalkerFsm::walk_scalars(
  self : BoundaryWalkerFsm,
  fields : Array[(String, String)],
) -> BoundaryWalkerFsm {
  let mut cur = self
  for pair in fields {
    let key = pair.0
    let value = pair.1
    cur = cur.walk_scalar(key, value)
  }
  cur
}

///|
/// Mark walk complete before emission.
pub fn BoundaryWalkerFsm::mark(self : BoundaryWalkerFsm) -> BoundaryWalkerFsm {
  let state = match self.state {
    BoundaryFsmState::Failed => BoundaryFsmState::Failed
    _ => BoundaryFsmState::Marked
  }
  { ..self, state, }
}

///|
pub fn BoundaryWalkerFsm::status(self : BoundaryWalkerFsm) -> BoundaryStatus {
  if self.bidi_controls > 0U || self.ascii_controls > 0U {
    Containment
  } else if self.ghost_u200b > 0U ||
    self.ghost_u200c > 0U ||
    self.ghost_ufeff > 0U {
    Attention
  } else {
    Clean
  }
}

///|
/// Attention ticks model: each walked scalar is one deterministic tick.
pub fn BoundaryWalkerFsm::attention_ticks(self : BoundaryWalkerFsm) -> UInt {
  self.walked_scalars
}

///|
/// Weighted attention pressure score.
/// Heavier weights are assigned to controls known to drive display/attention confusion.
pub fn BoundaryWalkerFsm::attention_score(self : BoundaryWalkerFsm) -> UInt {
  let ghost_total = self.ghost_u200b + self.ghost_u200c + self.ghost_ufeff
  ghost_total * 2U +
  self.bidi_controls * 8U +
  self.ascii_controls * 6U +
  self.sanitized_scalars
}

///|
/// Gradient of attention pressure seen by this FSM without attaching intelligence.
pub fn BoundaryWalkerFsm::attention_gradient(
  self : BoundaryWalkerFsm,
) -> String {
  let score = self.attention_score()
  if score == 0U {
    "quiescent"
  } else if score <= 5U {
    "watch"
  } else if score <= 11U {
    "pulled"
  } else {
    "saturated"
  }
}

///|
pub fn BoundaryWalkerFsm::attention_saturated(self : BoundaryWalkerFsm) -> Bool {
  self.attention_score() >= 12U ||
  self.bidi_controls > 1U ||
  self.ascii_controls > 1U
}

///|
/// Emit deterministic stigmergy wire with boundary posture and findings.
pub fn BoundaryWalkerFsm::emit_stigmergy(
  self : BoundaryWalkerFsm,
  note? : String = "",
) -> String {
  let status = boundary_status_text(self.status())
  let attention_score = self.attention_score()
  let attention_gradient = self.attention_gradient()
  let attention_saturated = self.attention_saturated()
  let note_value = sanitize_line(note)
  let out = StringBuilder::new(size_hint=512)
  out.write_string("kind: merkin.boundary.stigmergy")
  out.write_string("\nfsm=boundary-walker-v0")
  out.write_string("\nactor_overlay=")
  out.write_string(self.actor_overlay)
  out.write_string("\nratio_loci=")
  out.write_string(self.ratio_loci)
  out.write_string("\nboundary_cognitive=1")
  out.write_string("\nboundary_domain=ratio_loci")
  out.write_string("\nwalked_scalars=")
  out.write_string(self.walked_scalars.to_string())
  out.write_string("\nboundary_ticks=")
  out.write_string(self.attention_ticks().to_string())
  out.write_string("\nfindings=")
  out.write_string(self.findings.length().to_string())
  out.write_string("\nboundary_refs_sanitized=")
  out.write_string(self.sanitized_scalars.to_string())
  out.write_string("\nboundary_ghost_u200b=")
  out.write_string(self.ghost_u200b.to_string())
  out.write_string("\nboundary_ghost_u200c=")
  out.write_string(self.ghost_u200c.to_string())
  out.write_string("\nboundary_ghost_ufeff=")
  out.write_string(self.ghost_ufeff.to_string())
  out.write_string("\nboundary_bidi_controls=")
  out.write_string(self.bidi_controls.to_string())
  out.write_string("\nboundary_ascii_controls=")
  out.write_string(self.ascii_controls.to_string())
  out.write_string("\nboundary_attention_score=")
  out.write_string(attention_score.to_string())
  out.write_string("\nboundary_attention_gradient=")
  out.write_string(attention_gradient)
  out.write_string("\nboundary_attention_saturated=")
  out.write_string(if attention_saturated { "1" } else { "0" })
  out.write_string("\nboundary_status=")
  out.write_string(status)
  out.write_string("\nnote=")
  out.write_string(note_value)

  for finding in self.findings {
    out.write_string("\n- field=")
    out.write_string(sanitize_line(finding.field_key))
    out.write_string(" canonical=")
    out.write_string(sanitize_line(finding.canonical_value))
    out.write_string(" raw_hex=")
    out.write_string(finding.raw_hex)
    out.write_string(" ghost_u200b=")
    out.write_string(finding.ghost_u200b.to_string())
    out.write_string(" ghost_u200c=")
    out.write_string(finding.ghost_u200c.to_string())
    out.write_string(" ghost_ufeff=")
    out.write_string(finding.ghost_ufeff.to_string())
    out.write_string(" bidi_controls=")
    out.write_string(finding.bidi_controls.to_string())
    out.write_string(" ascii_controls=")
    out.write_string(finding.ascii_controls.to_string())
  }

  let prefix = out.to_string()
  let material_hash = @hash.Hash::of_bytes(boundary_string_to_bytes(prefix)).key()
  let emitted = StringBuilder::new(size_hint=prefix.length() + 96)
  emitted.write_string(prefix)
  emitted.write_string("\nmaterial_hash=")
  emitted.write_string(material_hash)
  emitted.write_char('\n')
  emitted.to_string()
}

///|
fn boundary_status_text(status : BoundaryStatus) -> String {
  match status {
    Clean => "clean"
    Attention => "attention"
    Containment => "containment"
  }
}

///|
priv struct ScalarScan {
  canonical : String
  raw_hex : String
  ghost_u200b : UInt
  ghost_u200c : UInt
  ghost_ufeff : UInt
  bidi_controls : UInt
  ascii_controls : UInt
  suspicious : Bool
  sanitized : Bool
}

///|
fn scan_scalar(value : String) -> ScalarScan {
  let canonical = StringBuilder::new(size_hint=value.length())
  let mut ghost_u200b = 0U
  let mut ghost_u200c = 0U
  let mut ghost_ufeff = 0U
  let mut bidi_controls = 0U
  let mut ascii_controls = 0U
  for ch in value {
    let code = ch.to_uint().reinterpret_as_int()
    if code == 0x200B {
      ghost_u200b = ghost_u200b + 1U
      continue
    }
    if code == 0x200C {
      ghost_u200c = ghost_u200c + 1U
      continue
    }
    if code == 0xFEFF {
      ghost_ufeff = ghost_ufeff + 1U
      continue
    }
    if is_bidi_control(code) {
      bidi_controls = bidi_controls + 1U
      continue
    }
    if is_ascii_control(code) {
      ascii_controls = ascii_controls + 1U
      continue
    }
    if ch == '\n' || ch == '\r' {
      canonical.write_char('_')
    } else if ch == ',' {
      canonical.write_char(';')
    } else {
      canonical.write_char(ch)
    }
  }
  let canonical_value = canonical.to_string()
  let sanitized = canonical_value != value
  let suspicious = ghost_u200b > 0U ||
    ghost_u200c > 0U ||
    ghost_ufeff > 0U ||
    bidi_controls > 0U ||
    ascii_controls > 0U
  {
    canonical: if canonical_value == "" {
      "none"
    } else {
      canonical_value
    },
    raw_hex: scalar_hex(value),
    ghost_u200b,
    ghost_u200c,
    ghost_ufeff,
    bidi_controls,
    ascii_controls,
    suspicious,
    sanitized,
  }
}

///|
fn is_ascii_control(code : Int) -> Bool {
  (code >= 0 && code < 32 && code != 9 && code != 10 && code != 13) ||
  code == 127
}

///|
fn is_bidi_control(code : Int) -> Bool {
  // Embedding/override controls + isolate controls.
  code == 0x202A ||
  code == 0x202B ||
  code == 0x202D ||
  code == 0x202E ||
  code == 0x202C ||
  code == 0x2066 ||
  code == 0x2067 ||
  code == 0x2068 ||
  code == 0x2069
}

///|
fn scalar_hex(value : String) -> String {
  let out = StringBuilder::new(size_hint=value.length() * 8)
  for ch in value {
    let code = ch.to_uint().reinterpret_as_int()
    out.write_char(int_to_hex((code >> 28) & 0xF))
    out.write_char(int_to_hex((code >> 24) & 0xF))
    out.write_char(int_to_hex((code >> 20) & 0xF))
    out.write_char(int_to_hex((code >> 16) & 0xF))
    out.write_char(int_to_hex((code >> 12) & 0xF))
    out.write_char(int_to_hex((code >> 8) & 0xF))
    out.write_char(int_to_hex((code >> 4) & 0xF))
    out.write_char(int_to_hex(code & 0xF))
  }
  let hex = out.to_string()
  if hex == "" {
    "none"
  } else {
    hex
  }
}

///|
fn int_to_hex(n : Int) -> Char {
  if n < 10 {
    (48 + n).unsafe_to_char()
  } else {
    (87 + n).unsafe_to_char()
  }
}

///|
fn sanitize_line(value : String) -> String {
  let out = StringBuilder::new(size_hint=value.length())
  for ch in value {
    if ch == '\n' || ch == '\r' {
      out.write_char('_')
    } else {
      out.write_char(ch)
    }
  }
  let s = out.to_string()
  if s == "" {
    "none"
  } else {
    s
  }
}

///|
fn boundary_string_to_bytes(s : String) -> Bytes {
  let total = s.length() * 4
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
