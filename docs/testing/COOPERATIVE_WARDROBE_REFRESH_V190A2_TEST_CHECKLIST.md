# Quest Chronicle v1.9.0a2 Cooperative Wardrobe Refresh Test

## Installation

1. Exit WoW completely.
2. Replace the existing `QuestChronicle` folder with v1.9.0a2.
3. Start WoW with Quest Chronicle as the only enabled addon for the cleanest performance comparison.
4. Confirm Status reports version `1.9.0a2`, schema `2`, Courier format `1`, and wardrobe cache format `7`.

## Login and reload responsiveness

1. Log in with the existing wardrobe cache.
2. Wait for the automatic login refresh to begin after its normal delay.
3. During the refresh, move the character, rotate the camera, open chat, and switch Quest Chronicle tabs.
4. Confirm the client no longer freezes for tens of seconds.
5. Run `/reload` and repeat the test.

A temporary CPU increase while scanning is expected. A long single-frame lockup is not.

## Collection equivalence

1. After the scan completes, open Status and note the wardrobe visual count.
2. Open Outfits and inspect several armor and weapon slots.
3. Confirm collected appearance counts remain plausible and no slot is unexpectedly empty.
4. Click **Scan Collection** manually and confirm the completed totals remain stable.

## Live item metadata

1. Browse to a page containing an appearance whose item name or era is still loading.
2. Leave the page open without clicking the row.
3. Confirm the visible row updates when WoW supplies its item data.
4. Confirm the full Outfits workbench does not rebuild or change pages.

## Traveler calibration regression

1. Generate a Traveler outfit.
2. Run `/qc traveler debug`.
3. Confirm matching linked weapons are still one analysis block.
4. Confirm mismatch costs remain fractional and supported variations may cost `0.00`.
5. Confirm generation behavior itself is unchanged.

## Deferred scan fallback

When practical:

1. Enter combat or open Blizzard's native Wardrobe before the login refresh attempts to start.
2. Confirm Quest Chronicle defers the scan instead of erroring.
3. Close the blocking UI or leave combat and use **Scan Collection**.
4. Confirm item names and tooltips still update normally.
