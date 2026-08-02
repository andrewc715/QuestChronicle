# Quest Chronicle v1.9.0a3 Foreground Wardrobe Performance Test

## Installation

1. Exit WoW completely.
2. Replace the existing `QuestChronicle` folder with v1.9.0a3.
3. Start WoW with Quest Chronicle as the only enabled addon for the cleanest comparison.
4. Confirm Status reports version `1.9.0a3`, schema `2`, Courier format `1`, and wardrobe cache format `7`.

## Generate Outfit responsiveness

1. Wait for the automatic login wardrobe refresh to complete.
2. Open Outfits and select Traveler mode.
3. Click **Generate Outfit** five times, waiting for each preview to update.
4. Repeat in Zone, Class, and Echo modes.
5. Confirm the client does not freeze while the button is processed.
6. Confirm generated armor and weapon routes remain valid.

A brief ordinary frame hitch may occur while thousands of cached candidates are scored. A multi-second full-client lock is not expected.

## Manual Scan Collection responsiveness

1. Click **Scan Collection**.
2. Immediately move the character, rotate the camera, type in chat, and switch Quest Chronicle tabs.
3. Confirm the client remains responsive while the background scan proceeds.
4. Confirm the completion message reports a plausible appearance count and elapsed duration.
5. Confirm the final visual count remains stable relative to v1.9.0a2.

## Equipment and specialization refresh

1. Change one equipped weapon or armor item.
2. Change specialization when practical.
3. Confirm weapon-family availability updates without a client freeze.
4. Run `/qc weapon debug` and confirm physical topology and pair routes remain correct.

## Traveler diagnostic regression

1. Generate a Traveler outfit.
2. Run `/qc traveler debug`.
3. Confirm linked weapons remain one analysis block.
4. Confirm mismatch costs remain fractional.
5. Confirm supported variations may cost `0.00`.
6. Confirm diagnostics remain instrumentation-only.
