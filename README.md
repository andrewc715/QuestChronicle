# Quest Chronicle v1.11.6

Quest Chronicle records a character's quest journey, builds zone-aware outfit concepts, and exports verified Blizzard Custom Sets.

Version 1.11.6 guarantees that valid diagnostic actions leave a retained Debug History record even when their full payload exceeds the fixed persistence ceiling. It replaces fixed one-pass trimming with exact-size adaptive compaction tiers and an emergency mandatory-core stub.

## v1.11.6 focus

- measure the exact serialized report size after every compaction tier;
- continue deterministically from duplicate trimming through mandatory-core compaction until the report fits;
- retain action identity, Zone context and policy, selected anchors, capability and scheduler summaries, support outcome, Phase D state, warnings, and final message;
- preserve a compact emergency report rather than discarding a valid generation action;
- record original bytes, final bytes, compaction tier, and emergency-stub state in every compacted report;
- keep visible rejection handling only as an impossible-ceiling final guard.

## Architecture boundary

```text
Traveler implementation:       SHARED_FRAMEWORK
Zone Native implementation:    LEGACY
Zone foundation:               CONTEXT_EVIDENCE_V1
Zone anchor policy:            ZONE_ANCHOR_POLICY_V1 / ACTIVE
Zone support policy:           LEGACY
Diagnostic format:             1
Report persistence ceiling:    20,480 bytes
Adaptive compaction format:    1
```

v1.11.6 changes diagnostic storage only. Zone scoring, candidate order, random consumption, anchor selection, weapon routes, support, validation, repair, rerolls, locks, hidden state, SavedVariables, cache formats, and Courier output remain unchanged.
