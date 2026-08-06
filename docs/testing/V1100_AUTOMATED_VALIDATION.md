# Quest Chronicle v1.10.0 Automated Validation

## Required commands

Run from the top-level `QuestChronicle` folder.

### Lua regression suite

```bash
for f in tools/test_*.lua; do texlua "$f" || exit 1; done
```

Expected:

```text
74 / 74 tests pass
```

The suite includes the inherited v1.9.0.15 behavior fixtures plus v1.10.0 tests for:

- authoritative mode registration;
- Traveler `SHARED_FRAMEWORK` identity;
- three `LEGACY` adapters;
- mode-neutral API routing;
- action lifecycle and cancellation;
- contextual support-reroll lifecycle;
- legacy individual-reroll separation;
- deterministic Traveler weighted selection through the shared state machine;
- shared-versus-legacy phase and selection parity.

### Python static verifiers

```bash
for f in tools/verify_*.py; do python "$f" || exit 1; done
```

Expected:

```text
27 / 27 verifiers pass
```

### Lua syntax

Parse every runtime Lua module listed under `Core` and `UI`.

Expected:

```text
125 / 125 runtime Lua files parse
```

### Required static gates

- every runtime Lua file is below 500 physical lines;
- every runtime module appears in the TOC exactly once;
- no listed TOC path is missing;
- no blocking `C_TransmogCollection.UpdateUsableAppearances()` call exists;
- split-helper and scheduler guards remain green;
- Phase B, Phase C, Phase D, Phase E, cache, report, reroll, and weapon-index guards remain green;
- current metadata is exactly `1.10.0` with no prerelease suffix;
- Traveler is `SHARED_FRAMEWORK`;
- Zone, Class, and Echo are explicit `LEGACY` adapters;
- the Outfits UI has no direct generation-worker calls.
