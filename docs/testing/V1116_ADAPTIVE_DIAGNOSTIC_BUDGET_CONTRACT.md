# Quest Chronicle v1.11.6 Adaptive Diagnostic Budget Contract

## Fixed limits

```text
Diagnostic format: 1
Per-report ceiling: 20,480 bytes
History ceiling: 204,800 bytes
Maximum retained reports: 10
Adaptive compaction format: 1
```

No limit is raised.

## Tier order

```text
0 NONE
1 DUPLICATE_FIELDS
2 RECONSTRUCTIBLE_DETAIL
3 SUMMARY_TABLES
4 MANDATORY_CORE
5 EMERGENCY_STUB
6 MINIMAL_STUB
```

The serialized report is measured after every tier. Compaction stops at the first tier that fits.

## Mandatory core

Tier 4 and the emergency tier preserve the information needed to understand the completed action:

- report and lineage identity;
- action, mode, result, character, context, outfit name, and message;
- selected anchor identities and score headline;
- Zone foundation and affinity headline;
- `ZONE_ANCHOR_POLICY_V1` identity, authority, selected adjustments, pair summary, and pool counts;
- weapon capability and scheduler-integrity summary;
- support budget, configuration, and final validation state;
- Phase D before/after state and compact repair entries;
- warnings and compaction telemetry.

## Exact measurement

Production uses `QuestChronicle._Core.JsonEncode`. The persisted `approximateBytes` and `compaction.finalBytes` stabilize against that exact serialized representation.

## Failure boundary

A valid report should reach tier 5 or tier 6 rather than be discarded. `DIAGNOSTIC_REPORT_REJECTED` remains only for malformed input or an artificially impossible ceiling where even the minimal action stub cannot fit.
