# Quest Chronicle v1.11.4

## Diagnostic persistence repair

Retail validation of v1.11.3 proved that `ZONE_ANCHOR_POLICY_V1` was active, but realistic Zone reports could remain above the 20,480-byte persistence ceiling after the existing compaction passes. `AddReport()` rejected those reports, and the asynchronous generation path did not surface the rejection.

v1.11.4 fixes that failure without changing Zone generation behavior.

### Fixed

- Zone policy details are stored once in `zoneFoundation.anchorPolicy` instead of being duplicated inside every selected skeleton component when compaction is required.
- Persisted per-piece Zone affinity detail is removed only from oversized reports; the aggregate affinity and live `/qc zone debug export` remain complete.
- Generate Outfit, Reroll Unlocked, contextual support rerolls, and individual rerolls can again enter Debug History.
- An uncompactable report now prints `Debug report could not be saved: ...` and emits `DIAGNOSTIC_REPORT_REJECTED`.

### Preserved

- `ZONE_ANCHOR_POLICY_V1` coefficients and authority;
- all Zone candidate and pair scores;
- shared anchor beam behavior and random consumption;
- legal weapon topology and linked-visual deduplication;
- Zone support, final validation, repair, and rerolls;
- Traveler, Class Fantasy, and Chronicle Echo behavior;
- diagnostic format 1 and the 20,480-byte persistence ceiling.
