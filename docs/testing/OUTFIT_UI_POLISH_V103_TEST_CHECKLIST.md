# Quest Chronicle v1.0.3 Outfit UI Polish Test Checklist

## Install

1. Exit World of Warcraft completely.
2. Replace the current `QuestChronicle` addon folder with v1.0.3.
3. Log in and open `/qc` → **Outfits**.

No collection rescan or concept migration is required.

## Outfit Concepts footer

1. Click **Concepts**.
2. Confirm the native Custom Set buttons appear together on their own row:
   - **Update Custom Set** or **Save to Custom Sets**
   - **Save as New**
   - **Replace Existing**
3. Confirm the lower row contains:
   - Previous, page number, and Next on the left;
   - **Load Selected** and **Delete** on the right.
4. Confirm no button overlaps another button or the page controls.
5. Test a concept linked to a Custom Set and confirm the longer **Update Custom Set** label fits cleanly.
6. Confirm all five actions still perform their existing functions.

## Generation-mode tooltips

1. Select **Zone**, **Traveler**, **Class**, and **Echo** in turn.
2. After selecting each mode, hover that same active button.
3. Confirm its tooltip still appears.
4. Confirm the active mode remains visually highlighted rather than disabled.
5. Confirm clicking another mode moves the highlight and refreshes the style context.

## Regression

- Generate Outfit and Reroll Unlocked still work.
- Save Concept and Concepts still open the manager.
- Updating the linked Custom Set still verifies all intended slots.
- Chronicle, Active Quests, Write Note, and Status still open normally.
