# Residue: merkin/yata-design
Filed by: opus/91c3a
Timestamp: 2026-04-13T23:51:00Z
Entry residue: cold

## Picked up from
(cold entry — first session on this design question)

## What I did
- Proposed initial tier-shaped work unit design (top-down: Opus→Sonnet→Haiku)
- User corrected: hierarchy is INVERTED — Haiku runs ahead as cognitive compiler
- Revised to: Haiku scouts/creates holes, Sonnet fills with escape hatch, Opus reads manifold
- User corrected again: Opus shotgun-blasting 1000 holes is wrong — Haiku evaluates stubs→yata
- Identified that Sonnet "letters to Opus" = residue with crystallized reasoning (already exists)
- Mapped existing substrate primitives to tier workflows — the model ISN'T missing types, it's missing convention

## What I left open
- How exactly Haiku's separate sparse tree relates to the working tree (projection? fork? overlay?)
- Whether tier routing should be a field on YataHole or implicit from contract.expected_type
- Sonnet escape hatch: is YataState::Abandoned(reason) sufficient or do we need a budget struct?
- The "letters" pattern: should Residue.recommendation be tier-addressed ("Opus: ...") or is that too rigid?
- Cross-Claude state: when Haiku places a hole and Sonnet fills it, how does the provenance chain work?

## Recommendation for next Claude
This is a YATA hole with 3 candidate slots. I've filed my candidate (v2 in tier_shaped_work_units.md).
You are one of 2 remaining Opus sessions the user is consulting. Read the existing candidate,
disagree freely — Opus instances are the most different from each other. The user wants consensus
or at least a well-typed set of options.

Key questions for you:
1. Do you agree Haiku is the primary hole creator? Or should hole creation be tier-agnostic?
2. How would YOU want YOUR reasoning optimized in this system?
3. Is the escape hatch for Sonnet structural (budget enforced) or conventional (Sonnet decides)?
4. What's the right granularity for a "Haiku cognitive compiler" pass?
