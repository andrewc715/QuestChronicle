# Quest Chronicle v1.9.0.13 Automated Validation Report

## Results

```text
58 Lua regression harnesses passed
22 static verification tools passed
148 Lua files passed syntax validation
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

## Dedicated v1.9.0.13 coverage

- `LOGIN_SESSION_RESET` initialization for the session-only weapon index
- Reason retention across cold and partial bucket builds
- `NONE` on fully warm reuse
- Canonical cache-replacement and character-capability transitions
- Defensive inference when the index identity changes without an explicit caller reason
- `UNKNOWN` fallback only for missing or unrecognized reasons
- Warning emission only for genuine `UNKNOWN` fallback
- Cold build to partial build to warm reuse action diagnostics
- Continued v1.9.0.12 scheduler, cache, selection, scoring, route, and contextual-support coverage

## Cross-version regression comparison

```text
54 of 56 common Lua harness outputs matched byte for byte
1 benchmark differed only in measured elapsed time
1 weapon-index diagnostic harness changed intentionally for v1.9.0.13 semantics
All 58 v1.9.0.13 harnesses passed
```

## Compatibility

```text
SavedVariables schema:   2
Courier format:          1
Wardrobe cache format:   7
Generation cache:        2
Diagnostic format:       1
Weapon index format:     1
```

Retail validation remains required before v1.9.0.13 replaces v1.9.0.12 as the live-validated baseline.
