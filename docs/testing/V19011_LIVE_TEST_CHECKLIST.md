# Quest Chronicle v1.9.0.11 Retail Live-Test Checklist

## Compatibility

```text
SavedVariables schema:  2
Courier format:         1
Wardrobe cache format:  7
Generation cache:       2
Diagnostic format:      1
Weapon index format:    1
```

Weapon index format 1 is an additive acceleration layer. No Quest Chronicle database or wardrobe-cache reset is expected.

## Installation

1. Exit World of Warcraft completely.
2. Back up `WTF/Account/<ACCOUNT>/SavedVariables/QuestChronicle.lua`.
3. Replace the existing `QuestChronicle` addon folder with the folder from `QuestChronicle-v1.9.0.11.zip`.
4. Launch Retail and confirm `/qc status` reports `1.9.0.11`.
5. Open `/qc debug` and keep verbose performance details enabled.

## Support-reroll sequence

```text
1. Hide Shoulders
2. Hide Tabard
3. Traveler Generate Outfit
4. Reroll Unlocked
5. Reroll Head
6. Reroll Back
7. Reroll Hands
8. Lock Back
9. Reroll Head
10. Reroll Waist
11. /reload
12. Immediately reroll Head
13. Reroll Hands
14. Reroll Waist
```

For every support-only reroll, verify:

- `Synchronous launch preparation` remains below `2.0 ms`.
- No diagnostic substage reaches `4.0 ms`.
- No eligibility call reaches `4.0 ms`.
- No cooperative worker slice reaches `8.0 ms`.
- The old `Reroll diagnostic foundation` phase does not appear.
- Decomposed identity, anchor-summary, state-materialization, style-context, eligibility-context, support-summary, and cache-summary phases appear.
- Candidate preparation remains at or below 32 and the final shortlist remains at or below six.
- Only the requested support slot changes.
- Profile ID and profile source remain stable inside the current anchor lineage.
- Profile adjustment remains `+0.00` and budget reconciliation passes.
- Hidden Shoulders remain absent from active relationship endpoints.
- Head reports `Chest identity support` and Back reports `Chest silhouette support` while Shoulders are hidden.
- Locked Back remains locked.

## Weapon-index sequence

```text
15. Generate Outfit with a cold or invalidated weapon index
16. Copy the report
17. Generate Outfit again
18. Copy the report
19. Trigger a natural collection or metadata change if available
20. Generate Outfit again
21. Copy the report
```

Record the Weapon index line from each report:

- State and use classification
- Buckets available
- Sources examined
- Worker yields
- Builds, repairs, and warm reuses
- Invalidation reason, when present

Required behavior:

- Cold construction or repair is identified explicitly.
- No weapon-index call reaches `4.0 ms`.
- No worker slice reaches `8.0 ms`.
- The second generation reuses warm buckets rather than rebuilding them.
- A localized repair does not discard unrelated subtype buckets.
- Weapon route and appearance selections remain valid.

## Extended warmed sequence

Perform three additional Generate Outfit actions. Promotion requires:

```text
Zero individual calls at or above 8.0 ms
Zero worker slices at or above 8.0 ms
Zero severe warnings
No repeated complete weapon-index rebuild
No selection, profile, budget, lock, hidden-state, ancestry, or export regression
```

## Rollback

Until this checklist passes, the production fallback remains `QuestChronicle-v1.9.0.5.zip`.
