# Quest Chronicle v0.5.4 Native Visual Index Live Test

## Install and migrate

1. Exit World of Warcraft completely.
2. Back up `WTF\\Account\\<ACCOUNT>\\SavedVariables\\QuestChronicle.lua`.
3. Replace the installed `Interface\\AddOns\\QuestChronicle` folder with v0.5.4.
4. Log into the same character used for the v0.5.3 Legs comparison.
5. Open `/qc`, then open **Outfits**.
6. Confirm the format 3 wardrobe cache is treated as stale and **Rescan Collection** is offered. Do not delete SavedVariables.

## Native comparison

1. Open Blizzard's Collections Wardrobe and select **Legs**.
2. Clear the native search box and use the same class/collection filters expected for this character.
3. Record the native number of collected, collapsed visual tiles or pages.
4. Close Blizzard's Wardrobe and Transmogrify windows.
5. In Quest Chronicle, click **Rescan Collection** and wait for completion.
6. Select **Legs**.
7. Confirm Quest Chronicle now shows roughly the full native catalog—about 15 seven-row pages for the reported collection—not one visual.
8. Hover the scan summary and confirm `Appearance rows returned` is close to the native visual count while `Source rows examined` may be much larger.

## Preview resolution

1. Visit the first, middle, and last Legs pages.
2. Preview at least two appearances on each page.
3. Confirm every enabled row changes the embedded model and remains selected while paging.
4. Confirm appearances sharing several item sources appear once, matching Blizzard's collapsed visual tile.
5. Confirm **Clear Slot**, mouse-wheel paging, **Previous**, and **Next** remain functional.

## Regression checks

1. Check Head, Chest, Hands, Feet, and each weapon group for plausible multi-page counts.
2. Run `/reload` and confirm the format 4 cache and current selections persist.
3. Add or remove a transmog source and confirm Quest Chronicle marks the cache for refresh.
4. Confirm Chronicle history, active quests, RP notes, drafts, window settings, and filters remain intact.
5. Refresh the Courier export and confirm it still reports format 1 and exports normally through Courier v1.0.0.

## Report if counts still diverge

Capture the Quest Chronicle Legs page count and the diagnostics tooltip values for collected sources, returned appearance rows, examined source rows, validated unique visuals, and excluded visuals. Also capture the native Legs page count using the same character and filters.
