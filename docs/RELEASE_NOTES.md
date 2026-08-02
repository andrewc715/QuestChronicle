# Quest Chronicle v1.8.2: Heritage Armor Progression Rule

Version 1.8.2 adds race Heritage Armor to Quest Chronicle's progression restrictions while preserving the normalized v1.8 architecture and the validated v1.7.2 weapon-route behavior.

## New rule

Race Heritage Armor remains visible in the appearance browser and may be selected manually for preview, but automatic outfit generation excludes it while the character is below the maximum level currently reachable by the account.

At maximum level, Heritage Armor returns to the normal generation pipeline and must still pass the existing zone-era, provenance, promotion, coherence, weapon, and per-zone preference rules.

## Detection

Quest Chronicle identifies Heritage Armor through Blizzard's native transmog-set membership and `TransmogSetInfo` metadata. It checks a source's containing sets and recognizes Blizzard set labels, descriptions, or names that identify Heritage Armor. This avoids maintaining a fragile per-item list and allows future Heritage sets to participate when Blizzard classifies them consistently.

The current level cap is resolved through Blizzard's expansion-aware level APIs, preferring the maximum level reachable for the player's owned expansion and retaining current-max fallbacks for client compatibility.

## Browser feedback

Below max level, affected rows remain browseable and display:

```text
Heritage locked
```

Their tooltip explains the current and maximum levels and confirms that manual preview remains available.

## Preserved

- Every runtime Lua file remains at or below 500 lines.
- SavedVariables schema remains 2.
- Courier format remains 1.
- Wardrobe cache format remains 6.
- Weapon Appearance Routes are unchanged.
- Linked and unlinked Main Hand and Off Hand generation are unchanged.
- Existing concepts and linked Custom Sets require no migration or rebuild.
- No wardrobe rescan is required solely for this update.
