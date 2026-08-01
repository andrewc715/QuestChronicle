# Quest Chronicle v0.7.3: Starter-Origin Provenance

Version 0.7.3 closes the quest-reward geography gap exposed by **Cord of Grieving**.

## Why Cord of Grieving slipped into Blade's Edge

WoW's cached transmog source identifies Cord of Grieving as a quest source, but that record does not include the rewarding quest or map. Its legacy item-era value can also describe it like an older generic item. Quest Chronicle therefore saw a collected, compatible belt that passed the Classic-through-TBC ceiling and had no conflicting location text.

The item is actually a reward from **Passing Wisdom** on the Wandering Isle and was added with Mists of Pandaria. v0.7.3 gives that source—and the published Wandering Isle questing sets and weapons—an explicit Mists/Wandering Isle origin.

## General quest-source provenance

For quest appearances, generation now asks WoW's appearance-tracking system for the best source map. The returned map and parent-map trail are resolved through the same curated provenance engine used for the player's current location.

- A quest reward tracked to the current source pool remains eligible after the era gate.
- A quest reward tracked to another starting area or zone is rejected before style scoring.
- Source ID and collapsed visual ID are both supported because client builds may expose either trackable identity.
- Pending tracking data is retried; stable failures fall back to the existing conservative metadata rule.
- Manual wardrobe browsing and deliberate preview selection remain unrestricted.

## Complete starting-zone regression matrix

The engine now has deterministic era and provenance coverage for 30 retail starting experiences:

- Every core racial start, including shared Dun Morogh and Durotar pools.
- Worgen, goblin, pandaren, and dracthyr instanced starts.
- The original and allied/pandaren death-knight openings and the demon-hunter opening.
- Exile's Reach.
- Every allied-race arrival area through Earthen and Haranir.

Each case verifies its expected era ceiling and source pool, accepts a representative local quest reward, and rejects that reward from a foreign pool.

## Safety and compatibility

- Wardrobe cache format 5 remains valid; no collection rescan is required.
- SavedVariables schema 2 is preserved.
- Courier format 1 and Courier v1.0.0 compatibility are preserved.
- Existing concepts, selections, locks, hidden slots, style modes, Current Look data, and cached appearances remain compatible.
- Promotional exclusion and complete-outfit coherence from v0.7.2 remain active.
- Preview only: no transmog is applied, no gold is spent, and no Blizzard outfit slot is changed.
