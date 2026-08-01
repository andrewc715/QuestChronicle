# Quest Chronicle v1.0.4 AddOn Compartment Test Checklist

## Install

1. Exit World of Warcraft completely.
2. Replace the current `QuestChronicle` addon folder with v1.0.4.
3. Log in and allow the UI to finish loading.

No migration, collection rescan, or concept resave is required.

## Native AddOns tray

1. Open Blizzard's AddOns compartment beside the minimap.
2. Confirm **Quest Chronicle** appears with the book icon.
3. Hover **Quest Chronicle**.
4. Confirm the tooltip displays:
   - Quest Chronicle version;
   - left-click instruction;
   - right-click Status instruction.
5. Confirm no `GameTooltip:SetOwner(region)` error appears.
6. Move the pointer away and confirm the tooltip closes.

## Click behavior

1. Left-click the Quest Chronicle tray entry and confirm the main window opens.
2. Left-click it again and confirm the main window closes.
3. Right-click the entry and confirm **Status & Maintenance** opens.

## Regression

- `/qc` still toggles the main window.
- Chronicle, Active Quests, Write Note, Status, and Outfits tabs still open.
- Outfit Concepts and linked Custom Sets remain unchanged.
- `/qc export` followed by `/reload` still updates SavedVariables for the Courier.
