# Quest Chronicle v1.6.3: Linked Weapon Preview Slot Fix

Version 1.6.3 repairs the remaining live-client failure in **Link weapon hands** for slot-based weapon transmog exceptions such as Fury Warrior.

## What the screenshots revealed

v1.6.2 correctly generated and stored a linked one-handed sword for the secondary hand, but the embedded model continued showing the physically equipped two-handed off-hand weapon. The problem was no longer generation. It was the final model handoff.

`DressUpModel:TryOn(sourceID, "SECONDARYHANDSLOT")` can return success while leaving the existing secondary-hand visual untouched when the equipped weapon and selected appearance use Blizzard's special slot-based compatibility rules.

## Fixed

- Weapon previews now use `DressUpModel:SetItemTransmogInfo()` with the actual Main Hand or Secondary Hand inventory slot.
- Main Hand is applied before Secondary Hand.
- Secondary Hand uses child-item isolation so it cannot inherit or preserve the equipped two-handed relationship.
- The equipped weapon visual is cleared before an explicit generated weapon is assigned, preventing silent no-op previews from looking successful.
- The resulting model slot is verified through `GetItemTransmogInfo()` when available.
- `TryOn()` remains only as a compatibility fallback and is also verified.
- Preview failures now identify the exact slot WoW refused instead of reporting only a generic count.

## Link behavior retained

- Exact same visual in both hands when Blizzard permits it.
- Another appearance from the same exact subtype only when the visual cannot be duplicated.
- No unrelated weapon family or subtype fallback.
- The second hand remains unchanged only when no valid linked selection exists before previewing.

## Compatibility

- SavedVariables schema remains 2.
- Courier format remains 1.
- Wardrobe cache format remains 6.
- No collection rescan, concept migration, or Custom Set rebuild is required.
