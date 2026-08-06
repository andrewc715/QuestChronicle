# Quest Chronicle v1.10.0 Validation Report

## Build identity

```text
Version: 1.10.0
Baseline: Quest Chronicle v1.9.0.15
Baseline SHA-256: 9090655fb8bbec7170698df2b45caae499bdde4da8df67ae6e9dcf32ad49ec66
```

## Automated result

```text
Lua tests: 74 / 74 PASS
Python verifiers: 27 / 27 PASS
Runtime Lua syntax: 125 / 125 PASS
TOC runtime modules: 125, each listed exactly once
Lua line limit: PASS, every file below 500 lines
```

## Structural parity

```text
Original runtime modules: 99
Byte-identical original modules: 91
Changed original modules: 8
New shared-framework modules: 26
Current runtime modules: 125
```

The modified original modules are limited to runtime version fallback, shared dispatch attachment, support-reroll lifecycle attachment, additive diagnostics, and UI routing.

## Behavioral evidence

- All inherited v1.9.0.15 Lua fixtures pass.
- All inherited Phase B through Phase E static guards pass.
- Cache, weapon-index, report-compaction, scheduler, and no-blocking-refresh guards pass.
- A deterministic shared-versus-original orchestration fixture produced identical selections, candidate counts, armor counts, worker steps, and phase call counts.
- Traveler registers as `SHARED_FRAMEWORK`.
- Zone Native, Class Fantasy, and Chronicle Echo register as `LEGACY`.
- No shared root engine contains Traveler mode constants or Traveler scoring logic.

## Remaining gate

Retail live validation cannot be executed in this build environment. The package is ready for the in-game checklist in `V1100_LIVE_VALIDATION_STEPS.md`.
