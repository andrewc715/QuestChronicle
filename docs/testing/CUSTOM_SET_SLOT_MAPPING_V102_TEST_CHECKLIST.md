# Quest Chronicle v1.0.2 Complete Custom Set Handoff Test Checklist

## Install and rebuild the source cache

1. Exit World of Warcraft completely.
2. Back up the account-level `SavedVariables\QuestChronicle.lua` file.
3. Replace the existing Quest Chronicle addon folder with v1.0.2.
4. Log into the character that owns the affected concept.
5. Wait for the automatic wardrobe refresh, or open **Outfits** and click **Scan Collection**.
6. Confirm the scan completes before testing Custom Sets. Cache format 6 intentionally rebuilds source representatives; saved concepts are preserved.

## Repair the existing partial set

1. Open `/qc` and select **Outfits → Concepts**.
2. Select the concept that produced the partial native set.
3. Load it and confirm the Quest Chronicle preview still shows the intended look.
4. Use ordinary **Save / Update** once to refresh the concept's source and visual snapshot.
5. Reopen Concepts and select it.
6. Click **Update Custom Set**. If the old partial set was never linked, **Save to Custom Sets** should find and replace the same-name set rather than create a duplicate.
7. Wait for Quest Chronicle's verification result.
8. Open Blizzard's Transmogrify interface and select **Custom Sets**.
9. Confirm the native preview matches Quest Chronicle.

For the reported Blade's Edge Mountains concept, verify:

- Head
- Shoulders
- Back
- Chest
- Shirt
- hidden or empty Tabard as designed
- Wrists
- Hands
- Waist
- Legs
- Feet
- Two-Hand weapon

## Successful verification

A healthy save should report:

```text
Custom Set saved and verified: N/N selected slots matched.
```

The concept should display a linked Custom Set state instead of `Custom Set mismatch`.

## Failure safety

If any selected visual cannot be rebound to a collected source, Quest Chronicle should:

- name every unresolved slot;
- leave the Quest Chronicle concept untouched;
- avoid creating or overwriting a native Custom Set;
- recommend rescanning and saving the local concept again.

If Blizzard drops or substitutes an unrelated visual after the save, chat should identify the affected slot as Missing or Altered. A different source representing the same visual is acceptable.

## Save as New

1. Select a disposable concept.
2. Click **Save as New**.
3. Confirm a new Custom Set appears.
4. Confirm every selected and hidden slot verifies, not merely Head and Chest.

## Replace Existing

1. Choose **Replace Existing**.
2. Select a disposable native Custom Set.
3. Replace it with the Quest Chronicle concept.
4. Confirm the replacement verifies slot by slot.
5. Confirm the overwritten native recipe remains backed up inside the Quest Chronicle concept.

## Regression

- Ordinary **Save / Update** remains Quest Chronicle-only.
- No `ADDON_ACTION_FORBIDDEN` occurs.
- Chronicle, Active Quests, Write Note, Status, Courier export, and `/qc export` remain unchanged.
- Existing concepts and linked Custom Set IDs survive `/reload`.
