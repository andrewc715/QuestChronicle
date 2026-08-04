# Quest Chronicle v1.9.0.12 Retail Live-Test Checklist

## Installation

1. Exit World of Warcraft completely.
2. Replace the existing `QuestChronicle` addon folder with the folder from `QuestChronicle-v1.9.0.12.zip`.
3. Do not delete `QuestChronicleDB` or the wardrobe cache.
4. Launch Retail and confirm `/qc status` reports `1.9.0.12`.
5. Open `/qc debug` and clear only the diagnostic report history if a cleaner test sequence is desired.

## Initial state

- Traveler mode.
- Hide Shoulders.
- Hide Tabard.
- Leave all other support slots visible.
- Record whether the weapon index initially reports `LOGIN_SESSION_RESET`, partial readiness, or warm readiness.

## Support-reroll sequence

1. Generate Outfit.
2. Reroll Unlocked.
3. Reroll Head.
4. Reroll Back.
5. Reroll Hands.
6. Lock Back.
7. Reroll Head.
8. Reroll Waist.
9. `/reload`.
10. Immediately reroll Head.
11. Reroll Hands.
12. Reroll Waist.

For every support-only reroll verify:

```text
Synchronous launch preparation: below 2 ms
Cache scalar snapshot: below 1 ms
Largest individual call: below 8 ms
Longest cooperative worker slice: below 8 ms
Post-expensive-call continuations: 0
Prepared target candidates: at most 32
Final shortlist: at most 6
Profile phase: Reused
Profile adjustment: +0.00
Budget reconciliation: Pass
Anchor selection changed: No
```

Only the requested support slot may change. Hidden Shoulders and Tabard must remain hidden. A locked Back must remain unchanged and be labeled Locked rather than Context Fixed.

## Weapon-index sequence after reload

1. Generate Outfit and copy the report.
2. Generate Outfit again and copy the report.
3. Generate Outfit a third time and copy the report.

Expected progression:

```text
First action:
State before STALE or PARTIAL
Canonical invalidation reason, normally LOGIN_SESSION_RESET after reload
Explicit buckets built or repaired

Second action:
Explicit remaining build or warm reuse
Action-local counts separated from lifetime totals

Third action:
WARM_REUSE for already valid requested buckets
0 buckets built for reused buckets
0 candidates examined for fully reused buckets
```

No report should use `UNSPECIFIED` as the normal invalidation reason.

## Warm performance sequence

1. Reroll Head.
2. Reroll Hands.
3. Generate Outfit.
4. Generate Outfit again.

Promotion gates:

```text
No individual call at or above 8 ms
No worker slice at or above 8 ms
No severe warning
No post-expensive-call continuation
No repeated full weapon-index rebuild
No selection, profile, budget, lock, hidden-state, ancestry, or naming regression
```

Preferred action latency:

```text
Head, Hands, Waist: 0.8 sec or less
Back: 1.2 sec or less
Post-reload Head: 1.2 sec or less
```

A slower action may still be functionally acceptable when it contains legitimate cold metadata work, but call and slice limits are hard promotion gates.

## Report bundle to return

Copy the reports for:

- first Generate Outfit;
- Reroll Unlocked;
- Head, Back, Hands, and Waist rerolls;
- immediate post-reload Head reroll;
- all three post-reload weapon-index generations;
- final two warmed generations.
