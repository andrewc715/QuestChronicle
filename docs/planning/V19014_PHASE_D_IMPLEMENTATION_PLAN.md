# Quest Chronicle v1.9.0.14 Implementation Plan

## Phase D: Outlier Repair

## Release purpose

Quest Chronicle v1.9.0.14 adds the final validation and bounded two-pass repair stage for the Traveler Cohesion Rewrite.

Phase D begins only after Phase B has chosen a legal anchor skeleton and Phase C has produced a complete contextual-support configuration. It evaluates the finished outfit as one visual composition, repairs the worst unlocked support outlier when necessary, and commits only an accepted final configuration.

This is the final aesthetic-correction stage of the Traveler pipeline. It is not a new scoring rewrite, scheduler rewrite, cache release, or weapon-routing release.

## Starting point

Create v1.9.0.14 directly from the live-validated v1.9.0.13 source.

v1.9.0.13 is the required baseline because it has live-confirmed:

- cold and partial weapon-index lifecycle reporting;
- warm reuse with `NONE`;
- manual wardrobe replacement reporting;
- character-capability invalidation;
- legal warm weapon routing;
- cooperative Generate Outfit and Reroll Unlocked execution;
- isolated support-slot rerolls;
- lock and hidden-slot preservation;
- atomic reports and preview commits.

No v1.9.0.14 implementation work should be based on an earlier branch.

---

# Original Phase D contract

The accepted Traveler Cohesion Rewrite defined Phase D with these final-validation triggers:

```text
Final mismatch budget exceeds 2.00 points
Any support-slot outlier severity exceeds 0.72
The finished outfit contains more than 3 dominant palette families
A loud accent has zero echo elsewhere in the outfit
```

The accepted outlier-severity formula is:

```text
OutlierSeverity =
    0.45 × Isolation
  + 0.30 × Loudness
  + 0.15 × FinishConflict
  + 0.10 × WeightConflict
```

The accepted repair behavior is:

```text
Find the worst unlocked support slot
Exclude the failed appearance
Rescore legal alternatives against the completed outfit
Replace the slot
Recalculate the whole outfit
Repeat for at most 2 repair passes
If the outfit still fails, use the next valid anchor skeleton and refill support
Anchors change only as the last resort
```

Locked pieces consume mismatch first and can never be removed automatically.

Strong unsupported outliers are rejected. Useful weathered mismatch, supported variation, and echoed accents may remain.

---

# Pipeline placement

The v1.9.0.14 foreground pipeline becomes:

```text
Generation setup
Phase B anchor skeleton
Phase C support profile
Phase C locked commitments
Phase C candidate pools
Phase C support beam
Phase C finalist selection
Phase D final validation
Phase D repair pass 1, when required
Phase D final revalidation
Phase D repair pass 2, when required
Phase D final revalidation
Optional next-skeleton refill, only after both support repairs fail
Atomic state commit
Preview application
UI refresh
Completion callback
```

Phase D operates before any support selection is copied into the visible preview.

The live preview remains unchanged until the entire action succeeds.

---

# Design principles

## One visual language

Phase D must reuse the calibrated Traveler cohesion and mismatch language already established by Phase A and used by Phases B and C.

It must not introduce competing palette, material, finish, weight, motif, loudness, echo, bridge, or provenance formulas.

The current Traveler mismatch classifier should be factored into a shared runtime module so both `/qc traveler debug` and Phase D use the same calculations.

## Completed-outfit context

Phase C evaluates support candidates while the beam is still being built. Early support slots cannot see every later support choice.

Phase D evaluates the completed configuration, including:

- all active Phase B anchors;
- all selected Phase C support pieces;
- linked weapon appearances as one visual block where applicable;
- locked support pieces;
- final palette echo;
- final bridge support;
- final mismatch spending;
- final palette-family count.

Hidden and unavailable slots are excluded.

## Monotonic repair

A repair may be accepted only when the completed outfit becomes strictly better under the Phase D validation objective.

A repair must never trade one severe outlier for another equal or worse outlier.

## Bounded work

Phase D permits:

- at most 2 accepted support-slot repair passes;
- at most 32 already prepared candidates examined for each repair target;
- at most 1 alternate Phase B skeleton refill;
- no unbounded reroll or retry loop.

## Sovereign state

Phase D must never change:

- a locked slot;
- a hidden slot;
- an unavailable slot;
- an equipped-weapon topology;
- a Phase B anchor during either support repair pass.

The anchor skeleton may change only after both support repair passes fail and only through the explicit next-skeleton path.

---

# Shared final-analysis model

## Full configuration entries

Build one transient analysis entry for each active visual unit.

Each entry contains:

- slot key and label;
- source and stable visual identity;
- descriptor;
- slot prominence;
- profile cohesion and components;
- dominant palette family;
- intrinsic loudness;
- visual impact;
- echo support;
- bridge support;
- mismatch classification;
- mismatch points;
- outlier severity;
- locked and repairable state.

Linked Main Hand and Off Hand appearances that represent one linked weapon visual remain one analysis block.

## Echo support

Use the existing calibrated Traveler echo calculation:

```text
EchoSupport =
    summed presence of the entry's dominant palette
    across the other active outfit units,
    weighted by their slot prominence,
    clamped to 0 through 1
```

The established supported-accent threshold remains approximately:

```text
EchoSupport >= 0.65
```

A loud accent has zero echo when the clamped value is effectively `0.00`.

Use a small numeric tolerance only to absorb floating-point noise.

## Isolation

Define normalized isolation as:

```text
Isolation =
    1 - max(
        ProfileCohesion,
        EchoSupport,
        BridgeSupport
    )
```

This preserves the original intent:

- an appearance is not isolated when it fits the anchor profile;
- an unusual appearance may survive when another piece echoes it;
- an unusual appearance may survive when material, finish, or motif provides a strong bridge.

## Loudness

Use final visual impact rather than raw intrinsic loudness:

```text
Loudness =
    IntrinsicLoudness × SlotProminence
```

This prevents a tiny Wrist or Shirt deviation from being judged like a bright Head, Back, Hands, or weapon-adjacent deviation.

## Finish conflict

```text
FinishConflict =
    1 - FinishCompatibility
```

Use the finish component from the existing Traveler profile-cohesion calculation.

## Weight conflict

```text
WeightConflict =
    1 - VisualWeightCompatibility
```

Use the visual-weight component from the existing Traveler profile-cohesion calculation.

## Outlier severity

Calculate and clamp:

```text
OutlierSeverity =
    0.45 × Isolation
  + 0.30 × Loudness
  + 0.15 × FinishConflict
  + 0.10 × WeightConflict
```

A support appearance becomes a severe final outlier when:

```text
OutlierSeverity > 0.72
```

The comparison must remain strict. A value of exactly `0.72` does not exceed the threshold.

## Palette-family count

Count distinct dominant palette families across the active completed-outfit analysis blocks.

Rules:

- hidden and unavailable slots do not count;
- a linked weapon visual counts once;
- repeated families count once;
- families use the canonical Traveler palette keys;
- the failure gate is strictly greater than 3.

Therefore:

```text
3 dominant palette families: valid
4 dominant palette families: repair required
```

## Final mismatch budget

Phase D uses the established Traveler final mismatch budget:

```text
2.00 points
```

This is separate from the Phase C slot-aware cumulative ledger.

The two ledgers serve different purposes:

- Phase C's current ledger controls slot allowances, reserve pressure, borrowing, and beam feasibility.
- Phase D's 2-point ledger judges the completed outfit using the calibrated whole-outfit mismatch classifications.

Phase C budget formulas and the current 9.25-style aggregate support allowance remain unchanged.

---

# Final-validation triggers

A completed configuration requires repair when any repairable condition is true:

```text
Final mismatch used > 2.00
Maximum unlocked support severity > 0.72
Dominant palette families > 3
Loud zero-echo unlocked support accents > 0
Generated final POSTAL or OUTLIER classifications > 0
```

The validator also records, but does not treat as removable:

```text
Locked outliers
Locked mismatch commitment
Locked zero-echo accents
Locked palette-family contribution
```

A configuration containing only locked violations is classified as:

```text
LOCKED_OVERRIDE
```

It may commit because the user explicitly made those pieces sovereign.

The report must explain that Phase D preserved the locked mismatch.

---

# Validation objective

Compare completed configurations lexicographically in this order:

1. Internal validity and budget reconciliation
2. Repairable POSTAL or OUTLIER count
3. Repairable zero-echo loud-accent count
4. Repairable severity above `0.72`
5. Dominant palette-family overflow above 3
6. Final mismatch overflow above 2.00
7. Prominence-weighted total outlier severity
8. Fallback-slot count
9. Empty active-slot count
10. Higher whole-outfit cohesion
11. Higher Phase C configuration score
12. Stable visual-identity tie break

A candidate replacement is accepted only when this objective strictly improves.

The repair path must not use random selection.

---

# Choosing the repair target

Each repair pass ranks unlocked support slots by:

1. explicit `POSTAL` or `OUTLIER` state;
2. outlier severity;
3. zero-echo loud-accent state;
4. unique contribution to palette overflow;
5. visual impact;
6. mismatch points;
7. slot prominence;
8. canonical support-slot order.

Locked slots are excluded from replacement.

If a failure is caused partly by a locked piece, Phase D may still replace an unlocked support piece when doing so adds palette echo, adds a bridge, reduces palette overflow, or frees mismatch budget.

Phase D must never replace the locked piece itself.

---

# Repair pass behavior

## Pass preparation

For the chosen target slot:

- reuse the existing Phase C candidate pool;
- exclude the currently failed visual identity;
- exclude any appearance already rejected for that slot during the action;
- preserve anchors, locks, hidden state, and all non-target support choices;
- do not rescan the wardrobe;
- do not repeat source validation or era eligibility;
- do not query the weapon index;
- do not change the random stream.

## Candidate evaluation

For each legal remaining candidate:

1. substitute it transiently into the completed support map;
2. rebuild the final support decisions against the full configuration;
3. rebuild the Phase C budget ledger in canonical support-slot order;
4. run the complete Phase D final validator;
5. compare the result with the current configuration;
6. retain the best strictly improving replacement.

Candidate ties are broken by stable visual identity.

## Pass acceptance

Accept one replacement at most per repair pass.

Record:

- pass number;
- target slot;
- previous appearance;
- replacement appearance;
- trigger that selected the slot;
- mismatch before and after;
- severity before and after;
- palette families before and after;
- zero-echo count before and after;
- whole-outfit cohesion before and after;
- Phase C score delta.

After accepting a replacement, rerun full validation.

## Pass 2

Run pass 2 only when repairable failures remain after pass 1.

Pass 2 selects the new worst unlocked support slot.

Because pass 1 evaluates every legal alternative for its target, pass 2 should normally target a different slot.

No third support repair pass is permitted.

---

# Next-skeleton fallback

## Trigger

Use the next-skeleton path only when:

- both support repair passes have been exhausted;
- repairable failures remain;
- the failures are not solely protected locked violations;
- another valid Phase B finalist exists.

## Skeleton choice

Select the highest-ranked unused valid skeleton from the original Phase B finalist set under the original Phase B legality, quality-window, mode-identity, and novelty rules.

Do not perform another random roll.

## Refill behavior

When the alternate skeleton is selected:

- restore the transient draft to its pre-support anchor state;
- apply the alternate legal armor and weapon bundle;
- rebuild the Traveler generation context;
- derive a new immutable support profile;
- rebuild Phase C support pools and beam search;
- choose a complete support finalist;
- run one final Phase D validation.

The action-wide maximum of two support repair passes has already been consumed. The alternate skeleton does not receive another two-pass cycle.

## Alternate result

If the alternate skeleton passes, commit it and report:

```text
Alternate skeleton used after support repair exhaustion
```

If it fails only because of locked violations, commit as `LOCKED_OVERRIDE`.

If it still has repairable violations, fail the generation action and preserve the previous visible preview.

Do not invoke the legacy independent armor generator as an outlier-repair fallback.

---

# Action coverage

## Generate Outfit

Run full Phase D validation, two support repair passes, and optional next-skeleton fallback.

## Reroll Unlocked

Run the same full Phase D pipeline.

Unlocked anchors and support may change through the existing reroll behavior. Locks and hidden state remain authoritative.

## Support-only Reroll Slot

Use the same final validator, but preserve target isolation:

- only the requested support slot may change;
- all contextual support slots remain fixed;
- anchors and weapons remain fixed;
- evaluate the selected target replacement against the full outfit;
- try at most two alternate target candidates when the chosen result fails;
- never invoke the next-skeleton path;
- if no passing target candidate exists, commit nothing and report no coherent alternative.

## Individual anchor or weapon-slot rerolls

The legacy individual anchor and weapon-slot reroll path is not redesigned in v1.9.0.14.

Phase D must not expand this release into weapon-workbench hardening or legacy reroll scheduler surgery.

---

# Atomicity and cancellation

All Phase D work remains transient.

The visible preview changes only after:

- final validation passes;
- locked-only override is explicitly accepted; or
- an alternate skeleton passes final validation.

If the workbench revision, locks, hidden state, style mode, specialization, equipment topology, or collection identity changes while Phase D is running:

```text
Cancel the action
Discard all transient repairs
Preserve the visible preview
Record one cancelled attempt
```

A validation invariant failure, unreconciled ledger, missing selected source, or malformed candidate map fails the action without changing the preview.

---

# Cooperative scheduling

Phase D must use the v1.9.0.12 and v1.9.0.13 shared scheduler unchanged.

Use:

```text
Preferred worker budget: 5.5 ms
Soft ceiling: 7.5 ms
Expensive-call force-yield threshold: 2.0 ms
```

Required cooperative phases:

```text
Support final validation
Support repair target selection
Support repair candidate evaluation
Support repair pass 1 commit
Support repair revalidation
Support repair pass 2 commit
Alternate skeleton preparation
Alternate support refill
Alternate final validation
```

Scheduling rules:

- check the elapsed guard before candidate batches;
- check after every candidate substitution and final-analysis operation;
- yield before phase transitions when the reservation cannot fit;
- store candidate index, target index, pass number, and best replacement on the transient job;
- never repeat or skip a candidate after yielding;
- never continue into another phase after an expensive call;
- preserve `0 post-expensive continuations`.

Repair evaluation should reuse the shared adaptive batch policy.

No scheduler surgery is planned.

---

# Runtime module plan

## New modules

### `Core/ZoneStyle/Traveler/MismatchAnalysis.lua`

Shared calibrated helpers extracted from the current Traveler instrumentation:

- profile cohesion;
- echo support;
- bridge support;
- mismatch classification;
- mismatch points;
- palette-family counting;
- outlier-severity calculation;
- complete transient analysis.

`/qc traveler debug` and Phase D must call the same helpers.

No formula changes are permitted during extraction.

### `Core/Wardrobe/SupportFinalValidation.lua`

Responsibilities:

- build completed support-analysis entries;
- combine anchors and support safely;
- run final validation;
- classify repairable and protected failures;
- calculate the validation objective;
- export immutable aggregate diagnostics.

### `Core/Wardrobe/SupportRepair.lua`

Responsibilities:

- rank repair targets;
- manage rejected visual identities;
- evaluate bounded candidate substitutions;
- rebuild exact ledgers;
- retain the best strictly improving candidate;
- commit at most one replacement per pass;
- coordinate the two-pass state machine.

## Existing modules expected to change

```text
Core/Wardrobe/SupportWorker.lua
Core/Wardrobe/SupportScoring.lua
Core/Wardrobe/SupportBeam.lua
Core/Wardrobe/SupportRerollWorker.lua
Core/Wardrobe/AnchorSkeletonSearch.lua
Core/Wardrobe/AnchorSkeletonWorker.lua
Core/Wardrobe/GenerationWorker.lua
Core/Wardrobe/GenerationPerformance.lua
Core/Diagnostics/SupportSnapshot.lua
Core/Diagnostics/SupportReportFormatter.lua
Core/Diagnostics/SupportComparison.lua
Core/Diagnostics/Comparison.lua
Core/Diagnostics/ReportFormatter.lua
Core/ZoneStyle/Traveler/Cohesion.lua
QuestChronicle.toc
README.md
RELEASE_NOTES.md
docs/ARCHITECTURE.md
docs/CHANGELOG.md
```

All runtime Lua files must remain below 500 physical lines.

Large responsibilities must be placed in the new modules rather than swelling `SupportWorker.lua`, `SupportRerollWorker.lua`, `GenerationWorker.lua`, or `Cohesion.lua`.

---

# Internal data model

Add a transient Phase D work object:

```text
job.phaseDWork = {
    stage,
    validation,
    currentConfiguration,
    bestConfiguration,
    repairPass,
    repairTargetIndex,
    candidateIndex,
    rejectedVisuals,
    bestReplacement,
    repairs,
    initialSkeleton,
    alternateSkeleton,
    alternateAttempted
}
```

Persist only compact immutable results.

Do not persist:

- candidate pools;
- mutable beam nodes;
- source arrays;
- trial configurations;
- rejected-candidate tables;
- transient pair caches.

---

# Diagnostics

## Contextual Support section

Add:

```text
Final validation: CLEAN
```

or:

```text
Final validation: REPAIRED • 2 passes
```

or:

```text
Final validation: LOCKED_OVERRIDE
```

or:

```text
Final validation: ALTERNATE_SKELETON
```

Include:

```text
Mismatch: 2.31 → 1.74 / 2.00
Maximum severity: 0.81 → 0.54 / 0.72
Palette families: 4 → 3 / 3
Zero-echo loud accents: 1 → 0
Repairable outliers: 2 → 0
Protected locked violations: 0
```

For each accepted repair:

```text
Repair pass 1: Back
  Old appearance → New appearance
  Trigger: zero-echo loud accent
  Severity: 0.81 → 0.43
  Mismatch: 2.31 → 1.86
  Cohesion: 0.621 → 0.654
```

When the skeleton changes:

```text
Skeleton fallback: initial rank 3 → alternate rank 1
Reason: two support repair passes exhausted
```

## Per-piece decision fields

Add optional compact fields:

```text
finalMismatchClass
echoSupport
outlierSeverity
repairPass
repaired
replacedVisualID
protectedByLock
```

## Warnings

Use:

```text
SUPPORT_REPAIR_APPLIED
    INFO

SUPPORT_LOCKED_OVERRIDE
    INFO

SUPPORT_ALTERNATE_SKELETON
    INFO

SUPPORT_REPAIR_UNRESOLVED
    SEVERE on a failed attempt

SUPPORT_FINAL_VALIDATION_FAILED
    SEVERE on an invariant or ledger failure
```

The existing `SUPPORT_OUTLIER` warning must reflect final unresolved outliers, not the pre-repair configuration.

Clean and successfully repaired outfits must not receive an outlier warning.

## Snapshot compatibility

Keep:

```text
SavedVariables schema: 2
Courier format: 1
Wardrobe cache format: 7
Generation cache: 2
Diagnostic format: 1
```

Add optional Phase D fields without changing the diagnostic format number.

Maximum-detail persisted reports must remain below the established 20 KB ceiling.

---

# Performance ledger

Add phase labels for:

```text
Support final validation
Support repair targeting
Support repair candidate evaluation
Support repair pass 1
Support repair revalidation
Support repair pass 2
Alternate skeleton preparation
Alternate support refill
Alternate final validation
```

The compact performance tooltip should continue showing only the existing headline timing.

The Debug report may show the detailed Phase D rows.

---

# Explicit non-goals

v1.9.0.14 must not change:

- Traveler descriptor extraction;
- pair-cohesion weights;
- profile-cohesion weights;
- existing mismatch-classification thresholds;
- the `0.72` severe threshold;
- the `2.00` final mismatch budget;
- Phase B anchor candidate pools;
- Phase B beam widths;
- Phase B score formulas;
- Phase B novelty classes or penalties;
- the Phase B 28-point quality window;
- weapon appearance routes;
- equipped-weapon topology;
- Phase C pool limit of 32;
- Phase C beam width of 24;
- Phase C final shortlist of 6;
- Phase C 20-point support score window;
- Phase C slot allowances or reserve formulas;
- locked and hidden semantics;
- wardrobe cache format;
- generation cache format;
- weapon-index format or lifecycle reasons;
- Courier export format;
- outfit naming;
- background scan behavior;
- scheduler budgets or force-yield thresholds;
- UI layout;
- legacy individual weapon-slot reroll design.

No cache reset should be required.

---

# Automated test plan

## Shared Traveler analysis parity

Verify the extraction into `MismatchAnalysis.lua` preserves byte-for-byte output for:

- pair cohesion;
- profile cohesion;
- mismatch classes;
- mismatch points;
- echo support;
- bridge support;
- Traveler debug text;
- linked weapon-block handling.

## Threshold boundaries

Verify:

```text
Mismatch 2.00: pass
Mismatch 2.01: fail

Severity 0.720: pass
Severity 0.721: fail

3 palette families: pass
4 palette families: fail

Loud accent with zero echo: fail
Loud accent with EchoSupport 0.65: supported
```

## Clean-path parity

For every existing deterministic fixture that passes final validation:

- selected anchor IDs remain identical;
- selected support IDs remain identical;
- weapon route remains identical;
- Phase C score remains identical;
- locks and hidden slots remain identical;
- only additive Phase D diagnostics differ;
- Phase D consumes no random values;
- no repair pool is evaluated.

## Repair pass 1

Create a complete outfit with one severe unlocked support outlier.

Verify:

- the correct worst slot is targeted;
- the failed visual is excluded;
- one replacement is accepted;
- all other slots remain unchanged;
- anchors remain unchanged;
- final validation passes;
- pass count is 1.

## Repair pass 2

Create a complete outfit with two repairable outliers.

Verify:

- pass 1 repairs the worst slot;
- full validation runs again;
- pass 2 repairs the remaining worst slot;
- no third pass starts;
- both replacements are recorded;
- final validation passes.

## No acceptable candidate

Verify:

- every target candidate is evaluated at most once;
- no non-improving replacement commits;
- failed visuals remain excluded;
- Phase D advances to the next-skeleton path after both passes;
- no visible preview mutation occurs before success.

## Locked sovereignty

Verify:

- locked pieces are never replacement targets;
- locked mismatch is counted first;
- unlocked support may be repaired around locked context;
- locked-only failure produces `LOCKED_OVERRIDE`;
- the locked appearance remains unchanged.

## Palette overflow

Verify a four-family outfit targets an unlocked unique-palette contributor and reduces the final count to three when an alternative exists.

## Zero echo

Verify a loud unique accent is repaired when echo is zero and retained when another visible piece supplies sufficient echo.

## Next-skeleton fallback

Verify:

- the original selected skeleton is tried first;
- exactly two support repairs are allowed;
- the highest-ranked unused valid Phase B skeleton is selected afterward;
- no random reroll chooses the alternate;
- Phase C refills support under the alternate profile;
- the final report reflects the committed alternate skeleton;
- initial and final ranks are recorded.

## Alternate failure

Verify that a failing alternate configuration:

- does not commit;
- leaves the previous visible preview unchanged;
- records one failed attempt;
- does not invoke the legacy armor generator.

## Support-slot reroll

Verify:

- only the target slot may change;
- full final validation sees the fixed outfit;
- up to two target alternatives may be tried;
- no anchor or non-target repair occurs;
- failure leaves the preview unchanged;
- budget reconciliation remains exact.

## Cancellation

Cancel during:

- initial final validation;
- repair candidate evaluation;
- pass revalidation;
- alternate skeleton refill.

Every cancellation must preserve the prior preview and produce one completed cancellation report.

## Performance

Synthetic gates:

```text
Longest worker slice < 8 ms
Largest instrumented Phase D call < 8 ms
Post-expensive continuations = 0
Maximum 32 repair candidates per pass
Maximum 2 support repair passes
Maximum 1 alternate skeleton
No synchronous launch preparation >= 8 ms
```

The clean path should complete final validation without scanning sources or rebuilding eligibility.

## Release hygiene

Verify:

- all Lua files parse;
- all runtime modules appear exactly once in the TOC;
- no runtime Lua file exceeds 500 physical lines;
- no orphaned split-helper references;
- no blocking transmog refresh call;
- JSON remains valid;
- version strings agree;
- ZIP extracts cleanly;
- report snapshots remain below 20 KB.

---

# Retail live-validation plan

## Clean generation

Generate a normal Traveler outfit.

Expected:

```text
Final validation: CLEAN
Repair passes: 0
Fallback: None
No support-outlier warning
```

Confirm normal scoring, routing, hidden slots, locks, and timing remain healthy.

## One-pass repair

Use a validation test build or a naturally produced severe unlocked support outlier.

Expected:

```text
Final validation: REPAIRED
Repair passes: 1
Repairable outliers: 1 → 0
```

Confirm only one support slot changes after the Phase C finalist.

## Two-pass repair

Use a controlled test fixture that produces two repairable support outliers.

Expected:

```text
Final validation: REPAIRED
Repair passes: 2
Repairable outliers: 2 → 0
```

Confirm no third pass appears.

Any temporary failure-injection hook used for this test must not ship in the final package.

## Locked override

Lock a deliberately conflicting support appearance.

Expected:

```text
Final validation: LOCKED_OVERRIDE
Locked appearance preserved
Protected locked violations reported
```

No automatic unlock or replacement is permitted.

## Next-skeleton fallback

Use a controlled test build that makes both support repair passes fail for the initial skeleton.

Expected:

```text
Final validation: ALTERNATE_SKELETON
Initial and final skeleton ranks reported
Support refilled under the alternate profile
```

The temporary test condition must be removed before packaging.

## Reroll Unlocked

Confirm Phase D runs after the rerolled Phase B and Phase C result, preserves locks and hidden slots, and commits atomically.

## Support-slot reroll

Confirm only the requested support slot changes and an invalid target replacement is rejected without changing the visible preview.

## Performance

Across clean, repaired, alternate-skeleton, and reroll actions:

```text
No visible freeze
No repeated worker slice above 8 ms
No individual Phase D call above 8 ms
0 post-expensive continuations
No duplicate, malformed, or partial report
```

---

# Acceptance criteria

v1.9.0.14 becomes a release candidate only when:

1. Final validation uses the shared calibrated Traveler formulas.
2. The 2-point budget, 0.72 severity threshold, three-palette limit, and zero-echo rule are enforced exactly.
3. Clean configurations preserve v1.9.0.13 selections and scores.
4. The worst unlocked support outlier is repaired first.
5. The failed appearance is excluded from its repair pass.
6. Every accepted repair strictly improves the completed configuration.
7. No more than two support repair passes occur.
8. Locked and hidden slots remain sovereign.
9. The next-skeleton path occurs only after both repair passes fail.
10. At most one alternate skeleton is attempted.
11. A still-invalid alternate fails atomically without changing the preview.
12. Support-only rerolls remain target-isolated.
13. No weapon-route, cache, scheduler, or schema regression appears.
14. All automated tests pass.
15. Retail validation confirms clean, repaired, locked, reroll, and alternate-skeleton behavior.
16. Worker slices and Phase D calls remain inside the responsiveness gate.
17. Maximum-detail reports remain below 20 KB.

---

# Implementation order

1. Branch v1.9.0.14 from the live-validated v1.9.0.13 source.
2. Add failing threshold and final-analysis tests.
3. Extract shared mismatch-analysis helpers without changing formulas.
4. Prove Traveler debug parity.
5. Add completed-configuration final validation.
6. Insert the validation stage after Phase C selection and before support application.
7. Add pass-1 target ranking and bounded candidate replacement.
8. Add full revalidation.
9. Add pass 2 with the global two-pass cap.
10. Add next-skeleton fallback using the original Phase B finalist set.
11. Add target-isolated support-reroll validation.
12. Add atomic failure and cancellation handling.
13. Add compact diagnostics and performance phases.
14. Run clean-path parity against v1.9.0.13.
15. Run the complete automated suite and performance harnesses.
16. Package a release candidate with a simplified Live Validation Steps Markdown file.
17. Promote only after Retail validation passes.

---

# Planned commit message

```text
feat: Update Quest Chronicle to v1.9.0.14

Add completed-outfit Traveler validation after Phase C support selection
Repair the worst unlocked support outlier through at most two bounded passes
Enforce the two-point mismatch budget, severity, palette, and echo gates
Use the next valid anchor skeleton only after support repair is exhausted
Preserve locks, hidden slots, weapon routes, scheduler behavior, and atomic commits
```
