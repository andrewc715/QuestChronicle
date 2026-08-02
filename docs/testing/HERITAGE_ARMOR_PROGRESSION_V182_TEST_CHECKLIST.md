# Quest Chronicle v1.8.2 Heritage Armor Progression Test Checklist

## Install

1. Exit World of Warcraft completely.
2. Replace the existing `QuestChronicle` addon folder with v1.8.2.
3. Log in and confirm Status reports version `1.8.2`.
4. Allow the normal one-time wardrobe scan for the login or `/reload` session to finish.

## Below-max-level behavior

1. Use a character below the account's current maximum reachable level.
2. Open **Outfits** and browse an armor slot containing a collected race Heritage Armor appearance.
3. Confirm the appearance remains visible and can be selected manually.
4. Hover it and confirm the tooltip says the Heritage set is excluded from generated outfits below max level.
5. Confirm the row displays **Heritage locked** rather than **Promo excluded**.
6. Generate and reroll several outfits.
7. Confirm no race Heritage Armor piece is selected automatically.

## Maximum-level behavior

1. Repeat on a character at the account's current maximum reachable level.
2. Confirm Heritage Armor no longer receives the below-max-level restriction.
3. Confirm it may enter generation when it passes all other era, provenance, promotion, and coherence rules.

## Non-Heritage control

1. Browse a normal quest, dungeon, raid, crafted, or vendor set.
2. Confirm the new rule does not classify it as Heritage Armor.
3. Confirm existing promotion and zone-era exclusions still behave normally.

## Regression

- Linked One-Hand generation still selects Main Hand and Off Hand.
- Linked Two-Hand generation still selects Main Hand and Off Hand.
- `/qc weapon debug` still reports physical pair routes.
- Concepts and Custom Set synchronization still work.
- No runtime Lua file exceeds 500 lines.
