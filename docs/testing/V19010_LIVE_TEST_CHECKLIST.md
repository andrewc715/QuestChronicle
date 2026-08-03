# Quest Chronicle v1.9.0.10 Retail Live-Test Checklist

## Compatibility

```text
SavedVariables schema:  2
Courier format:         1
Wardrobe cache format:  7
Generation cache:       2
Diagnostic format:      1
```

No database or cache reset is expected.

## Installation

1. Exit World of Warcraft completely.
2. Back up `WTF/Account/<ACCOUNT>/SavedVariables/QuestChronicle.lua`.
3. Replace the existing `QuestChronicle` addon folder with the folder from `QuestChronicle-v1.9.0.10.zip`.
4. Launch Retail and confirm `/qc status` reports `1.9.0.10`.
5. Open `/qc debug` and leave verbose performance details enabled.

## Required sequence

```text
1. Hide Shoulders
2. Hide Tabard
3. Traveler Generate Outfit
4. Reroll Unlocked
5. Reroll Waist
6. Reroll Head
7. Reroll Back
8. Reroll Hands
9. Lock Back
10. Reroll Head
11. Reroll Hands
12. /reload
13. Immediately reroll Head
14. Reroll Waist
15. Generate Outfit
16. Reroll Head
17. Generate Outfit again
18. Copy all reports
```

## Support-reroll acceptance

For every support-only reroll, verify:

- `Synchronous launch preparation` remains below `8.0 ms`.
- `Longest cooperative worker slice` remains below `8.0 ms` preferred.
- `Largest cooperative call` remains below `8.0 ms`.
- The Performance table contains `Reroll launch manifest`, `Reroll anchor snapshot reuse`, `Reroll state materialization`, and `Reroll diagnostic foundation`.
- The legacy `Reroll state capture` phase does not appear.
- Candidate preparation is at most 32 and the final shortlist is at most six.
- Only the requested support slot changes.
- Profile ID and profile source remain stable inside the current anchor lineage.
- Profile adjustment remains `+0.00` and budget reconciliation passes.
- Hidden Shoulders remain excluded from the active-anchor mask and relationship endpoints.
- With Shoulders hidden, Head reports `Chest identity support` and Back reports `Chest silhouette support`.
- Locked Back remains locked and is never mislabeled as merely Context Fixed.

## Post-reload decisive gate

The immediate post-reload Head reroll must show:

```text
Synchronous launch preparation: <8.0 ms
Profile phase: Reused
Profile adjustment: +0.00
Shoulders: Hidden
Role: Chest identity support
```

The reroll must not repeat the `8.4 ms` or `9.5 ms` synchronous preparation spikes observed in v1.9.0.9.

## Full-generation watch

For the two warmed Generate Outfit actions, record:

- total duration and frames;
- longest worker slice;
- largest instrumented call;
- support-beam maximum call;
- weapon-context maximum call;
- era-source checks, cache additions, and invalidations.

A single worker slice slightly above 8 ms remains a watch item. Repeated warmed instrumented calls above 8 ms or any call above 12 ms require investigation.

## Promotion rule

Promote v1.9.0.10 only when all support-reroll gates pass, no hidden anchor enters role text or scoring, budget reconciliation remains exact, and warmed full-generation behavior shows no material regression.

Rollback package: `QuestChronicle-v1.9.0.5.zip`.
