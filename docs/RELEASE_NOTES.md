# Quest Chronicle v1.5.1: Two-Hand Topology Fix

Version 1.5.1 corrects a live-client weapon-layout classification bug introduced with the v1.5.0 weapon-family controls.

## Fixed

- Equipped weapon topology now treats the item's `itemEquipLoc` as authoritative.
- `INVTYPE_2HWEAPON` always resolves to **Two-Hand**, even when Blizzard also reports the item as valid for a broad sword, axe, or mace transmog category.
- `INVTYPE_RANGED`, `INVTYPE_RANGEDRIGHT`, and `INVTYPE_THROWN` resolve to **Ranged**.
- `INVTYPE_WEAPON`, `INVTYPE_WEAPONMAINHAND`, and `INVTYPE_WEAPONOFFHAND` resolve to **One-Hand**.
- Shields and held-in-off-hand items resolve to **Off-Hand**.
- Transmog-category checks remain only as a fallback when WoW cannot provide an equipment location.
- Added the detected main-hand and off-hand equipment locations to the internal topology diagnostics.

## Root cause

`C_TransmogCollection.IsCategoryValidForItem()` answers whether an item belongs to an appearance category. A two-handed sword may therefore be valid for a broad sword category even though its equipped hand layout is unambiguously two-handed. v1.5.0 consulted that category answer before `itemEquipLoc`, causing some two-handed swords to satisfy both One-Hand and Two-Hand and then fall into the One-Hand fallback.

## Preserved

- SavedVariables schema 2.
- Courier format 1.
- Wardrobe cache format 6; no collection rescan is required.
- Existing weapon-family preferences and outfit concepts.
- Custom Set links and verification data.
- One automatic collection scan per login or `/reload`.
