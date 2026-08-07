# Quest Chronicle v1.11.9

## Cooperative era execution-boundary correction

- Fixed the v1.11.8 `script ran too long` failure caused by synchronously draining a cooperative era worker after `DEFERRED`.
- Added explicit era execution contracts and scheduler ownership.
- Removed eager synchronous era lookup from cached eligibility construction.
- Added nested cooperative era stages to cached and raw eligibility.
- Made synchronous era resolution non-deferring with direct forward-progress protection.
- Isolated background era reevaluation from ambient foreground scheduler state.
- Added watchdog-integrity diagnostics and retained them through adaptive report compaction and Zone export format 4.

No Zone scoring, support scoring, evidence precedence, random order, weapon-route legality, persistence format, or policy coefficient changes are included.
