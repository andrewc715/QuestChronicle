# Quest Chronicle v1.9.0.15a2 Implementation Plan

## Purpose

Apply the first reviewed Phase E descriptor corrections while freezing every Traveler formula and validation threshold.

## Runtime design

- Add `Core/ZoneStyle/Traveler/CuratedOverrides.lua` after `StyleLexicon.lua` and before `Descriptors.lua`.
- Resolve correction layers in this order: visual identity, optional item refinement, optional source refinement.
- Replace only approved palette or finish maps during descriptor construction.
- Assign 0.95 confidence to each curated field.
- Include curated tuning version 1 in the descriptor fingerprint.
- Add `descriptor.echoPalette`, defaulting to a copy of the final palette.
- Read `echoPalette` only for echo support; continue using normal palette for pair cohesion, profile centers, dominant palette, and Phase D family count.
- Add compact curated identity markers to Debug snapshots and tuning-audit exports.

## Frozen systems

Do not change:

- StyleLexicon token tables or relation matrices;
- Phase B scoring, novelty, shortlist, or search widths;
- Phase C profile, candidate, support-beam, budget, or role formulas;
- Phase D mismatch, severity, palette-family, echo, repair-pass, or alternate-skeleton rules;
- routes, topology, locks, hidden state, random consumption, scheduler budgets, or atomic commit;
- SavedVariables, wardrobe cache, generation cache, diagnostic, weapon-index, or Courier formats.

## Acceptance

- All six exact descriptor fixtures match the curated ledger.
- Both shirts retain their lexicon-derived palettes.
- Unreviewed appearances receive no override.
- Unaffected regression fixtures remain semantically identical to corrected a1.
- Normal reports remain bounded and copyable.
- Retail descriptor inspection and a focused ten-action batch pass.
