///|
test "Artifact from_bytes and verify" {
  let data = b"\x01\x02\x03\x04"
  let art = @model.Artifact::from_bytes(data)
  assert_true(art.verify())
  assert_eq(art.size_bytes, 4UL)
}

///|
test "Artifact with mime" {
  let art = @model.Artifact::from_bytes_with_mime(
    b"\xFF", "application/octet-stream",
  )
  assert_true(art.mime is Some(_))
}

///|
test "Envelope header encoding arbyte_grin" {
  let hash = @hash.Hash::of_bytes(b"\x01")
  let header = ["a", "b", "c", "d", "e", "f", "g", "h"] // len=8
  let env = @model.Envelope::new(hash, header)
  assert_eq(env.header_encoding, @model.ArbyteGrin)
}

///|
test "Envelope header encoding chain_coda" {
  let hash = @hash.Hash::of_bytes(b"\x01")
  let header = ["a", "b", "c"] // len=3, not 8
  let env = @model.Envelope::new(hash, header)
  assert_eq(env.header_encoding, @model.ChainCoda)
}

///|
test "Envelope commit semantic hash" {
  let hash = @hash.Hash::of_bytes(b"\x01")
  let env = @model.Envelope::new(hash, ["x", "y"])
  assert_true(env.semantic_hash is None)
  let env2 = env.commit_semantic()
  assert_true(env2.semantic_hash is Some(_))
  assert_true(env2.state.semantic_committed)
}

///|
test "Envelope seal" {
  let hash = @hash.Hash::of_bytes(b"\x01")
  let env = @model.Envelope::new(hash, ["x"])
  let s = env.seal()
  assert_true(s.is_sealed())
}

///|
test "Envelope sealed immutability for semantic commit" {
  let hash = @hash.Hash::of_bytes(b"\x01")
  let env = @model.Envelope::new(hash, ["x"]).seal()
  let after = env.commit_semantic()
  assert_true(after.semantic_hash is None)
  assert_eq(after.state.freshness, @model.SEALED)
}

///|
test "Envelope subject_hash fallback" {
  let hash = @hash.Hash::of_bytes(b"\x01")
  let env = @model.Envelope::new(hash, ["x"])
  // No semantic hash => falls back to artifact_hash
  assert_eq(env.subject_hash(), env.artifact_hash)
  // With semantic hash => uses semantic
  let env2 = env.commit_semantic()
  match env2.semantic_hash {
    Some(sh) => assert_eq(env2.subject_hash(), sh)
    None => ()
  }
}

///|
test "Anchor state transitions" {
  let hash = @hash.Hash::of_bytes(b"\x01")
  let a = @model.Anchor::new(hash)
  assert_eq(a.anchor_state, @model.UNANCHORED)
  let a2 = a.mark_pending()
  assert_eq(a2.anchor_state, @model.PENDING)
  let root = @hash.Hash::of_bytes(b"\xFF")
  let a3 = a2.mark_anchored(42UL, root)
  assert_eq(a3.anchor_state, @model.ANCHORED)
}

///|
test "Anchor optional refs and replication vector" {
  let hash = @hash.Hash::of_bytes(b"\xAB")
  let a = @model.Anchor::new(hash)
    .set_mmr_proof_ref("proof://mmr/123")
    .set_temporash_ref("tempora://ref/456")
    .add_replica("replica-a")
  assert_true(a.mmr_proof_ref is Some(_))
  assert_true(a.temporash_ref is Some(_))
  assert_eq(a.replication_vector.length(), 1)
}

///|
test "Anchor set_time" {
  let hash = @hash.Hash::of_bytes(b"\xCC")
  let a = @model.Anchor::new(hash)
  assert_true(a.anchored_at is None)
  let a2 = a.set_time("2023-10-27T10:00:00Z")
  assert_eq(a2.anchored_at, Some("2023-10-27T10:00:00Z"))
}

///|
test "WorkPromise lifecycle" {
  let ih = @hash.Hash::of_bytes(b"\x01")
  let th = @hash.Hash::of_bytes(b"\x02")
  let ph = @hash.Hash::of_bytes(b"\x03")
  let wp = @model.WorkPromise::new(ih, th, ph)
  assert_eq(wp.state, @model.ABSENT)
  let wp2 = wp.promise()
  assert_eq(wp2.state, @model.PROMISED)
  let wp3 = wp2.start()
  assert_eq(wp3.state, @model.RUNNING)
}

///|
test "WorkPromise id includes policy id" {
  let input = @hash.Hash::of_bytes(b"\x01")
  let transform = @hash.Hash::of_bytes(b"\x02")
  let policy_a = @hash.Hash::of_bytes(b"\x03")
  let policy_b = @hash.Hash::of_bytes(b"\x04")
  let a = @model.WorkPromise::new(input, transform, policy_a)
  let b = @model.WorkPromise::new(input, transform, policy_b)
  assert_true(a.promise_id != b.promise_id)
}

///|
test "WorkPromise can be projected into generalized solve ticket" {
  let input = @hash.Hash::of_bytes(b"\x01")
  let transform = @hash.Hash::of_bytes(b"\x02")
  let policy = @hash.Hash::of_bytes(b"\x03")
  let promise = @model.WorkPromise::new(input, transform, policy)
    .promise()
    .start()
  let ticket = promise.to_solve_ticket(
    "repair", "delegate-control", "provider.codex", "compiler bug fix",
  )
  assert_eq(ticket.solve_id, promise.promise_id)
  assert_eq(ticket.solve_kind, "repair")
  assert_eq(ticket.offloaded_to, "delegate-control")
  assert_eq(ticket.handler, "provider.codex")
  assert_eq(ticket.status, @model.Running)
}

///|
test "SolveTicket can materialize and verify result linkage" {
  let solve_id = @hash.Hash::of_bytes(b"\x07")
  let result_hash = @hash.Hash::of_bytes(b"\x08")
  let result_envelope_id = @hash.Hash::of_bytes(b"\x09")
  let ticket = @model.SolveTicket::new(
      solve_id,
      "smt",
      "mu.local",
      @model.Queued,
      "mu.local.z3",
      "queued solve",
    )
    .attach_result(result_hash, result_envelope_id)
    .with_witness("proof://z3/run-1")
    .mark_verified()
  assert_eq(ticket.status, @model.Verified)
  assert_eq(ticket.result_hash, Some(result_hash))
  assert_eq(ticket.result_envelope_id, Some(result_envelope_id))
  assert_eq(ticket.witness_ref, Some("proof://z3/run-1"))
}

///|
test "AI substrate fingerprint v2 can be APP-masked" {
  let context_hash = @hash.Hash::of_bytes(b"\x10")
  let capability_hash = @hash.Hash::of_bytes(b"\x11")
  let substrate_hash = @hash.Hash::of_bytes(b"\x12")
  let ciphertext_hash = @hash.Hash::of_bytes(b"\x13")
  let fingerprint = @model.AiSubstrateFingerprintV2::new(
    "openai", "codex", "chatgpt", "tool", context_hash, capability_hash, substrate_hash,
    "issuer://codex",
  )
  let masked = fingerprint.mask_with_app(
    "app/v1", "genius-loci", "app://mask/opaque-1", ciphertext_hash,
  )
  assert_eq(masked.protocol, "app/v1")
  assert_eq(masked.audience, "genius-loci")
  assert_eq(masked.ciphertext_ref, "app://mask/opaque-1")
  assert_eq(masked.ciphertext_hash, ciphertext_hash)
  assert_true(masked.masked_commitment != fingerprint.commitment())
}

///|
test "Genius procsi attestation derives session identity" {
  let fingerprint_commitment = @hash.Hash::of_bytes(b"\x21")
  let ciphertext_hash = @hash.Hash::of_bytes(b"\x22")
  let attestation = @model.GeniusProcsiAttestation::from_masked_refs(
    Some("adversary"),
    "zpc/merkin",
    "repo-root",
    "codex",
    fingerprint_commitment,
    "app/v1",
    "genius-loci",
    "app://mask/opaque-2",
    ciphertext_hash,
  )
  let session = @model.SessionIdentity::from_genius_attestation(attestation)
  assert_eq(session.tier, "codex")
  assert_eq(session.locus, Some("adversary"))
  assert_true(session.short_id != "")
}

///|
test "APP envelope record can derive a masked envelope" {
  let fingerprint_commitment = @hash.Hash::of_bytes(b"\x31")
  let record = @model.AppEnvelopeRecord::new(
    "app://mask/opaque-3", "app/v1", "genius-loci", b"\x01\x02opaque",
  )
  let masked = record.to_mask_envelope(fingerprint_commitment)
  assert_eq(masked.protocol, "app/v1")
  assert_eq(masked.audience, "genius-loci")
  assert_eq(masked.ciphertext_ref, "app://mask/opaque-3")
  assert_eq(masked.ciphertext_hash, record.ciphertext_hash)
}

///|
test "PR1 custom section roundtrips" {
  let fingerprint_commitment = @hash.Hash::of_bytes(b"\x41")
  let context_hash = @hash.Hash::of_bytes(b"\x42")
  let policy_hash = @hash.Hash::of_bytes(b"\x43")
  let record = @model.AppEnvelopeRecord::new(
    "app://mask/opaque-4", "app/v1", "genius-loci", b"\xCA\xFE\xBA\xBE",
  )
  let attestation = @model.GeniusProcsiAttestation::new(
    Some("adversary"),
    "zpc/merkin",
    "repo-root",
    "codex",
    fingerprint_commitment,
    record.to_mask_envelope(fingerprint_commitment),
  )
  let section = @model.ProcsiAttestedSectionV1::new(
    attestation, context_hash, policy_hash,
  )
  let bytes = section.emit_pr1_custom_section()
  match @model.ProcsiAttestedSectionV1::parse_pr1_custom_section(bytes) {
    Some(parsed) => {
      assert_eq(parsed.attestation.project, "zpc/merkin")
      assert_eq(parsed.attestation.ratio_loci, "repo-root")
      assert_eq(parsed.attestation.session_surface, "codex")
      assert_eq(parsed.attestation.locus, Some("adversary"))
      assert_eq(
        parsed.attestation.app_envelope.ciphertext_ref,
        "app://mask/opaque-4",
      )
      assert_eq(parsed.context_hash, context_hash)
      assert_eq(parsed.policy_hash, policy_hash)
    }
    None => assert_true(false)
  }
}
