# Quest Chronicle v1.11.3 Implementation Conformance

## Architecture contract

v1.11.3 implements the approved first Zone anchor-policy slice without claiming a complete Zone rewrite.

```text
Generation implementation: LEGACY
Zone foundation: CONTEXT_EVIDENCE_V1
Zone Context Snapshot: 1
Zone affinity: 2
Zone anchor policy: ZONE_ANCHOR_POLICY_V1
Zone anchor-policy format: 1
Zone anchor authority: ACTIVE
Zone support policy: LEGACY
Zone debug export: 3
```

## Shared bridge ownership

`Core/Wardrobe/AnchorPolicyBridge.lua` owns mode-neutral anchor-policy dispatch for:

```text
GetAnchorSlots
GetAnchorSearchConfiguration
EvaluateAnchorCandidate
ScoreAnchorPair
ScoreAnchorSkeleton
BuildNoveltyReference
ClassifyNovelty
```

Modes without an authoritative anchor policy continue through the existing compatibility helpers. Shared mechanics contain no Zone profile facts and no literal `ZONE_NATIVE` scoring branch.

## Zone policy ownership

`Core/Generation/Modes/Zone/AnchorPolicy.lua` owns the registered callback contract.

`Core/ZoneStyle/Zone/AnchorScoring.lua` owns all v1 coefficient values, bounded candidate adjustment, bounded pair support, logical weapon deduplication, and selected-policy diagnostics.

Profile facts remain in the validated Zone evidence registries. Policy coefficients are not embedded in profile data.

## Immutable context

One validated Zone Context Snapshot is captured at action setup. Candidate, pair, weapon, novelty, and report work use that snapshot.

Immediately before live-state commit, the current context fingerprint is rebuilt and compared with the action fingerprint. A material difference cancels atomically and preserves the previous preview.

## Preference boundary

Zone affinity runs only after existing legality and eligibility checks. It cannot:

- grant era or provenance eligibility;
- bypass promotion or Heritage exclusions;
- clear a visual hard clash;
- create a new weapon route;
- reject a locked anchor;
- unhide a hidden slot;
- change novelty classes or repeat penalties;
- alter support budgets, validation thresholds, repair caps, or reroll behavior.

Unknown, partial, and zero-confidence evidence receive no candidate penalty. `NOT_APPLICABLE` remains neutral.

## Random and scheduling boundary

The policy reuses the candidate's already-consumed pool random value when recalculating weighted priority. Policy and affinity modules contain no `math.random()` calls and perform no second full candidate pass.

Every individual Zone policy callback is timed through the existing cooperative ledger. No new scheduler or worker budget is introduced.

## Mode truthfulness

```text
Traveler:        SHARED_FRAMEWORK
Zone Native:     LEGACY with active Zone anchor policy
Class Fantasy:   LEGACY
Chronicle Echo:  LEGACY
```

Zone remains overall `LEGACY` because support, completed-outfit validation, repair, and rerolls remain on their established policy path.

## Result

```text
Implementation conformance: PASS
Retail validation: Pending
```
