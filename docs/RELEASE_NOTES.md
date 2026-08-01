# Quest Chronicle v1.6.8: Inventory Slot Enum Repair

Version 1.6.8 repairs the weapon-rule lookup at the boundary between WoW's traditional inventory slot IDs and the new Transmog Outfit API.

## Root cause

`GetInventorySlotInfo()` returns 1-based equipment slot IDs such as Main Hand 16 and Off Hand 17. `C_TransmogOutfitInfo.GetTransmogOutfitSlotFromInventorySlot()` accepts the zero-based `Enum.InventorySlots` values, where Main Hand is 15 and Off Hand is 16.

Quest Chronicle passed 16 and 17 directly. Its native rule queries were therefore shifted one equipment slot:

- the Main Hand query addressed the Off Hand slot;
- the Off Hand query addressed the Ranged slot.

Physical topology still displayed correctly because it uses the ordinary equipped-item APIs. The shifted native slot lookup only affected appearance permission and selection, which is why the UI correctly said `Dual two-handed weapons equipped` while linked one-hand generation never wrote `OFF_HAND`.

## Changes

- Converts the 1-based `INVSLOT_*` value to the zero-based `InventorySlots` enum before resolving a Transmog Outfit slot.
- Uses the linked primary outfit slot when checking collection-category permission for a linked secondary weapon.
- Keeps the secondary outfit slot for its actual selected appearance and manifest entry.
- Adds `/qc weapon debug` to print the live inventory-slot conversion, resolved outfit slots, option owners, available subtypes, and current weapon selections.
- Leaves the stable synchronous preview code from v1.6.5 untouched.

## Compatibility

- SavedVariables schema remains 2.
- Courier format remains 1.
- Wardrobe cache format remains 6.
- No wardrobe rescan, concept migration, or Custom Set rebuild is required.
