///|
/// Convert a hash to a string key for map storage.
fn hash_key(h : @hash.Hash) -> String {
  h.key()
}

///|
/// ArtifactStore: in-memory content-addressed artifact storage (§8.1).
pub(all) struct ArtifactStore {
  items : Map[String, @model.Artifact]
}

///|
/// Create a new empty ArtifactStore.
pub fn ArtifactStore::new() -> ArtifactStore {
  { items: {} }
}

///|
/// Put an artifact into the store. Returns the content hash key.
pub fn ArtifactStore::put(
  self : ArtifactStore,
  artifact : @model.Artifact,
) -> String {
  let key = hash_key(artifact.content_hash)
  self.items[key] = artifact
  key
}

///|
/// Get an artifact by its content hash.
pub fn ArtifactStore::get(
  self : ArtifactStore,
  hash : @hash.Hash,
) -> @model.Artifact? {
  let key = hash_key(hash)
  self.items.get(key)
}

///|
/// EnvelopeStore: in-memory envelope storage (§8.1).
pub(all) struct EnvelopeStore {
  items : Map[String, @model.Envelope]
}

///|
/// Create a new empty EnvelopeStore.
pub fn EnvelopeStore::new() -> EnvelopeStore {
  { items: {} }
}

///|
/// Put an envelope. Returns the envelope_id key.
pub fn EnvelopeStore::put(
  self : EnvelopeStore,
  envelope : @model.Envelope,
) -> String {
  let key = hash_key(envelope.envelope_id)
  self.items[key] = envelope
  key
}

///|
/// Get an envelope by its id.
pub fn EnvelopeStore::get(
  self : EnvelopeStore,
  hash : @hash.Hash,
) -> @model.Envelope? {
  let key = hash_key(hash)
  self.items.get(key)
}

///|
/// AnchorStore: in-memory anchor storage (§8.1).
pub(all) struct AnchorStore {
  items : Map[String, @model.Anchor]
}

///|
/// Create a new empty AnchorStore.
pub fn AnchorStore::new() -> AnchorStore {
  { items: {} }
}

///|
/// Put an anchor. Returns the anchor_id key.
pub fn AnchorStore::put(self : AnchorStore, anchor : @model.Anchor) -> String {
  let key = hash_key(anchor.anchor_id)
  self.items[key] = anchor
  key
}

///|
/// Get an anchor by its id.
pub fn AnchorStore::get(
  self : AnchorStore,
  hash : @hash.Hash,
) -> @model.Anchor? {
  let key = hash_key(hash)
  self.items.get(key)
}
