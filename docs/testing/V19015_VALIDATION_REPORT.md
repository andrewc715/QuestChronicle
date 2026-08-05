# Quest Chronicle v1.9.0.15 Automated Validation Report

## Source baseline

- Uploaded Retail-validated package: `QuestChronicle-v1.9.0.15a2(2).zip`
- Verified baseline SHA-256: `7fbf907d44247881a3dd860cf5ce2869eb63663aace814dec1a9bfb2ef7f75ee`
- Baseline suite before modification: clean

## Release-candidate results

- 70 Lua regression harnesses passed.
- 26 Python static verifiers passed.
- 170 Lua files passed syntax validation.
- 99 runtime Lua modules were present exactly once in the TOC.
- 1 JSON configuration passed validation.
- Every runtime Lua file remained below 500 physical lines.
- The largest Lua file remained `Core/ZoneStyle/SourceMetadata.lua` at 499 lines.
- No runtime call to the blocking transmog usability refresh exists.
- Version, split-helper, diagnostics, Phase B, Phase C, Phase D, Phase E, scheduler, cache, weapon-index, reroll-reconciliation, and report-compaction guards passed.

## Curated descriptor freeze

The release candidate retains exactly six visual-ID overrides:

- Gray Woolen Shirt: neutral palette retained; plain finish.
- Stylish Black Shirt: dark palette retained; plain finish.
- Hide of Lupos: dark .45, neutral .35, purple .20; primal .75, weathered .25.
- Rugged Plate Vest: blue .45, steel .35, dark .20; weathered .60, plain .40.
- Expedition Defender's Shoulders: green .70, steel .30; military .80, polished .20.
- Orcish Scout Boots: dark .70, blue .20, steel .10; plain .75, polished .25.

No item override, source override, global lexicon change, or echo-only addition exists.

## Runtime scope

Of the 99 TOC runtime modules, exactly one file differs from validated a2:

```text
Core/Chronicle/Foundation.lua
```

That difference is only the fallback version token `1.9.0.15a2` → `1.9.0.15`. All curated, descriptor, scoring, generation, repair, audit, reroll, route, cache, and scheduler runtime modules are byte-identical to validated a2.

## Status

Automated-validated release candidate. The exact packaged ZIP requires the short Retail smoke test in `V19015_LIVE_VALIDATION_STEPS.md` before promotion. The tested ZIP must be promoted without rebuilding it.
