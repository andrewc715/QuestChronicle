# Quest Chronicle v0.4.0 UI Foundation Live Test

Back up the account-level `QuestChronicle.lua` SavedVariables file before the first test.

## 1. Load and open

1. Install the v0.4.0 `QuestChronicle` folder.
2. Log into the character with the existing Chronicle history.
3. Confirm the login message reports v0.4.0.
4. Run `/qc`.
5. Confirm the standalone window opens and no Lua error appears.
6. Press Escape and confirm the window closes.

## 2. AddOn Compartment

1. Open the AddOn Compartment beside the minimap.
2. Confirm Quest Chronicle is listed with a book icon.
3. Left-click it and confirm the window toggles.
4. Right-click it and confirm Status & Maintenance opens.
5. Hover it and confirm the tooltip appears.

## 3. Chronicle tab

1. Confirm old v0.2 and v0.3 events appear.
2. Cycle all five filter modes.
3. Search for a known quest name.
4. Search for text contained in an RP note.
5. Switch between Newest First and Oldest First.
6. Use Older and Newer page buttons when more than 25 matching events exist.
7. Confirm quest IDs, sequence numbers, timestamps, zones, and levels appear correctly.

## 4. Active Quests tab

1. Confirm the visible active quests match `/qc active 50`.
2. Confirm objectives and ready-for-turn-in state are readable.
3. Click `Rescan Quest Log`.
4. Confirm the sync timestamp changes and no duplicate lifecycle events are created when nothing changed.

## 5. Write Note tab

1. Type a multiline RP note.
2. Close and reopen the window; confirm the unfinished draft returns.
3. Click `Record Note`.
4. Confirm the note clears and a success message appears.
5. Confirm the note appears on the Chronicle tab.
6. Type another note and press Ctrl+Enter.
7. Confirm it records.
8. Test `Record & Close`.

## 6. Status & Maintenance

1. Compare all event counts with `/qc status` and known history.
2. Toggle Chat Notifications off and on.
3. Confirm the equivalent WoW AddOns setting changes with it.
4. Click `Refresh Courier Export`.
5. Confirm the reported snapshot size updates.
6. Run `/reload`, then let Warcraft Quest Chronicle Courier export the new UI-recorded RP note.

## 7. Window behavior

1. Drag the window to a new location.
2. Run `/reload` and confirm it returns there.
3. Enable `Lock window position` under Options → AddOns → Quest Chronicle.
4. Confirm dragging no longer moves it.
5. Disable `Remember window position`, reopen the window, and confirm it returns to the screen center.

## 8. Lifecycle regression

Repeat one short lifecycle test:

1. Accept a quest.
2. Advance an objective.
3. Complete its objectives.
4. Turn it in.
5. Confirm all events appear in the Chronicle window and `/qc recent 20`.
6. Abandon a different quest and confirm it remains `QUEST_ABANDONED`, not `QUEST_REMOVED`.

Report the first Lua error exactly as shown by BugSack/BugGrabber or the default error window, including file and line number.
