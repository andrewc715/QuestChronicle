# Quest Chronicle v1.11.5 Architecture & Development Plan

## Zone anchor-policy lineage and cooperative performance closure

## Release purpose

Quest Chronicle v1.11.5 closes the remaining validation gaps from the first authoritative Zone anchor-policy slice.

v1.11.3 activated:

```text
ZONE_ANCHOR_POLICY_V1
```

v1.11.4 then repaired the diagnostic-persistence regression that prevented realistic Zone reports from reaching Debug History.

Retail validation of v1.11.4 confirmed that these actions now persist successfully:

```text
Generate Outfit
Reroll Unlocked
Contextual support-slot reroll
Legacy individual anchor-slot reroll
```

The same validation exposed two remaining issues:

1. `/qc zone debug export` uses the newest Zone Native report for both its general report summary and its Zone Anchor Policy section. When the newest report is a legacy individual-slot reroll without a policy payload, the export incorrectly reports that no current Zone anchor-policy report exists even though newer-policy generation reports remain in history.
2. Cooperative Zone generation still produced performance overages in the weapon path: a cold Generate Outfit reached a 33.9 ms worker slice with an 8.7 ms `weaponStyleEligibility` call, and a subsequent Reroll Unlocked reached a 9.4 ms worker slice with a 6.1 ms `weaponContext` call.

v1.11.5 is therefore a narrow closure release:

```text
v1.11.3 = authoritative Zone anchor policy
v1.11.4 = diagnostic persistence repair
v1.11.5 = policy-report lineage + cooperative performance closure
```

It does not begin Zone support-policy work.

---

# Starting point

Create v1.11.5 directly from the Retail-validated Quest Chronicle v1.11.4 package:

```text
QuestChronicle-v1.11.4.zip
SHA-256:
d4829fd2ac476e47c0d12ebcf89fdf5cb2a806d6d21c08cee0884e2ae5adab2c
```

v1.11.4 remains authoritative for:

- `CONTEXT_EVIDENCE_V1`;
- Zone Context Snapshot format 1;
- Zone Affinity format 2;
- `ZONE_ANCHOR_POLICY_V1` coefficients and authority;
- Zone debug export format 3 and `DIAGNOSTIC_ESCAPE_V1`;
- report compaction and visible rejection behavior;
- shared anchor beam behavior;
- candidate and pair adjustments;
- linked-weapon logical-visual deduplication;
- stale Zone-context cancellation;
- legal weapon routes;
- novelty and repeat penalties;
- contextual support, validation, repair, and reroll behavior.

No earlier Zone package is an acceptable baseline.

---

# Retail evidence

## Diagnostic persistence passed

The v1.11.4 Retail batch retained complete reports for:

- Generate Outfit;
- Reroll Unlocked;
- a contextual Feet reroll;
- a legacy individual Legs reroll.

The two full-generation reports began above 33 KB and were compacted beneath the existing 20,480-byte persistence ceiling while preserving Zone policy, selected anchors, support ancestry, Phase D, warnings, and messages.

v1.11.5 must not disturb that repair.

## Export lineage defect

The newest Zone Native report in the batch was the legacy individual Legs reroll.

That report correctly lacked a v1.11.3 anchor-policy payload because the individual anchor/weapon reroll path remains legacy and deferred.

The final Zone export therefore printed:

```text
No current Zone anchor-policy report is available.
```

and summarized the latest report as:

```text
Action: REROLL_SLOT
Generation implementation: Unknown
Zone anchor policy: Not recorded
```

Earlier retained Generate Outfit and Reroll Unlocked reports in the same history contained:

```text
Policy: ZONE_ANCHOR_POLICY_V1 • ACTIVE
```

The exporter is conflating two different questions:

```text
What is the newest Zone Native report?

What is the newest Zone report carrying an authoritative anchor-policy payload?
```

Those lookups must become independent.

## Cooperative performance evidence

The cold Generate Outfit report recorded:

```text
Prepared: 433 frames • 6.3 sec
Longest worker slice: 33.9 ms
Largest instrumented call: weaponStyleEligibility 8.7 ms
Scheduler: 17 expensive-call yields
Maximum slice debt: 5.05 ms
Weapon index: STALE → PARTIAL • COLD_BUILD
```

The subsequent Reroll Unlocked report recorded:

```text
Prepared: 250 frames • 3.6 sec
Longest worker slice: 9.4 ms
Largest instrumented call: Weapon context 6.1 ms
Scheduler: 8 expensive-call yields
Maximum slice debt: 3.84 ms
Weapon index: PARTIAL → PARTIAL • PARTIAL_BUILD
```

The legacy individual Legs reroll recorded a synchronous 308.6 ms `rerollSlot` call. That path is known technical debt and is not part of the cooperative anchor-policy closure.

---

# Release identity

v1.11.5 retains the established hybrid identity:

```text
Generation implementation: LEGACY
Zone foundation: CONTEXT_EVIDENCE_V1
Zone anchor policy: ZONE_ANCHOR_POLICY_V1
Zone anchor authority: ACTIVE
Zone support policy: LEGACY
```

Schema and format state:

```text
SavedVariables schema:        2
Courier format:               1
Wardrobe cache:               7
Generation cache:             2
Diagnostic format:            1
Zone Context Snapshot:        1
Zone Affinity:                2
Zone debug export:            3 → 4
Zone anchor policy:           1
```

Only the Zone debug export format advances because its report-selection contract changes.

No migration or cache reset is required.

---

# Track A: independent Zone report lineage

## Architectural rule

The export must not treat “latest Zone report” and “latest Zone policy report” as aliases.

```text
Latest Zone Native report:
Newest retained report whose mode is ZONE_NATIVE.

Latest Zone anchor-policy report:
Newest retained ZONE_NATIVE report carrying a structurally valid
zoneFoundation.anchorPolicy payload.
```

## New report-selection helpers

Replace the single private `LatestZoneReport()` lookup with explicit selectors owned by the Zone debug-export module or a small read-only diagnostics query helper:

```text
LatestZoneNativeReport()
LatestZoneAnchorPolicyReport()
```

`LatestZoneAnchorPolicyReport()` accepts a report only when:

- `report.mode == ZONE_NATIVE`;
- `report.zoneFoundation` is a table;
- `report.zoneFoundation.anchorPolicy` is a table;
- `anchorPolicy.policyID` is present;
- `anchorPolicy.authority` is present;
- the payload includes a snapshot fingerprint or an explicit fallback reason.

The selector must not require `result == COMPLETED`, because a future stale-context cancellation or explicit policy fallback is diagnostically meaningful.

Malformed or partial payloads are skipped rather than synthesized.

## Zone export format 4

`/qc zone debug export` advances to format 4.

The export keeps both sections but feeds them independently:

```text
## Zone Anchor Policy
Source report: <ID> • <time> • <action> • <result>
Latest Zone report carries policy: YES|NO
...

## Latest Zone Native diagnostic report
Source report: <newest Zone Native report>
...
```

When the newest Zone report lacks a policy payload, the Zone Anchor Policy section must explicitly say:

```text
The latest Zone Native report is a legacy action without an anchor-policy payload.
Showing the most recent policy-bearing Zone report instead.
```

The section then renders the complete policy payload from that older policy-bearing report.

## Lineage integrity

The exporter must preserve report provenance rather than blending live state with old policy state.

The Zone Anchor Policy section must identify:

- source report ID;
- timestamp;
- action;
- result;
- parent report ID when available;
- anchor-source report ID when available;
- snapshot fingerprint;
- whether the report is also the latest Zone Native report.

Current live Zone context and current-look affinity remain live-state sections.

The policy section remains report-state evidence.

The exporter may not silently replace a recorded policy snapshot with the current live snapshot.

## Empty-history behavior

If no Zone report exists:

```text
No Zone Native diagnostic report is currently available.
No Zone anchor-policy report is currently available.
```

If Zone reports exist but none carries a valid policy payload:

```text
Zone Native reports are available, but none contains a valid Zone anchor-policy payload.
```

These are distinct states.

---

# Track B: cooperative weapon-path performance

## Performance scope

v1.11.5 targets only the cooperative paths used by:

```text
Generate Outfit
Reroll Unlocked
```

It does not modernize the synchronous legacy individual anchor/weapon reroll path.

The 308.6 ms individual Legs reroll remains documented technical debt for a later dedicated reroll slice.

## Protected selection contract

Performance work may change when the worker yields.

It may not change:

- candidate eligibility results;
- candidate ordering for an identical random stream;
- style scores or Zone policy adjustments;
- random-call count or random-call order;
- legal weapon routes;
- linked-hand behavior;
- selected anchor skeleton;
- selected weapon bundle;
- support selection;
- novelty or repeat penalties;
- atomic commit behavior.

```text
Scheduling may change.
Selection may not.
```

---

# Source-level performance findings

## Finding 1: weapon eligibility is still drained synchronously per candidate

`ZoneStyle.OrderWeaponCandidates()` currently calls:

```text
GetSourceEligibilityCached(candidate.source, modeKey, context)
```

The synchronous helper internally drains eligibility work using:

```text
markerBatch = 1000000
```

Only after eligibility and coherence both finish does the weapon coroutine yield under:

```text
weaponStyleEligibility
```

Therefore one candidate can exceed the cooperative slice budget before the worker regains control.

This is structurally consistent with the observed 8.7 ms `weaponStyleEligibility` call.

## Finding 2: weapon capabilities are rebuilt across a multi-second action

`CreateWeaponGenerationContext()` calls:

```text
Wardrobe.GetWeaponAppearanceCapabilities()
```

The underlying route model has only a 0.20-second time-based cache even though equipment, specialization, collection, and topology events already trigger explicit route invalidation.

Anchor expansion evaluates multiple finalists over several seconds. Repeated context creation can therefore rebuild equivalent route and capability data during one action.

This is structurally consistent with the observed warm 6.1 ms `weaponContext` call, but Retail instrumentation must verify the exact subphase before the optimization is considered proven.

---

# Cooperative weapon eligibility work

## New work object

Add a bounded weapon-style ordering work object rather than draining all source eligibility synchronously.

Suggested ownership:

```text
Core/Wardrobe/WeaponStyleOrdering.lua
```

The work object owns:

- candidate list;
- reverse eligibility index;
- current cached-eligibility work;
- current coherence result;
- scoring index;
- random-call count;
- completion state;
- diagnostic counters.

## Eligibility stepping

For each candidate:

1. Create cached source-eligibility work with `CreateCachedSourceEligibilityWork()`.
2. Step it with the existing bounded marker batch used by cooperative reroll work:

```text
markerBatch = 4
```

3. Yield while the eligibility work remains incomplete.
4. Compute coherence only after eligibility completes.
5. Remove an ineligible or incoherent candidate at the same logical point as v1.11.4.
6. Continue to the next candidate.

New yield identities:

```text
weaponStyleEligibilityStep
weaponStyleCoherence
weaponStyleScoring
```

The old aggregate `weaponStyleEligibility` label may remain as a compatibility alias in report formatting, but the new subphase labels must identify the real hotspot.

## Random parity

The eligibility pass consumes no random values.

The scoring pass must preserve exactly one random draw for each retained candidate, in the same candidate order used by v1.11.4.

Automated fixtures must compare:

- input candidate sequence;
- eligibility decisions;
- retained sequence;
- random-call count;
- random values consumed;
- final `stylePriority` values;
- sorted output order.

No extra draw may be introduced for scheduling.

---

# Weapon capability snapshot cache

## Session cache

Add a read-only weapon capability snapshot cache derived from the existing route invalidation lifecycle.

Suggested state:

```text
P.weaponCapabilitySnapshot
P.weaponCapabilitySnapshotGeneration
P.weaponCapabilitySnapshotInvalidationReason
P.weaponCapabilitySnapshotBuildCount
P.weaponCapabilitySnapshotReuseCount
```

`Wardrobe.InvalidateWeaponAppearanceRoutes(reason)` must invalidate both:

- the route model cache;
- the capability snapshot cache.

Existing invalidation events remain authoritative:

- character change;
- equipment change;
- specialization change;
- talent configuration change;
- collection/scan changes that already invalidate weapon routes.

## Immutable action snapshot

At the first weapon-context request in a generation action:

1. obtain the current cached capability snapshot or build it once;
2. attach that snapshot to the generation job;
3. reuse it for every anchor-finalist weapon expansion in that action;
4. create only the small mutable per-expansion context maps:

```text
appearancesByCategory
locationsBySlot
validation
activeRoute
```

The shared capabilities object is read-only.

No finalist may refresh capabilities independently midway through the same action.

## Context staleness

Explicit weapon-route invalidation during an active action must mark the action snapshot stale.

Before commit, the job compares its capability generation with the current capability generation.

If equipment or specialization materially changed, the action must fail atomically and preserve the previous preview rather than committing a route based on stale equipment topology.

This mirrors the existing Zone Context Snapshot stale-commit contract.

A simple cache TTL expiration does not invalidate an action because v1.11.5 removes TTL as an authority boundary for capability correctness.

## New diagnostics

Reports must distinguish:

```text
Weapon capabilities: BUILT | REUSED
Capability generation: <number>
Capability builds this action: <count>
Capability reuses this action: <count>
Capability stale at commit: YES | NO
Capability invalidation: <canonical reason>
```

`weaponContext` timing must be decomposed into:

```text
weaponContextSnapshot
weaponContextMutableState
weaponCapabilitiesBuild
weaponCapabilitiesReuse
```

The report should no longer force the entire context path under one opaque label.

---

# Scheduler contract

The frozen worker constants remain:

```text
Preferred slice:          5.5 ms
Soft slice ceiling:       7.5 ms
Expensive-call threshold: 2.0 ms
Phase-transition reserve: 1.0 ms
```

v1.11.5 must not raise the budgets to make the warnings disappear.

Every eligibility step and capability build/reuse phase must report through the existing worker scheduler.

After any call at or above 2.0 ms:

- `forceYield` must be set;
- no unrelated phase may continue in that slice;
- `postExpensiveCallContinuations` must remain zero.

---

# Diagnostics and export additions

Zone debug export format 4 adds a compact performance closure summary sourced from the latest policy-bearing report:

```text
## Zone Anchor Policy Performance
Source report: <ID>
Worker slice: <ms>
Largest call: <phase> <ms>
Capability snapshot: BUILT|REUSED
Eligibility steps: <count>
Eligibility yields: <count>
Maximum slice debt: <ms>
Post-expensive continuations: <count>
```

This section is diagnostic only and does not duplicate the full Debug report.

When the latest policy-bearing report predates v1.11.5, unavailable fields render as `Not recorded` rather than zero.

---

# Compatibility and parity

Retain:

```text
SavedVariables schema:        2
Courier format:               1
Wardrobe cache:               7
Generation cache:             2
Diagnostic format:            1
Zone Context Snapshot:        1
Zone Affinity:                2
Zone anchor policy:           1
```

Advance only:

```text
Zone debug export: 3 → 4
```

Existing reports remain readable.

The new export selector must work with:

- v1.11.3 reports;
- compacted v1.11.4 reports;
- v1.11.5 reports;
- legacy Zone reroll reports without policy payloads.

---

# Automated validation

## Export lineage regression

Create report history in newest-first order:

1. v1.11.5 legacy individual Legs reroll without policy;
2. v1.11.5 contextual support reroll reusing anchors;
3. v1.11.5 Reroll Unlocked with `ZONE_ANCHOR_POLICY_V1`;
4. older v1.11.4 Generate Outfit with policy.

Require:

- Latest Zone Native report resolves to the individual Legs reroll;
- Latest Zone anchor-policy report resolves to the v1.11.5 Reroll Unlocked report;
- the policy section includes the correct report ID, action, result, and snapshot;
- the latest-report section includes the individual Legs reroll;
- the export states that the latest Zone report lacks a policy payload;
- no fields are blended between the two reports;
- export format reports `4`.

## Malformed policy filtering

Insert newer reports with:

- empty `anchorPolicy` table;
- missing policy ID;
- missing authority;
- missing snapshot and missing fallback reason.

Require the selector to skip them and return the newest structurally valid policy report.

## Cooperative eligibility regression

Build a candidate whose eligibility work requires multiple provenance-marker batches.

Require:

- no synchronous drain with batch 1,000,000;
- marker batch is 4;
- the weapon coroutine yields before the candidate finishes;
- final eligibility result matches v1.11.4;
- coherence runs exactly once after eligibility;
- no random value is consumed during eligibility.

## Weapon ordering parity

With a fixed random stream and deterministic candidates, compare v1.11.4-compatible ordering and v1.11.5 cooperative ordering.

Require exact equality for:

- retained candidate IDs;
- style weights;
- random-call count and order;
- style priorities;
- final sorted order;
- selected route and selected weapon source.

## Capability snapshot cache

Require:

- first request builds once;
- subsequent contexts reuse the same snapshot;
- all anchor finalists in one action share one capability generation;
- explicit route invalidation clears the snapshot;
- the next request rebuilds exactly once;
- stale capability generation blocks commit atomically;
- no cache TTL alone marks the snapshot stale.

## Performance benchmark fixtures

Instrument a cold and warm mocked weapon route.

Require:

- eligibility work yields between bounded steps;
- no synthetic resume performs more than one bounded eligibility step plus one bounded coherence/scoring operation;
- capability builds per action are at most one;
- warm action capability builds are zero when no invalidation occurred;
- post-expensive-call continuations remain zero;
- scheduler constants remain unchanged.

## Full regression

Require every inherited Lua test and static verifier to remain green.

## Static scope guard

Verify:

- numeric v1.11.5 metadata;
- export format 4;
- separate latest-report selectors;
- capability cache invalidates with route invalidation;
- synchronous `GetSourceEligibilityCached()` is no longer used inside weapon candidate ordering;
- marker batch 1,000,000 is not introduced into the weapon ordering path;
- policy constants remain unchanged;
- support-policy identity remains `LEGACY`;
- no runtime Lua file reaches 500 lines.

---

# Retail live validation

## Test 1: cold Zone Generate Outfit

After installing v1.11.5 and `/reload`:

1. Wait for the normal wardrobe refresh to settle.
2. Select Zone Native.
3. Generate one outfit.
4. Confirm a fresh Debug report persists.
5. Confirm:

```text
Zone anchor policy: ZONE_ANCHOR_POLICY_V1 • ACTIVE
Capability builds this action: 1 or fewer
Capability stale at commit: NO
Post-expensive continuations: 0
```

Cold acceptance gate:

- no worker slice above 16.0 ms;
- no individual instrumented call above 16.0 ms;
- `weaponStyleEligibility` is replaced by bounded subphase reporting;
- any warning between 8.0 and 16.0 ms must identify one exact subphase rather than the old aggregate label.

A cold run above 16.0 ms blocks closure.

## Test 2: three consecutive warm Reroll Unlocked actions

Run Reroll Unlocked three times without equipment, specialization, collection, or mode changes.

Every report must show:

```text
Capability snapshot: REUSED
Capability builds this action: 0
Capability stale at commit: NO
Post-expensive continuations: 0
```

Warm acceptance gate for all three runs:

- longest worker slice below 8.0 ms;
- largest instrumented call below 8.0 ms;
- maximum slice debt at or below 2.0 ms;
- no `WORKER_SLICE`, `SEVERE_WORKER_SLICE`, `INSTRUMENTED_CALL`, or `SEVERE_INSTRUMENTED_CALL` warning.

One passing warm sample is insufficient. All three must pass.

## Test 3: capability invalidation

1. Change equipped weapon or specialization.
2. Wait for the normal capability event.
3. Generate or Reroll Unlocked.
4. Confirm the next action builds a new capability snapshot once.
5. Confirm a following unchanged action reuses it.
6. Confirm legal weapon routing remains correct.

## Test 4: export lineage

After completing:

- Generate Outfit;
- Reroll Unlocked;
- contextual support reroll;
- legacy individual anchor reroll;

run:

```text
/qc zone debug export
```

Confirm:

- export format is 4;
- Latest Zone Native diagnostic report identifies the newest legacy individual reroll;
- Zone Anchor Policy identifies the newest policy-bearing Generate/Reroll Unlocked report;
- the export explicitly explains that the latest Zone report lacks policy data;
- policy source report ID, action, result, and snapshot are correct;
- the performance closure section uses the same policy-bearing source report;
- `DIAGNOSTIC_ESCAPE_V1` remains intact.

## Test 5: persistence parity

Confirm all reports still reach Debug History and no visible persistence-rejection warning appears.

---

# Acceptance criteria

v1.11.5 is package-ready when:

1. The newest Zone Native report and newest Zone policy-bearing report are selected independently.
2. Zone debug export format 4 identifies the source report for each section.
3. A legacy individual reroll can remain newest without hiding the latest valid policy report.
4. Malformed policy payloads are skipped without synthesizing values.
5. Weapon eligibility is stepped cooperatively with bounded marker batches.
6. Weapon candidate ordering and random consumption remain exactly parity-safe.
7. One immutable capability snapshot is used per action.
8. Explicit route invalidation rebuilds capabilities; TTL expiration alone does not.
9. Stale capability topology blocks atomic commit.
10. Scheduler constants remain unchanged.
11. All inherited tests and verifiers pass.
12. All runtime Lua files parse.
13. Every runtime module appears exactly once in the TOC.
14. No runtime Lua file reaches 500 lines.
15. The exact ZIP passes fresh-extraction validation.

v1.11.5 is live-validated only when:

1. the cold Generate Outfit remains below the severe 16 ms boundary;
2. three consecutive warm Reroll Unlocked actions each remain below 8 ms;
3. all warm runs have maximum slice debt at or below 2 ms;
4. post-expensive-call continuations remain zero;
5. capability build/reuse transitions match the event lifecycle;
6. the format-4 export reports both lineages correctly;
7. Debug History persistence remains intact.

Only then is the `ZONE_ANCHOR_POLICY_V1` slice considered closed.

---

# Explicit non-goals

v1.11.5 does not:

- change Zone anchor-policy coefficients;
- change Zone affinity scoring or classifications;
- begin Zone contextual support policy;
- alter final validation or repair thresholds;
- modernize legacy individual anchor or weapon rerolls;
- repair the 308.6 ms synchronous individual Legs reroll;
- alter report persistence limits or compaction rules;
- change SavedVariables or Courier formats;
- change weapon-index eligibility semantics;
- add new weapon routes;
- change Traveler, Class Fantasy, or Chronicle Echo behavior;
- relabel Zone Native as `SHARED_FRAMEWORK`.

---

# Expected runtime changes

Likely new module:

```text
Core/Wardrobe/WeaponStyleOrdering.lua
```

Likely changed modules:

```text
Core/ZoneStyle/Scoring.lua
Core/ZoneStyle/Zone/DebugExport.lua
Core/Wardrobe/AppearanceRoutes.lua or WeaponFilters.lua
Core/Wardrobe/EquipmentTopology.lua
Core/Wardrobe/GenerationAndConcepts.lua
Core/Wardrobe/AnchorSkeletonWorker.lua
Core/Wardrobe/GenerationPerformance.lua
Core/Diagnostics/ReportFormatter.lua
Core/Diagnostics/Snapshot.lua
QuestChronicle.toc
```

The implementation should prefer small extracted modules over pushing any existing runtime file toward the 500-line ceiling.

---

# Planned artifacts

```text
QuestChronicle-v1.11.5.zip
QuestChronicle-v1.11.5-Architecture-and-Development-Plan.md
QuestChronicle-v1.11.5-Live-Validation-Steps.md
QuestChronicle-v1.11.5-Automated-Validation.md
QuestChronicle-v1.11.5-Parity-Report.md
QuestChronicle-v1.11.5-Implementation-Conformance.md
QuestChronicle-v1.11.5-Zone-Anchor-Performance-Closure.md
QuestChronicle-v1.11.5-Release-Notes.md
QuestChronicle-v1.11.5-Validation-Report.md
QuestChronicle-v1.11.5-Handoff-Manifest.md
QuestChronicle-v1.11.5.sha256
```

---

# Planned commit message

```text
perf: Update Quest Chronicle to v1.11.5

Select the newest Zone report and newest policy-bearing report independently
Make weapon eligibility ordering cooperative without changing selection or RNG
Reuse immutable weapon capability snapshots across each generation action
Add policy-source and performance-closure details to Zone debug export format 4
Preserve v1.11.4 report persistence and all Zone anchor-policy coefficients
```
