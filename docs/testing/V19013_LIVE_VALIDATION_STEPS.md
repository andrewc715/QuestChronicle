# Quest Chronicle v1.9.0.13 Live Validation Steps

## Purpose

This release changes only weapon candidate-index invalidation diagnostics. Live validation must confirm that the correct lifecycle reason appears for cold, partial, repaired, and warm actions while v1.9.0.12 selection, scoring, routing, locking, and scheduler behavior remains unchanged.

## Installation

1. Exit World of Warcraft completely.
2. Replace the existing `QuestChronicle` addon folder with the folder from `QuestChronicle-v1.9.0.13.zip`.
3. Do **not** delete `QuestChronicleDB`, the wardrobe cache, or the persistent generation cache.
4. Launch Retail WoW.
5. Run `/qc status` and confirm the addon reports `1.9.0.13`.
6. Allow the automatic login wardrobe refresh to finish before beginning the test sequence.
7. Open `/qc debug` and clear only the diagnostic report history when a clean report sequence is useful.

## Test state

Use the same character and outfit settings used to validate v1.9.0.12 whenever possible.

Recommended state:

- Traveler mode.
- Hide Shoulders.
- Hide Tabard.
- Leave the remaining support slots visible.
- Keep one visible support slot unlocked for the preservation spot-check.

Record the character's specialization and equipped weapon layout before testing.

## Test 1: Post-reload index lifecycle

Immediately after the automatic login wardrobe refresh:

1. Select **Generate Outfit**.
2. Copy the completed Debug report.
3. Select **Generate Outfit** again.
4. Copy the completed Debug report.
5. Select **Generate Outfit** a third time.
6. Copy the completed Debug report.

The exact number of cold-session builds depends on which weapon subtype buckets the character requires.

### Required cold result

The first action that constructs a weapon-index bucket must report:

```text
Weapon index use: COLD_BUILD
Weapon index invalidation: LOGIN_SESSION_RESET
At least 1 bucket built
```

### Required partial result, when another bucket is needed

A later action that constructs another bucket from the same post-login index lifecycle must report:

```text
Weapon index use: PARTIAL_BUILD
Weapon index invalidation: LOGIN_SESSION_RESET
At least 1 additional bucket built
```

A warm action may occur between the cold and partial builds. That warm action must not erase the pending lifecycle cause for a later missing bucket.

### Required warm result

An action whose requested buckets are already valid must report:

```text
Weapon index use: WARM_REUSE
Weapon index invalidation: NONE
Buckets built: 0
Buckets repaired: 0
Candidates examined this action: 0
```

A character whose first action constructs every required bucket may move directly from `COLD_BUILD` to `WARM_REUSE`. That is valid as long as the cold action reports `LOGIN_SESSION_RESET` and the warm action reports `NONE`.

## Test 2: Manual wardrobe-cache replacement

1. Open Quest Chronicle's maintenance controls.
2. Select **Scan Collection**.
3. Allow the scan to finish completely.
4. Select **Generate Outfit**.
5. Copy the completed Debug report.

The first weapon-index construction after the manual scan must report:

```text
Weapon index use: COLD_BUILD
Weapon index invalidation: WARDROBE_CACHE_REPLACED
```

A later missing bucket may report `PARTIAL_BUILD`, but it must retain `WARDROBE_CACHE_REPLACED` until that bucket is constructed. Fully warm reuse must return to `NONE`.

## Test 3: Character capability transition

1. Change one weapon capability input:
   - switch specialization;
   - change the equipped weapon layout; or
   - change the active talent configuration.
2. Wait one second for WoW's equipment and talent events to settle.
3. Select **Generate Outfit**.
4. Copy the completed Debug report.

When the affected weapon index is rebuilt, the report must contain:

```text
Weapon index invalidation: CHARACTER_CAPABILITY_CHANGED
```

A following fully warm action must report:

```text
Weapon index invalidation: NONE
```

Restore the original specialization, talents, and equipment after this test when desired.

## Test 4: Warm preservation spot-check

With the index warm:

1. Select **Reroll Unlocked** and copy the report.
2. Reroll one visible support slot, preferably Head or Hands, and copy the report.
3. Lock a different visible support slot.
4. Reroll the first support slot again and copy the report.

Verify:

```text
Only the requested or unlocked slots change
Hidden Shoulders remain hidden
Hidden Tabard remains hidden
The locked support slot remains unchanged and is labeled Locked
Budget reconciliation: Pass
Fallback: None
No duplicate or partial report is committed
Longest cooperative worker slice remains below 8 ms
Largest individual instrumented call remains below 8 ms
Post-expensive-call continuations: 0
```

The selected appearances, scores, weapon routes, profile result, and scheduler counters should remain consistent with v1.9.0.12 for equivalent state and seed.

## Warning gate

Across every normal report in this checklist, verify:

```text
No UNKNOWN_WEAPON_INDEX_INVALIDATION warning
No Weapon index invalidation: UNKNOWN
No Weapon index invalidation: UNSPECIFIED
```

`UNKNOWN` is reserved for a deliberately invoked internal or debug invalidation that supplied no recognized reason. Ordinary gameplay must not produce it.

## Promotion criteria

v1.9.0.13 is ready to replace v1.9.0.12 as the live-validated baseline only when:

1. Cold post-login construction reports `LOGIN_SESSION_RESET`.
2. Any later post-login partial construction retains `LOGIN_SESSION_RESET`.
3. Warm reuse reports `NONE`.
4. Manual Scan Collection reports `WARDROBE_CACHE_REPLACED` when construction occurs.
5. A specialization, equipment, or talent transition reports `CHARACTER_CAPABILITY_CHANGED` when construction occurs.
6. No normal action reports `UNKNOWN` or `UNSPECIFIED`.
7. No normal action raises `UNKNOWN_WEAPON_INDEX_INVALIDATION`.
8. Hidden, locked, selected, scored, routed, and scheduled behavior remains consistent with v1.9.0.12.
9. No new frame-budget, atomic-commit, or report-integrity regression appears.

## Reports to return

Please return the completed Debug reports for:

- the first post-login Generate Outfit;
- any post-login partial build;
- the first fully warm Generate Outfit;
- the first Generate Outfit after manual Scan Collection;
- the first Generate Outfit after the capability change;
- the following warm Generate Outfit;
- Reroll Unlocked;
- the two support-slot rerolls from the preservation spot-check.

When no partial build occurs, note that the character moved directly from cold construction to warm reuse.
