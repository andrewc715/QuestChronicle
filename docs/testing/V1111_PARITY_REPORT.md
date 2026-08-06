# Quest Chronicle v1.11.1 Cross-Version Parity Report

## Compared releases

```text
Reference: Quest Chronicle v1.11.0
Target:    Quest Chronicle v1.11.1
```

## Difference classes

```text
VERSION_ONLY
ADDITIVE_ZONE_DEBUG_EXPORT
DOCUMENTATION_ONLY
SEMANTIC
```

No unexplained semantic difference was found by automated validation.

## Runtime parity

The v1.11.0 package contains 138 runtime Lua modules.

```text
Byte-identical original modules: 135
Changed existing modules:          3
New runtime modules:               2
Removed runtime modules:           0
Current runtime modules:          140
```

### Changed existing modules

```text
Core/Chronicle/Foundation.lua
Core/Chronicle/Commands.lua
UI/DebugReport.lua
```

Classifications:

- `Foundation.lua`: `VERSION_ONLY`
- `Commands.lua`: `ADDITIVE_ZONE_DEBUG_EXPORT`
- `DebugReport.lua`: `ADDITIVE_ZONE_DEBUG_EXPORT`

### New runtime modules

```text
Core/Chronicle/ZoneDebugCommands.lua
Core/ZoneStyle/Zone/DebugExport.lua
```

Both are classified `ADDITIVE_ZONE_DEBUG_EXPORT`.

## Frozen behavior

The following remain byte-identical to v1.11.0:

- every Zone context, registry, compatibility, affinity, and compact-debug provider;
- legacy Zone scoring and independent slot selection;
- eligibility, provenance, era, favorites, exclusions, and suggestion behavior;
- all Traveler shared-framework modules and calibrated scoring;
- Class Fantasy and Chronicle Echo adapters;
- weapon topology and routes;
- scheduler behavior;
- caches, reports, SavedVariables, and Courier formats.

## Export neutrality

The new exporter:

- reads the current immutable Zone snapshot;
- reads selected-look affinity;
- reads generation-mode capabilities;
- reads the latest Zone Native report summary;
- produces a transient Markdown string;
- opens the existing Debug Workbench copy dialog.

It does not:

- enumerate generation candidates;
- invoke scoring or generation;
- consume random values;
- commit or alter preview state;
- create a diagnostic report;
- write a persistent export;
- change Courier output.

## Compatibility formats

```text
SavedVariables schema:          2
Courier format:                 1
Wardrobe cache format:          7
Generation cache:               2
Diagnostic format:              1
Weapon-index format:            1
Traveler tuning audit format:   1
Curated tuning version:         1
Zone context format:            1
Zone affinity format:           1
Zone debug export format:       1
```

No migration or reset is required.

## Automated parity verdict

```text
VERSION_ONLY differences:              Expected
ADDITIVE_ZONE_DEBUG_EXPORT differences: Expected
DOCUMENTATION_ONLY differences:        Expected
Unexplained SEMANTIC differences:      0
Automated parity:                      PASS
Retail parity:                         Pending
```
