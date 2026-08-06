# Quest Chronicle v1.10.0 Live Validation Steps

## Before installing

1. Exit World of Warcraft completely.
2. Back up the existing `QuestChronicle` addon folder and `QuestChronicle.lua` SavedVariables.
3. Replace the addon folder with the `QuestChronicle` folder from `QuestChronicle-v1.10.0.zip`.
4. Confirm the folder is named exactly `QuestChronicle`.
5. Launch Retail and enable Quest Chronicle.

No cache reset, SavedVariables deletion, or collection rescan is expected.

## Test 1: version and existing state

1. Open Quest Chronicle with `/qc`.
2. Confirm version `1.10.0` appears in the interface or addon list.
3. Confirm the previously selected mode, preview, locks, hidden slots, concepts, and report history load normally.
4. Confirm no Lua error appears at login or when opening Outfits.

## Test 2: Traveler shared framework

Select **Traveler** and perform, in order:

```text
Generate Outfit
Generate Outfit
Reroll Unlocked
Reroll one visible unlocked support slot, such as Waist, Hands, Feet, Head, Back, Wrists, Shirt, or Tabard
```

After each action:

1. Open Debug History and inspect the newest report.
2. Confirm `Generation implementation: SHARED_FRAMEWORK`.
3. Confirm the action completed once and produced one report.
4. Confirm legal Main Hand and Off Hand appearances.
5. Confirm locked slots stayed unchanged.
6. Confirm hidden slots stayed hidden.
7. Confirm `Fallback: None` unless the context genuinely requires a documented fallback.
8. Confirm Phase D is `CLEAN`, `REPAIRED`, `LOCKED_OVERRIDE`, or `ALTERNATE_SKELETON`, never an unexplained failure.
9. For the support reroll, confirm only the requested support slot changed and the anchor skeleton was reused.

## Test 3: scheduler and performance

For each Traveler report, confirm:

```text
No repeated worker slice above 8 ms
No individual shared-framework call above 8 ms
Post-expensive continuations: 0
No synchronous launch stall
No repeated phase
```

Wall-clock duration may vary with cold metadata and collection size. Report any repeatable phase or call above 8 ms with the copied Debug report.

## Test 4: curated visual spot checks

Use the appearance browser or `/qc traveler debug` while the relevant visual is selected or present.

Confirm:

```text
Rugged Plate Vest
palette blue 45%, steel 35%, dark 20%
finish weathered 60%, plain 40%
visual ID 1139

Expedition Defender's Shoulders
palette green 70%, steel 30%
finish military 80%, polished 20%
visual ID 5237

Orcish Scout Boots
palette dark 70%, blue 20%, steel 10%
finish plain 75%, polished 25%
visual ID 12877
```

Orcish Scout Boots must not contain green.

## Test 5: legacy modes

Generate one outfit in each mode:

```text
Zone Native
Class Fantasy
Chronicle Echo
```

For each newest Debug report:

1. Confirm `Generation implementation: LEGACY`.
2. Confirm the mode label is correct.
3. Confirm the existing mode behavior and controls remain familiar.
4. Confirm no Traveler policy error or shared-policy fallback appears.
5. Confirm legal weapons, locks, hidden slots, and preview commit still work.

## Test 6: tuning audit

Run:

```text
/qc traveler tuning clear confirm
/qc traveler tuning start
```

Perform one successful Traveler Generate Outfit action, then run:

```text
/qc traveler tuning status
/qc traveler tuning stop
```

Expected:

```text
Completed Traveler actions: 1
Collection errors: 0
```

## Test 7: reload persistence

1. Select Traveler.
2. Generate an outfit and leave it visible.
3. Use `/reload`.
4. Confirm mode selection and preview persistence behave as in v1.9.0.15.
5. Confirm report history remains available.
6. Confirm no wardrobe-cache reset occurs.
7. Confirm the first post-reload weapon-index report retains `LOGIN_SESSION_RESET` during cold or partial construction and later warm reuse reports `NONE`.

## Report back

Provide:

- whether every test passed;
- copied Debug reports for the four Traveler actions;
- one Debug report from each legacy mode;
- any Lua errors;
- any repeatable slice or individual call above 8 ms;
- the tuning-audit status output.
