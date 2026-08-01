# Quest Chronicle v0.5.0: Wardrobe Foundation

Quest Chronicle now includes the first piece of its road to a zone-aware outfit designer: a fifth **Outfits** tab that indexes the player's collected appearances and provides a safe manual fitting room.

## Included

- A fifth Outfits tab in the standalone Quest Chronicle window.
- A collected-appearance scanner using WoW's transmog collection APIs.
- Account-wide cache grouped into practical equipment slots.
- One representative collected source per visual appearance to reduce duplicates.
- Batched scanning to reduce visible client stalls.
- Automatic dirty marking when the transmog collection changes.
- Embedded `DressUpModel` character preview.
- Manual appearance selection with eight-item pagination.
- Persistent selected appearances and page positions.
- Per-slot clearing and complete preview reset.
- Model rotation controls.
- Compatibility validation using collection, display, player-condition, and source-validity fields supplied by WoW.

## Deliberately not included yet

v0.5.0 does not generate outfits, score appearances by zone, save outfit concepts, apply transmogrification, or modify official WoW outfit slots. Those systems build on this scanner and preview foundation in later releases.

## Data compatibility

- Addon version: 0.5.0
- SavedVariables schema: 2
- Courier format: 1

Existing Chronicle events, quest snapshots, RP notes, settings, and Courier exports remain compatible. The wardrobe cache is stored under `QuestChronicleDB.wardrobe` and can be rebuilt at any time.

## First-run note

The initial collection scan may take several seconds on a large wardrobe. Quest Chronicle scans one practical equipment group at a time and yields between groups. Once complete, browsing uses the SavedVariables cache instead of rescanning the full collection whenever the tab opens.
