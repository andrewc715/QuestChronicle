# Quest Chronicle v0.8.0 Live Test Checklist

This checklist validates Chronicle Intelligence, generated names, and per-zone preferences without applying a transmog or changing a Blizzard outfit slot.

## Preparation

1. Install v0.8.0 and enter the world on a character with an existing wardrobe scan.
2. Confirm `/qc status` reports addon version **0.8.0**, SavedVariables schema **2**, and Courier format **1**.
3. Open **Outfits** and confirm the existing cache, preview selections, locks, hidden slots, and saved concepts remain available without a rescan.

## Chronicle Echo

1. Accept or progress several quests that clearly mention one enemy family, such as demons/fel, undead/Scourge, trolls, naga, dragons, pirates, beasts, elementals, void forces, or machines.
2. Open **Outfits** and confirm the third information line reads `Echo:` followed by a matching enemy or faction theme and a recent-quest count.
3. Select **Echo**, then click **Generate Outfit** several times.
4. Confirm matching appearance names receive `Echo:` reasons in their tooltip score and appear more often than unrelated pieces.
5. Confirm every result still obeys the zone's era and source pool, promotional exclusion, outfit-coherence rules, and the currently equipped weapon's Blizzard transmog rules.
6. Progress the same objective repeatedly and confirm the recent-quest count does not grow for every objective update; one quest should count once.

## Faction and enemy themes

1. Test at least one quest containing an explicit Alliance or Horde faction signal.
2. Confirm the Echo summary shows the faction when it is a meaningful part of recent quest history.
3. Test a quest containing an enemy signal and confirm the enemy appears before the faction in the compact summary.
4. Confirm RP notes are not used as outfit-scoring evidence.

## Generated outfit names

1. Generate an outfit in each mode: **Zone**, **Traveler**, **Class**, and **Echo**.
2. Confirm the Character Preview heading receives a generated outfit name after each generation.
3. Click **Reroll Slot** and confirm the current look receives a refreshed name.
4. Open **Current Look** and confirm its heading includes the same name.
5. Open **Save Concept** and confirm the generated name is offered as the default concept name.
6. Save, change, and reload the concept. Confirm its generated name returns with its selections, locks, hidden slots, weapon layout, and style mode.
7. Manually choose or clear an appearance and confirm the generated label clears, because the preview is now a manually edited look.

## Per-zone favorites

1. Select a collected appearance and click **Favor in Zone**.
2. Confirm the button becomes **Unfavor**, the row says **Zone favorite**, and the header count increases.
3. Hover the row and confirm its tooltip says the favorite remains subject to all normal eligibility and coherence rules.
4. Generate or reroll repeatedly and confirm the visual is strongly favored when it is valid for the selected slot.
5. Travel to a different curated zone and confirm that appearance is not marked as a favorite there.
6. Return to the original zone and confirm the favorite is restored.

## Per-zone exclusions

1. Select an appearance and click **Exclude in Zone**.
2. Confirm the button becomes **Allow in Zone**, the row says **Zone excluded**, and the header count increases.
3. Confirm the appearance remains manually selectable and previewable.
4. Generate and reroll repeatedly; confirm the excluded visual is never selected in that zone.
5. Travel to another zone and confirm the exclusion does not apply there.
6. Return and click **Allow in Zone**; confirm the row returns to normal generation eligibility.
7. Favor an appearance and then exclude it. Confirm the exclusion replaces the favorite rather than leaving both states active.

## Regression pass

1. In an Outland launch zone, confirm Wrath and later appearances are still excluded.
2. Confirm a foreign TBC raid source remains excluded from a different TBC questing zone.
3. Confirm Trading Post, shop, subscription, Recruit-a-Friend, and other promotional appearances remain excluded from generation but browsable manually.
4. Confirm a dark or neutral outfit still rejects an isolated dramatic conflicting accent unless it belongs to the same Blizzard transmog set.
5. Test one-hand plus off-hand, dual-wield, two-hand, ranged, and empty-hand equipment configurations.
6. Reload the UI and confirm zone preferences, generated-name concepts, Chronicle history, and Courier export remain intact.

## Pass criteria

- Chronicle Echo reflects deduplicated recent quest, faction, and enemy evidence.
- Generated names remain attached to generated or loaded concepts and clear after deliberate manual edits.
- Favorites are strong local weights; exclusions are hard local generation bans.
- No v0.7.x safety rule regresses.
- Wardrobe cache format 5, SavedVariables schema 2, and Courier format 1 remain unchanged.
