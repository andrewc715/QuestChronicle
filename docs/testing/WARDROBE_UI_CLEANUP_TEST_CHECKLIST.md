# Quest Chronicle v0.5.3 Wardrobe UI Cleanup Test Checklist

## Install

1. Exit World of Warcraft completely.
2. Replace the existing `QuestChronicle` addon folder with v0.5.3.
3. Log in and open `/qc`.
4. Open **Outfits**. The v0.5.2 wardrobe cache should remain available without a forced rescan.

## Browser layout

1. Select a slot with many appearances, such as Head or Chest.
2. Confirm the right panel shows:
   - the slot title and Scan Collection button on the first line;
   - the selected appearance and Clear Slot control on the second line;
   - a compact scan summary below;
   - seven appearance rows;
   - Previous on the left, page text centered, and Next on the right.
3. Confirm no appearance row overlaps the pagination footer.
4. Confirm no footer buttons overlap one another at the minimum window size.
5. Resize the Quest Chronicle window taller and shorter within its allowed range and verify the layout remains stable.

## Paging

1. Click **Next** and **Previous**.
2. Hover the appearance list and use the mouse wheel.
3. Confirm page numbers change correctly and stop at the first and last page.

## Diagnostics

1. Hover the compact scan-summary text.
2. Confirm the tooltip explains:
   - cached previewable visuals;
   - WoW's collected source count;
   - returned appearance and source rows when available;
   - why those values do not necessarily match.
3. Confirm the old red warning about mismatched counts no longer appears after a healthy non-empty scan.

## Selection

1. Select an appearance and confirm the row highlights and the model updates.
2. Confirm **Clear Slot** becomes enabled and clears only that slot.
3. Confirm **Clear Selections** still clears the complete manual preview.

## Regression

- Chronicle, Active Quests, Write Note, and Status tabs still open.
- `/qc recent 20` still works.
- Existing Chronicle history and Courier exports remain unchanged.
