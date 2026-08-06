# Quest Chronicle v1.11.0 Cross-Version Parity Report

## Compared releases

```text
Reference: Quest Chronicle v1.10.0
Target:    Quest Chronicle v1.11.0
```

## Difference classification

Every observed difference is classified as:

```text
VERSION_ONLY
ADDITIVE_ZONE_FOUNDATION
DOCUMENTATION_ONLY
SEMANTIC
```

No unexplained semantic difference was found by automated validation.

## Runtime module parity

```text
Original v1.10.0 runtime modules: 125
Byte-identical in v1.11.0:        120
Changed existing modules:           5
New Zone foundation modules:       13
Removed modules:                    0
```

### Changed existing modules

```text
Core/Chronicle/Foundation.lua
Core/Chronicle/Commands.lua
Core/Diagnostics/SnapshotBuilder.lua
Core/Diagnostics/ReportFormatter.lua
Core/Generation/Modes/ZoneLegacyAdapter.lua
```

Classification:

- `Foundation.lua`: `VERSION_ONLY`
- `Commands.lua`: `ADDITIVE_ZONE_FOUNDATION` for `/qc zone debug`
- `SnapshotBuilder.lua`: `ADDITIVE_ZONE_FOUNDATION`
- `ReportFormatter.lua`: `ADDITIVE_ZONE_FOUNDATION`
- `ZoneLegacyAdapter.lua`: `ADDITIVE_ZONE_FOUNDATION`; implementation remains `LEGACY`

### New modules

```text
Core/ZoneStyle/Zone/Foundation.lua
Core/ZoneStyle/Zone/EvidenceLedger.lua
Core/ZoneStyle/Zone/CanonicalStyles.lua
Core/ZoneStyle/Zone/ProfileRegistry.lua
Core/ZoneStyle/Zone/ProvenanceRegistry.lua
Core/ZoneStyle/Zone/StartingZoneRegistry.lua
Core/ZoneStyle/Zone/ContextResolver.lua
Core/ZoneStyle/Zone/Compatibility.lua
Core/ZoneStyle/Zone/Affinity.lua
Core/ZoneStyle/Zone/Debug.lua
Core/Generation/Modes/Zone/Context.lua
Core/Generation/Modes/Zone/Affinity.lua
Core/Generation/Modes/Zone/Diagnostics.lua
```

All are classified `ADDITIVE_ZONE_FOUNDATION`.

## Frozen behavioral providers

The following original areas remain byte-identical:

- Zone legacy scoring and source weighting;
- generation eligibility and progression restrictions;
- era evidence and source metadata;
- independent armor selection;
- outfit motif accumulation;
- weapon topology, legal routes, and weapon selection;
- scheduler budgets and cooperative worker logic;
- Traveler descriptors, cohesion, anchors, support, final validation, repair, and tuning;
- Class Fantasy and Chronicle Echo legacy behavior;
- saved data, wardrobe cache, generation cache, diagnostics format, and Courier export.

## Zone context parity

The compatibility compiler is tested against the saved v1.10.0 resolver functions and requires exact parity for the legacy public context fields.

Confirmed:

```text
Profile key and label:          exact
Profile seed and alias order:   exact
Keywords and avoids:            exact
Era ceiling and labels:         exact
Provenance identity:            exact
Zone and detail keys:           exact
Restriction label:              exact
Suggestion lifecycle:           exact
Starting-zone behavior:         exact
Random values consumed:         zero by new foundation
```

## Mode identity parity

```text
Traveler        SHARED_FRAMEWORK   unchanged
Zone Native     LEGACY             unchanged
Class Fantasy   LEGACY             unchanged
Chronicle Echo  LEGACY             unchanged
```

Zone adds only:

```text
Zone foundation: CONTEXT_EVIDENCE_V1
```

## Saved data and cache parity

```text
SavedVariables schema:          2
Courier format:                 1
Wardrobe cache format:          7
Generation cache:               2
Diagnostic format:              1
Weapon-index format:            1
Traveler tuning audit format:   1
Curated tuning version:         1
```

No migration or reset is required.

## Automated parity verdict

```text
VERSION_ONLY differences:             Expected
ADDITIVE_ZONE_FOUNDATION differences: Expected
DOCUMENTATION_ONLY differences:       Expected
Unexplained SEMANTIC differences:     0
Automated parity:                     PASS
Retail parity:                        Pending
```
