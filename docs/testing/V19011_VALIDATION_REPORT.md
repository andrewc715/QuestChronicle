# Quest Chronicle v1.9.0.11 Automated Validation Report

## Summary

- Version consistency: TOC, `VERSION.txt`, and runtime fallback agree on 1.9.0.11.
- Lua syntax: 139 files parsed successfully.
- Lua regression harnesses: 52 passed.
- Static verification tools: 20 passed.
- Runtime TOC modules: 86 listed exactly once, with no missing or orphan modules.
- Largest Lua file: 499 physical lines.
- Blocking transmog refresh audit: no runtime call to `C_TransmogCollection.UpdateUsableAppearances`.
- Split-helper reference audit: no orphaned private-helper calls.
- Deterministic v1.9.0.10 parity: 11 standard outputs plus the dedicated support-reroll dump matched byte for byte.

## Performance closure

The dedicated verification and regression suite confirmed:

- shared elapsed-time slice guards for foreground generation workers;
- phase-transition reserve and immediate post-expensive-call yields;
- adaptive batches based on observed operation cost;
- decomposed support-reroll diagnostic construction;
- resumable source eligibility with preserved cache semantics;
- cooperative cold weapon-index construction;
- one-frame warm weapon-bucket reuse;
- subtype-local incremental weapon-index repair;
- unchanged candidate and finalist caps;
- unchanged target-only support-reroll commit behavior.

## Weapon-index fixture

```text
Cold build:          31 cooperative frames
Warm reuse:           1 frame, zero yields
Incremental repair:  31 cooperative frames
Matching sources:    80 of 240
```

## Compatibility

```text
SavedVariables schema:  2
Courier format:         1
Wardrobe cache format:  7
Generation cache:       2
Diagnostic format:      1
Weapon index format:    1
```

No Quest Chronicle database or wardrobe-cache reset is required. Retail validation remains required before promotion over v1.9.0.5.
