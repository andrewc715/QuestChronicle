# Quest Chronicle v1.0.0 Live Test Checklist

## Upgrade and migration

1. Back up `QuestChronicleDB` and install v1.0.0 over v0.9.2.
2. Enter the world and confirm the load message reports v1.0.0.
3. Confirm Chronicle history, active quests, RP notes, settings, wardrobe counts, current preview, favorites, exclusions, and saved concepts remain present.
4. Confirm an existing concept initially says **Quest Chronicle only** and no native outfit was created automatically.

## Create a native outfit

1. Load or generate a complete concept with a visible weapon and at least one hidden optional slot.
2. Open **Concepts**, give it a Blizzard-valid name, and click **Save / Update**.
3. Confirm the row changes from **Saving to WoW...** to **WoW Outfit**.
4. Open Blizzard's native Transmog outfit list and confirm one outfit with that name exists.
5. Confirm the saved armor, hidden slots, and weapon match Quest Chronicle's Character Preview.
6. Confirm the outfit was saved but not applied and no gold was spent.

## Update without duplication

1. Load the linked concept, change at least one armor appearance, and save it again with the same concept name.
2. Confirm the same Blizzard outfit changes.
3. Confirm a second native outfit was not created.

## Migrate an older concept

1. Select a pre-v1 concept marked **Quest Chronicle only**.
2. Click **Save to WoW**.
3. Confirm it gains a native WoW outfit link without changing the current Quest Chronicle preview.

## Weapon and visibility coverage

1. Save one concept for each equipped configuration available to the test character: one-hand plus shield/holdable, dual-wield, two-hand, and ranged.
2. Confirm each native outfit uses the weapon category Blizzard permits for the currently equipped item.
3. Confirm hidden helm, cloak, shirt, and tabard states are preserved.
4. Confirm normal shoulders do not become an unintended asymmetric pair.

## Guardrails

1. Attempt a native save during combat and confirm Quest Chronicle refuses it cleanly.
2. Attempt a name Blizzard rejects and confirm the local concept remains saved with a useful native-save error.
3. If native outfit slots are full, confirm the local concept remains intact and the failure is reported.
4. Delete a linked Quest Chronicle concept and confirm its native WoW outfit is not deleted.

## v1.0 smoke test

1. Accept, progress, abandon, and turn in safe test quests; verify their Chronicle events.
2. Record and search for an RP note.
3. Refresh the Courier export and confirm format 1 remains ready.
4. Generate and reroll outfits without triggering a wardrobe rescan.
5. Learn a new appearance and confirm exactly one debounced automatic wardrobe refresh occurs.

Expected result: Quest Chronicle remains migration-safe while concepts can be deliberately created and updated as real Blizzard transmog outfits.
