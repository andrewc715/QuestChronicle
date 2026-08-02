# Quest Chronicle v1.9.0a4 — Cooperative Outfit Generation

v1.9.0a4 preserves the calibrated Traveler Cohesion instrumentation from v1.9.0a1 and the cooperative wardrobe scan from v1.9.0a2. It removes the remaining foreground hitch from **Generate Outfit** and **Reroll Unlocked** by preparing armor candidates in bounded timer-frame work units and committing the completed outfit atomically.

## Performance

- Added `Core/Wardrobe/GenerationWorker.lua` as the cooperative generation coordinator.
- Evaluates at most 30 appearance candidates per worker slice and aims for approximately 2.5 ms of Quest Chronicle work per frame.
- Spreads armor eligibility, coherence, and weighted scoring across timer frames instead of evaluating the full wardrobe in the button-click frame.
- Runs weapon-route generation in its own frame and commits the finished armor-and-weapon bundle in a later frame.
- Applies the embedded model preview and performs the full Outfits UI refresh on separate subsequent frames.
- Reports the number of preparation frames and the longest measured Quest Chronicle worker step in the completion status.

## Atomicity and safety

- Builds the outfit against a private draft state. The visible preview state is unchanged until every armor and weapon selection succeeds.
- Cancels the draft rather than overwriting changes if the player modifies selections, locks, hidden slots, weapon families, weapon subtypes, hand linking, or style mode during preparation.
- Prevents a wardrobe scan from starting while generation is active and cancels generation if the collection becomes dirty.
- Keeps the original synchronous `Wardrobe.GenerateOutfit()` API as a fallback when WoW timer scheduling is unavailable.

## Preserved behavior

- Traveler generation rules remain unchanged and the v1.9.0a1 cohesion system remains instrumentation-only.
- The weighted selection formulas, slot order, existing set/motif coherence, era restrictions, Heritage restrictions, promotional exclusions, and zone preferences are unchanged.
- Weapon Appearance Routes, linked and unlinked hands, concepts, Custom Sets, live metadata updates, wardrobe cache format 7, SavedVariables schema 2, and Courier format 1 are unchanged.
- No wardrobe rescan or data migration is required.
