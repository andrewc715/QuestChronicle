# Quest Chronicle v1.7.0 Weapon Appearance Routes Test Checklist

## Install

1. Exit World of Warcraft completely.
2. Replace the existing `QuestChronicle` addon folder with v1.7.0.
3. Log into Xyrkian.
4. Open `/qc` and select **Outfits**.
5. A wardrobe rescan is not required solely for this update.

## Inspect the native route model

Run:

```text
/qc weapon debug
```

For Fury with dual two-handed weapons, confirm:

- topology is **Dual two-handed weapons equipped**;
- Main Hand and Secondary Hand resolve to distinct native outfit slots;
- the slots are reported as a linked pair;
- accepted routes are listed separately, typically a One-Hand pair and a Two-Hand pair;
- no option is represented as one merged list of One-Hand, Two-Hand, Ranged, and Off-Hand categories;
- ambiguous options, if present, appear as `UNSUPPORTED` rather than activating families.

## Family panel

With Xyrkian's current linked Fury layout, confirm:

- One-Hand is available when Blizzard exposes a one-hand route.
- Two-Hand is available when Blizzard exposes a two-hand route.
- Ranged is disabled unless a distinct native ranged route is listed by `/qc weapon debug`.
- Off-Hand is disabled because the Secondary Hand is a linked weapon, not a shield/focus companion slot.
- The Off-Hand tooltip explains that shields and holdables require an independent companion slot.

## Linked One-Hand route

1. Enable **One-Hand** and disable the other main families.
2. Select one or more permitted One-Hand subtypes.
3. Enable **Link weapon hands**.
4. Click **Generate Outfit** repeatedly.
5. Confirm Current Preview lists both:
   - One-Hand: Selected
   - Off-Hand: Selected
6. Confirm both hands use the same visual when possible, otherwise the same exact subtype.
7. Confirm neither hand becomes a Two-Hand, Ranged, Shield, or Holdable appearance.

## Unlinked One-Hand route

1. Disable **Link weapon hands**.
2. Generate repeatedly.
3. Confirm the two hands may differ.
4. Confirm both remain within the chosen One-Hand route and selected subtype filters.

## Linked Two-Hand route

1. Enable only **Two-Hand**.
2. Enable **Link weapon hands**.
3. Generate repeatedly.
4. Confirm Main Hand and Secondary Hand are both selected Two-Hand appearances.
5. Confirm the hands use the same visual when possible, otherwise the same exact Two-Hand subtype.

## Independent shield/focus companion

Use a character or equipment layout with a one-hand weapon and an independently equipped shield or focus:

1. Confirm One-Hand is available.
2. Confirm Off-Hand is available.
3. Confirm Off-Hand subtype choices contain only Shield and Holdable / Focus.
4. Generate with both families enabled.
5. Confirm Main Hand and the companion slot are committed together.
6. Confirm the companion family never represents a second sword, axe, mace, or other weapon.

## Atomic failure behavior

Create a deliberately narrow combination where no complete linked pair can be resolved:

1. Lock or filter a weapon subtype so Main Hand is valid but Secondary Hand has no compatible source.
2. Generate.
3. Confirm Quest Chronicle reports that no complete route could be generated.
4. Confirm the previously displayed Main Hand and Secondary Hand selections remain unchanged.

## Manual and reroll behavior

1. Manually select a Main Hand appearance while linking is enabled.
2. Confirm the Secondary Hand synchronizes through a compatible route.
3. Disable linking and reroll the Secondary Hand.
4. Confirm it remains within the active route family.
5. Confirm browsing Ranged or Off-Hand shows zero appearances when those families have no valid route.

## Regression

- Two-Hand generation from v1.6.8 remains functional.
- Character preview remains full-sized and stable.
- Current Look labels Main Hand and Secondary Hand selections correctly.
- Saved concepts load.
- Linked Custom Sets continue exporting and verifying.
- Chronicle, Active Quests, Write Note, Status, minimap button, and Courier export remain functional.
