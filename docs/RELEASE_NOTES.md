# Quest Chronicle v1.6.7: Linked Weapon Option-Owner Repair

Version 1.6.7 fixes the remaining Fury Warrior case where Quest Chronicle correctly recognized **Dual two-handed weapons equipped**, allowed one-handed appearances, and generated a one-handed Main Hand, but left the Secondary Hand on its physically equipped two-handed weapon.

## What the live evidence proved

The topology label was already correct. Quest Chronicle knew that both physical weapon hands contained two-handed weapons.

The decisive evidence was the Current Preview manifest:

- `One-Hand` was `Selected`;
- `Off-Hand` remained `Equipped`.

That means the problem occurred before model rendering. Quest Chronicle never committed a generated `OFF_HAND` selection.

## Root cause

Blizzard models certain weapon slots as a linked primary/secondary pair.

The primary slot owns the weapon-option dropdown. Blizzard then uses the option selected on the primary slot when it resolves the linked secondary appearance. The secondary slot does not necessarily expose the complete option list independently.

Quest Chronicle v1.6.6 asked each hand for its own option list. In the live Fury case:

- Main Hand exposed the one-handed appearance option;
- Secondary Hand independently exposed only the equipped two-handed option;
- the one-handed secondary appearance was rejected before linked generation ran.

## Changes

- Uses `C_TransmogOutfitInfo.GetLinkedSlotInfo()` to identify linked primary and secondary weapon slots.
- Fetches equipped, standard, and artifact weapon options from the linked **primary** slot.
- Tests those shared options against the actual requested target slot through `GetCollectionInfoForSlotAndOption()`.
- Records the primary option-owner slot and linked-secondary target in capability diagnostics.
- Treats Blizzard's linked slot-and-option permission as authoritative during generated-source validation.
- Improves subtype tooltips so a linked secondary permission explains that it was granted through the primary hand's weapon option.
- Preserves strict linked generation:
  - exact same visual first;
  - same exact subtype second;
  - no unrelated weapon fallback.
- Does not modify the stable synchronous character-preview path restored in v1.6.5.

## Expected Fury behavior

With two physical two-handed weapons equipped, One-Hand enabled, Two-Hand disabled, One-Handed Sword selected, and Link weapon hands enabled:

- topology remains `Dual two-handed weapons equipped`;
- Main Hand and Secondary Hand both resolve the one-handed option owned by the linked primary slot;
- generation writes both `ONE_HAND` and `OFF_HAND` selections;
- Current Preview lists both weapon entries as `Selected`;
- the embedded model receives targeted Main Hand and Secondary Hand preview calls.

A character whose linked primary slot exposes only a two-handed option remains restricted to Two-Hand appearances.

## Compatibility

- SavedVariables schema remains 2.
- Courier format remains 1.
- Wardrobe cache format remains 6.
- No wardrobe rescan, concept migration, or Custom Set rebuild is required.
- Existing concepts, Custom Set links, Chronicle records, RP notes, settings, and Courier data remain intact.
