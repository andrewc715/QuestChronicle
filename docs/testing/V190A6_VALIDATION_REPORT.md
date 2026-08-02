# Quest Chronicle v1.9.0a6 Validation Report

Date: 2026-08-02
Build: `1.9.0a6`
Scope: Adaptive cooperative outfit generation and phase-aware performance diagnostics

## Live evidence driving the release

Quest Chronicle v1.9.0a5 produced the following measurements on Andrew's live wardrobe:

```text
Cold post-/reload Generate Outfit: 1,408 frames, 331.2 ms worst step, about 23 seconds
Warm Reroll Unlocked:                204 frames, 96.7 ms worst step
Second warm Reroll Unlocked:         204 frames, 56.2 ms worst step
```

The stable 204-frame reroll count matched the fixed 30-candidate worker cap across roughly 6,000 armor candidates. The cold spike also showed that one uncached era-evidence call could enumerate a complete visual-sibling family before the worker regained control.

## Implemented repair

- Removed `GENERATION_CANDIDATE_BATCH = 30`.
- Made the 2.5 ms addon-time budget the primary scheduler boundary.
- Added a 2,000-operation emergency ceiling that does not normally throttle work.
- Added resumable era-evidence work that resolves one visual sibling per operation.
- Added pre-era rejection for zone exclusions, promotional sources, and progression-restricted sources.
- Cached unchanged normalized source metadata.
- Reused coherence results during source weighting.
- Added phase totals and maximum-operation measurements through final preview and UI refresh.
- Preserved weighted random order and atomic state commit behavior.

## Automated validation

Passed:

- Lua syntax compilation for every runtime and test Lua file.
- Runtime Lua line limit: all files at or below 500 physical lines.
- TOC dependency order and version metadata review.
- Split-module private-helper reference guard.
- Blocking `C_TransmogCollection.UpdateUsableAppearances()` guard.
- Independent phase-aware performance-status wiring guard.
- Adaptive scheduler and resumable era-evidence static guard.
- Cooperative generation regression harness.
- Cooperative era-evidence regression harness.
- Weighted selection parity harness.
- Metadata-cache invalidation and pending-load retry harness.
- Pre-era rejection harness.
- Traveler calibration regression harness.
- Cooperative wardrobe-login performance harness.

Synthetic scheduler benchmark:

```text
6,000 armor candidates
100 uncached era siblings
34 worker frames
2.80 ms longest worker step
```

The same candidate count would require at least 200 armor frames under the removed 30-candidate cap. The benchmark is synthetic and does not substitute for Retail client timing, but it verifies the intended scheduler mechanics and budget yielding.

## Compatibility

- SavedVariables schema: 2
- Courier format: 1
- Wardrobe cache format: 7
- No migration required
- No forced wardrobe rescan required
- Traveler cohesion remains instrumentation only

## Live validation status

Awaiting Andrew's Retail test of the packaged v1.9.0a6 build. v1.9.0a2 remains the last fully live-validated fallback until this test passes.
