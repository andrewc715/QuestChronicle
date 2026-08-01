# Quest Chronicle 0.3.0

Quest Chronicle records a character's quest journey inside World of Warcraft Retail and prepares a JSON snapshot for Warcraft Quest Chronicle Courier.

Version 0.3.0 expands the Chronicle from completions and RP notes into a lifecycle recorder.

## New in 0.3.0

- Records standard quest acceptance.
- Maintains an exported snapshot of the character's currently active quests.
- Records objective progress and intermediate objective stages.
- Records quest state changes such as `ACTIVE`, `READY_FOR_TURN_IN`, and `FAILED`.
- Records confirmed player abandonment as `QUEST_ABANDONED`.
- Separately records uncertain or automatic removals as `QUEST_REMOVED`.
- Preserves initial and final objective snapshots on acceptance, abandonment, and turn-in events.
- Keeps the Courier format version at 1 for compatibility while advancing the addon data schema to 2.

Existing Quest Chronicle 0.1.0 and 0.2.0 data remains in `QuestChronicleDB`. Old events are not rewritten or discarded.

## Install or upgrade

1. Close World of Warcraft completely.
2. Back up:

   `World of Warcraft\_retail_\WTF\Account\<ACCOUNT>\SavedVariables\QuestChronicle.lua`

3. Replace the existing `QuestChronicle` addon folder with the folder from this archive.
4. Launch WoW and verify that Quest Chronicle is enabled.
5. Log in and run `/qc status`.
6. Run `/qc active` to inspect the baseline active-quest snapshot.
7. Accept a disposable quest, advance one objective, and abandon it to perform the first live lifecycle test.
8. Run `/reload` so WoW writes the updated SavedVariables file for the Courier.

## Event types

- `QUEST_ACCEPTED`
- `QUEST_BECAME_ACTIVE`
- `QUEST_OBJECTIVE_UPDATED`
- `QUEST_STATE_CHANGED`
- `QUEST_ABANDONED`
- `QUEST_REMOVED`
- `QUEST_TURNED_IN`
- `RP_NOTE`

## Abandonment accuracy

WoW's `QUEST_REMOVED` event does not prove that the player clicked **Abandon Quest**. Quests may also disappear because an event expired, a dynamic task ended, phasing changed, or the game removed the quest through a script.

Quest Chronicle therefore hooks the normal quest-log abandonment flow:

- A removal following the player's confirmed abandonment call becomes `QUEST_ABANDONED` with `removalConfidence = CONFIRMED`.
- Other removals become `QUEST_REMOVED` with an explanatory reason and `removalConfidence = UNCONFIRMED`.

This intentionally favors an honest Chronicle over a dramatic but inaccurate one.

## Objective behavior

Quest Chronicle diffs the current quest state against the previous snapshot. Although `QUEST_LOG_UPDATE` can fire frequently, an event is stored only when an objective or quest state actually changed.

Rapid changes may be coalesced by the short synchronization delay. For example, several progress increments occurring within roughly a third of a second may appear as one intermediate jump.

Each objective event can include:

- objective index;
- displayed objective text;
- objective type;
- completed state;
- fulfilled and required values;
- previous objective values;
- the event that caused the quest-log rescan.

## Active quest snapshot

Each character now has `activeQuests` in both `QuestChronicleDB` and `QuestChronicleCourierExport`.

A quest that was already active when 0.3.0 was first installed is added to the baseline snapshot without inventing a historical acceptance event. New quests accepted afterward receive acceptance events normally.

## Commands

- `/qc status`
- `/qc recent 10`
- `/qc active 25`
- `/qc sync`
- `/qc note <roleplay observation>`
- `/qc export`
- `/qc on` and `/qc off`
- `/qc chat on` and `/qc chat off`
- `/qc lifecycle on` and `/qc lifecycle off`
- `/qc objectives on` and `/qc objectives off`
- `/qc removals on` and `/qc removals off`

`/qc export` rescans the quest log and refreshes the in-memory JSON snapshot. Run `/reload` afterward to write it to disk immediately.

## Courier configuration

Warcraft Quest Chronicle Courier 1.0.0 was initially configured for only completions and RP notes. To deliver the new lifecycle events, expand `includeEventTypes` in its live configuration to:

```json
"includeEventTypes": [
  "QUEST_ACCEPTED",
  "QUEST_BECAME_ACTIVE",
  "QUEST_OBJECTIVE_UPDATED",
  "QUEST_STATE_CHANGED",
  "QUEST_ABANDONED",
  "QUEST_REMOVED",
  "QUEST_TURNED_IN",
  "RP_NOTE"
]
```

The existing Courier may preserve the new events in JSON while presenting unfamiliar event types generically in text output. A companion Courier update can add purpose-built human-readable formatting and active-quest sections.

## Known boundaries

- The addon can only observe events while it is enabled and the character is logged in.
- Quests abandoned while the addon is disabled cannot be reconstructed later.
- Quests already active at first 0.3.0 login receive a baseline state but no invented acceptance timestamp.
- Bonus objectives and temporary task quests can behave differently from ordinary quest-log entries. They may be recorded as `QUEST_BECAME_ACTIVE` and later `QUEST_REMOVED` rather than normal acceptance and abandonment.
- Some hidden or heavily scripted quests may expose incomplete objective information through the public UI API.
- WoW writes SavedVariables on `/reload`, logout, or game exit. The Courier cannot see unsaved in-memory changes.
