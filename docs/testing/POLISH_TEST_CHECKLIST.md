# Quest Chronicle v0.4.1 Polish Test Checklist

Back up `QuestChronicle.lua` SavedVariables before replacing the addon folder.

## 1. Upgrade and history

- Log in with the same character used for v0.4.0.
- Open `/qc`.
- Confirm the event count, active quest count, RP notes, and historical pages remain intact.
- Confirm Status reports version `0.4.1`, schema `2`, and Courier format `1`.

## 2. Chronicle polish

- Confirm raw states such as `READY_FOR_TURN_IN` now display as `Ready for Turn-In`.
- Confirm events are grouped beneath readable date headings.
- Search for a quest name, quest ID, location, state phrase, and RP-note phrase.
- Close and reopen the window; confirm the search text remains.
- Use Clear Search.
- Cycle every filter and both sort orders.
- Confirm page labels show a sensible event range.
- Toggle **Show quest IDs in the UI** and **Group Chronicle events by date** in WoW Settings.

## 3. Active Quest polish

- Confirm objective rows say `Complete` or `In Progress` instead of displaying empty square glyphs.
- Confirm quest states use friendly labels.
- Cycle filters: All Quests, Ready for Turn-In, Active, Failed.
- Cycle sorts: Ready First, Quest Name, Recently Accepted.
- Confirm ready-for-turn-in quests appear first under Ready First.
- Press Rescan Quest Log and confirm counts remain consistent.

## 4. RP-note editor

- Confirm the empty editor shows a character-specific prompt.
- Type a draft, close the window, and reopen it; confirm the draft returns.
- Confirm Record buttons disable when the draft is empty.
- Press Clear Draft and verify the confirmation prompt.
- Disable clear confirmation in WoW Settings and verify clearing becomes immediate.
- Record a note with Ctrl+Enter.
- Record another with Record & Close.
- Confirm both notes appear in Chronicle and remain Courier-compatible.

## 5. Window behavior

- Drag the resize grip in the lower-right corner.
- Close and reopen the window; confirm its size and position return.
- Enable **Lock window position and size** and confirm dragging/resizing is blocked.
- Use Status → Reset Window and confirm the default centered size returns.

## 6. Recorder regression

- Accept a quest.
- Advance an objective.
- Finish its objectives.
- Turn it in.
- Deliberately abandon another quest.
- Run `/qc recent 20`.
- Confirm lifecycle events still record and state summaries use friendly labels.

## 7. Courier regression

- Refresh Courier Export from Status.
- Run `/reload`.
- Confirm Warcraft Quest Chronicle Courier v1.0.0 exports the new events without configuration changes or duplicate deliveries.
