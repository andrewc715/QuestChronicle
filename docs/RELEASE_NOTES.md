# Quest Chronicle v1.0.6: Deliberate Wardrobe Refreshes

Version 1.0.6 removes mid-session automatic wardrobe rescans. Quest Chronicle now refreshes the wardrobe exactly once after login or `/reload`, then leaves further refreshes under player control.

## New refresh policy

- The first `PLAYER_ENTERING_WORLD` event in a freshly loaded addon session schedules one wardrobe scan.
- Additional loading screens and zone transitions in the same session do not schedule another scan.
- `/reload` starts a new addon session, so it receives one new login scan.
- Learning, removing, or otherwise changing transmog appearances only marks the cache stale.
- Collection events never launch a background rescan.
- **Scan Collection** remains available for deliberate manual refreshes at any time.

## UI

When WoW reports a collection change after the most recent scan, the Outfits header displays:

```text
Collection may be stale    [Scan Collection]
```

The warning disappears after a successful manual scan or the next login/reload scan. Its tooltip explains that Quest Chronicle intentionally does not refresh again automatically during the current session.

Status & Maintenance now reports **Collection may be stale** instead of implying that an automatic scan is queued.

## Settings

The old **Refresh the wardrobe after collection changes** setting has been retired because collection events no longer trigger scans. The remaining wardrobe-maintenance chat setting now applies to the one-time login scan, deferred login scans, and appearance-source recovery notices.

## Preserved

- SavedVariables schema 2.
- Courier format 1.
- Wardrobe cache format 6.
- Chronicle history, RP notes, active quests, outfit concepts, locks, hidden slots, source identities, and zone preferences.
- Linked and verified Blizzard Custom Sets.
- Minimap button and AddOn Compartment access.

No wardrobe cache migration or Custom Set resave is required.
