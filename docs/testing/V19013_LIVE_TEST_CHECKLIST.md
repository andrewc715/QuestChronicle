# Quest Chronicle v1.9.0.13 Retail Live-Test Checklist

## Installation

1. Exit World of Warcraft completely.
2. Replace the existing `QuestChronicle` addon folder with the folder from `QuestChronicle-v1.9.0.13.zip`.
3. Do not delete `QuestChronicleDB` or the wardrobe cache.
4. Launch Retail and confirm `/qc status` reports `1.9.0.13`.
5. Allow the automatic login wardrobe refresh to complete before the first generation.
6. Open `/qc debug` and clear only diagnostic report history if a clean sequence is desired.

## Required post-reload sequence

1. Generate Outfit and copy the report.
2. Generate Outfit again and copy the report.
3. Generate Outfit a third time and copy the report.

The reports should progress according to the buckets required by the character's weapon routes:

```text
Cold build:
Weapon index use: COLD_BUILD
Weapon index invalidation: LOGIN_SESSION_RESET
At least one bucket built

Additional cold-session bucket work, when needed:
Weapon index use: PARTIAL_BUILD
Weapon index invalidation: LOGIN_SESSION_RESET
At least one additional bucket built

Warm reuse:
Weapon index use: WARM_REUSE
Weapon index invalidation: NONE
0 buckets built
0 buckets repaired
0 candidates examined for fully reused buckets
```

A character whose first action constructs every required bucket may move directly from `COLD_BUILD` to `WARM_REUSE`. In that case the first report must use `LOGIN_SESSION_RESET` and the warm report must use `NONE`.

## Manual cache replacement

1. Use **Scan Collection** after the initial sequence.
2. Generate Outfit.
3. Copy the report.

Expected:

```text
Weapon index use: COLD_BUILD or PARTIAL_BUILD
Weapon index invalidation: WARDROBE_CACHE_REPLACED
```

## Character capability transition

1. Change specialization, equipped weapon layout, or active talent configuration.
2. Generate Outfit.
3. Copy the report.

Expected when the affected weapon bucket is rebuilt:

```text
Weapon index invalidation: CHARACTER_CAPABILITY_CHANGED
```

## Warning gate

Across all normal reports:

```text
No UNKNOWN_WEAPON_INDEX_INVALIDATION warning
No Weapon index invalidation: UNKNOWN
No Weapon index invalidation: UNSPECIFIED
```

`UNKNOWN` is acceptable only when deliberately exercising an internal or debug invalidation path that supplied no recognized reason.

## Preservation gates

For identical seeds and state, verify that v1.9.0.13 preserves v1.9.0.12 behavior:

```text
Same selected appearances
Same anchor and support scores
Same weapon routes and topology
Same profile and budget reconciliation
Same hidden and locked-slot behavior
Same scheduler counters and phase boundaries
Same atomic preview and report commit behavior
```

## Report bundle to return

Copy reports for:

- first post-reload Generate Outfit;
- any partial-build Generate Outfit;
- first fully warm Generate Outfit;
- first Generate Outfit after manual Scan Collection;
- first Generate Outfit after a specialization, equipment, or talent change;
- one final warm Generate Outfit.
