# Quest Chronicle v1.11.4

Quest Chronicle records a character's quest journey, builds zone-aware outfit concepts, and exports verified Blizzard Custom Sets.

Version 1.11.4 repairs the diagnostic-persistence regression discovered during v1.11.3 Retail validation. Zone Native generation and `ZONE_ANCHOR_POLICY_V1` remain behaviorally unchanged, while oversized Zone reports now compact policy duplicates before the 20,480-byte persistence gate.

## v1.11.4 focus

- retain Generate Outfit, Reroll Unlocked, support reroll, and individual-reroll reports in Debug History;
- store the authoritative Zone anchor-policy summary once;
- remove duplicated component policy calculations and persisted per-piece affinity details only when compaction is required;
- preserve selected anchors, policy adjustments, pair channels, weapon deduplication, ancestry, Phase D, warnings, and headline performance;
- print a visible warning and emit `DIAGNOSTIC_REPORT_REJECTED` if a report still cannot be saved.

## Architecture boundary

```text
Traveler implementation:       SHARED_FRAMEWORK
Zone Native implementation:    LEGACY
Zone foundation:               CONTEXT_EVIDENCE_V1
Zone anchor policy:            ZONE_ANCHOR_POLICY_V1 / ACTIVE
Zone support policy:           LEGACY
Class Fantasy implementation:  LEGACY
Chronicle Echo implementation: LEGACY
```

v1.11.4 changes diagnostics only. Zone scoring, candidate order, random consumption, legal weapon routes, support behavior, validation, repair, rerolls, locks, hidden slots, caches, SavedVariables, and Courier output remain unchanged.
