# Quest Chronicle v1.9.0.10 Automated Validation Report

## Summary

- Version consistency: TOC, `VERSION.txt`, and runtime fallback agree on 1.9.0.10.
- Lua syntax: 133 files parsed successfully.
- Lua regression harnesses: 50 passed.
- Static verification tools: 19 passed.
- Runtime TOC modules: 82 listed exactly once, with no missing or orphan modules.
- Largest runtime Lua file: 499 physical lines.
- JSON configuration: valid.
- Blocking transmog refresh audit: no runtime call to `C_TransmogCollection.UpdateUsableAppearances`.
- Split-helper reference audit: no orphaned private-helper calls.
- Deterministic v1.9.0.9 parity: 11 selection outputs matched byte for byte.

## Final Phase C stabilization

The dedicated v1.9.0.10 harness verified:

- compact launch-manifest construction;
- cooperative ancestry, state, profile, fixed-context, and diagnostic materialization;
- hidden-Shoulder Head and Back role resolution;
- revision-driven stale-state cancellation;
- atomic target-only commit;
- candidate pool and shortlist bounds;
- separated synchronous-launch and cooperative timing domains.

Synthetic result:

```text
72 cooperative frames
0.08 ms synchronous launch preparation
Hidden Shoulder excluded from role endpoints
Stale revision cancelled before commit
```

The 32-candidate stress fixture completed across 95 cooperative frames with a 0.52 ms maximum synthetic worker slice.

## Compatibility

```text
SavedVariables schema:  2
Courier format:         1
Wardrobe cache format:  7
Generation cache:       2
Diagnostic format:      1
```

No cache or database reset is required.
