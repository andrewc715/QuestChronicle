# Quest Chronicle v0.7.1: Chronological Zone Pools and Current Look

Version 0.7.1 prevents the Zone Style Engine from recommending appearances that are chronologically or geographically wrong for the character's current adventure.

## Era ceilings

Every armor and weapon candidate now has to pass the current zone's expansion ceiling before style scoring begins.

- Classic zones use Classic items.
- Outland uses Classic and The Burning Crusade items.
- Northrend adds Wrath of the Lich King.
- Cataclysm, Pandaria, Draenor, Legion, Battle for Azeroth, Shadowlands, Dragonflight, The War Within, and Midnight regions add their respective eras in order.

Quest Chronicle reads Blizzard's `expansionID` from the representative item's current item data. Missing item data is requested and the candidate remains outside generation until WoW supplies its era. The value is added lazily to the existing source record, so wardrobe cache format 5 remains valid and no rescan is required.

## Local source provenance

Era alone is not enough. Blade's Edge and Sunwell both belong to The Burning Crusade, but they are not the same source family.

For boss drops, Quest Chronicle reads Blizzard's instance and encounter provenance. A Gruul's Lair appearance can enter the Blade's Edge pool; a Sunwell Plateau appearance cannot. Curated provenance families cover the major questing regions and their associated dungeons or raids from Outland through Midnight.

For sources without exact Blizzard location data, explicit foreign-zone terms in the loaded item/source metadata are rejected. A source with no reported location and no conflicting marker remains eligible after passing the era ceiling. This conservative fallback avoids claiming more provenance precision than WoW exposes.

The rule applies to Generate Outfit, Reroll Unlocked, individual armor rerolls, and individual weapon rerolls in all three style modes. Locked slots remain deliberately preserved even when the character changes zones.

## Browser transparency

The appearance browser still shows the complete collected wardrobe and permits deliberate manual previews. A row outside the automatic pool says **Not generated** or **Loading era**. Its tooltip explains whether it is too new, comes from another zone family, or is waiting for Blizzard item data.

## Current Look

Equipment-slot buttons now contain a thumbnail for the layer represented on the embedded model. Selected appearances use their cached icon; unmodified layers use the equipped item's icon. Hidden layers are desaturated, and locked layers retain their gold padlock and border.

The new **Current Look** button opens a compact manifest containing:

- every armor layer;
- the active main-hand mode and applicable off-hand only;
- exact selected appearance or equipped-item names;
- Selected, Equipped, Hidden, and Locked states;
- appearance source and item IDs on hover.

## Compatibility

- Wardrobe cache format 5; no collection rescan is required.
- SavedVariables schema 2 is preserved.
- Courier format 1 and Courier v1.0.0 compatibility are preserved.
- Existing concepts and their saved style modes remain compatible.
- Quest history, active quests, notes, drafts, settings, and Courier snapshots are unchanged.
- Preview only; no transmog is applied, no gold is spent, and no Blizzard outfit slot is changed.
