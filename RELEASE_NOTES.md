# Quest Chronicle v0.9.0: Era and Collection Polish

Version 0.9.0 finishes and hardens the progression, collection, recovery, performance, coverage, settings, and accessibility work already begun in v0.7 and v0.8.

## Expansion progression

- Generated outfits and rerolls continue to reject appearances introduced after the current zone's expansion.
- The rule is now an explicit default-on setting: **Restrict generated outfits to the zone's expansion**.
- The full manual appearance browser remains unrestricted.
- Local provenance still applies after the era check, so an expansion-valid Sunwell source does not become native to a launch-zone questing pool.

## Collection changes and recovery

- Appearance collection events are debounced into one automatic refresh instead of leaving a permanently dirty cache or starting repeated scans.
- Automatic refresh waits until combat ends and Blizzard's Wardrobe or Transmogrify windows are closed.
- Existing manual scan controls remain available.
- Preview selections and saved concepts now retain Blizzard's collapsed visual ID beside the representative source ID.
- When a scan selects a different compatible source for the same visual, Quest Chronicle rebinds the preview and concepts instead of dropping the appearance.
- Legacy selections and concepts gain visual identities from the existing cache without a format reset.

## Performance and diagnostics

- Repeated collection events share one quiet-window refresh.
- The scanner continues to yield between slots, stage its result, retry temporarily empty categories, and preserve a healthy cache after an impossible all-zero response.
- Scan duration, the last automatic refresh, and the last source-recovery result appear in the Outfits diagnostic tooltip.
- Status & Maintenance now shows wardrobe readiness and cached visual count.

## Zone coverage

- Adds local provenance throughout Classic Eastern Kingdoms and Kalimdor questing zones.
- Adds Cataclysm launch and patch zones.
- Fills Pandaria, Ashran, Nazjatar, Siren Isle, and K'aresh gaps.
- Adds renewed Eversong handling and retains Zul'Aman, Harandar, and Voidstorm coverage for Midnight.
- Adds broader Cataclysm, Draenor, Broken Isles, Nazjatar, Fourth War, Eastern Kingdoms, and Kalimdor style profiles.

## Settings and accessibility

WoW's **Options → AddOns → Quest Chronicle** category now includes:

- Restrict generated outfits to the zone's expansion;
- Refresh the wardrobe after collection changes;
- Recover changed appearance sources;
- Announce wardrobe maintenance in chat;
- High-contrast outfit states.

High contrast strengthens selected, zone-favorite, and zone-excluded row backgrounds. Written labels remain present, so state is never communicated by color alone.

## Compatibility

- SavedVariables schema 2 is preserved.
- Courier format 1 is preserved.
- Wardrobe cache format 5 is preserved.
- Existing history, caches, selections, concepts, locks, hidden slots, generated names, Chronicle Intelligence, favorites, and exclusions remain compatible.
- No mandatory collection rescan is required during upgrade.
- Preview only: no transmog is applied, no gold is spent, and no Blizzard outfit slot is changed.

See `ERA_COLLECTION_POLISH_V090_TEST_CHECKLIST.md` for the live verification pass.
