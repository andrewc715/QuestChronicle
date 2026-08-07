# Quest Chronicle v1.11.8 Parity Report

## Baseline

```text
Source: QuestChronicle-v1.11.7.zip
SHA-256: e0eddc6c6c66d407a0960dc1355c89a64845db68792293c9d0c9055b6d449ff0
Runtime modules: 149
```

## Runtime boundary

```text
Inherited runtime modules: 149
Byte-identical modules:    133
Changed existing modules:   16
New runtime modules:         2
Removed runtime modules:     0
Final runtime modules:     151
```

New runtime modules:

```text
Core/ZoneStyle/EraCandidateWork.lua
Core/Diagnostics/EraPerformanceFormatter.lua
```

Changed existing runtime modules:

```text
Core/Chronicle/Foundation.lua
Core/Diagnostics/ReportCompaction.lua
Core/Diagnostics/ReportEmergencyStub.lua
Core/Diagnostics/ReportFormatter.lua
Core/Diagnostics/SnapshotBuilder.lua
Core/Wardrobe/AnchorSkeletonWorker.lua
Core/Wardrobe/AppearanceMetadata.lua
Core/Wardrobe/GenerationPerformance.lua
Core/Wardrobe/GenerationWorker.lua
Core/Wardrobe/PendingEvidenceResolver.lua
Core/Wardrobe/SupportRerollScheduling.lua
Core/Wardrobe/SupportRerollScoring.lua
Core/Wardrobe/SupportRerollWorker.lua
Core/Wardrobe/SupportWorker.lua
Core/ZoneStyle/EraEvidence.lua
Core/ZoneStyle/Zone/DebugExport.lua
```

## Intentional differences

- one per-sibling era pipeline is now a resumable state machine;
- variable external evidence stages require fresh-slice admission;
- stable non-pending sibling fragments may be reused in session memory;
- era diagnostics identify the exact bounded subphase;
- package metadata is `1.11.8`.

## Required parity

Executable fixtures preserve the exact v1.11.7 candidate evidence tuple and aggregate sibling semantics. The complete inherited generation regression wall remains green, protecting candidate ordering, Zone policy adjustments, selected anchors, support selection, weapon routing, Phase D, locks, hidden slots, and random-consumption behavior.
