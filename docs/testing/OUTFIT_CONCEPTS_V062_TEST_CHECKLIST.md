# Quest Chronicle v0.6.2 Live Test: Outfit Concepts and Locked Slots

## Upgrade and preserved data

1. Exit World of Warcraft completely and install v0.6.2.
2. Log into the character used for v0.6.1 testing and open Quest Chronicle.
3. Confirm the wardrobe cache and appearance counts remain populated without a collection rescan.
4. If any concepts were successfully saved in an earlier build, confirm they appear in the manager.

## Locked-slot visibility

1. Select Head, choose an appearance, and click **Lock Slot**.
2. Select Two-Hand, choose a valid appearance for the equipped weapon, and lock it.
3. Switch to Shoulders as in the reported screenshot.
4. Confirm Head and Two-Hand each retain a visible gold padlock and complete gold border; no tiny trailing `L` is used.
5. Return to Head and confirm its disabled active-slot button still shows the padlock and border.
6. Confirm the detail header says **Locked** and the action reads **Unlock Slot**.
7. Click **Generate Outfit** and verify both locked appearances are preserved.
8. Unlock each slot and confirm its padlock and border disappear immediately.

## Save a concept

1. Generate or manually assemble an outfit, lock at least two slots, and hide at least one optional slot.
2. Click **Save Concept**.
3. Confirm the in-panel **Outfit Concepts** manager opens above a shaded workbench; no separate global popup appears.
4. Enter a distinctive name and click **Save / Update** or press Enter.
5. Confirm the concept appears in the list with appearance, locked, hidden, and update details.
6. Close the manager and confirm the main button reads **Concepts (1)** and the subtitle names the active concept.

## Overwrite and multiple concepts

1. Change one unlocked appearance and open **Save Concept** again.
2. Save using the exact same name and confirm the existing row updates rather than duplicating.
3. Change the name and save again; confirm a second concept is created.
4. Create at least five concepts and confirm the previous/next paging controls expose every row.

## Load a concept

1. Change several appearances, locks, and hidden states without saving.
2. Click **Concepts (N)**, select an earlier concept row, and click **Load Selected**.
3. Confirm the manager closes and the model restores the saved appearances.
4. Confirm locks and hidden helm/cloak/shirt/tabard states also restore.
5. Confirm weapon selections restore to the concept preview without applying a transmog to the character.

## Delete and persistence

1. Open the manager, select a disposable concept, and click **Delete** once.
2. Confirm the button changes to **Confirm Delete** and the concept remains.
3. Click **Confirm Delete** and confirm the row and main concept count update.
4. Confirm deleting a concept does not alter the current character preview.
5. Run `/reload`, reopen the manager, and confirm remaining concepts persist.
6. Log into another character and confirm concepts remain character-specific.

## Regression checks

1. Generate one-hand/off-hand, dual-wield, two-hand, and ranged outfits and confirm v0.6.1 weapon rules still hold.
2. Confirm the bottom navigation tabs remain aligned and functional.
3. Confirm manual appearance browsing, paging, preview, slot hiding, and collection scanning still work.
4. Confirm SavedVariables schema 2, Courier format 1, and wardrobe cache format 5 remain unchanged.
