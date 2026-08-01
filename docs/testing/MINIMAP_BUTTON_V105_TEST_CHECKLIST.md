# Quest Chronicle v1.0.5 Minimap Button Test Checklist

## Install

1. Exit World of Warcraft completely.
2. Replace the current `QuestChronicle` addon folder with v1.0.5.
3. Log in and wait for Quest Chronicle to finish loading.

No wardrobe rescan, concept migration, or Custom Set resave is required.

## Standalone button

1. Confirm a Quest Chronicle book icon appears on the minimap or inside your minimap-button organizer.
2. Left-click it and confirm the main Quest Chronicle window toggles.
3. Right-click it and confirm **Status & Maintenance** opens.
4. Hover it and confirm the tooltip appears without a Lua error.

## Position and recovery

1. If the button remains on the minimap, drag it around the minimap edge.
2. Run `/reload` and confirm its position is remembered.
3. Run `/qc minimap reset` and confirm it returns to the default lower-left position.
4. Run `/qc minimap hide`, then `/qc minimap show`.
5. Confirm the **Show minimap button** checkbox under `Options → AddOns → Quest Chronicle` controls the same visibility setting.

## MinimapButtonBag Reborn

1. Open MinimapButtonBag Reborn after login.
2. Confirm Quest Chronicle is collected into the bag if the organizer is configured to gather new minimap buttons.
3. Test the organizer's `Ctrl+Right-click` reattachment gesture. Quest Chronicle intentionally does not consume that combination.
4. If the organizer does not automatically gather the new button, reload once or use the organizer's rescan function.

## Regression

- The Blizzard AddOn Compartment entry still opens Quest Chronicle.
- Its hover tooltip still works.
- `/qc`, Chronicle, Active Quests, Write Note, Status, and Outfits remain functional.
- Existing Custom Sets remain linked and verified.
