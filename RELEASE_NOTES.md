# Quest Chronicle v0.4.1 Release Notes

Version 0.4.1 is the first polish pass over the successfully live-tested v0.4.0 interface.

The recorder, lifecycle classification, SavedVariables schema, and Courier JSON structure remain unchanged. The work is concentrated in presentation, navigation, drafting safety, and window behavior.

## Headline improvements

- Raw quest states are now rendered as friendly phrases.
- Active Quest objectives use reliable text labels instead of missing-glyph squares.
- Ready-for-turn-in quests can be surfaced first or filtered exclusively.
- Chronicle pages can be grouped by date and remember their search text.
- RP-note drafting has placeholder text, safer clearing, button-state feedback, and character-limit warnings.
- The main window can be resized, remembers its dimensions, and can be reset from Status.
- Status now includes addon/schema/Courier versions plus objective and state-change totals.

## Compatibility promises

- Existing Chronicle history is preserved.
- Data schema remains version 2.
- Courier export format remains version 1.
- Warcraft Quest Chronicle Courier v1.0.0 requires no configuration or parser update.
- Every previous slash command remains available.

## Validation completed before packaging

- Lua syntax compilation for all addon Lua files.
- Mock creation of the full window and every tab.
- Friendly quest-state and removal-reason formatting.
- Date grouping and large-number formatting.
- Chronicle rendering without raw `READY_FOR_TURN_IN` strings.
- Active Quest ready-first display and objective-label rendering.
- RP-note draft preservation and placeholder behavior.
- Status version/count rendering.
- Window reset behavior.

The remaining validation step is rendering and interaction in the live Retail client.
