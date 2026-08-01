# Quest Chronicle v0.7.1 Live Test Checklist

## Upgrade and preserved data

1. Exit World of Warcraft completely and install v0.7.1.
2. Confirm the Status tab reports v0.7.1.
3. Confirm existing quest history, wardrobe counts, selections, locks, hidden slots, concepts, and selected style mode remain present.
4. Do not rescan solely for this update; wardrobe cache format 5 remains valid.

## Blade's Edge chronological pool

1. Enter Blade's Edge Mountains and open **Outfits**.
2. Confirm the style context says **Through TBC** and **Blade's Edge Mountains sources**.
3. Select each of Zone Native, Traveler, and Class Fantasy and generate several outfits.
4. Confirm no Wrath or later appearance is generated. Shadowmourne must never be selected automatically.
5. Reroll the active weapon and several armor slots; confirm the same ceiling applies.
6. Hover a known Wrath-or-later row and confirm it says **Excluded from generation** with its expansion and the TBC ceiling.

## Blade's Edge local provenance

1. Locate a collected appearance associated with Gruul's Lair and confirm its tooltip says it is eligible for Blade's Edge.
2. Locate a collected Sunwell Plateau appearance from the same TBC era.
3. Confirm its row says **Not generated** and the tooltip identifies its source as outside the Blade's Edge pool.
4. Generate and reroll repeatedly and confirm the Sunwell appearance is never selected automatically.
5. Click the excluded Sunwell row manually and confirm deliberate preview selection still works.

## Other era ceilings

1. Visit a Classic launch zone and confirm the ceiling is Classic.
2. Visit Northrend and confirm the ceiling is Wrath.
3. If available, visit Pandaria, Draenor, the Broken Isles, Kul Tiras or Zandalar, the Shadowlands, the Dragon Isles, Khaz Algar, and Midnight regions.
4. Confirm each location reports the corresponding era ceiling and never recommends a later expansion.
5. In renewed Midnight regions, confirm a **Midnight** parent map permits Midnight items; the original-era version should retain its older ceiling when Blizzard reports the older parent.

## Current Look thumbnails

1. Confirm populated equipment-slot buttons display the icon represented on the character preview.
2. Select a new appearance and confirm its slot thumbnail updates immediately.
3. Hide helm, cloak, shirt, or tabard and confirm its thumbnail becomes desaturated.
4. Lock several slots and confirm thumbnails coexist with the gold padlock and border.
5. Switch between One-Hand, Two-Hand, and Ranged previews and confirm inactive weapon-category thumbnails disappear.

## Current Look manifest

1. Click **Current Look** at the bottom of the equipment-slot panel.
2. Confirm the manifest lists each armor layer and its exact selected or equipped name.
3. Confirm hidden and locked states are clearly labeled.
4. Confirm only the active main-hand category and applicable off-hand are listed.
5. Hover entries and confirm appearance source and item IDs appear when available.
6. Close the manifest and confirm appearance browsing returns unchanged.

## Regression checks

1. Generate and reroll with one-hand/off-hand, dual-wield, two-hand, ranged, and empty-hand configurations.
2. Confirm Blizzard's equipped-item and hand compatibility rules still hold.
3. Confirm saved concepts still round-trip appearances, weapons, locks, hidden slots, and style modes.
4. Confirm automatic zone suggestions, bottom tabs, Chronicle, Active Quests, Write Note, and Status still work.
5. Confirm no Lua errors appear during login, `/reload`, zone changes, item-data loading, generation, browsing, or Current Look use.
