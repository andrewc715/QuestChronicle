# Quest Chronicle v0.6.0 Outfit Workbench Live Test

## Upgrade and cache compatibility

1. Install v0.6.0 and run `/reload` or restart WoW.
2. Open `/qc` and select **Outfits**.
3. Confirm the format 5 collection counts remain populated without rescanning.
4. Confirm existing manual selections still preview correctly.
5. Confirm Chronicle, Active Quests, Write Note, Status, and Outfits render as native top tabs rather than red push-buttons.
6. Switch through all five tabs and confirm the selected tab joins the content panel, tooltips work, and the last tab is remembered after closing and reopening the window.

## Generate a complete outfit

1. Click **Generate Outfit**.
2. Confirm Head, Shoulders, Back, Chest, Shirt, Tabard, Wrists, Hands, Waist, Legs, Feet, and a valid weapon mode receive selections where cached appearances exist.
3. Confirm the embedded model immediately displays the generated combination.
4. Generate five more outfits and confirm the selections change without UI errors or emptying the cache.

## Reroll and locks

1. Select Chest and click **Lock Slot**; confirm the left button gains `L` and the selected line says **Locked**.
2. Click **Reroll Unlocked** and confirm Chest stays unchanged while other pieces change.
3. Select Legs and click **Reroll Slot**; confirm only Legs changes.
4. Attempt to reroll locked Chest and confirm the workbench asks for it to be unlocked.
5. Unlock Chest and confirm it can be rerolled.

## Hidden optional slots

1. Select Head and click **Hide Slot**; confirm the helm disappears, the left button gains `H`, and the selected source remains stored.
2. Click **Show Slot** and confirm the same helm returns.
3. Repeat for Back, Shirt, and Tabard.
4. Confirm non-hideable slots do not display a Hide button.
5. Hide two optional slots, click **Reroll Unlocked**, and confirm those visibility choices remain hidden.

## Weapon handling

1. Select Two-Hand and reroll it; confirm One-Hand, Ranged, and Off-Hand selections clear.
2. Select Ranged and confirm Two-Hand and Off-Hand clear.
3. Select Off-Hand directly and confirm a One-Hand appearance is supplied when none is selected.
4. Generate outfits repeatedly and confirm each result uses only Two-Hand, Ranged, or One-Hand with an optional Off-Hand.
5. Lock a One-Hand and Off-Hand pair, click **Reroll Unlocked**, and confirm both remain.

## Save and load concepts

1. Build an identifiable outfit with at least two locks and one hidden slot.
2. Click **Save Concept**, enter `Workbench Test A`, and save.
3. Generate a different outfit.
4. Click **Load Concept** and choose `Workbench Test A`.
5. Confirm appearances, locks, hidden slots, and weapon configuration are restored.
6. Change one piece and save again as `Workbench Test A`; confirm loading that name restores the updated version.
7. Run `/reload` and confirm the concept remains available.

## Reset and regressions

1. Click **Reset Outfit** and confirm selections, locks, and hidden states clear while the model returns to equipped gear.
2. Confirm manual browsing, pagination, mouse-wheel paging, collection rescanning, and scan diagnostics still work.
3. Confirm Chronicle history, active quests, RP notes, settings, and Courier format 1 remain unchanged.
