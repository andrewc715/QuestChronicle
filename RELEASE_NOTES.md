# Quest Chronicle v0.8.0: Chronicle Intelligence

Version 0.8.0 lets the recorded Chronicle participate directly in outfit generation. Recent quests, their objectives, recognizable factions, and enemy families now provide a bounded, explainable style signal while every v0.7 safety rule remains authoritative.

## Chronicle Echo

The Outfit Workbench now has four compact generation modes:

- **Zone** favors the current curated culture and environment.
- **Traveler** favors practical expedition gear.
- **Class** favors the character's class fantasy.
- **Echo** favors the factions and enemies appearing in the character's recent quest history.

Chronicle Intelligence reads the newest twelve distinct quest records from the existing schema-2 event history and active-quest snapshot. Repeated objective updates are merged into their quest instead of being counted repeatedly. Quest titles and objective text can recognize Alliance and Horde signals plus themes such as the Burning Legion, undead, void forces, elementals, dragons, beasts, trolls, naga, pirates, and machines.

Recent quest influence is strongest in Chronicle Echo and remains a smaller accent in the other three modes. The Workbench shows a compact Echo summary and matching appearance tooltips explain their Echo score. RP notes are not used for scoring.

## Generated outfit names

Every complete generated outfit receives a stable name based on its mode, current zone, Chronicle theme, and selected visual identities. Individual slot rerolls refresh that name.

- The name appears in the Character Preview and Current Look headings.
- Save Concept offers it as the default concept name.
- Concepts save and restore the generated name through optional additive fields.
- Existing concepts without a generated name remain fully loadable.
- Deliberate manual appearance changes clear the generated label so it never misrepresents a hand-edited preview.

## Per-zone favorites and exclusions

The selected appearance now has **Favor in Zone** and **Exclude in Zone** controls.

- A favorite receives a strong generation weight but still must pass era, source provenance, promotion, coherence, usability, and equipped-weapon rules.
- An exclusion is a hard generation ban in that zone but does not prevent manual browsing or preview.
- Favoring and excluding are mutually exclusive.
- Preferences use Blizzard's collapsed visual identity, so alternate item sources for the same appearance share the preference.
- Preferences are stored per character and per curated zone; they do not leak into another zone.

Rows and tooltips identify local favorites and exclusions, and the style summary shows their current counts.

## Preserved safeguards and compatibility

- Zone expansion ceilings and local source-provenance gates remain authoritative.
- Trading Post, shop, subscription, Recruit-a-Friend, and other promotional appearances remain excluded from generated outfits.
- Native transmog-set affinity, shared-motif scoring, and dramatic-outlier rejection remain active.
- Weapons still follow Blizzard's currently equipped item, category, usability, hand-slot, and character-validity rules.
- Wardrobe cache format 5 remains valid; no collection rescan is required.
- SavedVariables schema 2 is preserved.
- Courier format 1 and Warcraft Quest Chronicle Courier v1.0.0 compatibility are preserved.
- Existing quest history, notes, cache entries, selections, locks, hidden slots, style modes, and outfit concepts remain compatible.
- Preview only: no transmog is applied, no gold is spent, and no Blizzard outfit slot is changed.

See `CHRONICLE_INTELLIGENCE_V080_TEST_CHECKLIST.md` for the live validation pass.
