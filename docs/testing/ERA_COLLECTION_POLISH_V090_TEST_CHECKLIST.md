# Quest Chronicle v0.9.0 Live Test Checklist

## Upgrade and compatibility

1. Exit WoW completely and install v0.9.0 over the existing QuestChronicle folder.
2. Launch the same character used with v0.8.1 and run `/qc`.
3. Confirm Chronicle history, active quests, notes, the wardrobe browser, current preview, locks, hidden slots, concepts, generated names, favorites, and exclusions remain present.
4. Confirm the Outfits tab does not demand a new scan solely because of the version update.
5. Open Status & Maintenance and confirm it reports **Quest Chronicle 0.9.0**, **Schema 2**, **Courier format 1**, and the wardrobe state.

## Expansion progression

1. Enter a Classic launch zone such as Westfall or The Barrens.
2. Generate and reroll several outfits in each style mode.
3. Hover browser rows and confirm later-expansion appearances say they are excluded from generation while remaining manually previewable.
4. Enter Blade's Edge Mountains and confirm the restriction line says **Through TBC** with the local source pool.
5. Confirm Wrath and later items are not generated and Sunwell sources are not treated as Blade's Edge sources.
6. In **Options → AddOns → Quest Chronicle**, disable **Restrict generated outfits to the zone's expansion** and confirm the restriction line changes to **Zone era limit off**.
7. Re-enable the setting for the remaining tests.

## Collection-change refresh

1. Start from a completed, healthy wardrobe scan.
2. Learn a new appearance or otherwise trigger a transmog collection update.
3. Confirm the Outfits status says **automatic refresh queued** and that one scan begins after the short quiet period.
4. Trigger several collection changes close together and confirm they produce one refresh, not one scan per event.
5. Repeat while in combat; confirm no scan begins until combat ends.
6. Repeat with Blizzard's Wardrobe or Transmogrify window open; confirm Quest Chronicle waits or defers without changing Blizzard's filters.
7. Confirm a completed automatic refresh prints one concise chat notice when announcements are enabled.

## Missing-appearance recovery

1. Build a preview with selections in several slots and save it as a concept.
2. Rescan the collection and confirm the current preview and saved concept retain the same visuals.
3. Hover the collection diagnostic line and confirm **Last recovery** is present after a successful scan.
4. If a game update changes the representative source for a collected visual, confirm the concept loads that same visual and reports the recovered source instead of skipping it.
5. Disable **Recover changed appearance sources**, rescan only for comparison, then re-enable it.

## Performance and cache safety

1. Run a full manual scan and confirm progress advances slot by slot without freezing the client.
2. Hover the scan summary and confirm **Last scan duration** is shown.
3. Confirm the native Wardrobe filters are restored after scanning.
4. Confirm a failed or impossible empty response preserves the previous healthy cache and marks refresh as recommended.
5. Confirm repeated item hovers and outfit rerolls remain responsive after the scan.

## Zone-profile coverage

Sample at least one zone from each group and verify the displayed era and local source label:

- Classic: Westfall, Redridge, Stranglethorn, Barrens, Feralas, Tanaris, or Winterspring;
- Cataclysm: Mount Hyjal, Vashj'ir, Deepholm, Uldum, Twilight Highlands, or Molten Front;
- Pandaria: Krasarang Wilds, Townlong Steppes, Dread Wastes, or Timeless Isle;
- Draenor/Legion/BFA: Nagrand, Broken Isles zones, Ashran, or Nazjatar;
- The War Within: Siren Isle or K'aresh;
- Midnight: renewed Eversong Woods, Zul'Aman, Harandar, or Voidstorm.

Generate several Zone Native looks in each sample and confirm foreign tracked quest rewards and foreign boss drops remain excluded.

## Settings and accessibility

1. Open **Options → AddOns → Quest Chronicle** and confirm all five new outfit settings are present.
2. Enable **High-contrast outfit states**.
3. Confirm Selected rows use a stronger green background, Zone Favorite rows a stronger gold background, and Zone Excluded rows a stronger red background.
4. Confirm the written **Selected**, **Zone favorite**, and **Zone excluded** labels remain visible without relying on color.
5. Disable wardrobe chat announcements and confirm automatic maintenance remains functional but quiet.

## Final safety pass

1. Confirm manual preview still applies only to the embedded character model.
2. Confirm no Blizzard transmog is applied, no gold is spent, and no Blizzard outfit slot changes.
3. Use `/reload`, reopen Quest Chronicle, and confirm settings, preview state, concepts, Chronicle data, and Courier compatibility persist.
