# Quest Chronicle v1.0.5: Minimap Button

Version 1.0.5 adds the standalone minimap button requested after the v1.0.4 AddOn Compartment tooltip repair.

## Added

- A named `QuestChronicleMinimapButton` parented to Blizzard's Minimap.
- Left-click toggles the main Quest Chronicle window.
- Right-click opens **Status & Maintenance**.
- Dragging moves the button around the minimap and saves its angle.
- A **Show minimap button** checkbox under WoW's Quest Chronicle AddOns settings.
- `/qc minimap show|hide|toggle|reset` recovery commands.
- A dedicated tooltip explaining both click actions and dragging.

## Minimap button organizers

The button is a conventional named Minimap child rather than a private launcher. Minimap button organizers such as MinimapButtonBag Reborn should therefore be able to collect it into their bag. Quest Chronicle leaves `Ctrl+Right-click` unconsumed so organizer-specific reattachment gestures remain available.

The existing Blizzard AddOn Compartment entry remains available as a second access route.

## Preserved

- SavedVariables schema 2.
- Courier format 1.
- Wardrobe cache and outfit concepts.
- Linked and verified WoW Custom Sets.
- Chronicle history, active quests, RP notes, settings, drafts, and window state.
- No wardrobe rescan or Custom Set resave is required.
