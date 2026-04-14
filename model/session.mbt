///|
/// SessionIdentity: the identity of an agent session.
/// Format: <tier>/<short-id> (e.g., "sonnet/a7f3c")
///
/// Sources (in priority order):
///   1. MERKIN_SESSION env var (fully formed "sonnet/a7f3c")
///   2. MERKIN_TIER env var + generated short-id
///   3. Default: "unknown/00000"
pub(all) struct SessionIdentity {
  /// Model tier: "haiku", "sonnet", "opus".
  tier : String
  /// Short session id, stable within a session, not reused.
  short_id : String
  /// Current locus name, if entered.
  locus : String?
} derive(Debug)

///|
/// Create a session identity.
pub fn SessionIdentity::new(tier : String, short_id : String) -> SessionIdentity {
  { tier, short_id, locus: None }
}

///|
/// Create with locus context.
pub fn SessionIdentity::with_locus(
  tier : String,
  short_id : String,
  locus : String,
) -> SessionIdentity {
  { tier, short_id, locus: Some(locus) }
}

///|
/// Canonical display: "sonnet/a7f3c".
pub fn SessionIdentity::display(self : SessionIdentity) -> String {
  self.tier + "/" + self.short_id
}

///|
/// Set the active locus.
pub fn SessionIdentity::enter_locus(
  self : SessionIdentity,
  locus : String,
) -> SessionIdentity {
  { ..self, locus: Some(locus) }
}

///|
/// Valid tier values.
pub fn valid_tiers() -> Array[String] {
  ["haiku", "sonnet", "opus"]
}

///|
/// Check if a tier string is valid.
pub fn is_valid_tier(tier : String) -> Bool {
  for t in valid_tiers() {
    if t == tier {
      return true
    }
  }
  false
}

///|
/// Generate a short id from arbitrary bytes (first 5 hex chars).
pub fn short_id_from_bytes(bytes : Bytes) -> String {
  let h = @hash.Hash::of_bytes(bytes)
  let key = h.key()
  // Take first 5 characters from the hex key
  let b = StringBuilder::new(size_hint=5)
  let mut count = 0
  for ch in key {
    if count >= 5 {
      break
    }
    b.write_char(ch)
    count = count + 1
  }
  b.to_string()
}
