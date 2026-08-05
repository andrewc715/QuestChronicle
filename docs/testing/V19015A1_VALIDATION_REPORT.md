# Quest Chronicle v1.9.0.15a1 Automated Validation Report

## Results

- 67 Lua regression harnesses passed.
- 25 Python static verifiers passed.
- 166 Lua files passed syntax validation.
- 98 runtime Lua modules were present exactly once in the TOC.
- 1 JSON configuration passed validation.
- Every runtime Lua file remained below 500 physical lines.
- No runtime call to the blocking transmog usability refresh exists.
- Split-helper references, version metadata, diagnostics, Phase B, Phase C, Phase D, scheduler, cache, and weapon-index guards passed.

## Phase E-specific coverage

- audit disabled behavior;
- start, stop, status, export, and confirmed clear;
- stable identity precedence;
- linked weapon deduplication;
- repair target and replacement accounting;
- palette-overflow and zero-echo accounting;
- severe and worst-outlier accounting;
- repeat-offender thresholds;
- duplicate-report isolation;
- observer failure containment;
- 300-identity cap and deterministic pruning;
- sample-report and context caps;
- bounded Markdown export;
- no audit payload inside normal diagnostic snapshots;
- no curated override module in the observation build.
- live-profile support-reroll ledger reconciliation when parent-report totals are stale.

## Parity

All 63 shared v1.9.0.14 Lua harnesses passed in both versions. Sixty-two outputs were byte-identical; the only difference was wall-clock benchmark timing.

## Status

Automated-validated observation build. Retail validation of the commands and export UI is required before beginning the 20-to-30-action tuning batch.
