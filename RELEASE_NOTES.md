# Quest Chronicle v1.10.0

## Shared Generation Framework extraction

Quest Chronicle v1.10.0 extracts the live-validated Traveler generation orchestration into a shared, mode-neutral framework without changing Traveler's semantic results.

### Shared framework

- Adds one authoritative mode registry and policy contract.
- Routes Generate Outfit, Reroll Unlocked, contextual support rerolls, cancellation, and generation-state queries through `QuestChronicle.Generation`.
- Gives the shared layer ownership of action identity, lifecycle state, cooperative phase routing, candidate-phase routing, validation and alternate-skeleton routing, weapon-phase routing, atomic commit routing, contextual reroll lifecycle, and implementation diagnostics.
- Keeps the calibrated selection and scoring implementations behind explicit Traveler policy callbacks to preserve exact v1.9.0.15 behavior.
- Adds shared visual-language access for descriptors, pair cohesion, and curated metadata.

### Mode implementations

```text
Traveler        SHARED_FRAMEWORK
Zone Native     LEGACY
Class Fantasy   LEGACY
Chronicle Echo  LEGACY
```

The three legacy adapters preserve their existing results and controls. Missing or unsupported policies fail clearly rather than falling back to Traveler.

### Traveler parity

- Preserves anchor candidate identity, beam results, novelty, quality windows, and weighted choice.
- Preserves contextual support profiles, role scoring, beam search, mismatch budgets, and target-isolated support rerolls.
- Preserves final validation, two-pass deterministic repair, and one alternate-skeleton limit.
- Preserves legal weapon bundles, linked-hand rules, locks, hidden slots, and atomic preview commit.
- Preserves scheduler budgets: 5.5 ms preferred, 7.5 ms soft ceiling, and 2.0 ms expensive-call force-yield threshold.
- Preserves all six curated descriptor corrections. Orcish Scout Boots remain dark 70%, blue 20%, steel 10%, and never green.

### Compatibility

No SavedVariables migration, cache reset, wardrobe rescan, or Courier update is required.

Retained formats:

```text
SavedVariables schema: 2
Courier format: 1
Wardrobe cache format: 7
Generation cache: 2
Diagnostic format: 1
Weapon-index format: 1
Traveler tuning audit format: 1
Curated tuning version: 1
```

### Deferred work

- Zone generation policy rewrite begins in v1.11.0.
- Class generation policy rewrite begins in v1.12.0.
- Echo generation policy rewrite begins in v1.13.0.
- Legacy individual anchor and weapon-slot rerolls remain outside the extracted modern path.
- Moving Outfits into the Transmog window remains a later project.
