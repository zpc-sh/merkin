///|
test "Bench: hash throughput (1KiB payload)" (b : @bench.T) {
  let payload = Bytes::make(1024, b'\xAB')
  b.bench(
    () => b.keep(@hash.Hash::of_bytes(payload)),
    name="hash.of_bytes.1k",
    count=15,
  )
}

///|
test "Bench: tree ingest throughput" (b : @bench.T) {
  let ids : Array[@hash.Hash] = []
  for i = 0; i < 512; i = i + 1 {
    let bytes = FixedArray::make(2, b'\x00')
    bytes[0] = ((i >> 8) & 0xFF).to_byte()
    bytes[1] = (i & 0xFF).to_byte()
    ids.push(@hash.Hash::of_bytes(Bytes::from_array(bytes)))
  }

  let tree = @tree.MerkinTree::new()
  let mut cursor = 0
  b.bench(
    () => {
      let id = ids[cursor]
      ignore(tree.ingest(id, ["doc", "image", "route"]))
      cursor = (cursor + 1) % ids.length()
    },
    name="tree.ingest.flat",
    count=10,
  )
}

///|
test "Bench: epoch seal (128 ingests)" (b : @bench.T) {
  let ids : Array[@hash.Hash] = []
  for i = 0; i < 128; i = i + 1 {
    let bytes = FixedArray::make(2, b'\x00')
    bytes[0] = ((i >> 8) & 0xFF).to_byte()
    bytes[1] = (i & 0xFF).to_byte()
    ids.push(@hash.Hash::of_bytes(Bytes::from_array(bytes)))
  }

  b.bench(
    () => {
      let tree = @tree.MerkinTree::new()
      for id in ids {
        ignore(tree.ingest(id, ["doc", "seal"]))
      }
      b.keep(tree.seal())
    },
    name="tree.seal.128",
    count=8,
  )
}

///|
test "Bench: artifact store put+get" (b : @bench.T) {
  let store = @store.ArtifactStore::new()
  let artifact = @model.Artifact::from_bytes(Bytes::make(2048, b'\x5A'))
  b.bench(
    () => {
      ignore(store.put(artifact))
      b.keep(store.get(artifact.content_hash))
    },
    name="store.artifact.put_get",
    count=10,
  )
}
