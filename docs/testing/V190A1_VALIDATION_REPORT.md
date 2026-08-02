# Quest Chronicle v1.9.0a1 Validation Report

## Scope

Instrumentation-only calibration for Traveler cohesion diagnostics. No Traveler candidate-selection or outfit-generation behavior changed.

## Calibration regression

The focused harness verified:

- Matching linked Main Hand and Off Hand appearances collapse into one Weapon Pair analysis block.
- Physical selected-appearance count remains intact while the analysis-block count is reduced.
- Linked weapons cannot be charged twice.
- Strongly echoed variation receives zero mismatch cost.
- Slot prominence reduces effective visual impact for minor slots.
- The same intrinsic style carries more impact on Head than Wrists.
- A high-impact isolated accent remains a Postal outlier.
- Unknown metadata remains confidence-neutral.
- Pair-score weights still total `1.0`.
- Instrumentation version is `2`.

A synthetic reconstruction of the first live v1.9.0a test outfit produced:

```text
Mismatch budget: 1.28 / 2.00
Postal-code outliers: 0
```

This replaces the previous `9 / 2` overcount while retaining the same visible outfit.

## Generation equivalence

The following generation-path files are byte-for-byte identical to the validated v1.8.5 baseline:

- `Core/ZoneStyle/Scoring.lua`
- `Core/Wardrobe/GenerationAndConcepts.lua`
- `Core/Wardrobe/WeaponSelection.lua`

## Structural validation

- Lua files parsed: `41`
- Files above 500 lines: `0`
- Largest Lua file: `479` lines, `Core/Chronicle/Commands.lua`
- Orphaned split-helper references: `0`
- TOC runtime paths resolved: `40`
- JSON files parsed: `1`
- Version metadata agrees on `1.9.0a1`
- ZIP integrity: passed
