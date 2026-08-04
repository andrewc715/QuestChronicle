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

- Post-login `COLD_BUILD -> LOGIN_SESSION_RESET`.
- Intervening `WARM_REUSE -> NONE` without erasing the login lifecycle.
- Later `PARTIAL_BUILD -> LOGIN_SESSION_RESET`.
- Final `WARM_REUSE -> NONE`.
- Actions that perform no weapon-index work report `NONE`.
- An invalidation that is queued but not processed reports `NONE` for the current action and retains its cause for the later build.
- Every recognized canonical reason survives cold construction without being marked unknown.
- Bucket-local repairs retain their canonical cause.
- Format, character, and wardrobe identity mismatches are inferred defensively and classified as cold rebuilds.
- Missing and unrecognized causes are the only `UNKNOWN` fallbacks.
- `UNKNOWN` does not leak into later warm reuse.
- Only a final action reason of `UNKNOWN` emits `UNKNOWN_WEAPON_INDEX_INVALIDATION`.
- All production weapon-route invalidation entrypoints supply explicit reasons.

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
