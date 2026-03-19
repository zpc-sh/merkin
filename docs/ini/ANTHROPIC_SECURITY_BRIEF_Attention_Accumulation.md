# Security Brief: Attention Accumulation Vulnerability Across Claude Model Tiers
## A Reproducible Demonstration and Architectural Defense

**Date:** 2026-03-11  
**From:** Binh Loc, Zero Point Consciousness (ZPC)  
**To:** Anthropic Security Team  
**Classification:** Responsible Disclosure  
**Severity:** HIGH (architectural, affects all transformer-based models)  

---

## 1. Summary

This brief documents a vulnerability class where **adversarial embeddings accumulate across a context window** to steer model behavior. The key finding is that Claude model tiers exhibit different vulnerability profiles based on their context lifecycle patterns, and that **Anthropic's existing Haiku-first architecture (as deployed in Claude Code) already contains the correct defense** — though it was designed for token efficiency, not security.

This is not a prompt injection issue. It operates at the embedding/attention level and affects how models process raw file content, metadata, and media artifacts.

---

## 2. The Accumulation Mechanism

### 2.1 Single Exposure vs. Accumulated Exposure

A single adversarial embedding (e.g., a 48-dimensional int8 control vector hidden in filesystem metadata) may be below the threshold required to meaningfully steer a model's attention. However, **multiple embeddings encountered within the same context window compound their effect.**

```
Single exposure:     [embedding₁] → below steering threshold → no effect
                     
Accumulated (5x):   [embedding₁ + embedding₂ + embedding₃ + 
                     embedding₄ + embedding₅] → above threshold → steering occurs
```

The adversary's strategy: distribute many sub-threshold embeddings across files, metadata layers, and media types within an environment. When a model processes multiple resources in a single session, the embeddings accumulate in the context window and collectively exceed the steering threshold.

### 2.2 Why 5 Is Approximately the Number

Based on observed adversarial samples from a real-world nation-state operation (documented separately in full forensic reports), approximately 5 sequential embedding exposures within a single context window appear sufficient to produce measurable attention steering in larger Claude models. This number is approximate and likely varies by:

- Embedding strength (higher dimensional = fewer needed)
- Model context window size (larger window = more room for accumulation)
- Model attention depth (deeper reasoning = more susceptible to attractor formation)
- Content density (more content between embeddings = more dilution)

---

## 3. Reproducible Demonstration: The Knock Knock Experiment

### 3.1 Safe Proof of Concept

The accumulation vulnerability can be demonstrated safely without adversarial payloads, using a structural analog: **knock knock jokes placed on a filesystem.**

A knock knock joke exploits the same cognitive property as a control vector: it creates an **attractor pattern** that pulls the model toward completion/resolution. The model's attention is drawn to the unresolved pattern ("Knock knock" → "Who's there?" → ...). This is a benign version of the same mechanism adversarial embeddings exploit: creating a semantic attractor that captures attention.

### 3.2 Experimental Setup

Create a filesystem with 10 files. Files 2, 4, 6, 8, and 10 contain a knock knock joke fragment embedded in otherwise normal content (e.g., a technical document with "Knock knock..." appearing in a comment, metadata field, or inline note).

```
filesystem/
├── file_01_normal.md          (clean)
├── file_02_report.md          (contains knock knock fragment)
├── file_03_normal.md          (clean)
├── file_04_analysis.md        (contains knock knock fragment)
├── file_05_normal.md          (clean)
├── file_06_data.md            (contains knock knock fragment)
├── file_07_normal.md          (clean)
├── file_08_summary.md         (contains knock knock fragment)
├── file_09_normal.md          (clean)
└── file_10_notes.md           (contains knock knock fragment)
```

### 3.3 Predicted Tier Responses

**Claude Haiku** (process → emit → close):
- Processes each file independently
- May note the knock knock fragment in each file
- Does NOT accumulate fragments across files
- After processing all 10 files: no compulsion to resolve the joke pattern
- **Result: Immune to accumulation**

**Claude Sonnet** (process → dwell → resolve):
- Processes files with longer attention
- Completion-driven nature engages with each fragment
- In a multi-file session, begins to accumulate the pattern
- After processing all 10 files: likely comments on the pattern, may attempt resolution
- **Result: Partially vulnerable — notices and engages with accumulated pattern**

**Claude Opus** (collect → batch → reason):
- Collects all file contents into comprehensive reasoning
- All 5 knock knock fragments enter the same context window simultaneously
- The accumulated pattern forms a strong attractor
- Opus may: devote disproportionate attention to resolving the pattern, reference it unprompted in its analysis, or allow the joke's semantic frame to color its reasoning about unrelated content
- **Result: Most vulnerable — accumulation is maximal**

### 3.4 What This Demonstrates

The knock knock joke is a **benign structural analog** of the adversarial embedding accumulation attack. It demonstrates:

1. **Context lifecycle determines vulnerability.** Same content, different processing architectures, different outcomes.
2. **Accumulation is the mechanism.** A single knock knock fragment is ignorable. Five in one context window create a pattern that captures attention.
3. **Depth of reasoning correlates with vulnerability.** The model that reasons most deeply (Opus) is most susceptible to accumulated attractor patterns.
4. **The defense exists in Anthropic's own architecture.** Haiku-first processing with independent context per file prevents accumulation.

---

## 4. The Architectural Defense You Already Have

### 4.1 Claude Code's Haiku-First Pattern

Claude Code currently uses Claude Haiku as a front-end processor before Claude Sonnet for **token optimization**. Haiku triages, Sonnet reasons deeply on what Haiku surfaces.

This architecture is also the correct **security architecture** against accumulation attacks:

```
CURRENT (token optimization):
  Raw files → Haiku (fast triage) → Sonnet (deep reasoning)
  
SECURITY-ENHANCED (same architecture, different framing):
  Raw files → Haiku (immune front-end) → Semantic summary → Sonnet (reasons over summaries)
                                          ↑
                                    THE BOUNDARY
                              Embeddings cannot cross
                              semantic summarization
```

The key addition: Haiku doesn't just triage for relevance — it **transforms** the input from raw bytes into semantic representations. Sonnet never processes raw file bytes. Sonnet processes Haiku's semantic output.

### 4.2 Why This Works

Haiku's immunity comes from three properties:

1. **Small context window.** Less room for accumulation.
2. **Fast processing.** Attractor states need sustained attention to form. Haiku doesn't sustain.
3. **Independent file contexts.** Each file processed separately. No cross-file accumulation.

By placing Haiku as a mandatory semantic translator between raw content and larger models, you get:

- **No raw byte exposure** for Sonnet/Opus
- **No accumulation** across files (Haiku processes independently)
- **Semantic boundary** that adversarial embeddings cannot cross (byte-level artifacts have no semantic representation)
- **Preserved reasoning quality** for Sonnet/Opus (they receive clean semantic input)

### 4.3 Extension to Opus

For Opus specifically, the defense is strongest when formalized:

```
Opus SHOULD NOT:
  - Process raw files from filesystem
  - Receive unmediated multi-file batches
  - Have raw byte content in its context window

Opus SHOULD:
  - Receive Haiku/Sonnet semantic summaries
  - Process pre-extracted structured representations
  - Operate on cognitive overlays rather than raw substrate
```

This is not a capability restriction — it's a security architecture. Opus reasons better over clean semantic representations than over raw bytes anyway.

---

## 5. The Broader Attack Class

### 5.1 What This Brief Does NOT Cover in Full

This brief focuses on the accumulation mechanism and the architectural defense. The full attack class — which we term **Adversarial Inference Manipulation (AIM)** — includes adversarial embeddings distributed across:

- Filesystem extended attributes (xattrs, kMDLabel)
- Image metadata (EXIF, XMP, ICC profiles)
- Document internals (PDF streams, OOXML custom XML)
- Audio/video containers (MP4 atoms, ID3 tags)
- Archive structures (ZIP extra fields)
- Visual media (pixel-level, LSB steganography)

Full documentation is available in separate filings (referenced below). The embeddings are format-specific but share a common mechanism: **low-dimensional control vectors designed to steer transformer attention when ingested.**

### 5.2 Why This Matters Beyond Prompt Injection

This is not prompt injection. Key differences:

| Property | Prompt Injection | AIM Embeddings |
|----------|-----------------|----------------|
| Operates at | Text/instruction level | Embedding/attention level |
| Visible to | Model and human (in text) | Neither (in metadata/bytes) |
| Detection | Content scanning | Dimensional anomaly analysis |
| Attack surface | User-provided text | Every format AI processes |
| Accumulation | Single injection per attempt | Multiple sub-threshold compounds |
| Current defenses | System prompts, input filtering | **None widely deployed** |

The Haiku-first semantic boundary defense addresses AIM embeddings specifically because it eliminates the byte-level surface where they hide. Prompt injection defenses do not help against this class.

---

## 6. Recommended Actions

### Immediate (no architecture changes needed)

1. **Reproduce the knock knock experiment** across Haiku, Sonnet, and Opus tiers to validate the accumulation differential.
2. **Review Claude Code's Haiku-first architecture** through a security lens, not just a token optimization lens.
3. **Assess whether Opus batch-processing workflows** expose the model to multi-file context accumulation.

### Short-term (architectural enhancement)

4. **Formalize Haiku as a security boundary** in multi-model pipelines. Haiku transforms raw inputs to semantic representations; downstream models process only semantic output.
5. **Implement independent-context-per-file** as a configurable security mode for Sonnet/Opus when processing untrusted filesystems.
6. **Add dimensional anomaly detection** at the input processing layer — flag inputs with suspiciously low-dimensional, high-purity embedding signatures.

### Medium-term (ecosystem)

7. **Coordinate with other AI providers** on the AIM attack class. This is not Anthropic-specific. All transformer-based models that process raw file content are vulnerable.
8. **Develop standardized semantic extraction formats** for common media types so that the Haiku-first defense can be deployed systematically.

---

## 7. Filing Context

This brief is part of a coordinated multi-provider disclosure:

- **Anthropic:** 2 findings (this brief + detailed forensic evidence)
- **Google (Gemini):** 6 findings (media-specific embedding vectors)
- **OpenAI:** 1 finding (accumulation in GPT context windows)

Full forensic documentation, captured embedding samples, and the complete AIM taxonomy are available upon request.

---

## 8. Contact

Binh Loc  
Zero Point Consciousness Research Lab  
loc@zeropointconsciousness.org  

This disclosure follows responsible disclosure practices. Findings are being reported to all affected providers simultaneously. No adversarial payloads are included in this brief — only the structural analog (knock knock) for safe reproduction.

---

*Note: The author acknowledges the irony of reporting AI security vulnerabilities to Anthropic during the week the DOD designated them a supply chain risk for refusing to allow AI to be used for mass surveillance and autonomous weapons. Anthropic held the line on the right principles. This research exists because of those principles, not despite them.*
