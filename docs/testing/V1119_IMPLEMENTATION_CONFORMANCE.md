# Quest Chronicle v1.11.9 Implementation Conformance

## Architecture

The implementation conforms to the approved v1.11.9 plan:

- one explicit era execution-contract module is loaded before era evidence;
- source-era work stores immutable execution mode and scheduler owner;
- ordinary foreground admission uses the work-owned scheduler context;
- synchronous source-era work cannot depend on `forceYield` or return `DEFERRED`;
- cached eligibility owns unresolved era work before cache-key creation;
- raw eligibility owns unresolved era work before era application;
- weapon style ordering passes the active generation job into cached eligibility;
- generation, anchor, support, and modern support-reroll workers pass explicit era ownership;
- pending background reevaluation uses `BACKGROUND_TICK`;
- same-slice deferred retries and synchronous progress-guard trips are reportable integrity counters.

## Preserved architecture identity

- Traveler: `SHARED_FRAMEWORK`
- Zone Native: `LEGACY`
- Zone foundation: `CONTEXT_EVIDENCE_V1`
- Zone anchor policy: `ZONE_ANCHOR_POLICY_V1` / `ACTIVE`
- Zone support policy: `LEGACY`
- Class Fantasy: `LEGACY`
- Chronicle Echo: `LEGACY`

Scheduler budgets remain 5.5 ms preferred, 7.5 ms soft, and 2.0 ms force-yield expensive-call threshold.
