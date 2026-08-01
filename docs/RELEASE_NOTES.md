# Quest Chronicle v1.6.6: Weapon Option Matrix Repair

Version 1.6.6 is a root-cause repair for Fury Warrior one-handed appearance generation over physically equipped two-handed weapons.

## What the live screenshots proved

- Physical topology was correct: Xyrkian remained **Dual two-handed weapons equipped**.
- The Main Hand could generate a permitted one-handed appearance.
- The Secondary Hand remained on its equipped two-handed appearance.
- **Current Preview** confirmed this was not only a model-rendering defect: Main Hand was `Selected`, while Off-Hand was still `Equipped`.
- Two-handed appearance generation continued to select both hands correctly.

That combination isolated the defect to secondary-hand permission discovery rather than source linking or model dressing.

## Root cause

Quest Chronicle asked Blizzard for the currently equipped weapon option through `GetEquippedSlotOptionFromTransmogSlot()`, then checked appearance categories only against that one option.

Blizzard's native Transmog interface uses a broader model:

1. `GetWeaponOptionsForSlot()` returns every enabled standard and artifact editing option for the hand.
2. The equipped option is only the preferred default in the dropdown.
3. `GetCollectionInfoForSlotAndOption()` decides which categories are valid for each selected option.

For Fury, the physical item can remain a two-handed weapon while a separate enabled **One-Handed Weapon** option permits one-handed appearances. Checking only the equipped two-hand option caused the second hand to reject the one-hand family before linked generation could run.

## Changes

- Replaces the single equipped-option permission check with a complete per-hand weapon-option matrix.
- Enumerates all enabled standard and artifact options returned by Blizzard for Main Hand and Secondary Hand.
- Checks every selected appearance category against every enabled option for that hand.
- Prefers the equipped option first for stable ordinary behavior, but no longer treats it as the complete permission set.
- Records the exact Blizzard option that granted each subtype, including its native name.
- Uses that resolved option consistently for:
  - family availability;
  - subtype flyouts;
  - generation;
  - linked secondary-hand generation;
  - browser filtering;
  - rerolls;
  - locked-weapon validation.
- Preserves the stable synchronous preview path restored in v1.6.5.
- Keeps the existing strict linked-hand ladder: same visual first, same exact subtype second, no unrelated fallback.
- Improves subtype tooltips so they identify the Blizzard weapon option granting permission, or report how many enabled options rejected it.

## Expected Fury behavior

With two two-handed weapons physically equipped, **One-Hand** enabled, **Two-Hand** disabled, **One-Handed Sword** selected, and **Link weapon hands** enabled:

- the physical-topology label remains `Dual two-handed weapons equipped`;
- Main Hand resolves One-Handed Sword through Blizzard's enabled one-hand option;
- Secondary Hand independently resolves the same one-hand option;
- generation writes both `ONE_HAND` and `OFF_HAND` selections;
- Current Preview lists both weapons as `Selected`;
- the model receives targeted `TryOn()` calls for `MAINHANDSLOT` and `SECONDARYHANDSLOT`.

A non-Fury two-handed layout that exposes only the two-hand option remains Two-Hand only.

## Compatibility

- SavedVariables schema remains 2.
- Courier format remains 1.
- Wardrobe cache format remains 6.
- No wardrobe scan, concept migration, or Custom Set rebuild is required solely for this update.
- Existing concepts, linked Custom Sets, Chronicle records, RP notes, settings, and Courier data remain intact.
