# Quest Chronicle v1.0.1 Custom Sets Test Checklist

## Migration

1. Exit WoW and replace the addon folder with v1.0.1.
2. Log in and open `/qc` → **Outfits** → **Concepts**.
3. Confirm existing concepts remain present.
4. Confirm old `WoW save failed` or native Outfit-slot status is gone.
5. Confirm Blizzard's paid Outfit slots are unchanged.

## Local Save / Update

1. Load or generate a concept.
2. Change one appearance.
3. Click **Save / Update**.
4. Confirm the Quest Chronicle concept updates.
5. Confirm no Custom Set or Outfit slot is created automatically.

## Save to Custom Sets

1. Select an unlinked concept.
2. Click **Save to Custom Sets**.
3. Open Blizzard's Transmogrify interface → **Custom Sets**.
4. Confirm a new Custom Set exists with the concept name and appearances.
5. Return to Quest Chronicle and confirm the button now says **Update Custom Set**.

## Update linked Custom Set

1. Change the concept and save it locally.
2. Click **Update Custom Set**.
3. Confirm the linked native Custom Set changes and no duplicate is created.

## Save as New

1. Select a linked concept.
2. Click **Save as New**.
3. Confirm another native Custom Set is created.
4. Confirm the concept now links to the newly created set.

## Replace Existing

1. Click **Replace Existing**.
2. Select a native Custom Set in the picker.
3. Click **Replace Selected**.
4. Confirm that Custom Set now contains the Quest Chronicle concept.
5. Confirm no transmog is applied and no Outfit slot changes.

## Failure cases

- Try during combat and confirm the action is rejected cleanly.
- Fill all Custom Set slots and confirm **Save as New** reports that replacement is required.
- Rename a linked concept, save locally, then update its Custom Set and confirm the native name changes.
- Delete the Quest Chronicle concept and confirm the native Custom Set remains.

## Regression

- Chronicle, Active Quests, Write Note, Status, wardrobe scanning, generation, preview, and Courier export continue to work.
