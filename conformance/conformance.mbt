///|
/// Lightweight linker for conformance package dependencies.
/// Keeps package imports explicit even when most logic lives in test files.
pub fn core_packages_linked() -> Bool {
  ignore(@hash.Hash::of_bytes(b"\x00"))
  let _fresh : @model.Freshness = @model.Freshness::FRESH
  ignore(_fresh)
  ignore(@store.ArtifactStore::new())
  ignore(@tree.MerkinTree::new())
  ignore(@bloom.BloomSketch::new())
  ignore(@gaussian.GaussianField::new())
  ignore(@bench.Bench::new())
  true
}
