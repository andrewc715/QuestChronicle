# Quest Chronicle v0.7.0 Live Test Checklist

## Installation and preserved data

1. Exit World of Warcraft completely.
2. Replace the existing `QuestChronicle` addon folder with v0.7.0.
3. Start WoW and confirm Quest Chronicle reports v0.7.0 on the Status tab.
4. Confirm existing quest history, wardrobe counts, selections, locks, hidden slots, and saved concepts remain present.
5. Do not rescan unless Quest Chronicle already reported the wardrobe cache as stale; v0.6.2 cache format 5 remains valid.

## Zone and subzone detection

1. Enter Silvermoon or Eversong and open **Outfits**.
2. Confirm the line above the model shows the detected location and the **Quel'Thalas** profile.
3. Move between subzones and confirm the location text follows the current subzone without errors.
4. If accessible, repeat in Zul'Aman, Harandar, or the Voidstorm and confirm the Amani, Harandar, or Voidstorm profile appears.
5. Visit an unprofiled area and confirm the **Azeroth Adventurer** fallback appears.

## New-zone suggestion

1. Close Quest Chronicle, cross into a different zone, and wait about one second.
2. Confirm chat announces a new Zone Native outfit suggestion.
3. Open Quest Chronicle on a non-Outfits tab and confirm **Outfits*** is marked.
4. Open **Outfits** and confirm the tab marker clears while the workbench still says **Suggestion ready**.
5. Generate in Traveler or Class Fantasy mode and confirm the Zone Native suggestion remains ready.
6. Select **Zone Native**, click **Generate Outfit**, and confirm the suggestion-ready text clears.
7. Confirm no suggestion ever changes the preview before **Generate Outfit** is clicked.

## Weighted modes

1. In a strongly themed area, select **Zone Native** and generate or reroll several times.
2. Confirm results vary and that locally named appearances appear more often; exact full-set matching is not expected.
3. Select **Traveler** and confirm repeated generations trend toward expedition, ranger, scout, weathered, rugged, fur, leather, pouch, cloak, and boot themes when such names exist in the cache.
4. Select **Class Fantasy** and confirm repeated generations trend toward appearances named for the current class and its familiar motifs.
5. Hover appearance rows and confirm the tooltip shows the selected mode's score and any matched reasons.

## Weapon rules and workbench preservation

1. Test the equipped one-hand/off-hand, dual-wield, two-hand, and ranged configurations available to the character.
2. Generate and reroll in all three modes.
3. Confirm weapon previews always remain compatible with the currently equipped weapon categories and hands.
4. Lock one armor slot and the active weapon slot, then generate again; confirm both remain unchanged and visibly locked.
5. Hide helm, cloak, shirt, or tabard and confirm generation preserves the hidden choice.

## Concept round-trip

1. Select Traveler, generate an outfit, add locks or hidden slots, and save a new concept.
2. Switch to Class Fantasy and alter the preview.
3. Load the saved concept and confirm its appearances, weapon configuration, locks, hidden slots, and Traveler mode are restored.
4. Load a concept saved before v0.7.0 and confirm it loads without errors while retaining the current generation mode.

## Regression checks

1. Confirm Chronicle, Active Quests, Write Note, Status, and bottom navigation tabs still work.
2. Confirm manual appearance selection immediately updates the embedded character preview.
3. Confirm the concept manager can save, overwrite, load, page, and delete concepts.
4. Confirm no Lua errors appear during login, `/reload`, zone changes, generation, rerolls, concept operations, or wardrobe browsing.
