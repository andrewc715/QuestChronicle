# Quest Chronicle v1.5.0: Weapon Generation Families

Version 1.5.0 turns weapon selection into a first-class part of the Outfits workbench.

## Added

- Four independent generation checkboxes:
  - One-Hand
  - Two-Hand
  - Ranged
  - Off-Hand
- Equipment-topology detection using the currently equipped main-hand and off-hand items.
- Live recalculation after `PLAYER_EQUIPMENT_CHANGED`.
- Dynamic tooltips explaining why each weapon family is available or unavailable.
- Weapon-family preferences stored with every Quest Chronicle outfit concept.
- Weapon-family summaries in the Outfit Concepts list.
- Support for selecting any subset of compatible families when no main-hand weapon is equipped.

## Weapon topology rules

- **Two-handed melee, staff, or polearm:** Two-Hand only.
- **Bow, crossbow, or gun:** Ranged only.
- **One-hand with an empty off-hand:** One-Hand only.
- **One-hand with shield or focus:** One-Hand, with Off-Hand independently optional.
- **Dual wield:** One-Hand generates both hands; the separate Off-Hand pool is unavailable.
- **No main-hand weapon:** any cached main family may be checked; Off-Hand requires One-Hand.

Unchecked or incompatible families cannot be selected by Generate Outfit or Reroll Unlocked. A locked weapon that conflicts with the checkbox pool produces a clear error instead of silently changing topology.

## Preserved

- SavedVariables schema 2.
- Courier format 1.
- Wardrobe cache format 6, so no collection rescan is required solely for this update.
- Existing concepts migrate with all four weapon families enabled, matching earlier behavior before topology filtering.
- Custom Set creation, verification, and authoritative Quest Chronicle concept backups.
- One automatic wardrobe refresh per login or `/reload`; later changes only mark the cache stale.
