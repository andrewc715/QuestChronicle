# Quest Chronicle 0.4.0 Lifecycle Regression Checklist

Use a disposable low-stakes quest for this test after the UI foundation checklist. This confirms the v0.3.0 recorder still behaves identically beneath the new interface.

1. Log in and run `/qc status`.
2. Run `/qc active 50`; existing quests should appear without new acceptance spam.
3. Accept one quest. Expect one `Recorded acceptance` notice.
4. Run `/qc recent 10`; confirm a `QUEST_ACCEPTED` entry.
5. Advance one objective. Wait one second.
6. Run `/qc recent 10`; confirm a `QUEST_OBJECTIVE_UPDATED` entry.
7. Complete the final objective without turning in. Confirm a `QUEST_STATE_CHANGED` entry to `READY_FOR_TURN_IN`.
8. Abandon a different unfinished disposable quest. Confirm `QUEST_ABANDONED`, not merely `QUEST_REMOVED`.
9. Turn in the completed quest. Confirm `QUEST_TURNED_IN` and no duplicate abandonment/removal event for it.
10. Run `/qc active`; both removed quests should be absent.
11. Run `/qc export`, then `/reload`.
12. Preview the Courier and confirm the new event types appear after updating `includeEventTypes`.

If abandonment appears as `QUEST_REMOVED` with `UNKNOWN_REMOVAL`, save the Lua error output, the recent event list, and the quest ID. That would indicate the built-in abandonment hook behaved differently in the current client build.
