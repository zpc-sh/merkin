///|
/// How an imprint is materialized for later projection.
pub(all) enum MirageMode {
  /// Keep only visible surface markers from the source.
  SurfaceOnly
  /// Keep surface and contract tags, but no private payload.
  ContractOnly
  /// Keep forward/backward horizon metadata for timeline-facing projections.
  Temporal
  /// Surface only plus contract graph for defense-side inspection.
  Defense
} derive(Eq, Show)

///|
/// Universal imprint source classes.
pub(all) enum ImprintKind {
  Router
  Node
  Artifact
  Envelope
  Unknown
} derive(Eq, Show)

///|
/// Source-neutral imprint that can be lifted from any subsystem.
pub(all) struct Imprint {
  /// Deterministic identifier of the imprint record.
  imprint_id : @hash.Hash
  /// Stable source label (e.g. `router://ingest`).
  source : String
  /// What this imprint points to.
  kind : ImprintKind
  /// Surface-only appearance fields (intent labels, tags, names).
  surface_projection : Array[String]
  /// Human-readable route/path projection.
  route_projection : Array[String]
  /// Contract/constraint tags visible at this layer.
  contract_graph : Array[String]
  /// Optional lineage pointer to a previous imprint.
  parent_imprint : @hash.Hash?
  /// Horizon size for preemptive projection (0 = collapsed to single step).
  horizon : UInt
  /// Materialization mode.
  mode : MirageMode
  /// Deterministic confidence proxy used by callers.
  confidence : UInt
} derive(Show)

///|
/// Read-only, surface-only representation of an imprint.
pub(all) struct Mirage {
  /// Deterministic identifier of the mirage record.
  mirage_id : @hash.Hash
  /// Source imprint this mirage was derived from.
  source_imprint : @hash.Hash
  /// Stable source label.
  source : String
  /// Source class.
  kind : ImprintKind
  /// Public face of the system for fast transfer and inspection.
  appearance : Array[String]
  /// Public route surface.
  route_projection : Array[String]
  /// Public contract-facing signatures.
  contract_graph : Array[String]
  /// Horizon retained in the projected form.
  horizon : UInt
  /// Projection mode.
  mode : MirageMode
  /// Projected confidence.
  confidence : UInt
  /// Always false for content fields because this is intentionally hollow.
  has_private_payload : Bool
} derive(Show)

///|
/// Lift a router-like object into a universal imprint.
/// No private payload is included; this is a mirage-ready surface record.
pub fn lift_router_imprint(
  router_id : String,
  route : Array[String],
  contract_graph : Array[String],
  parent_imprint : @hash.Hash?,
) -> Imprint {
  let surface_projection = ["router", router_id]
  Imprint::new(
    router_id,
    ImprintKind::Router,
    surface_projection,
    route,
    contract_graph,
    parent_imprint,
    1U,
    MirageMode::Defense,
  )
}

///|
/// Construct a generic imprint.
pub fn Imprint::new(
  source : String,
  kind : ImprintKind,
  surface_projection : Array[String],
  route_projection : Array[String],
  contract_graph : Array[String],
  parent_imprint : @hash.Hash?,
  horizon : UInt,
  mode : MirageMode,
) -> Imprint {
  let confidence = infer_confidence(
    surface_projection, route_projection, contract_graph, horizon,
  )
  let material = imprint_material(
    source, kind, surface_projection, route_projection, contract_graph, parent_imprint,
    horizon, mode, confidence,
  )
  let imprint_id = @hash.Hash::of_bytes(imprint_string_to_bytes(material))
  {
    imprint_id,
    source,
    kind,
    surface_projection,
    route_projection,
    contract_graph,
    parent_imprint,
    horizon,
    mode,
    confidence,
  }
}

///|
/// Convert an imprint into a hollow, portable mirage.
pub fn Imprint::to_mirage(self : Imprint) -> Mirage {
  let appearance = [self.mode_name()]
  for value in self.surface_projection {
    appearance.push(value)
  }
  {
    mirage_id: self.imprint_id,
    source_imprint: self.imprint_id,
    source: self.source,
    kind: self.kind,
    appearance,
    route_projection: self.route_projection,
    contract_graph: self.contract_graph,
    horizon: self.horizon,
    mode: self.mode,
    confidence: self.confidence,
    has_private_payload: false,
  }
}

///|
/// Deterministic confidence proxy:
/// more tags and wider horizon increase confidence up to 100.
fn infer_confidence(
  surface : Array[String],
  route : Array[String],
  contracts : Array[String],
  horizon : UInt,
) -> UInt {
  let score = surface.length().reinterpret_as_uint() * 12U +
    route.length().reinterpret_as_uint() * 8U +
    contracts.length().reinterpret_as_uint() * 10U +
    horizon * 3U
  if score > 100U {
    100U
  } else {
    score
  }
}

///|
/// Internal identifier materialization helper.
fn imprint_material(
  source : String,
  kind : ImprintKind,
  surface_projection : Array[String],
  route_projection : Array[String],
  contract_graph : Array[String],
  parent_imprint : @hash.Hash?,
  horizon : UInt,
  mode : MirageMode,
  confidence : UInt,
) -> String {
  let b = StringBuilder::new()
  b.write_string(kind.to_string())
  b.write_string("|")
  b.write_string(source)
  b.write_string("|")
  b.write_string(join_strings(surface_projection, ";"))
  b.write_string("|")
  b.write_string(join_strings(route_projection, "->"))
  b.write_string("|")
  b.write_string(join_strings(contract_graph, ","))
  b.write_string("|")
  match parent_imprint {
    Some(parent) => b.write_string(parent.key())
    None => b.write_string("none")
  }
  b.write_string("|")
  b.write_string(horizon.to_string())
  b.write_string("|")
  b.write_string(mode.to_string())
  b.write_string("|")
  b.write_string(confidence.to_string())
  b.to_string()
}

///|
/// Friendly display helper for debug and deterministic IDs.
fn join_strings(items : Array[String], sep : String) -> String {
  if items.length() == 0 {
    return ""
  }
  let mut out = items[0]
  for i = 1; i < items.length(); i = i + 1 {
    out = out + sep + items[i]
  }
  out
}

///|
/// Build label for a mode on mirage conversion.
fn MirageMode::to_string(self : MirageMode) -> String {
  match self {
    SurfaceOnly => "surface-only"
    ContractOnly => "contract-only"
    Temporal => "temporal"
    Defense => "defense"
  }
}

///|
/// Build label for the source kind.
fn ImprintKind::to_string(self : ImprintKind) -> String {
  match self {
    Router => "router"
    Node => "node"
    Artifact => "artifact"
    Envelope => "envelope"
    Unknown => "unknown"
  }
}

///|
/// Build label with mode context for the appearance layer.
fn Imprint::mode_name(self : Imprint) -> String {
  "mode:" + mode_to_tag(self.mode)
}

///|
fn mode_to_tag(mode : MirageMode) -> String {
  match mode {
    SurfaceOnly => "surface-only"
    ContractOnly => "contract-only"
    Temporal => "temporal"
    Defense => "defense"
  }
}

///|
fn imprint_string_to_bytes(s : String) -> Bytes {
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
