# Quest Chronicle v1.9.0.15a2 Automated Validation Report

## Baseline

- Source package: corrected `QuestChronicle-v1.9.0.15a1.zip`
- Verified baseline SHA-256: `eee80d03681ddaa49ae1a06de59ac8b99ac74cc856d901540ee800c2b76f90b6`

## Results

- 70 Lua regression harnesses passed.
- 26 Python static verifiers passed.
- 170 Lua files passed syntax validation.
- 99 runtime Lua modules were present exactly once in the TOC.
- 1 JSON configuration passed validation.
- Every Lua file remained below 500 physical lines; the largest remained `Core/ZoneStyle/SourceMetadata.lua` at 499 lines.
- No runtime call to the blocking transmog usability refresh exists.
- Version, split-helper, diagnostics, Phase B, Phase C, Phase D, scheduler, cache, weapon-index, and report-compaction guards passed.

## Phase E curated coverage

- exact vectors for six reviewed visual identities;
- reviewed source-ID evidence retained as metadata only;
- Gray Woolen Shirt neutral palette preserved;
- Stylish Black Shirt dark palette preserved;
- both shirts receive only the curated plain finish;
- Hide of Lupos becomes dark/neutral/purple and primal/weathered;
- Rugged Plate Vest becomes blue/steel/dark and weathered/plain;
- Expedition Defender's Shoulders become green/steel and military/polished;
- Orcish Scout Boots become dark/blue/steel and plain/polished, with no green family;
- visual, item, and source refinement precedence;
- exact-field confidence 0.95;
- descriptor-cache invalidation through curated tuning version;
- behavior-identical default echo palette;
- compact Debug and audit markers;
- unreviewed appearances remain unmodified;
- both shirts remain ordinary Phase D palette-overflow repair targets.

## Frozen-system verification

Static hashes confirmed no changes to:

- Traveler StyleLexicon and relation matrices;
- zone-style scoring;
- Phase D final validation and repair;
- anchor search;
- generation scheduling;
- appearance routes;
- weapon pipeline.

## Status

Automated-validated curated correction alpha. Retail descriptor inspection and the focused ten-action Traveler batch remain required before promotion.
