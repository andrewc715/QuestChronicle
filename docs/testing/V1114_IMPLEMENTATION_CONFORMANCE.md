# Quest Chronicle v1.11.4 Implementation Conformance

## Scope conformance

v1.11.4 implements the approved diagnostic-persistence repair only.

### Implemented

- dedicated `ReportCompaction.lua` responsibility;
- policy-aware Zone duplicate removal;
- aggregate Zone policy preservation;
- support-profile and Phase D preservation;
- visible chat warning for rejected reports;
- `DIAGNOSTIC_REPORT_REJECTED` callback event;
- realistic near-limit report regression;
- rejection-visibility regression;
- exact-package validation plan.

### Not changed

- Zone anchor policy scoring;
- Zone affinity formulas;
- anchor beam mechanics;
- random consumption;
- support selection;
- final validation and repair;
- reroll behavior;
- weapon topology;
- cache formats;
- diagnostic format;
- UI layout;
- other generation modes.

## Architectural boundaries

```text
ReportCompaction.lua
  owns what may be removed and in what order

History.lua
  owns whether a report is accepted and how failure is surfaced

SnapshotBuilder.lua
  remains byte-identical and continues producing immutable snapshots

Generation modules
  remain byte-identical to v1.11.3
```

## Data compatibility

```text
SavedVariables schema: 2
Courier format: 1
Wardrobe cache: 7
Generation cache: 2
Diagnostic format: 1
Zone Context Snapshot: 1
Zone Affinity: 2
Zone export: 3
Zone anchor policy: 1
```

No migration or reset is required.

## Versioning conformance

The release is exactly:

```text
v1.11.4
```

No alpha, beta, release-candidate, or letter suffix is used.
