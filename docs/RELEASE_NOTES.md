# Quest Chronicle v1.0.1: Custom Sets Integration

Version 1.0.1 removes the protected native Outfit-slot workflow and replaces it with Blizzard Custom Sets integration.

## Fixed

- Ordinary **Save / Update** now saves only the Quest Chronicle concept.
- Removed the `C_TransmogOutfitInfo` staging, clear, commit, and Outfit-slot creation pipeline that triggered `ADDON_ACTION_FORBIDDEN`.
- Removed obsolete `blizzardOutfitID`, native Outfit name/icon, pending state, timestamps, and errors during concept migration.

## Added

- Dedicated **Save to Custom Sets** action.
- The action changes to **Update Custom Set** after a concept is linked.
- **Save as New** creates a separate Blizzard Custom Set.
- **Replace Existing** opens a native Custom Set picker and replaces the chosen recipe.
- Replacement saves preserve up to five internal backups of the overwritten Custom Set data inside the Quest Chronicle concept.
- List-capacity, name, combat, and API validation.
- Save verification through `GetCustomSetItemTransmogInfoList`.
- `TRANSMOG_CUSTOM_SETS_CHANGED` handling, with a timeout verification fallback.

## Authority and safety

Quest Chronicle concepts remain the authoritative record. Exporting to Custom Sets never applies a transmog, spends gold, changes paid Outfit slots, or deletes a native Custom Set when a Quest Chronicle concept is deleted.

## Compatibility

- SavedVariables schema remains 2.
- Courier format remains 1.
- Wardrobe cache remains 5.
- Existing concepts, Chronicle history, RP notes, active quests, generated looks, locks, hidden slots, and zone preferences are preserved.
