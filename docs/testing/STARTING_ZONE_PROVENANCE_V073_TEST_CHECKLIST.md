# Quest Chronicle v0.7.3 Live Test Checklist

## Install and compatibility

1. Exit World of Warcraft completely.
2. Replace the installed `QuestChronicle` addon folder with v0.7.3.
3. Start WoW and confirm the Status tab reports **Quest Chronicle 0.7.3**, **Schema 2**, and **Courier format 1**.
4. Open Outfits and confirm the existing wardrobe counts, preview selections, locks, hidden slots, and concepts remain present.
5. Do **not** rescan solely for this update; wardrobe cache format 5 remains compatible.

## Cord of Grieving regression

1. Travel to Blade's Edge Mountains and select **Zone Native**.
2. Open the Waist browser and find **Cord of Grieving**.
3. Hover it and confirm the tooltip says it is excluded from generation as a **Mists of Pandaria** / **Wandering Isle** starter reward.
4. Click it manually and confirm it still previews; v0.7.3 restricts generation, not browsing.
5. Clear or reset the preview, then run **Generate Outfit** and **Reroll Unlocked** at least 20 times.
6. Confirm Cord of Grieving, Ropes of Grieving, Cinch of Grieving, Unmarred waist pieces, and other Wandering Isle starter rewards are never generated in Blade's Edge.

## Quest-source map provenance

1. In any curated questing zone, generate and reroll several outfits.
2. Hover generated quest rewards and confirm locally tracked sources say WoW tracks the appearance to the current pool.
3. Browse a quest reward known to come from another starting area or zone.
4. Confirm its row says **Not generated** and its tooltip names the foreign source pool when WoW provides a tracking map.
5. Confirm a temporary **Loading era** state clears after item data arrives rather than permanently excluding the appearance.

## Starting-zone smoke matrix

The automated suite exercises all 30 cases below. For live smoke testing, enter any available starts on existing characters or temporary alts and verify the source-pool label beneath the style buttons.

| Character/start | Expected source pool | Era ceiling |
|---|---|---|
| Human — Northshire | Northshire Valley | Classic |
| Dwarf/Gnome — Dun Morogh | Dun Morogh | Classic |
| Night Elf — Shadowglen | Teldrassil | Classic |
| Draenei — Ammen Vale | Azuremyst Isle | TBC |
| Worgen — Gilneas | Gilneas | Cataclysm |
| Pandaren — Wandering Isle | The Wandering Isle | Mists |
| Dracthyr — Forbidden Reach | The Forbidden Reach | Dragonflight |
| Orc/Troll — Durotar | Durotar | Classic |
| Undead — Deathknell | Tirisfal Glades | Classic |
| Tauren — Camp Narache | Mulgore | Classic |
| Blood Elf — Sunstrider Isle | Sunstrider Isle | TBC |
| Goblin — Kezan/Lost Isles | Kezan and the Lost Isles | Cataclysm |
| Core Death Knight — Scarlet Enclave | The Scarlet Enclave | Wrath |
| Pandaren/Allied Death Knight — Frozen Throne | The Frozen Throne | Wrath |
| Demon Hunter — Mardum | Mardum | Legion |
| Core races — Exile's Reach | Exile's Reach | Shadowlands |
| Void Elf — Telogrus Rift | Telogrus Rift | Legion |
| Lightforged Draenei — Vindicaar | The Vindicaar | Legion |
| Dark Iron Dwarf — Shadowforge City | Shadowforge City | Classic |
| Kul Tiran — Boralus | Tiragarde Sound | BFA |
| Mechagnome — Mechagon | Mechagon | BFA |
| Nightborne — Nighthold | Suramar | Legion |
| Highmountain Tauren — Thunder Totem | Highmountain | Legion |
| Mag'har Orc/Vulpera — Valley of Honor | Orgrimmar | Classic |
| Zandalari Troll — Dazar'alor | Zuldazar | BFA |
| Earthen — Hall of Awakening | Hall of Awakening | TWW |
| Haranir — Har'mara | Harandar | Midnight |

## Preserved behavior

1. Confirm promotional appearances still say **Promo excluded** and never generate.
2. Confirm a dark or muted outfit does not gain an isolated dramatic fire/frost/fel piece.
3. Confirm locked slots remain unchanged through generation and rerolls.
4. Confirm the equipped weapon still determines valid generated weapon categories.
5. Save, load, overwrite, and delete one temporary concept.
6. Confirm no action applies a real transmog, spends gold, or changes a Blizzard outfit.
