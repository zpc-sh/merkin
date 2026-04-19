# Ratio Boundary Shim Spec v0.1

Design for running Merkin as the trusted internal structure while still interoperating with git as an external transport boundary.

Date baseline: `2026-04-18`.

## 1) Goal

Treat git as an untrusted ingress/egress surface and enforce deterministic normalization + policy checks before material enters Merkin state.

Boundary claim:

- a technical boundary in Merkin is also a cognitive boundary: cross-boundary material must be representation-safe and policy-shaped, not raw session authority.

## 2) Boundary Model

Pipeline:

1. `IngressAdapter(git)` reads refs, branch names, metadata, and candidate object payloads as raw bytes.
2. `ByteScanner` detects disallowed/ambiguous codepoints and control bytes.
3. `Normalizer` emits canonical scalar forms for policy and indexing.
4. `RuleEngine` applies allow/strip/quarantine/reject policies.
5. `MerkinWriter` writes accepted material into Merkin-native structures.
6. `DriftEmitter` updates `finger.plan.wasm` and triad metadata with boundary posture.

Guiding rule:

- No direct git string should become Merkin trust material without passing the shim.

## 3) Rule Classes

## 3.1 Scalar hygiene rules (mandatory)

Targets:

- branch names
- ref names
- peer ref tokens
- head pins
- policy ids or tool-provided labels

Detect at minimum:

- `U+200B` (zero-width space)
- `U+200C` (zero-width non-joiner)
- `U+FEFF` (bom/zero-width no-break space)
- ASCII controls except `\n`, `\r`, `\t` where explicitly allowed

Actions:

- `strip`: remove known ghost bytes but preserve canonical visible string
- `reject`: refuse ingestion
- `quarantine`: preserve raw value in quarantine and mark suspicious

## 3.2 Structural rules

- enforce bounded scalar lengths (for refs/labels)
- enforce UTF-8 validity for text fields
- replace embedded newlines/carriage returns in compact `.plan` fields
- deny comma injection in CSV-bound fields (normalize to semicolon or array form)

## 3.3 Object provenance rules

- keep content-addressed object hashes independent of display names
- annotate source transport (`git`, `manual`, `api`) on ingestion envelope
- quarantine objects with malformed metadata but preserve payload hash for forensics

## 4) Policy Modes

- `observe`: detect + report only; no mutation
- `sanitize`: normalize known-bad scalars and continue
- `strict`: reject any non-byte-clean trusted scalar
- `quarantine`: accept into isolated lane only, excluded from trusted drift pins

Recommended defaults:

- local dev bootstrap: `sanitize`
- release/CI: `strict`
- incident response: `quarantine`

## 5) Shim Outputs

Each boundary event should produce:

- `raw_hex` for suspicious scalars
- `canonical` scalar used for Merkin-trusted indexing
- action taken (`accepted`, `sanitized`, `quarantined`, `rejected`)
- deterministic event hash for audit replay

## 6) `.plan/finger` Security Signaling Profile

`finger.plan.wasm` should carry compact security posture fields:

- `boundary_mode=<observe|sanitize|strict|quarantine>`
- `boundary_cognitive=<0|1>`
- `boundary_domain=<ratio_loci|genius_loci|cross_loci>`
- `boundary_refs_total=<n>`
- `boundary_refs_sanitized=<n>`
- `boundary_refs_quarantined=<n>`
- `boundary_ghost_u200b=<n>`
- `boundary_ghost_u200c=<n>`
- `boundary_ghost_ufeff=<n>`
- `boundary_bidi_controls=<n>`
- `boundary_ascii_controls=<n>`
- `boundary_ticks=<n>`
- `boundary_attention_score=<n>`
- `boundary_attention_gradient=<quiescent|watch|pulled|saturated>`
- `boundary_attention_saturated=<0|1>`
- `boundary_status=<clean|attention|containment>`

Status mapping:

- `clean`: no suspicious refs in trusted set
- `attention`: ghost-byte sanitized refs present
- `containment`: bidi controls or disallowed ASCII controls present (and may also be used by policy quarantine/reject)

## 7) Response Semantics

If `boundary_status=containment`:

- triad contract should set a compatibility warning field (additive)
- pin updates from contaminated refs should be withheld from trusted repo pins
- release gates should fail closed in CI strict mode

If `boundary_status=attention`:

- continue with warning
- require explicit acknowledgement for release tagging

If `boundary_cognitive=1`:

- consumers must treat payload as boundary-filtered representation
- direct session authority material must not be assumed to cross boundary

## 8) Minimal Implementation Plan

1. Extract current ghost-byte helpers into shared boundary utility module.
2. Add boundary scanner for git-derived scalars in daemon Yata actions and triad emission path.
3. Add compact boundary posture lines to `plan_finger_wasm`.
4. Add additive fields in triad contract JSON for boundary summary.
5. Mirror policy in `.well-known/interface-drift-policy.md`.

## 9) Non-Goals (v0.1)

- replacing git transport entirely
- full malware/static analysis of arbitrary blob payloads
- policy execution outside deterministic scalar/object boundary checks

## 10) Integration Targets

- `api/api.mbt` (`plan_finger_wasm`, `triad_contract_wasm`)
- `cmd/main/main.mbt` Yata actions
- `tools/yata-wasm-plan-drift-sync.sh`
- `tools/yata-triad-contract-sync.sh`
