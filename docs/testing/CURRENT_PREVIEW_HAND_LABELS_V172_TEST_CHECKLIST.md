# Quest Chronicle v1.7.2 Current Preview Hand Labels Test Checklist

## Install

1. Exit World of Warcraft completely.
2. Replace the existing `QuestChronicle` addon folder with v1.7.2.
3. Log in and open `/qc` → **Outfits**.

No wardrobe rescan is required.

## Linked One-Hand pair

1. Enable One-Hand and **Link weapon hands**.
2. Generate an outfit.
3. Open **Current Look**.
4. Confirm the weapon rows read:
   - **Main Hand** — Selected
   - **Off Hand** — Selected
5. Confirm the family name `One-Hand` is not used as the Main Hand row label.

## Linked Two-Hand pair

1. Enable Two-Hand and **Link weapon hands**.
2. Generate an outfit.
3. Open **Current Look**.
4. Confirm both generated weapons are listed separately:
   - **Main Hand** — Selected
   - **Off Hand** — Selected
5. Confirm the panel no longer collapses the pair into one `Two-Hand` row.

## Unlinked pair

1. Disable **Link weapon hands**.
2. Generate either a One-Hand or Two-Hand pair.
3. Confirm Main Hand and Off Hand may show different appearance names while retaining the hand labels.

## Single and companion layouts

- A single Ranged or ordinary single Two-Hand presentation should show only **Main Hand**.
- A One-Hand plus shield/focus layout should show **Main Hand** and **Off Hand**.

## Regression

- `/qc weapon debug` retains the same route and selection output as v1.7.1.
- Generate Outfit and Reroll Unlocked still update both hands atomically.
- Custom Set save verification remains unchanged.
