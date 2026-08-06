# Quest Chronicle v1.11.5

## Zone anchor-policy closure

Retail validation of v1.11.4 confirmed that oversized Zone reports persist correctly. It also showed that the final Zone export could hide an earlier valid anchor-policy report when the newest Zone report was a legacy individual reroll, and that cooperative weapon work still produced oversized worker slices.

v1.11.5 closes both gaps without changing Zone selection semantics.

### Fixed

- `/qc zone debug export` independently selects the latest Zone Native report and the latest structurally valid Zone anchor-policy report.
- A newer legacy reroll no longer causes the policy section to claim that no current policy report exists.
- Malformed or partial policy payloads are skipped rather than blended with live state.
- Weapon-style eligibility now advances through bounded provenance-marker batches of four instead of synchronously draining a candidate.
- Weapon capabilities are built or reused once per action and shared by every anchor finalist.
- Explicit route invalidation marks an active capability snapshot stale and blocks atomic commit.

### Diagnostics

- Zone debug export advances from format 3 to format 4.
- Policy lineage reports its source report, action, result, parent, anchor source, and snapshot.
- Performance diagnostics report capability build/reuse state, generation, invalidation reason, bounded eligibility steps and yields, scheduler debt, and post-expensive-call continuations.
- Older policy-bearing reports render unavailable v1.11.5 performance fields as `Not recorded`.

### Preserved

- `ZONE_ANCHOR_POLICY_V1` coefficients and authority;
- Zone candidate eligibility and retained order;
- one random draw per retained weapon candidate in the original order;
- style priorities, sorting, legal routes, and linked-visual behavior;
- contextual support, Phase D validation and repair, rerolls, locks, and hidden state;
- Traveler, Class Fantasy, Chronicle Echo, SavedVariables, cache formats, and Courier behavior.
