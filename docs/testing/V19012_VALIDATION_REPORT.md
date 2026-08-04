# Quest Chronicle v1.9.0.12 Automated Validation Report

## Results

```text
56 Lua regression harnesses passed
21 static verification tools passed
146 Lua files passed syntax validation
89 runtime Lua modules are listed exactly once in the TOC
1 JSON configuration file validated
Largest runtime Lua file: 499 physical lines
```

## Structural audits

```text
Missing TOC modules:                 0
Unlisted runtime modules:            0
Duplicate TOC entries:               0
Orphaned private-helper references:  0
Blocking wardrobe usability calls:   0
Version-source disagreements:        0
```

## Dedicated v1.9.0.12 coverage

- Immediate expensive-call yields and phase reservations
- Adaptive 32-operation cached fast lane and single-operation slow fallback
- Constant-time generation-cache scalar snapshots
- Immutable invalidation-reason copies and exact generation deltas
- Eight-stage cooperative full-generation setup
- Cold, warm, and incremental-repair weapon-index action diagnostics
- Canonical weapon-index invalidation reasons
- Exact selection and scoring parity with v1.9.0.11

## Compatibility

```text
SavedVariables schema:   2
Courier format:          1
Wardrobe cache format:   7
Generation cache:        2
Diagnostic format:       1
Weapon index format:     1
```

Retail validation remains required before the release can replace v1.9.0.5 as the live-validated production baseline.
