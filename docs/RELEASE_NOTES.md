# Quest Chronicle v1.0.0

Quest Chronicle reaches its first stable release with the complete Chronicle recorder, active quest lifecycle, RP journal, Courier export, zone-aware Outfit Workbench, saved concepts, and stable migrations.

## Concepts now become native WoW outfits

Saving a concept can now create an actual World of Warcraft transmog outfit. Quest Chronicle translates its preview into Blizzard's native outfit format:

- collapsed visual IDs are saved instead of temporary representative source IDs;
- selected armor is assigned to the matching native slot;
- unselected armor records the equipped-gear state shown by the preview;
- hidden helm, cloak, shirt, and tabard states remain hidden;
- shoulders use Blizzard's primary shoulder slot without accidentally enabling an asymmetric secondary shoulder;
- one-hand, two-hand, ranged, dagger, shield, holdable, and dual-wield appearances use the appropriate native weapon option;
- the concept stores the resulting Blizzard outfit ID, so **Save / Update** updates that outfit rather than allocating another slot.

Existing concepts are preserved as **Quest Chronicle only**. Select one and use **Save to WoW** to migrate it deliberately. Quest Chronicle never consumes native outfit slots automatically during login.

Native saving is non-destructive: it does not apply the transmog, charge gold, or delete a native outfit when its Quest Chronicle concept is deleted. Blizzard still validates outfit names, collection ownership, character compatibility, combat restrictions, and the account's available outfit slots.

## Complete v1.0 feature set

- Records quest acceptance, activation, objective progress, state changes, abandonment, removal, and turn-in.
- Maintains the current active-quest snapshot and reconciles it against the quest log.
- Provides an RP journal with search, timestamps, and Chronicle integration.
- Publishes the stable Courier format 1 snapshot.
- Generates zone-, subzone-, era-, provenance-, faction-, enemy-, and recent-quest-aware outfits.
- Supports Zone Native, Traveler, Class Fantasy, and Chronicle Echo modes.
- Supports rerolls, locks, hidden layers, valid equipped-weapon handling, generated names, Current Look, concepts, zone favorites, and exclusions.
- Debounces real wardrobe changes, suppresses internal usability events, and recovers changed representative sources by stable visual ID.

## Compatibility

- SavedVariables schema 2 is preserved.
- Courier format 1 is preserved.
- Wardrobe cache format 5 is preserved.
- Existing Chronicle history, RP notes, active quests, settings, wardrobe data, selections, concepts, favorites, and exclusions remain compatible.
- No collection rescan is required after updating from v0.9.2.

See `testing/QUEST_CHRONICLE_V100_TEST_CHECKLIST.md` for the live verification pass.
