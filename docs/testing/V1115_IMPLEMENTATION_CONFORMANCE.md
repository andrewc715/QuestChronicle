# Quest Chronicle v1.11.5 Implementation Conformance

## Scope conformance

v1.11.5 implements the approved Zone anchor-policy lineage and cooperative performance closure only.

### Implemented

- independent latest Zone Native and latest valid policy-bearing report selectors;
- structural policy validation requiring mode, policy ID, authority, and snapshot or fallback evidence;
- Zone debug export format 4 and explicit lineage wording;
- compact policy-performance summary sourced from the policy-bearing report;
- bounded weapon eligibility stepping with marker batch 4;
- preserved reverse eligibility traversal and forward scoring order;
- exactly one random draw per retained candidate;
- one cached capability snapshot attached to each generation job;
- route-invalidation integration and capability-generation stale check at commit;
- capability and ordering telemetry in immutable diagnostic snapshots;
- executable parity, lineage, invalidation, and stale-commit tests.

### Not changed

- Zone anchor-policy constants or formulas;
- eligibility results, provenance, era, promotions, favorites, or exclusions;
- anchor beam widths, novelty classes, or repeat penalties;
- contextual support, final validation, repair, or reroll policies;
- synchronous legacy individual anchor/weapon rerolls;
- scheduler budgets;
- SavedVariables, Courier, wardrobe cache, generation cache, diagnostic format, context format, or affinity format;
- Traveler, Class Fantasy, or Chronicle Echo policy behavior.

## Data compatibility

```text
SavedVariables schema: 2
Courier format: 1
Wardrobe cache: 7
Generation cache: 2
Diagnostic format: 1
Zone Context Snapshot: 1
Zone Affinity: 2
Zone debug export: 4
Zone anchor policy: 1
```

No migration or reset is required.

## Versioning conformance

The release is exactly:

```text
v1.11.5
```

No alpha, beta, release-candidate, or letter suffix is used.
