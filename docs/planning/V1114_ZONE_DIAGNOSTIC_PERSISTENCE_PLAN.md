# Quest Chronicle v1.11.4 Architecture & Development Plan

## Zone anchor-policy diagnostic persistence repair

## Release purpose

Quest Chronicle v1.11.4 repairs the Debug History regression discovered during Retail validation of v1.11.3.

v1.11.3 successfully activated `ZONE_ANCHOR_POLICY_V1`. Zone context resolution, anchor preference, legal weapon routing, generation, Reroll Unlocked, and slot rerolls continued to run. However, the new Zone policy diagnostics expanded realistic reports beyond the existing 20,480-byte persistence ceiling after the old compaction stages had finished.

The report insertion path then returned:

```text
Diagnostic report remained above the persistence limit after compaction.
```

Because generation queues reports asynchronously and did not surface the rejected return value, the failure appeared as an empty Debug tab. `/qc zone debug export` confirmed the symptom by showing the active policy while continuing to reference the last v1.11.2 report.

v1.11.4 is a narrow diagnostics release. It must restore report persistence without changing any generation result.

```text
v1.11.3 = Zone anchor policy behavior
v1.11.4 = Zone anchor policy diagnostic persistence repair
```

---

# Starting point

Create v1.11.4 directly from the package-ready Quest Chronicle v1.11.3 archive:

```text
QuestChronicle-v1.11.3.zip
SHA-256:
d5f88168d5c8f0a9da901e1174e5c983e91a2dde30c76a002c341817a47cf721
```

The v1.11.3 package remains authoritative for:

- `ZONE_ANCHOR_POLICY_V1` coefficients;
- candidate and pair adjustments;
- shared anchor beam behavior;
- immutable Zone Context Snapshot capture;
- stale-context cancellation;
- linked-weapon visual deduplication;
- novelty and repeat penalties;
- legal weapon routes;
- support, validation, repair, and reroll behavior;
- Zone export format 3;
- Zone Affinity format 2.

v1.11.4 may change diagnostics storage and failure reporting only.

---

# Retail evidence

The v1.11.3 Zone debug export reported:

```text
Zone anchor policy: ZONE_ANCHOR_POLICY_V1
Zone anchor authority: ACTIVE
Zone support policy: LEGACY
Compatibility parity: PASS
```

The same export also reported:

```text
No v1.11.3 Zone anchor-policy report is currently available.
```

and the latest retained Zone report remained an older v1.11.2-era report with no recorded anchor policy.

The player independently confirmed that these actions no longer added Debug History entries:

```text
Generate Outfit
Reroll Unlocked
Contextual support-slot reroll
Individual slot reroll
```

A deterministic reproduction using a realistic Zone report shape confirmed that v1.11.3 `AddReport()` returned `nil` after compaction and incremented the malformed/discarded counter.

---

# Root cause

v1.11.3 recorded Zone policy information in several overlapping places:

1. `zoneFoundation.anchorPolicy`, the authoritative selected-policy summary;
2. `skeleton.components[*].anchorPolicy`, a complete duplicate calculation per selected component;
3. `zoneFoundation.affinity.pieces`, a per-piece current-look ledger also reconstructible by `/qc zone debug export`;
4. normal support, Phase D, cache, performance, ancestry, and comparison payloads.

The pre-v1.11.4 compactor already removed:

- duplicated `outfit.slots`;
- display-only support-profile fields;
- some component score prose;
- detailed performance phase statistics at a later stage.

It did not know that the new component policy payload and persisted affinity-piece ledger duplicated authoritative information elsewhere. Realistic Zone reports could therefore remain above the persistence ceiling.

---

# Architectural rule

The report stores each semantic fact once.

```text
Authoritative Zone policy summary:
zoneFoundation.anchorPolicy

Selected appearance identity:
skeleton.components

Reusable support ancestry:
support.profile.entries

Current complete affinity dossier:
/qc zone debug export, rebuilt from live state
```

A compacted persisted report must not retain full component-level policy calculations merely because they existed transiently during generation.

---

# New diagnostics module

Add:

```text
Core/Diagnostics/ReportCompaction.lua
```

Load it immediately after `Core/Diagnostics/Foundation.lua` and before `History.lua`.

The module owns:

- approximate report sizing;
- the ordered compaction pipeline;
- the `REPORT_TRIMMED` warning;
- Zone-policy duplicate removal;
- general fallback compaction stages.

`History.lua` remains responsible for:

- report validation;
- duplicate detection;
- bounded storage;
- report insertion;
- rejection counters;
- UI notification;
- visible persistence-failure reporting.

This division keeps persistence policy separate from history ordering and lineage mechanics.

---

# Ordered compaction contract

Compaction runs only when the original report exceeds `20,480` bytes.

## Stage 1: established general duplicates

Remove:

```text
outfit.slots
support.profile.activeAnchors
support.profile.strongestRelationship
support.profile.descriptor.setIDs
support.decisions[*].itemID
zero-valued cache invalidation entries
```

Preserve:

```text
skeleton.components
support.profile.entries
support decisions
Phase D validation and repairs
warnings
ancestry
```

## Stage 2: Zone-specific duplicates

For Zone reports, remove:

```text
zoneFoundation.affinity.pieces
skeleton.components[*].anchorPolicy
empty compatibilityDifferences
```

These fields are duplicates because:

- aggregate affinity remains in `zoneFoundation.affinity`;
- the complete live affinity dossier is rebuilt by `/qc zone debug export`;
- selected Zone policy facts remain in `zoneFoundation.anchorPolicy`;
- selected source identities remain in `skeleton.components`.

## Stage 3: verbose selected-component prose

Only if the report remains oversized, remove:

```text
skeleton.components[*].scoreReasons
raw component policy calculation details, when no authoritative summary exists
```

## Stage 4: lower-value timing internals

Only if still required, remove:

```text
performance.phaseStats
cache.invalidationReasons
```

Headline performance, scheduler summary, selected results, warnings, support ancestry, and Phase D remain.

---

# Required retained Zone information

After compaction, a Zone report must preserve:

- report ID, generation token, lineage, parent, and anchor-source ancestry;
- action, result, version, message, character, and context;
- selected anchor source and visual identities;
- `ZONE_ANCHOR_POLICY_V1` identity and `ACTIVE` authority;
- snapshot fingerprint and stale-context result;
- selected legacy relevance, affinity, confidence, classification, adjustment, and final relevance;
- Chest, Legs, and Shoulders pool summaries;
- visual and Zone pair channels;
- legal weapon route family;
- logical weapon visual count and deduplication result;
- aggregate current-look affinity and class counts;
- reusable support profile entries;
- contextual support decisions;
- final validation and repair outcome;
- warnings and report-compaction notice;
- headline performance and cache summaries.

---

# Visible failure contract

A report that still exceeds the ceiling after every compaction stage may be rejected, but it may not fail silently.

`History.lua` must:

1. increment the existing discarded-report counter;
2. print:

```text
Debug report could not be saved: <reason>
```

3. emit:

```text
DIAGNOSTIC_REPORT_REJECTED
```

with the visible message and rejected report snapshot.

Duplicate-report suppression remains silent and is not a persistence failure.

---

# Compatibility

Retain:

```text
SavedVariables schema:        2
Courier format:               1
Wardrobe cache:               7
Generation cache:             2
Diagnostic format:            1
Zone Context Snapshot:        1
Zone Affinity:                2
Zone debug export:            3
Zone anchor policy:           1
```

No migration or reset is required.

Existing compacted reports remain readable.

---

# Protected generation behavior

v1.11.4 must not change:

- Zone context resolution;
- profile or provenance registries;
- era restrictions;
- candidate eligibility;
- Zone affinity formulas;
- anchor-policy constants;
- candidate weighting;
- pair support;
- anchor beam width or quality window;
- random consumption;
- novelty or repeat penalties;
- legal weapon routes;
- support profile, scoring, beam, budget, validation, repair, or rerolls;
- locks or hidden slots;
- Traveler, Class Fantasy, or Chronicle Echo behavior.

The generation-facing v1.11.3 modules should remain byte-identical.

---

# Automated validation

## Realistic Zone persistence regression

Construct a representative near-limit report containing:

- five selected anchor components with duplicated full policy calculations;
- one authoritative Zone policy summary;
- three candidate-pool summaries;
- twelve affinity pieces;
- reusable support profile entries;
- eight support decisions;
- Phase D result;
- a broad performance phase ledger.

Require:

- `D.AddReport()` returns a report;
- the report remains in `D.GetReports()`;
- final size is at or below `20,480` bytes;
- component policy duplicates are removed;
- affinity-piece duplicates are removed;
- authoritative Zone policy summary survives;
- selected adjustments, pools, pair channels, route, and deduplication survive;
- support ancestry and Phase D survive;
- `REPORT_TRIMMED` survives.

## Rejection visibility regression

Construct a deliberately uncompactable report.

Require:

- `D.AddReport()` rejects it;
- the rejection reason remains exact;
- one visible message is printed;
- `DIAGNOSTIC_REPORT_REJECTED` is emitted;
- the discarded counter increments.

## Full regression

Require every inherited Lua test and static verifier to remain green.

## Static scope guard

Verify:

- numeric v1.11.4 metadata;
- `ReportCompaction.lua` loads before `History.lua`;
- policy summary is retained;
- component duplicates and per-piece affinity duplicates are removable;
- support ancestry and Phase D are not removed;
- visible rejection path exists;
- the 20,480-byte ceiling remains unchanged.

---

# Retail live validation

## Test 1: Zone Generate Outfit

1. Select Zone Native.
2. Generate an outfit.
3. Open Debug.
4. Confirm a new v1.11.4 report appears.
5. Confirm the report shows:

```text
Zone foundation: CONTEXT_EVIDENCE_V1
Zone anchor policy: ZONE_ANCHOR_POLICY_V1
Zone anchor authority: ACTIVE
Zone support policy: LEGACY
```

6. A `REPORT_TRIMMED` warning is acceptable.
7. `Debug report could not be saved` must not appear.

## Test 2: Reroll Unlocked

Run Reroll Unlocked and confirm a second report appears with current ancestry and Zone policy details.

## Test 3: contextual support reroll

Reroll one visible support slot and confirm:

- a new report appears;
- only the target support slot changes;
- anchor ancestry remains available;
- support profile entries survive compaction;
- Phase D remains visible.

## Test 4: individual slot reroll

Reroll one individual non-support slot using the existing legacy path and confirm a report appears rather than disappearing.

## Test 5: Zone export

Run:

```text
/qc zone debug export
```

Confirm:

- the Zone Anchor Policy section uses the newest v1.11.4 report;
- Latest Zone Native diagnostic report uses a v1.11.4 report ID and time;
- copy encoding remains `DIAGNOSTIC_ESCAPE_V1`;
- no report-rejection warning appeared during the batch.

---

# Acceptance criteria

v1.11.4 is package-ready when:

1. The realistic v1.11.3 report fixture is retained after compaction.
2. The final persisted report is at or below 20,480 bytes.
3. The authoritative Zone policy summary remains complete.
4. Component-level Zone policy duplicates are removed when required.
5. Per-piece persisted affinity details are removed when required.
6. Support-profile entries and Phase D remain intact.
7. An uncompactable report emits a visible warning and callback event.
8. All inherited tests and verifiers pass.
9. All runtime Lua files parse.
10. Every runtime module appears exactly once in the TOC.
11. No runtime Lua file reaches 500 lines.
12. Protected generation modules remain byte-identical to v1.11.3.
13. The exact ZIP passes fresh-extraction validation.

v1.11.4 is live-validated only after all four action types add reports on Retail.

---

# Explicit non-goals

v1.11.4 does not:

- recalibrate Zone anchor scoring;
- modify affinity classifications;
- begin Zone support-policy work;
- change validation or repair thresholds;
- modernize legacy individual rerolls;
- change the diagnostic persistence ceiling;
- increment diagnostic format;
- add a SavedVariables migration;
- change the Zone debug export format;
- change any non-Zone generation mode.

---

# Planned artifacts

```text
QuestChronicle-v1.11.4.zip
QuestChronicle-v1.11.4-Architecture-and-Development-Plan.md
QuestChronicle-v1.11.4-Live-Validation-Steps.md
QuestChronicle-v1.11.4-Automated-Validation.md
QuestChronicle-v1.11.4-Parity-Report.md
QuestChronicle-v1.11.4-Implementation-Conformance.md
QuestChronicle-v1.11.4-Diagnostic-Persistence-Contract.md
QuestChronicle-v1.11.4-Release-Notes.md
QuestChronicle-v1.11.4-Validation-Report.md
QuestChronicle-v1.11.4-Handoff-Manifest.md
QuestChronicle-v1.11.4.sha256
```

---

# Planned commit message

```text
fix: Update Quest Chronicle to v1.11.4

Restore Zone generation and reroll reports in Debug History
Compact duplicated Zone policy and affinity details before persistence
Preserve selected anchors, policy summaries, ancestry, and Phase D results
Surface any future diagnostic persistence rejection visibly
Keep all v1.11.3 Zone generation behavior unchanged
```
