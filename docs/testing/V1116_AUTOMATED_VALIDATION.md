# Quest Chronicle v1.11.6 Automated Validation

## Exact-package results

The final package was extracted into a clean directory and all gates were rerun against the extracted files.

```text
Lua regression tests:      97 / 97 PASS
Python static verifiers:   34 / 34 PASS
Runtime Lua syntax:       149 / 149 PASS
TOC runtime modules:      149 / 149 exactly once
Runtime Lua files >= 500:   0
ZIP integrity:              PASS
Fresh extraction:          PASS
```

Lua regression tests were executed with the available Lua 5.3.6-compatible `texlua` runtime. Runtime files were parsed individually with `texluac -p`.

## Adaptive-budget fixture

The principal fixture begins with an exact serialized report of `8,147,167` bytes. It requires adaptive persistence below the frozen 20,480-byte limit while retaining:

- `ZONE_ANCHOR_POLICY_V1` identity and five selected anchors;
- weapon capability eligibility counters;
- scheduler post-expensive-call integrity;
- support final validation and Phase D final state;
- selected skeleton identities;
- exact equality between encoded byte length, `approximateBytes`, and `compaction.finalBytes`.

The fixture persisted through `EMERGENCY_STUB` at `13,787` bytes.

A second pathological report also persisted through the emergency tier without printing a rejection or emitting `DIAGNOSTIC_REPORT_REJECTED`.

## Final guard fixture

An artificially impossible 128-byte ceiling verifies that the last-resort rejection path remains visible in chat and emits `DIAGNOSTIC_REPORT_REJECTED` when even a minimal valid stub cannot fit.

## Runtime boundary

```text
v1.11.5 runtime modules: 148
Byte-identical modules:  144
Changed existing:          4
New runtime modules:       1
Removed modules:           0
v1.11.6 runtime modules: 149
```

Changed existing modules:

```text
Core/Chronicle/Foundation.lua
Core/Diagnostics/History.lua
Core/Diagnostics/ReportCompaction.lua
Core/Diagnostics/ReportFormatter.lua
```

New module:

```text
Core/Diagnostics/ReportEmergencyStub.lua
```
