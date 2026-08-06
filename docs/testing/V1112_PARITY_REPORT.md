# Quest Chronicle v1.11.2 Cross-Version Parity Report

## Baseline

```text
Baseline: Quest Chronicle v1.11.1
Target:   Quest Chronicle v1.11.2
```

## Runtime boundary

```text
v1.11.1 runtime modules:      140
Byte-identical modules:       135
Changed existing modules:       5
New runtime modules:             1
Removed runtime modules:         0
v1.11.2 runtime modules:       141
```

Changed existing modules:

```text
Core/Chronicle/Foundation.lua
Core/Diagnostics/SnapshotBuilder.lua
Core/ZoneStyle/Zone/Affinity.lua
Core/ZoneStyle/Zone/DebugExport.lua
Core/ZoneStyle/Zone/Foundation.lua
```

New runtime module:

```text
Core/ZoneStyle/Zone/ExportEncoding.lua
```

## Frozen behavior

The following remain unchanged:

- Zone Context Snapshot format and fingerprint inputs;
- profile, provenance, starting-zone, and era registries;
- profile identity, era, provenance, restrictions, and evidence ancestry;
- Zone Native legacy scoring, eligibility, selection, and random consumption;
- suggestions, favorites, exclusions, locks, and hidden state;
- legal weapon routes;
- Traveler shared-framework behavior;
- Class Fantasy and Chronicle Echo legacy behavior;
- SavedVariables, Courier, wardrobe-cache, generation-cache, and diagnostic formats.

## Allowed differences

```text
VERSION_ONLY
EXPORT_ENCODING_ONLY
AFFINITY_STATUS_ONLY
ADDITIVE_FORMAT_METADATA
DOCUMENTATION_ONLY
```

## Numeric fixture

The v1.11.1 Netherstorm fixture remains:

```text
Selected pieces: 12
Mean affinity: 0.291
Mean confidence: 0.536
OFF_ZONE_SIGNAL: 5
PARTIAL_EVIDENCE: 2
WEAK_LOCAL_SIGNAL: 5
```

Automated component tests confirm `NOT_APPLICABLE` contributes no score weight, confidence weight, or missing-channel warning.

## Result

```text
Automated semantic parity: PASS
Retail clipboard parity: Pending
```
