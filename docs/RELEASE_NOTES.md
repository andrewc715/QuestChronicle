# Quest Chronicle v1.6.2: Linked Weapon Hands Fix

Version 1.6.2 repairs the final coordination step in the Weapon Appearance Rules system.

## The problem

The v1.6.1 Fury permission fix correctly allowed one-handed appearances over equipped two-handed weapons. However, **Link weapon hands** only preferred the same broad family and exact subtype before falling back to any other legal second-hand type.

That allowed a generated main-hand one-handed sword to be paired with an unrelated two-handed axe even though linking was enabled.

## The corrected link contract

When two weapon hands are equipped and linking is enabled, Quest Chronicle now follows this strict order:

1. Use the exact same collapsed transmog visual in both hands when Blizzard permits it.
2. If the exact visual cannot be used in the second hand, choose another appearance from the same exact weapon subtype.
3. If neither is possible, retain the equipped second-hand appearance and report the limitation.

Quest Chronicle will no longer substitute an unrelated family or type while the hands are linked.

## Where the rule applies

The stricter link behavior now governs:

- Generate Outfit;
- Reroll Unlocked;
- main-hand Reroll Slot;
- manual main-hand appearance selection.

Independent weapon generation remains available by clearing **Link weapon hands**.

## Fury example

With dual two-handed weapons physically equipped, Fury may choose One-Handed Sword appearances when Blizzard permits them. If linking is enabled and the main hand receives a collected sword visual, Quest Chronicle attempts that same sword visual in the second hand.

If Blizzard rejects that exact visual for the second hand, Quest Chronicle may choose a different One-Handed Sword, but it will not switch to an axe, mace, staff, or another unrelated type.

## Compatibility

- Addon version: `1.6.2`
- SavedVariables schema: `2`
- Courier format: `1`
- Wardrobe cache format: `6`

No collection rescan, saved-concept migration, or Custom Set rebuild is required solely for this update.
