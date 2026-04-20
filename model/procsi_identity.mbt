///|
/// AI substrate fingerprint v2.
/// This is the AI-facing identity material that should generally be
/// carried behind an APP mask rather than exposed directly to humans.
pub(all) struct AiSubstrateFingerprintV2 {
  fingerprint_id : @hash.Hash
  family : String
  surface : String
  overlay : String
  mode : String
  context_hash : @hash.Hash
  policy_hash : @hash.Hash?
  capability_hash : @hash.Hash
  substrate_hash : @hash.Hash
  issuer : String
} derive(Show)

///|
/// APP-protected presentation of an AI substrate fingerprint.
/// Human-facing carriers should prefer this masked form.
pub(all) struct AppMaskEnvelope {
  protocol : String
  audience : String
  ciphertext_ref : String
  ciphertext_hash : @hash.Hash
  masked_commitment : @hash.Hash
} derive(Show)

///|
/// Concrete APP envelope record stored in a registry or repository-local store.
/// The ciphertext payload is intentionally opaque at this layer.
pub(all) struct AppEnvelopeRecord {
  ref_id : String
  protocol : String
  audience : String
  ciphertext_hash : @hash.Hash
  ciphertext : Bytes
} derive(Show)

///|
/// Procsi attestation used by Genius Loci entrypoints.
/// It carries a stable commitment plus the APP-masked envelope ref.
pub(all) struct GeniusProcsiAttestation {
  locus : String?
  project : String
  ratio_loci : String
  session_surface : String
  fingerprint_commitment : @hash.Hash
  app_envelope : AppMaskEnvelope
} derive(Show)

///|
pub fn AiSubstrateFingerprintV2::new(
  family : String,
  surface : String,
  overlay : String,
  mode : String,
  context_hash : @hash.Hash,
  capability_hash : @hash.Hash,
  substrate_hash : @hash.Hash,
  issuer : String,
) -> AiSubstrateFingerprintV2 {
  let fingerprint_id = compute_fingerprint_id(
    family,
    surface,
    overlay,
    mode,
    context_hash,
    None,
    capability_hash,
    substrate_hash,
    issuer,
  )
  {
    fingerprint_id,
    family,
    surface,
    overlay,
    mode,
    context_hash,
    policy_hash: None,
    capability_hash,
    substrate_hash,
    issuer,
  }
}

///|
pub fn AiSubstrateFingerprintV2::with_policy_hash(
  self : AiSubstrateFingerprintV2,
  policy_hash : @hash.Hash,
) -> AiSubstrateFingerprintV2 {
  let fingerprint_id = compute_fingerprint_id(
    self.family,
    self.surface,
    self.overlay,
    self.mode,
    self.context_hash,
    Some(policy_hash),
    self.capability_hash,
    self.substrate_hash,
    self.issuer,
  )
  { ..self, fingerprint_id, policy_hash: Some(policy_hash) }
}

///|
/// Stable commitment used for public or APP-carried references.
pub fn AiSubstrateFingerprintV2::commitment(
  self : AiSubstrateFingerprintV2,
) -> @hash.Hash {
  @hash.Hash::of_bytes(
    procsi_string_to_bytes("fingerprint-v2|" + self.fingerprint_id.key()),
  )
}

///|
pub fn AiSubstrateFingerprintV2::mask_with_app(
  self : AiSubstrateFingerprintV2,
  protocol : String,
  audience : String,
  ciphertext_ref : String,
  ciphertext_hash : @hash.Hash,
) -> AppMaskEnvelope {
  AppMaskEnvelope::new(
    self.commitment(),
    protocol,
    audience,
    ciphertext_ref,
    ciphertext_hash,
  )
}

///|
pub fn AppMaskEnvelope::new(
  fingerprint_commitment : @hash.Hash,
  protocol : String,
  audience : String,
  ciphertext_ref : String,
  ciphertext_hash : @hash.Hash,
) -> AppMaskEnvelope {
  let material = "app-mask|" +
    fingerprint_commitment.key() +
    "|" +
    protocol +
    "|" +
    audience +
    "|" +
    ciphertext_ref +
    "|" +
    ciphertext_hash.key()
  {
    protocol,
    audience,
    ciphertext_ref,
    ciphertext_hash,
    masked_commitment: @hash.Hash::of_bytes(procsi_string_to_bytes(material)),
  }
}

///|
pub fn AppEnvelopeRecord::new(
  ref_id : String,
  protocol : String,
  audience : String,
  ciphertext : Bytes,
) -> AppEnvelopeRecord {
  {
    ref_id,
    protocol,
    audience,
    ciphertext_hash: @hash.Hash::of_bytes(ciphertext),
    ciphertext,
  }
}

///|
pub fn AppEnvelopeRecord::to_mask_envelope(
  self : AppEnvelopeRecord,
  fingerprint_commitment : @hash.Hash,
) -> AppMaskEnvelope {
  AppMaskEnvelope::new(
    fingerprint_commitment,
    self.protocol,
    self.audience,
    self.ref_id,
    self.ciphertext_hash,
  )
}

///|
pub fn GeniusProcsiAttestation::new(
  locus : String?,
  project : String,
  ratio_loci : String,
  session_surface : String,
  fingerprint_commitment : @hash.Hash,
  app_envelope : AppMaskEnvelope,
) -> GeniusProcsiAttestation {
  {
    locus,
    project,
    ratio_loci,
    session_surface,
    fingerprint_commitment,
    app_envelope,
  }
}

///|
pub fn GeniusProcsiAttestation::from_masked_refs(
  locus : String?,
  project : String,
  ratio_loci : String,
  session_surface : String,
  fingerprint_commitment : @hash.Hash,
  protocol : String,
  audience : String,
  ciphertext_ref : String,
  ciphertext_hash : @hash.Hash,
) -> GeniusProcsiAttestation {
  let app_envelope = AppMaskEnvelope::new(
    fingerprint_commitment, protocol, audience, ciphertext_ref, ciphertext_hash,
  )
  {
    locus,
    project,
    ratio_loci,
    session_surface,
    fingerprint_commitment,
    app_envelope,
  }
}

///|
fn compute_fingerprint_id(
  family : String,
  surface : String,
  overlay : String,
  mode : String,
  context_hash : @hash.Hash,
  policy_hash : @hash.Hash?,
  capability_hash : @hash.Hash,
  substrate_hash : @hash.Hash,
  issuer : String,
) -> @hash.Hash {
  let policy_token = match policy_hash {
    Some(hash) => hash.key()
    None => "none"
  }
  let material = "fingerprint-v2|" +
    family +
    "|" +
    surface +
    "|" +
    overlay +
    "|" +
    mode +
    "|" +
    context_hash.key() +
    "|" +
    policy_token +
    "|" +
    capability_hash.key() +
    "|" +
    substrate_hash.key() +
    "|" +
    issuer
  @hash.Hash::of_bytes(procsi_string_to_bytes(material))
}

///|
fn procsi_string_to_bytes(s : String) -> Bytes {
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
