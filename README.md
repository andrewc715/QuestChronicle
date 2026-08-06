# Quest Chronicle v1.11.5

Quest Chronicle records a character's quest journey, builds zone-aware outfit concepts, and exports verified Blizzard Custom Sets.

Version 1.11.5 closes the first authoritative Zone anchor-policy slice. `/qc zone debug export` now distinguishes the newest Zone Native report from the newest report carrying a structurally valid `ZONE_ANCHOR_POLICY_V1` payload, while the cooperative weapon path performs bounded eligibility work and reuses one capability snapshot throughout each generation action.

## v1.11.5 focus

- advance Zone debug export to format 4 with independent latest-report and policy-report lineage;
- preserve the newest valid Zone policy report when a newer legacy individual reroll has no policy payload;
- replace synchronous weapon-style eligibility draining with bounded marker batches of four;
- preserve the exact retained-candidate order, random-call count, style priorities, and selected weapon routes;
- build or reuse one weapon capability snapshot per action and cancel atomically if explicit route invalidation makes it stale;
- expose capability builds, reuses, eligibility steps, eligibility yields, scheduler debt, and post-expensive-call continuations.

## Architecture boundary

```text
Traveler implementation:       SHARED_FRAMEWORK
Zone Native implementation:    LEGACY
Zone foundation:               CONTEXT_EVIDENCE_V1
Zone anchor policy:            ZONE_ANCHOR_POLICY_V1 / ACTIVE
Zone support policy:           LEGACY
Class Fantasy implementation:  LEGACY
Chronicle Echo implementation: LEGACY
Zone debug export:             4
```

v1.11.5 changes report selection and cooperative scheduling only. Zone policy coefficients, candidate eligibility results, random consumption, selected anchors, legal weapon routes, support behavior, validation, repair, rerolls, locks, hidden slots, SavedVariables, cache formats, and Courier output remain unchanged.
