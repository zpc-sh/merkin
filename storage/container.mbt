///|
/// Cognitive Container — OCI-compatible packaging of node state.
///
/// A cognitive container bundles all node state into portable layers:
///   - Void state (serialized accumulator)
///   - Tree snapshot (serialized merkin tree)
///   - Bloom sketch (serialized routing filter)
///   - Plugin layers (wasm bytes + procsi sections)
///   - Node-level procsi attestation (.pr1)
///   - Config (MUON node configuration)
///
/// The container follows OCI image conventions:
///   - Each layer is a content-addressed blob
///   - A manifest describes layers, media types, and annotations
///   - Tags follow epoch convention: "epoch-N", "latest"
///
/// UKI parallel:
///   UKI kernel   → node wasm module
///   UKI initrd   → plugin wasms + void state
///   UKI cmdline  → config MUON
///   UKI sig      → .pr1 attestation + APP envelope

// ---------------------------------------------------------------------------
// Media type constants
// ---------------------------------------------------------------------------

let media_void : String = "application/vnd.merkin.void.v1"

///|
let media_tree : String = "application/vnd.merkin.tree.v1"

///|
let media_bloom : String = "application/vnd.merkin.bloom.v1"

///|
let media_plugin : String = "application/vnd.mu.plugin.wasm-gc.v1"

///|
let media_procsi : String = "application/vnd.mu.procsi.pr1.v1"

///|
let media_config : String = "application/vnd.merkin.config.muon.v1"

///|
let _media_manifest : String = "application/vnd.merkin.cognitive.manifest.v1+json"

///|
let annotation_solve_kind : String = "solve_kind"

///|
let annotation_solve_report_offloaded_to : String = "solve_report_offloaded_to"

///|
let annotation_sat_smt_offloaded : String = "sat_smt_offloaded"

// Container magic: "COGN"

///|
let container_magic : Array[Byte] = [b'\x43', b'\x4F', b'\x47', b'\x4E']

///|
let container_version : Int = 1

// ---------------------------------------------------------------------------
// Layer descriptor
// ---------------------------------------------------------------------------

///|
/// Describes one layer in a cognitive container.
pub(all) struct LayerDescriptor {
  media_type : String
  digest : @hash.Hash
  size : Int
  name : String // human label (e.g., "void", "bloom", plugin name)
} derive(Show)

///|
pub fn LayerDescriptor::new(
  media_type : String,
  data : Bytes,
  name : String,
) -> LayerDescriptor {
  let digest = @hash.Hash::of_bytes(data)
  { media_type, digest, size: data.length(), name }
}

// ---------------------------------------------------------------------------
// Plugin layer
// ---------------------------------------------------------------------------

///|
/// A plugin's wasm bytes plus extracted procsi metadata.
pub(all) struct PluginLayer {
  name : String
  wasm_hash : @hash.Hash // content hash of wasm bytes
  wasm_size : Int
  wasm_bytes : Bytes
  procsi : Bytes // extracted .prc/.pr1 section bytes (may be empty)
  mks_state : Bytes? // optional .mks solve cursor bytes
} derive(Show)

///|
pub fn PluginLayer::new(name : String, wasm_bytes : Bytes) -> PluginLayer {
  {
    name,
    wasm_hash: @hash.Hash::of_bytes(wasm_bytes),
    wasm_size: wasm_bytes.length(),
    wasm_bytes,
    procsi: Bytes::default(),
    mks_state: None,
  }
}

///|
pub fn PluginLayer::with_procsi(
  self : PluginLayer,
  procsi : Bytes,
) -> PluginLayer {
  { ..self, procsi, }
}

///|
pub fn PluginLayer::with_mks(self : PluginLayer, mks : Bytes) -> PluginLayer {
  { ..self, mks_state: Some(mks) }
}

// ---------------------------------------------------------------------------
// Container manifest
// ---------------------------------------------------------------------------

///|
/// Manifest describing a cognitive container's layers.
pub(all) struct ContainerManifest {
  schema_version : Int
  layers : Array[LayerDescriptor]
  annotations : Map[String, String] // key/value metadata (includes finger.plan summary)
  total_size : Int // sum of all layer sizes
} derive(Show)

///|
pub fn ContainerManifest::new() -> ContainerManifest {
  {
    schema_version: container_version,
    layers: [],
    annotations: {},
    total_size: 0,
  }
}

///|
pub fn ContainerManifest::add_layer(
  self : ContainerManifest,
  descriptor : LayerDescriptor,
) -> ContainerManifest {
  self.layers.push(descriptor)
  { ..self, total_size: self.total_size + descriptor.size }
}

///|
pub fn ContainerManifest::set_annotation(
  self : ContainerManifest,
  key : String,
  value : String,
) -> ContainerManifest {
  self.annotations[key] = value
  self
}

///|
pub fn ContainerManifest::layer_count(self : ContainerManifest) -> Int {
  self.layers.length()
}

///|
/// Mark this manifest as carrying SAT/SMT work that was offloaded.
///
/// This mirrors solve metadata used in Yata plans:
/// - `solve_kind=smt`
/// - `sat_smt_offloaded=true`
/// - `solve_report_offloaded_to=<provider>`
pub fn ContainerManifest::mark_sat_smt_offloaded(
  self : ContainerManifest,
  offloaded_to : String,
) -> ContainerManifest {
  let next = self
    .set_annotation(annotation_solve_kind, "smt")
    .set_annotation(annotation_sat_smt_offloaded, "true")
  if offloaded_to == "" {
    next
  } else {
    next.set_annotation(annotation_solve_report_offloaded_to, offloaded_to)
  }
}

///|
/// Merge two packfile manifests.
///
/// Layer identity is keyed by `<media_type>|<name>`.
/// - Existing keys are replaced by `other`.
/// - New keys from `other` are appended.
/// - Annotation keys from `other` override `self`.
pub fn ContainerManifest::merge(
  self : ContainerManifest,
  other : ContainerManifest,
) -> ContainerManifest {
  let merged_layers : Array[LayerDescriptor] = []
  let layer_index : Map[String, Int] = {}

  for layer in self.layers {
    let key = merge_layer_key(layer)
    layer_index[key] = merged_layers.length()
    merged_layers.push(layer)
  }

  for layer in other.layers {
    let key = merge_layer_key(layer)
    match layer_index.get(key) {
      Some(index) => merged_layers[index] = layer
      None => {
        layer_index[key] = merged_layers.length()
        merged_layers.push(layer)
      }
    }
  }

  let annotations : Map[String, String] = {}
  for k, v in self.annotations {
    annotations[k] = v
  }
  for k, v in other.annotations {
    annotations[k] = v
  }

  let mut total_size = 0
  for layer in merged_layers {
    total_size = total_size + layer.size
  }

  {
    schema_version: container_version,
    layers: merged_layers,
    annotations,
    total_size,
  }
}

// ---------------------------------------------------------------------------
// Cognitive container
// ---------------------------------------------------------------------------

///|
/// A cognitive container — the portable packaging of all node state.
pub(all) struct CognitiveContainer {
  manifest : ContainerManifest
  void_layer : Bytes // serialized Void
  tree_layer : Bytes // serialized tree snapshot
  bloom_layer : Bytes // serialized bloom sketch
  plugin_layers : Array[PluginLayer] // plugin wasms
  procsi_layer : Bytes // node-level .pr1 attestation
  config_layer : Bytes // MUON config bytes
} derive(Show)

///|
/// Build a cognitive container from individual state components.
pub fn CognitiveContainer::pack(
  void_bytes : Bytes,
  tree_bytes : Bytes,
  bloom_bytes : Bytes,
  plugins : Array[PluginLayer],
  procsi_bytes : Bytes,
  config_bytes : Bytes,
  annotations : Map[String, String],
) -> CognitiveContainer {
  let mut manifest = ContainerManifest::new()

  // Core layers
  manifest = manifest.add_layer(
    LayerDescriptor::new(media_void, void_bytes, "void"),
  )
  manifest = manifest.add_layer(
    LayerDescriptor::new(media_tree, tree_bytes, "tree"),
  )
  manifest = manifest.add_layer(
    LayerDescriptor::new(media_bloom, bloom_bytes, "bloom"),
  )

  // Plugin layers
  for plugin in plugins {
    let plugin_desc : LayerDescriptor = {
      media_type: media_plugin,
      digest: plugin.wasm_hash,
      size: plugin.wasm_size,
      name: plugin.name,
    }
    manifest = manifest.add_layer(plugin_desc)
  }

  // Procsi attestation
  if procsi_bytes.length() > 0 {
    manifest = manifest.add_layer(
      LayerDescriptor::new(media_procsi, procsi_bytes, "procsi"),
    )
  }

  // Config
  if config_bytes.length() > 0 {
    manifest = manifest.add_layer(
      LayerDescriptor::new(media_config, config_bytes, "config"),
    )
  }

  // Apply annotations
  for k, v in annotations {
    manifest = manifest.set_annotation(k, v)
  }

  // Keep proof obligations attached to pack-layer accounting.
  ignore(
    expected_pack_layer_count(plugins.length(), procsi_bytes, config_bytes),
  )

  {
    manifest,
    void_layer: void_bytes,
    tree_layer: tree_bytes,
    bloom_layer: bloom_bytes,
    plugin_layers: plugins,
    procsi_layer: procsi_bytes,
    config_layer: config_bytes,
  }
}

///|
/// Digest of the container manifest (used as the container's content address).
pub fn CognitiveContainer::digest(self : CognitiveContainer) -> @hash.Hash {
  // Hash the concatenation of all layer digests to produce a stable container ID
  let material : Array[Byte] = []
  for b in container_magic {
    material.push(b)
  }
  container_write_u32_le(material, self.manifest.schema_version)
  container_write_u32_le(material, self.manifest.layers.length())
  for layer in self.manifest.layers {
    let key = layer.digest.key()
    for ch in key {
      material.push(ch.to_int().to_byte())
    }
    container_write_u32_le(material, layer.size)
  }
  @hash.Hash::of_bytes(container_bytes_to_fixed(material))
}

///|
/// Total size of all layers in bytes.
pub fn CognitiveContainer::total_size(self : CognitiveContainer) -> Int {
  self.manifest.total_size
}

///|
/// Number of plugin layers.
pub fn CognitiveContainer::plugin_count(self : CognitiveContainer) -> Int {
  self.plugin_layers.length()
}

///|
/// Push all layers to an OCI registry, returning the manifest digest.
pub fn CognitiveContainer::push_to_oci(
  self : CognitiveContainer,
  registry : InMemoryOciRegistry,
  repository : String,
  tag : String,
) -> @hash.Hash {
  // Push core layers as blobs
  ignore(registry.put_blob(repository, self.void_layer))
  ignore(registry.put_blob(repository, self.tree_layer))
  ignore(registry.put_blob(repository, self.bloom_layer))

  // Push plugin wasm layers
  for plugin in self.plugin_layers {
    ignore(registry.put_blob(repository, plugin.wasm_bytes))
  }

  // Push procsi and config
  if self.procsi_layer.length() > 0 {
    ignore(registry.put_blob(repository, self.procsi_layer))
  }
  if self.config_layer.length() > 0 {
    ignore(registry.put_blob(repository, self.config_layer))
  }

  // Push manifest reference (the digest itself acts as the manifest)
  let container_digest = self.digest()
  let manifest_key = container_digest.key()

  // Store the manifest digest as a tag
  registry.put_tag(repository, tag, manifest_key)

  container_digest
}

// ---------------------------------------------------------------------------
// Serialization — binary wire format for the container manifest
// ---------------------------------------------------------------------------

///|
/// Serialize the container manifest to bytes.
/// Format:
///   [4]  magic "COGN"
///   [4]  version u32 LE
///   [4]  layer_count u32 LE
///   per layer:
///     [4]  media_type_len u32 LE
///     [*]  media_type utf8
///     [4]  name_len u32 LE
///     [*]  name utf8
///     [4]  digest_key_len u32 LE
///     [*]  digest_key ascii
///     [4]  size u32 LE
///   [4]  annotation_count u32 LE
///   per annotation:
///     [4]  key_len u32 LE
///     [*]  key utf8
///     [4]  val_len u32 LE
///     [*]  val utf8
pub fn ContainerManifest::to_bytes(self : ContainerManifest) -> Array[Byte] {
  let buf : Array[Byte] = []

  // Magic + version
  for b in container_magic {
    buf.push(b)
  }
  container_write_u32_le(buf, self.schema_version)

  // Layers
  container_write_u32_le(buf, self.layers.length())
  for layer in self.layers {
    container_write_utf8_field(buf, layer.media_type)
    container_write_utf8_field(buf, layer.name)
    container_write_utf8_field(buf, layer.digest.key())
    container_write_u32_le(buf, layer.size)
  }

  // Annotations
  let ann_keys : Array[String] = []
  for k, _v in self.annotations {
    ann_keys.push(k)
  }
  container_write_u32_le(buf, ann_keys.length())
  for k in ann_keys {
    container_write_utf8_field(buf, k)
    match self.annotations.get(k) {
      Some(v) => container_write_utf8_field(buf, v)
      None => container_write_utf8_field(buf, "")
    }
  }

  buf
}

///|
/// Deserialize a container manifest from bytes.
pub fn ContainerManifest::from_bytes(data : Array[Byte]) -> ContainerManifest? {
  let len = data.length()
  if len < 12 {
    return None
  }

  // Verify magic
  if data[0] != container_magic[0] ||
    data[1] != container_magic[1] ||
    data[2] != container_magic[2] ||
    data[3] != container_magic[3] {
    return None
  }

  let mut pos = 4
  let _version = container_read_u32_le(data, pos)
  pos = pos + 4

  // Layers
  if pos + 4 > len {
    return None
  }
  let layer_count = container_read_u32_le(data, pos)
  pos = pos + 4

  let layers : Array[LayerDescriptor] = []
  let mut total = 0
  let mut i = 0
  while i < layer_count {
    match container_read_utf8_field(data, pos, len) {
      Some((media_type, p1)) => {
        pos = p1
        match container_read_utf8_field(data, pos, len) {
          Some((name, p2)) => {
            pos = p2
            match container_read_utf8_field(data, pos, len) {
              Some((digest_key, p3)) => {
                pos = p3
                if pos + 4 > len {
                  return None
                }
                let size = container_read_u32_le(data, pos)
                pos = pos + 4
                let digest = @hash.Hash::of_bytes(
                  container_string_to_bytes(digest_key),
                )
                layers.push({ media_type, digest, size, name })
                total = total + size
              }
              None => return None
            }
          }
          None => return None
        }
      }
      None => return None
    }
    i = i + 1
  }

  // Annotations
  if pos + 4 > len {
    return None
  }
  let ann_count = container_read_u32_le(data, pos)
  pos = pos + 4

  let annotations : Map[String, String] = {}
  i = 0
  while i < ann_count {
    match container_read_utf8_field(data, pos, len) {
      Some((k, p1)) => {
        pos = p1
        match container_read_utf8_field(data, pos, len) {
          Some((v, p2)) => {
            pos = p2
            annotations[k] = v
          }
          None => return None
        }
      }
      None => return None
    }
    i = i + 1
  }

  Some({
    schema_version: container_version,
    layers,
    annotations,
    total_size: total,
  })
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

///|
fn container_write_u32_le(buf : Array[Byte], v : Int) -> Unit {
  buf.push((v & 0xFF).to_byte())
  buf.push(((v >> 8) & 0xFF).to_byte())
  buf.push(((v >> 16) & 0xFF).to_byte())
  buf.push(((v >> 24) & 0xFF).to_byte())
}

///|
fn container_read_u32_le(data : Array[Byte], pos : Int) -> Int {
  (data[pos].to_int() & 0xFF) |
  ((data[pos + 1].to_int() & 0xFF) << 8) |
  ((data[pos + 2].to_int() & 0xFF) << 16) |
  ((data[pos + 3].to_int() & 0xFF) << 24)
}

///|
fn container_write_utf8_field(buf : Array[Byte], s : String) -> Unit {
  let encoded : Array[Byte] = []
  for ch in s {
    let cp = ch.to_int()
    if cp < 0x80 {
      encoded.push(cp.to_byte())
    } else if cp < 0x800 {
      encoded.push((0xC0 | (cp >> 6)).to_byte())
      encoded.push((0x80 | (cp & 0x3F)).to_byte())
    } else {
      encoded.push((0xE0 | (cp >> 12)).to_byte())
      encoded.push((0x80 | ((cp >> 6) & 0x3F)).to_byte())
      encoded.push((0x80 | (cp & 0x3F)).to_byte())
    }
  }
  container_write_u32_le(buf, encoded.length())
  for b in encoded {
    buf.push(b)
  }
}

///|
fn container_read_utf8_field(
  data : Array[Byte],
  pos : Int,
  len : Int,
) -> (String, Int)? {
  if pos + 4 > len {
    return None
  }
  let n = container_read_u32_le(data, pos)
  let start = pos + 4
  if start + n > len {
    return None
  }
  let sb = StringBuilder::new()
  let mut i = start
  let end = start + n
  while i < end {
    let b0 = data[i].to_int()
    if (b0 & 0x80) == 0 {
      sb.write_char(b0.to_char().unwrap())
      i = i + 1
    } else if (b0 & 0xE0) == 0xC0 && i + 1 < end {
      let b1 = data[i + 1].to_int()
      let cp = ((b0 & 0x1F) << 6) | (b1 & 0x3F)
      sb.write_char(cp.to_char().unwrap())
      i = i + 2
    } else if (b0 & 0xF0) == 0xE0 && i + 2 < end {
      let b1 = data[i + 1].to_int()
      let b2 = data[i + 2].to_int()
      let cp = ((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F)
      sb.write_char(cp.to_char().unwrap())
      i = i + 3
    } else {
      sb.write_char('\u{FFFD}')
      i = i + 1
    }
  }
  Some((sb.to_string(), end))
}

///|
fn container_string_to_bytes(s : String) -> Bytes {
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

///|
fn container_bytes_to_fixed(src : Array[Byte]) -> Bytes {
  let buf = FixedArray::make(src.length(), b'\x00')
  let mut i = 0
  while i < src.length() {
    buf[i] = src[i]
    i = i + 1
  }
  Bytes::from_array(buf)
}

///|
fn merge_layer_key(layer : LayerDescriptor) -> String {
  layer.media_type + "|" + layer.name
}

///|
/// Proof helper for packfile layer accounting:
/// optional procsi/config contributions are always in [0, 2].
fn optional_pack_layer_count(
  procsi_layer : Bytes,
  config_layer : Bytes,
) -> Int where {
  proof_ensure: result => result >= 0,
  proof_ensure: result => result <= 2,
} {
  let mut count = 0
  if procsi_layer.length() > 0 {
    count = count + 1
  }
  if config_layer.length() > 0 {
    count = count + 1
  }
  count
}

///|
/// Proof helper for packfile layer accounting:
/// total pack layers are always at least the 3 core layers + plugin count.
fn expected_pack_layer_count(
  plugin_count : Int,
  procsi_layer : Bytes,
  config_layer : Bytes,
) -> Int where {
  proof_require: plugin_count >= 0,
  proof_ensure: result => result >= 3 + plugin_count,
  proof_ensure: result => result <= 5 + plugin_count,
} {
  3 + plugin_count + optional_pack_layer_count(procsi_layer, config_layer)
}
