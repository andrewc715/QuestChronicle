# Quest Chronicle v1.9.0.14 Automated Validation Report

## Result

All automated validation completed successfully.

```text
63 Lua regression harnesses passed
24 Python static verification tools passed
159 Lua files passed syntax validation
95 runtime Lua modules verified in the TOC
1 JSON configuration validated
Every runtime Lua file remained below 500 physical lines
No blocking transmog usability refresh call found
No orphaned split-helper references found
```

## Dedicated Phase D coverage

- Exact 2.00 and 2.01 mismatch boundary
- Exact 0.720 and 0.721 severity boundary
- Three and four palette-family boundary
- Loud zero-echo and supported-echo behavior
- Locked-only override
- Clean path with zero repairs and unchanged selections
- Deterministic two-pass repair
- No third repair pass
- Alternate-skeleton escalation
- Alternate ordering inside the original quality window
- Compact maximum-detail formatted report below 20 KB
- Compact maximum-detail persisted snapshot below 20 KB
- Oversized live-style diagnostic report compacted and retained in Debug History
- Compacted support profiles continue formatting active-anchor labels

## Size gates

```text
Maximum-detail formatted Phase D report: 7,688 bytes
Maximum-detail persisted Phase D snapshot: 18,337 bytes
Maximum allowed persisted report: 20,480 bytes
Oversized-report retention regression: passed after compaction
```

## Retail status

The package is an automated-validated release candidate. Retail live validation remains required before v1.9.0.14 replaces v1.9.0.13 as the live-validated baseline.
