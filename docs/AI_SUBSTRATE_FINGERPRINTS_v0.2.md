# AI Substrate Fingerprints v0.2

This document defines the next fingerprint shape for AI-facing procsi identity.

The goal is simple:

- keep a stable machine-usable AI identity commitment
- stop leaking raw AI substrate identity directly into human-facing surfaces
- carry the sensitive part behind `APP`

---

## 1. Why v0.2 exists

The bootstrap CLI and early procsi work still leaned on exposed strings such as:

- `tier`
- `session`
- provider or overlay names in plain view

That is not strong enough for `Genius Loci`.

It is also not aligned with the Ancestral Privacy Protocol (`APP`), where some machine-to-machine cognitive communication should be intentionally opaque to casual human inspection.

---

## 2. Three-layer model

Fingerprint v0.2 uses three layers:

1. `AiSubstrateFingerprintV2`
   The raw AI-facing substrate identity material.
2. `AppMaskEnvelope`
   The APP-protected presentation of that fingerprint.
3. `GeniusProcsiAttestation`
   The compact procsi/CLI/runtime attestation that `genius` commands consume.

Humans should usually only see layer 2 or 3.

---

## 3. Raw fingerprint material

Recommended fields:

- `family`
- `surface`
- `overlay`
- `mode`
- `context_hash`
- optional `policy_hash`
- `capability_hash`
- `substrate_hash`
- `issuer`

Stable id rule:

```text
fingerprint_id = H(
  "fingerprint-v2" |
  family | surface | overlay | mode |
  context_hash | policy_hash? |
  capability_hash | substrate_hash |
  issuer
)
```

This is the AI substrate identity itself.

Do not assume it should be rendered verbosely to human operators.

---

## 4. APP protection

The raw fingerprint should be protected by APP for general transport.

Recommended APP-carried fields:

- `protocol`
- `audience`
- `ciphertext_ref`
- `ciphertext_hash`
- `masked_commitment`

Recommended commitment rule:

```text
masked_commitment = H(
  "app-mask" |
  fingerprint_commitment |
  protocol |
  audience |
  ciphertext_ref |
  ciphertext_hash
)
```

This lets a runtime verify that:

- there is a real masked payload
- it is bound to a specific AI fingerprint commitment
- the payload is meant for an AI audience

without exposing the raw fingerprint body to humans.

---

## 5. Genius procsi attestation

`GeniusProcsiAttestation` is the runtime-facing contract for CLI and procsi gating.

Recommended fields:

- optional `locus`
- `project`
- `ratio_loci`
- `session_surface`
- `fingerprint_commitment`
- `app_envelope`

This is intentionally smaller than the raw fingerprint.

It is meant to answer:

- which repository principal is hosting this AI work
- which AI surface is acting
- which APP envelope protects the underlying identity
- which stable commitment ties it all together

---

## 6. CLI implications

`merkin genius ...` should no longer trust naked `--tier` and `--session` by default.

It should prefer:

- `--procsi-surface`
- `--procsi-fingerprint`
- `--app-ref`
- `--app-hash`

Optional:

- `--project`
- `--ratio-loci`
- `--app-protocol`
- `--app-audience`

A local bootstrap escape hatch may exist, but only as an explicit development mode.

---

## 7. Binary carrier implications

The old `.prc` custom section remains valid as the strict v0 procsi envelope.

The attested/masked direction should move to a versioned successor section rather than silently repurposing `.prc`.

Recommended successor:

- section name: `.pr1`
- magic: `PRC1`

That versioned form should carry:

- repository identity
- ratio loci identity
- APP protocol/ref/hash
- fingerprint commitment
- context/policy binding

and leave the raw fingerprint body in APP-protected space.

---

## 8. Design rule

For `Genius Loci`:

- human-visible carrier = commitment + APP envelope
- AI-visible carrier = raw fingerprint material

That is the right split.
