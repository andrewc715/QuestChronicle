# Quest Chronicle v1.6.1: Fury Appearance Permission Fix

Version 1.6.1 fixes the Fury Warrior exception introduced with Midnight's Single-Minded Fury transmog rule.

## The problem

Quest Chronicle v1.6.0 correctly detected a Fury Warrior's physical layout as dual two-handed weapons, but it used `C_TransmogCollection.IsCategoryValidForItem()` as the final appearance-family permission check. That older item-category query did not expose Fury's new ability to place ordinary one-handed appearances over equipped two-handed weapons.

The result was a contradictory interface:

- physical layout: **Dual two-handed weapons equipped**;
- Two-Hand types: correctly available;
- ordinary One-Hand types: incorrectly unavailable;
- Paired Artifact: sometimes the only surviving One-Hand category.

## The fix

Quest Chronicle now mirrors Blizzard's native Transmog weapon-category dropdown.

For each equipped hand and each weapon category it resolves:

1. the native `TransmogOutfitSlot` for the inventory hand;
2. the currently equipped `TransmogOutfitSlotOption`;
3. `C_TransmogOutfitInfo.GetCollectionInfoForSlotAndOption(slot, option, category)`.

Blizzard's own Transmog UI treats a returned `collectionInfo.isWeapon` as the authoritative answer for whether a category belongs in that hand's weapon dropdown. This is the rule layer that includes Fury's Single-Minded Fury exception and other current slot/option-specific behavior.

`IsCategoryValidForItem()` remains only as a compatibility fallback on clients where the newer outfit-slot API is unavailable.

## Generation and validation

The same native slot/option permission check now governs:

- family checkbox availability;
- exact subtype flyouts;
- weapon appearance browsing;
- Generate Outfit;
- Reroll Unlocked;
- Reroll Slot;
- locked-weapon validation.

This prevents the UI from enabling a Fury one-handed category and then rejecting it later during generation.

## Expected Fury result

With dual two-handed weapons equipped, Blizzard should now determine the exact allowed categories. A typical Fury result is:

- One-Hand enabled for the one-handed categories Blizzard exposes;
- Two-Hand enabled;
- Ranged disabled;
- Off-Hand shield/focus disabled;
- each weapon hand validated independently.

Quest Chronicle does not hardcode a Fury category list. Blizzard remains the authority, so future class, specialization, or weapon-option exceptions can flow through the same API.

## Compatibility

- Addon version: `1.6.1`
- SavedVariables schema: `2`
- Courier format: `1`
- Wardrobe cache format: `6`

No collection rescan or concept migration is required.
