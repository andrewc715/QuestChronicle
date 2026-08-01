# Quest Chronicle v0.7.0: Zone Style Engine

Version 0.7.0 makes the Outfit Workbench location-aware while keeping its output varied, preview-only, and subject to Blizzard's transmog rules.

## Three generation modes

- **Zone Native** gives the strongest weight to the current area's culture, climate, magic, materials, creatures, and visual motifs.
- **Traveler** favors weathered, rugged, expedition-ready appearances and uses the current zone as a lighter accent.
- **Class Fantasy** gives the strongest weight to iconic class themes and uses the current zone as a smaller accent.

The selected mode appears above the character preview and is remembered per character. Saved outfit concepts now include their selected style mode. Concepts saved by v0.6.0 through v0.6.2 have no style field, so they load normally and retain the workbench's current mode.

## Zone and subzone context

Quest Chronicle reads Blizzard's current map, zone, subzone, and parent-map names. The first curated Midnight profiles cover:

- Quel'Thalas, including Silvermoon, Eversong, the Ghostlands, and Sunwell areas;
- the Amani Highlands and Zul'Aman;
- Harandar and its rootways;
- the Voidstorm and its void-touched regions.

Additional profiles cover Hallowfall, Khaz Algar, the Dragon Isles, kaldorei regions, Zandalar, Kul Tiras, Pandaria, Northrend, Outland, the Shadowlands, human kingdoms, orcish frontiers, and Forsaken marches. Unknown areas use the broad **Azeroth Adventurer** profile.

## Weighted appearance scoring

Generation is intentionally weighted rather than deterministic. Quest Chronicle scores names and item metadata already available from WoW, adds mode-specific and class-specific affinities, and retains a stable identity-based affinity for appearances whose item data has not loaded. Missing item data is requested for later generations.

Weapon scoring only orders candidates. Every generated or rerolled weapon must still pass the v0.6.1 equipped-item category, usability, character-display, valid-source, and hand-slot checks before it can enter the preview.

## Automatic suggestions

Entering a different zone or curated profile creates a Zone Native suggestion, posts a concise chat notice, and marks the **Outfits** tab with an asterisk. Opening Outfits acknowledges the notice. Generating in Zone Native mode consumes the suggestion.

Suggestions are non-destructive: they never overwrite the current preview, unlock a slot, change a hidden slot, apply transmog, spend gold, or modify a Blizzard outfit.

## Compatibility

- Wardrobe cache format 5; no collection rescan is required.
- Existing preview selections, locks, hidden slots, and outfit concepts remain compatible.
- SavedVariables schema 2 is preserved.
- Courier format 1 and Courier v1.0.0 compatibility are preserved.
- Quest history, active quests, notes, drafts, settings, and Courier snapshots are unchanged.
