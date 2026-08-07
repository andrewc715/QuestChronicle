# Quest Chronicle v1.11.7 Parity Report

## Baseline

```text
Source: QuestChronicle-v1.11.6.zip
SHA-256: fed59975f609ad3de52dedb4b1106bb4cb372eb825a4ea50634914277b10a199
Runtime modules: 149
```

## Runtime boundary

```text
Inherited runtime modules: 149
Byte-identical modules:    138
Changed existing modules:   11
New runtime modules:         0
Removed runtime modules:     0
Final runtime modules:     149
```

Changed runtime modules:

```text
Core/Chronicle/Foundation.lua
Core/Diagnostics/ReportCompaction.lua
Core/Diagnostics/ReportEmergencyStub.lua
Core/Diagnostics/ReportFormatter.lua
Core/Diagnostics/SnapshotBuilder.lua
Core/Diagnostics/SupportReportFormatter.lua
Core/Wardrobe/GenerationPerformance.lua
Core/Wardrobe/GenerationScheduling.lua
Core/Wardrobe/SupportBeam.lua
Core/Wardrobe/SupportWorker.lua
Core/ZoneStyle/Zone/DebugExport.lua
```

## Intentional differences

- support eligibility is resumable rather than synchronously drained;
- fallback scans are resumable rather than full-pool calls;
- stage finalization is admitted only from a fresh slice;
- support timing and scheduling counters are more precise;
- package metadata is `1.11.7`.

## Required parity

Executable fixtures preserve:

- validated source results;
- source completion and pool order;
- candidate random draws;
- fallback winner and exact-tie behavior;
- beam finalist semantics;
- final support selections;
- Zone anchor selection and coefficients;
- weapon routing;
- Phase D result;
- locks, hidden slots, and atomic commit.
