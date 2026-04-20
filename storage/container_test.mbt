///|
fn array_to_bytes(src : Array[Byte]) -> Bytes {
  let buf = FixedArray::make(src.length(), b'\x00')
  let mut i = 0
  while i < src.length() {
    buf[i] = src[i]
    i = i + 1
  }
  Bytes::from_array(buf)
}

///|
fn bytes_to_array(src : Bytes) -> Array[Byte] {
  let out : Array[Byte] = []
  let mut i = 0
  while i < src.length() {
    out.push(src[i])
    i = i + 1
  }
  out
}

///|
fn find_layer_by_name(
  manifest : @storage.ContainerManifest,
  name : String,
) -> @storage.LayerDescriptor? {
  for layer in manifest.layers {
    if layer.name == name {
      return Some(layer)
    }
  }
  None
}

///|
fn find_layer_by_media_and_name(
  manifest : @storage.ContainerManifest,
  media_type : String,
  name : String,
) -> @storage.LayerDescriptor? {
  for layer in manifest.layers {
    if layer.media_type == media_type && layer.name == name {
      return Some(layer)
    }
  }
  None
}

///|
test "CognitiveContainer export pushes pack blobs including plugins" {
  let annotations : Map[String, String] = {}
  annotations["finger.plan"] = "ready"
  annotations["origin"] = "pack-a"

  let plugin_a = @storage.PluginLayer::new("plugin-a", b"\x00asm-plugin-a")
  let plugin_b = @storage.PluginLayer::new("plugin-b", b"\x00asm-plugin-b")
  let container = @storage.CognitiveContainer::pack(
    b"void-snapshot",
    b"tree-snapshot",
    b"bloom-snapshot",
    [plugin_a, plugin_b],
    b"node-pr1",
    b"node-config",
    annotations,
  )

  assert_eq(container.plugin_count(), 2)
  assert_eq(container.manifest.layer_count(), 7)

  let reg = @storage.InMemoryOciRegistry::new()
  let digest = container.push_to_oci(reg, "repo/pack-a", "latest")
  assert_eq(digest.key(), container.digest().key())

  match reg.resolve_tag("repo/pack-a", "latest") {
    Some(value) => assert_eq(value, digest.key())
    None => assert_true(false)
  }

  assert_true(
    reg.has_blob("repo/pack-a", @hash.Hash::of_bytes(b"void-snapshot").key()),
  )
  assert_true(
    reg.has_blob("repo/pack-a", @hash.Hash::of_bytes(b"tree-snapshot").key()),
  )
  assert_true(
    reg.has_blob("repo/pack-a", @hash.Hash::of_bytes(b"bloom-snapshot").key()),
  )
  assert_true(
    reg.has_blob("repo/pack-a", @hash.Hash::of_bytes(b"\x00asm-plugin-a").key()),
  )
  assert_true(
    reg.has_blob("repo/pack-a", @hash.Hash::of_bytes(b"\x00asm-plugin-b").key()),
  )
  assert_true(
    reg.has_blob("repo/pack-a", @hash.Hash::of_bytes(b"node-pr1").key()),
  )
  assert_true(
    reg.has_blob("repo/pack-a", @hash.Hash::of_bytes(b"node-config").key()),
  )
}

///|
test "Packfile manifest export/import roundtrip via OCI manifest transport" {
  let annotations : Map[String, String] = {}
  annotations["finger.plan"] = "stable"
  annotations["importable"] = "true"

  let container = @storage.CognitiveContainer::pack(
    b"void-v1",
    b"tree-v1",
    b"bloom-v1",
    [@storage.PluginLayer::new("plugin-0", b"\x00asm-plugin-0")],
    b"pr1-v1",
    b"cfg-v1",
    annotations,
  )

  let reg = @storage.InMemoryOciRegistry::new()
  let offloaded_manifest = container.manifest.mark_sat_smt_offloaded(
    "mu.local.z3",
  )
  let manifest_bytes = array_to_bytes(offloaded_manifest.to_bytes())
  let digest = reg.put_manifest("repo/pack-b", "pack-1", manifest_bytes)

  match reg.resolve_tag("repo/pack-b", "pack-1") {
    Some(value) => assert_eq(value, digest)
    None => assert_true(false)
  }

  match reg.get_manifest("repo/pack-b", "pack-1") {
    Some(raw) =>
      match @storage.ContainerManifest::from_bytes(bytes_to_array(raw)) {
        Some(parsed) => {
          assert_eq(parsed.layer_count(), offloaded_manifest.layer_count())
          assert_eq(parsed.total_size, offloaded_manifest.total_size)
          match parsed.annotations.get("finger.plan") {
            Some(value) => assert_eq(value, "stable")
            None => assert_true(false)
          }
          match parsed.annotations.get("importable") {
            Some(value) => assert_eq(value, "true")
            None => assert_true(false)
          }
          match parsed.annotations.get("solve_kind") {
            Some(value) => assert_eq(value, "smt")
            None => assert_true(false)
          }
          match parsed.annotations.get("sat_smt_offloaded") {
            Some(value) => assert_eq(value, "true")
            None => assert_true(false)
          }
          match parsed.annotations.get("solve_report_offloaded_to") {
            Some(value) => assert_eq(value, "mu.local.z3")
            None => assert_true(false)
          }
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }

  match reg.get_manifest_by_digest("repo/pack-b", digest) {
    Some(_raw) => assert_true(true)
    None => assert_true(false)
  }
}

///|
test "ContainerManifest merge replaces keyed layers and overlays annotations" {
  let layer_void_v1 = @storage.LayerDescriptor::new(
    "application/vnd.merkin.void.v1", b"void-v1", "void",
  )
  let layer_tree_v1 = @storage.LayerDescriptor::new(
    "application/vnd.merkin.tree.v1", b"tree-v1", "tree",
  )
  let layer_void_v2 = @storage.LayerDescriptor::new(
    "application/vnd.merkin.void.v1", b"void-v2", "void",
  )
  let layer_bloom_v1 = @storage.LayerDescriptor::new(
    "application/vnd.merkin.bloom.v1", b"bloom-v1", "bloom",
  )

  let left0 = @storage.ContainerManifest::new()
  let left1 = left0.add_layer(layer_void_v1)
  let left2 = left1.add_layer(layer_tree_v1)
  let left3 = left2.set_annotation("origin", "left")
  let left = left3.set_annotation("shared", "left")

  let right0 = @storage.ContainerManifest::new()
  let right1 = right0.add_layer(layer_void_v2)
  let right2 = right1.add_layer(layer_bloom_v1)
  let right3 = right2.set_annotation("shared", "right")
  let right = right3.set_annotation("imported", "true")

  let merged = left.merge(right)
  assert_eq(merged.layer_count(), 3)
  assert_eq(
    merged.total_size,
    layer_void_v2.size + layer_tree_v1.size + layer_bloom_v1.size,
  )

  match find_layer_by_name(merged, "void") {
    Some(layer) => assert_eq(layer.digest.key(), layer_void_v2.digest.key())
    None => assert_true(false)
  }
  match find_layer_by_name(merged, "tree") {
    Some(layer) => assert_eq(layer.digest.key(), layer_tree_v1.digest.key())
    None => assert_true(false)
  }
  match find_layer_by_name(merged, "bloom") {
    Some(layer) => assert_eq(layer.digest.key(), layer_bloom_v1.digest.key())
    None => assert_true(false)
  }

  match merged.annotations.get("origin") {
    Some(value) => assert_eq(value, "left")
    None => assert_true(false)
  }
  match merged.annotations.get("shared") {
    Some(value) => assert_eq(value, "right")
    None => assert_true(false)
  }
  match merged.annotations.get("imported") {
    Some(value) => assert_eq(value, "true")
    None => assert_true(false)
  }
}

///|
test "ContainerManifest merge keeps same names when media types differ" {
  let void_shared = @storage.LayerDescriptor::new(
    "application/vnd.merkin.void.v1", b"void-shared-v1", "shared",
  )
  let tree_shared = @storage.LayerDescriptor::new(
    "application/vnd.merkin.tree.v1", b"tree-shared-v1", "shared",
  )
  let bloom_unique = @storage.LayerDescriptor::new(
    "application/vnd.merkin.bloom.v1", b"bloom-only-v1", "bloom",
  )

  let left = @storage.ContainerManifest::new().add_layer(void_shared)
  let right = @storage.ContainerManifest::new()
    .add_layer(tree_shared)
    .add_layer(bloom_unique)

  let merged = left.merge(right)
  assert_eq(merged.layer_count(), 3)
  assert_eq(
    merged.total_size,
    void_shared.size + tree_shared.size + bloom_unique.size,
  )

  match
    find_layer_by_media_and_name(
      merged, "application/vnd.merkin.void.v1", "shared",
    ) {
    Some(layer) => assert_eq(layer.digest.key(), void_shared.digest.key())
    None => assert_true(false)
  }
  match
    find_layer_by_media_and_name(
      merged, "application/vnd.merkin.tree.v1", "shared",
    ) {
    Some(layer) => assert_eq(layer.digest.key(), tree_shared.digest.key())
    None => assert_true(false)
  }
  match
    find_layer_by_media_and_name(
      merged, "application/vnd.merkin.bloom.v1", "bloom",
    ) {
    Some(layer) => assert_eq(layer.digest.key(), bloom_unique.digest.key())
    None => assert_true(false)
  }
}

///|
test "Packfile manifest import rejects invalid magic and truncation" {
  let manifest = @storage.ContainerManifest::new()
    .add_layer(
      @storage.LayerDescriptor::new(
        "application/vnd.merkin.void.v1", b"void-snapshot-vx", "void",
      ),
    )
    .set_annotation("finger.plan", "wire-check")
  let encoded = manifest.to_bytes()

  let bad_magic : Array[Byte] = []
  for b in encoded {
    bad_magic.push(b)
  }
  bad_magic[0] = b'\x00'

  match @storage.ContainerManifest::from_bytes(bad_magic) {
    Some(_) => assert_true(false)
    None => assert_true(true)
  }

  let truncated : Array[Byte] = []
  let mut i = 0
  while i < encoded.length() - 1 {
    truncated.push(encoded[i])
    i = i + 1
  }

  match @storage.ContainerManifest::from_bytes(truncated) {
    Some(_) => assert_true(false)
    None => assert_true(true)
  }
}

///|
test "ContainerManifest mark_sat_smt_offloaded sets solve metadata" {
  let manifest = @storage.ContainerManifest::new()
    .set_annotation("finger.plan", "solver")
    .mark_sat_smt_offloaded("delegate-control")

  match manifest.annotations.get("solve_kind") {
    Some(value) => assert_eq(value, "smt")
    None => assert_true(false)
  }
  match manifest.annotations.get("sat_smt_offloaded") {
    Some(value) => assert_eq(value, "true")
    None => assert_true(false)
  }
  match manifest.annotations.get("solve_report_offloaded_to") {
    Some(value) => assert_eq(value, "delegate-control")
    None => assert_true(false)
  }
}
