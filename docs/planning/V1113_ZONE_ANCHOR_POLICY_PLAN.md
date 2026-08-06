# Quest Chronicle v1.11.3 Architecture & Development Plan

## Zone Anchor Policy v1

## Release purpose

Quest Chronicle v1.11.3 is the first behavior-changing release in the Zone implementation train.

v1.11.0 through v1.11.2 established and live-validated the evidence foundation required to make that change safely:

- immutable Zone Context Snapshot format 1;
- complete evidence ancestry;
- 25 validated broad style profiles;
- 134 validated provenance pools;
- 30 validated starting-zone cases;
- canonical culture, climate, terrain, palette, material, finish, motif, magic, silhouette, and avoidance channels;
- coverage-aware Zone Affinity format 2;
- copy-safe Zone debug export format 2;
- `VALUE`, `MISSING`, and `NOT_APPLICABLE` component semantics;
- `DIAGNOSTIC_ESCAPE_V1` clipboard fidelity;
- exact compatibility with the existing Zone context and eligibility path.

v1.11.3 consumes that foundation to create the first explicit Zone generation policy:

```text
ZONE_ANCHOR_POLICY_V1
```

The new policy becomes authoritative for Zone Native anchor preference while reusing the existing legal anchor beam, legal weapon topology, cooperative scheduler, locks, hidden slots, novelty machinery, transient draft, and atomic commit.

```text
v1.11.0  Zone context and evidence foundation
v1.11.1  Copy-ready Zone evidence dossier
v1.11.2  Diagnostic fidelity and applicability semantics
v1.11.3  First authoritative Zone anchor policy
```

v1.11.3 does not rewrite Zone support selection, completed-outfit validation, repair, rerolls, or tuning.

The release succeeds only when Zone evidence can guide anchor selection without weakening visual cohesion, legality, scheduler behavior, player sovereignty, or the other three generation modes.

---

# Starting point

Create v1.11.3 directly from the final live-validated Quest Chronicle v1.11.2 package.

Required baseline:

```text
Quest Chronicle v1.11.2
SHA-256:
d2286798cc0fadbd1d8612b7d3a56db3a1f9152419c38bcb89037595cc39d88c
```

The v1.11.2 Retail export confirmed:

```text
Traveler implementation:        SHARED_FRAMEWORK
Zone Native implementation:     LEGACY
Zone foundation:                CONTEXT_EVIDENCE_V1
Class Fantasy implementation:   LEGACY
Chronicle Echo implementation:  LEGACY
Zone context format:            1
Zone affinity format:           2
Zone debug export format:       2
Compatibility parity:           PASS
Evidence warnings:              0
```

It also confirmed that dynamic descriptor values survive the WoW copy surface intact and that `NOT_APPLICABLE` channels are no longer reported as missing.

No earlier Zone package is an acceptable baseline.

---

# Primary architectural finding

## Zone already uses mature anchor mechanics

The current Zone Native path already passes through the established Wardrobe anchor machinery:

- Chest, Legs, and Shoulders candidate pools;
- diversity-balanced pool retention;
- bounded beam search;
- visual pair cohesion;
- hard-clash rejection;
- legal weapon-bundle expansion;
- quality-windowed finalists;
- novelty-aware weighted choice;
- contextual support generation;
- completed-outfit validation and repair;
- atomic preview commit.

What remains legacy is not the existence of the beam.

What remains legacy is the ownership of Zone preference.

The current anchor candidate builder still obtains Zone relevance from the global legacy function:

```text
ZoneStyle.ScoreSource(..., ZONE_NATIVE, ...)
```

That scorer mixes:

- broad profile-name keywords;
- avoidance keywords;
- small class influence;
- small Traveler influence;
- small Chronicle influence;
- current-outfit coherence;
- per-zone favorites;
- deterministic stable affinity noise.

It does not consume the immutable Zone Context Snapshot or coverage-aware Zone Affinity v2 as a policy-grade input.

Therefore v1.11.3 is not a new beam-search release.

It is an authority-transfer release:

```text
Before v1.11.3:
Shared anchor mechanics + implicit global Zone scoring

After v1.11.3:
Shared anchor mechanics + explicit Zone anchor policy
```

---

# Primary design decision

## Evidence guides; visual cohesion protects

Zone affinity answers:

```text
How strongly does this appearance relate to the current Zone evidence?
```

Shared visual cohesion answers:

```text
How well does this appearance work with the other selected anchor pieces?
```

Those are different questions and remain different score channels.

The Zone policy may prefer a locally meaningful appearance, but it may not use local relevance to excuse a severe visual clash.

```text
Zone evidence:
Preference

Visual cohesion and legality:
Protection
```

A fel-scarred Netherstorm piece may receive a Zone relevance bonus.

It may not override:

- source illegality;
- era restrictions;
- provenance restrictions;
- promotional exclusions;
- Heritage restrictions;
- incompatible equipment topology;
- a hard visual clash;
- a lock;
- a hidden slot.

---

# Implementation identity

Zone Native remains truthful about the scope of its modernization.

In v1.11.3 it reports:

```text
Generation implementation: LEGACY
Zone foundation: CONTEXT_EVIDENCE_V1
Zone anchor policy: ZONE_ANCHOR_POLICY_V1
Zone anchor authority: ACTIVE
Zone support policy: LEGACY
```

Zone Native does not yet report `SHARED_FRAMEWORK` because the following still remain outside a complete Zone policy implementation:

- outer generation lifecycle ownership;
- Zone-specific contextual support policy;
- Zone-specific final validation;
- Zone-specific repair objectives;
- Zone-specific reroll orchestration;
- Zone tuning and promotion.

The new anchor policy uses the shared policy seam and shared anchor orchestration, but the mode as a whole remains hybrid and therefore retains the established `LEGACY` implementation marker.

Required capability state:

```text
sharedFramework:        false
legacy:                 true
zoneEvidence:           true
zoneAffinityDiagnostics:true
zoneAnchorPolicy:       true
zoneAnchorPolicyVersion:1
zoneAnchorAuthority:    ACTIVE
zoneSupportPolicy:      false
zoneFinalValidation:    false
zoneTuningAudit:        false
```

---

# Core architectural rules

## Rule 1: one immutable Zone snapshot per action

At action start, Zone Native captures one Zone Context Snapshot and records its fingerprint.

Every Zone anchor operation in that action uses the same snapshot:

- candidate evaluation;
- pair interpretation;
- weapon-bundle scoring;
- diagnostics;
- final selected-anchor reporting.

The policy may not rebuild or silently replace the snapshot while the worker is active.

## Rule 2: context changes invalidate stale Zone work

Before atomic commit, Zone Native compares the action snapshot fingerprint with the current Zone snapshot fingerprint.

If the player changes to a materially different Zone context while generation is running, the action fails atomically:

```text
Zone context changed while Quest Chronicle was preparing the outfit; the previous preview was preserved.
```

A mere timestamp difference does not invalidate work because timestamps are excluded from the snapshot fingerprint.

## Rule 3: affinity is preference, never eligibility

Zone Affinity v2 may:

- add a bounded relevance bonus;
- add a bounded relevance penalty;
- provide diagnostic reasons;
- influence candidate ordering and final selection.

Zone Affinity v2 may not:

- make an ineligible source eligible;
- reject an otherwise eligible source by itself;
- invent provenance evidence;
- replace era or source-pool checks;
- reinterpret `MISSING` as negative evidence;
- reinterpret `NOT_APPLICABLE` as positive or negative evidence.

## Rule 4: unknown evidence is neutral

An appearance classified `UNKNOWN`, or an appearance whose affinity confidence is zero, receives no evidence adjustment.

It does not receive the maximum off-zone penalty merely because its descriptor is incomplete.

```text
Unknown evidence = neutral preference
Known off-zone evidence = bounded negative preference
```

## Rule 5: locked anchors are sovereign

A locked anchor remains selected regardless of Zone affinity.

The policy analyzes the locked anchor and records its relationship to the Zone, but it does not reject or replace it.

A low-affinity locked anchor may influence pair context exactly as the current locked appearance does.

## Rule 6: hidden anchors do not participate visually

A hidden anchor:

- is not selected;
- is not analyzed as a visible piece;
- is not counted in local-affinity averages;
- is not a pair endpoint;
- is not used to satisfy local evidence.

## Rule 7: local relevance cannot cancel a hard clash

The existing visual hard-clash rule remains authoritative.

Zone pair support is applied only after the hard-clash state is known.

A hard clash remains a hard clash even if both pieces have strong local provenance.

## Rule 8: random consumption remains bounded and auditable

Zone affinity analysis consumes no random values.

The policy preserves:

- one candidate-pool random draw per eligible anchor candidate;
- the existing final weighted-choice draw;
- existing novelty random behavior;
- existing weapon-route random behavior.

The policy may change weights and therefore selections, but it must not add random calls.

## Rule 9: profile facts and policy coefficients remain separate

v1.11.3 does not alter profile facts merely to produce a preferred outfit.

If a Zone profile is factually wrong, that requires an evidence correction release.

If the score response to correct evidence is wrong, that requires a policy correction.

The two cannot be quietly blended.

## Rule 10: no Traveler behavior may move

The second-policy hardening must preserve Traveler exactly.

Traveler remains the parity reference for:

- anchor candidates;
- pair scores;
- skeleton scores;
- novelty;
- random consumption;
- weapon routes;
- scheduler counters;
- support;
- validation;
- repair;
- diagnostics.

---

# Target architecture

```text
Quest Chronicle Outfits
│
├── Generation Mode Registry
│   ├── Traveler policy
│   ├── Zone legacy adapter
│   │   ├── Zone Context Policy
│   │   ├── Zone Affinity Policy v2
│   │   ├── Zone Anchor Policy v1       ← authoritative in v1.11.3
│   │   └── Zone Diagnostics Policy
│   ├── Class legacy adapter
│   └── Echo legacy adapter
│
├── Shared Anchor Orchestration
│   ├── candidate-pool lifecycle
│   ├── diversity retention
│   ├── bounded beam search
│   ├── policy candidate callback       ← hardened for second policy
│   ├── policy pair callback            ← hardened for second policy
│   ├── legal weapon-bundle expansion
│   ├── policy bundle callback          ← hardened for second policy
│   ├── novelty callback
│   ├── quality window
│   └── weighted final choice
│
├── Zone Evidence Foundation
│   ├── immutable context snapshot v1
│   ├── canonical style channels
│   ├── evidence ancestry
│   ├── provenance and era
│   └── Zone Affinity v2
│
└── Existing Legacy Zone Continuation
    ├── current support policy
    ├── current final validation
    ├── current repair
    ├── current rerolls
    └── current commit and reports
```

---

# Shared anchor-policy bridge

## Purpose

The current shared `AnchorEngine` exposes policy callbacks, but the established Wardrobe anchor worker still calls mode-neutral legacy helpers directly in several places.

v1.11.3 makes the policy seam authoritative without rewriting the proven beam mechanics.

## Job policy attachment

Every generation job receives a resolved mode policy during setup:

```lua
job.modePolicy
job.anchorPolicy
```

Resolution order:

```text
1. Existing sharedFrameworkPolicy attached by the Generation API
2. Registered mode policy resolved from job.styleMode
3. No policy, legacy compatibility helpers
```

This permits:

- Traveler to continue through its existing shared policy;
- Zone Native to use `ZONE_ANCHOR_POLICY_V1` while the outer mode remains `LEGACY`;
- Class and Echo to remain unchanged on compatibility helpers.

## Shared callback surface

The authoritative bridge uses the existing policy responsibilities:

```text
GetAnchorSlots
GetAnchorSearchConfiguration
EvaluateAnchorCandidate
ScoreAnchorPair
ScoreAnchorSkeleton
BuildNoveltyReference
ClassifyNovelty
```

The exact Lua signatures may be refined during implementation, but the worker must not inspect `ZONE_NATIVE` and apply Zone-specific formulas itself.

All Zone-specific preference belongs in the Zone policy.

## Compatibility fallback

Class Fantasy and Chronicle Echo do not have anchor policies in v1.11.3.

For those modes, the bridge calls the existing helpers exactly as before.

A missing required callback from a registered Zone anchor policy is a development error and blocks packaging.

Production must not silently substitute Traveler policy.

---

# Zone anchor policy contract

Suggested module:

```text
Core/Generation/Modes/Zone/AnchorPolicy.lua
```

The policy owns:

## Identity

```text
policy ID: ZONE_ANCHOR_POLICY_V1
policy version: 1
authority: ACTIVE
```

## Context

```text
Zone Context Snapshot fingerprint
profile key and label
provenance key and label
era ceiling
canonical style coverage
compatibility context
```

## Candidate relevance

```text
legacy continuity score
Zone affinity score
Zone affinity confidence
Zone affinity classification
bounded evidence adjustment
slot prominence multiplier
favorite state
locked state
final policy score
policy reasons
```

## Pair interpretation

```text
shared visual pair cohesion
shared hard-clash state
local-support bonus
Zone evidence confidence
final relationship bonus
```

## Weapon bundle interpretation

```text
legal route identity
logical weapon appearances
per-appearance Zone affinity
weapon/body visual cohesion
local-support bonus
linked-visual deduplication
final bundle score
```

## Novelty

The existing novelty classes and penalties remain unchanged:

```text
Initial Generation
Meaningfully New
Partial Change
Exact Repeat
```

Zone policy may add diagnostics describing how much local anchor evidence changed, but it does not introduce a new novelty class in v1.11.3.

---

# Candidate relevance model

## Compatibility base

The existing Zone Native source score remains the continuity base for v1.11.3.

This preserves current support for:

- profile keywords;
- avoidance keywords;
- small class influence;
- small Traveler influence;
- small Chronicle influence;
- current-outfit coherence;
- Zone favorites;
- deterministic stable affinity.

The policy records this as:

```text
legacyRelevance
```

The legacy score is not the final authority after v1.11.3, but it remains an explicit component rather than being discarded in one leap.

## Evidence adjustment

Zone Affinity v2 supplies a bounded adjustment.

Planned constants:

```text
ZONE_ANCHOR_AFFINITY_NEUTRAL       0.35
ZONE_ANCHOR_AFFINITY_SCALE        20.00
ZONE_ANCHOR_AFFINITY_MAX_BONUS     8.00
ZONE_ANCHOR_AFFINITY_MAX_PENALTY  -6.00
ZONE_ANCHOR_CONFIDENCE_FULL         0.65
```

Planned calculation:

```text
raw adjustment =
    (affinity score - neutral point) × scale

bounded adjustment =
    clamp(raw adjustment, maximum penalty, maximum bonus)

confidence factor =
    clamp(affinity confidence / confidence-full, 0, 1)

final evidence adjustment =
    bounded adjustment × confidence factor × slot multiplier
```

Planned slot multipliers:

```text
Chest           1.00
Legs            0.90
Shoulders       1.00
Logical weapon  1.10
```

These coefficients are calibration targets and become frozen only after automated fixture review proves that they create meaningful preference without overwhelming visual quality or user favorites.

Any coefficient change during implementation must be recorded in the validation report.

## Unknown and missing behavior

```text
Affinity classification UNKNOWN:
Adjustment 0

Confidence 0:
Adjustment 0

MISSING component:
Handled inside Affinity v2 confidence

NOT_APPLICABLE component:
No score weight and no confidence weight
```

## Favorites

A Zone favorite remains a strong user-authored preference through the legacy continuity score.

The evidence adjustment may inform ordering among favorites, but it may not quietly erase the player’s favorite bonus.

## Exclusions

Zone exclusions remain hard eligibility rules and never reach anchor preference scoring.

---

# Candidate diagnostics

Every selected Zone anchor candidate records:

```lua
{
    policyID = "ZONE_ANCHOR_POLICY_V1",
    legacyRelevance = 0,
    zoneAffinity = 0,
    zoneConfidence = 0,
    zoneClassification = "UNKNOWN",
    zoneAdjustment = 0,
    slotMultiplier = 1,
    finalRelevance = 0,
    favorite = false,
    locked = false,
    reasons = {},
}
```

Candidate-pool aggregate diagnostics record:

```text
prepared candidates
eligible candidates
UNKNOWN candidates
known off-zone candidates
weak-local candidates
supported-local candidates
strong-local candidates
mean affinity
mean confidence
mean adjustment
minimum adjustment
maximum adjustment
```

Raw diagnostic aggregation must remain bounded.

The persisted report prioritizes selected candidates and finalist summaries over full raw candidate lists.

---

# Zone pair interpretation

## Visual pair cohesion remains authoritative

The existing shared visual-language pair score remains the displayed cohesion value.

The Zone policy must not rename Zone alignment as visual cohesion.

```text
visualPairCohesion: 0..1
zonePairSupport:    bounded score bonus
```

## Local-support bonus

The first policy version rewards pairs where both pieces carry credible local evidence.

Planned calculation:

```text
left support  = affinity score × confidence
right support = affinity score × confidence
shared local support = minimum(left support, right support)
zone pair bonus = clamp(shared local support × 6, 0, 4)
```

Properties:

- two locally supported pieces may receive a small ranking bonus;
- one unknown piece produces little or no bonus;
- one known off-zone piece does not receive the bonus;
- no negative pair penalty is added in v1.11.3;
- individual candidate adjustments already handle known off-zone evidence;
- hard visual clashes remain unchanged.

The exact coefficient may be reduced during calibration but may not exceed `+4` in v1.11.3.

## Hard-clash sovereignty

If shared visual analysis marks the pair as a hard clash:

```text
hardClash = true
```

The local-support bonus may still be recorded diagnostically, but it does not clear the clash or remove the hard-clash penalty.

---

# Legal weapon-bundle policy

## Existing topology remains authoritative

v1.11.3 does not change:

- One-Hand routes;
- linked weapon handling;
- physical dual-wield handling;
- Two-Hand routes;
- genuine Ranged routes;
- Shield companions;
- Holdable/Focus companions;
- Fury permissions;
- Blizzard slot-and-option ownership;
- weapon candidate index behavior.

The Zone policy scores only bundles already declared legal by the existing weapon route system.

## Logical weapon identity

A linked weapon displayed in both physical hands is one logical visual for Zone affinity.

It is scored once for local relevance.

Independent Main Hand and Off Hand visuals are scored once each.

```text
Same visual in linked hands:
1 Zone affinity contribution

Two distinct weapon visuals:
2 Zone affinity contributions
```

This prevents a two-handed or linked presentation from receiving double local credit.

## Weapon/body relationships

Shared visual pair cohesion remains authoritative for weapon/body relationships.

The Zone policy adds the same bounded local-support bonus used by armor pairs.

## Weapon diagnostics

Record:

```text
route family
main logical visual
secondary logical visual, when distinct
per-visual affinity and confidence
linked deduplication state
legacy weapon relevance
Zone adjustment
visual relationship bonus
Zone pair-support bonus
final bundle score
```

---

# Novelty behavior

v1.11.3 preserves existing novelty behavior.

Generate Outfit:

- prefers the strongest available novelty class inside the established quality window;
- retains current repeat penalties;
- may accept an exact repeat only when no stronger novelty class remains inside the quality window.

Reroll Unlocked:

- preserves hard replacement semantics;
- does not use the Generate Outfit novelty preference path.

Zone diagnostics add:

```text
local evidence changed
local evidence repeated
selected-anchor mean affinity before and after
```

These fields are observational and do not create a second novelty system.

---

# Support boundary

## Support remains legacy in v1.11.3

After the Zone anchor skeleton is selected, the existing support system continues unchanged.

It may naturally produce a different support outfit because the selected anchors changed.

That is an allowed downstream consequence.

The following support mechanics remain byte-identical unless a narrowly required policy bridge proves unavoidable:

- support slot order;
- support profile construction;
- candidate preparation;
- support role assignment;
- mismatch allowances;
- beam width;
- budget ledger;
- final validation thresholds;
- repair targeting;
- repair comparison;
- alternate-skeleton behavior;
- contextual support rerolls.

Reports must state:

```text
Zone anchor policy: ZONE_ANCHOR_POLICY_V1
Zone support policy: LEGACY
```

## No Zone support claims

v1.11.3 must not claim that support pieces are selected through a Zone-native support policy.

The current support algorithm may consume the newly selected anchors, but it remains the existing inherited behavior.

---

# Context compatibility

The legacy compatibility context continues to exist because the current eligibility, support, naming, and downstream systems require it.

The Zone anchor policy consumes both:

```text
Immutable policy context:
Zone Context Snapshot v1

Compatibility runtime context:
Existing ZoneStyle generation context
```

The snapshot owns factual Zone identity and evidence.

The compatibility context owns existing downstream interfaces until later v1.11.x releases migrate them.

The anchor policy must not reconstruct Zone identity from the compatibility context when a valid snapshot exists.

---

# Fallback and failure behavior

## Explicit compatibility fallback

If a Zone action cannot obtain a valid format-1 snapshot before anchor scoring begins, it may use the existing Zone legacy anchor score for that action.

The report must state:

```text
Zone anchor policy fallback: LEGACY_SCORE
Reason: <specific reason>
```

This fallback:

- is explicit;
- does not claim `ZONE_ANCHOR_POLICY_V1` authority for that action;
- does not use Traveler policy;
- preserves legal generation;
- produces a warning.

## Policy contract failure

A missing required Zone policy callback is not a compatibility fallback.

It is a development or package-integrity error and must fail clearly.

## Runtime policy error

An unexpected Zone policy error must leave the previous preview unchanged.

It must not silently switch to Traveler scoring.

---

# Diagnostics and report format

## Zone debug export format

Increment:

```text
Zone debug export format: 2 → 3
```

Reason:

- new anchor-policy identity;
- anchor authority state;
- selected-anchor score decomposition;
- pool and finalist evidence summaries;
- logical weapon affinity;
- context-staleness result.

Retain:

```text
Dynamic value encoding: DIAGNOSTIC_ESCAPE_V1
```

## New report section

Add:

```text
== Zone Anchor Policy ==
```

Suggested contents:

```text
Policy: ZONE_ANCHOR_POLICY_V1 • ACTIVE
Snapshot: ZCTX-...
Context stale at commit: No
Support policy: LEGACY
Fallback: None

Selected anchor evidence:
Slot       Legacy   Affinity   Confidence   Adjustment   Final
Chest      ...
Legs       ...
Shoulders  ...
Weapon     ...

Candidate pools:
Slot       Prepared   Known   Unknown   Mean affinity   Mean adjustment
...

Pair interpretation:
Visual cohesion bonus
Zone local-support bonus
Hard clashes

Weapon bundle:
Route
Logical visuals
Linked deduplication
Zone adjustment
```

## Existing sections

Preserve existing:

- Overview;
- Anchor Skeleton;
- Contextual Support;
- Beam Search;
- Score Breakdown;
- Performance;
- Cache and Metadata;
- Warnings and Fallback;
- comparison ancestry.

The selected-anchor Zone decomposition may be referenced from the existing Anchor Skeleton section but must have one authoritative stored representation.

## Report compaction

When reports exceed the persistence ceiling, preserve:

1. policy ID and authority;
2. snapshot fingerprint;
3. selected-anchor score decomposition;
4. selected weapon-bundle decomposition;
5. fallback or context-staleness state;
6. headline pool and finalist statistics;
7. warnings;
8. ancestry needed by rerolls.

Raw per-candidate aggregates may be compacted first.

---

# Format and compatibility strategy

Retain:

```text
SavedVariables schema:             2
Courier format:                    1
Wardrobe cache format:            7
Generation cache store:           2
Diagnostic format:                1
Weapon-index format:              1
Zone Context Snapshot format:     1
Zone foundation:                  CONTEXT_EVIDENCE_V1
Profile registry:                 1
Provenance registry:              1
Starting-zone registry:           1
Era rules:                        1
Zone affinity format:             2
Dynamic value encoding:           DIAGNOSTIC_ESCAPE_V1
```

Add:

```text
Zone anchor policy format:         1
Zone anchor policy ID:             ZONE_ANCHOR_POLICY_V1
```

Increment:

```text
Zone debug export format:          2 → 3
```

No SavedVariables migration is required.

No cache reset is required.

No wardrobe rescan is required solely because of v1.11.3.

Existing reports remain readable.

---

# Runtime module plan

Suggested new modules:

```text
Core/Generation/Modes/Zone/AnchorPolicy.lua
Core/ZoneStyle/Zone/AnchorScoring.lua
Core/Wardrobe/AnchorPolicyBridge.lua
```

Possible existing-module updates:

```text
Core/Generation/AnchorEngine.lua
Core/Generation/Modes/ZoneLegacyAdapter.lua
Core/Generation/Modes/Zone/Diagnostics.lua
Core/Wardrobe/GenerationSetupWorker.lua
Core/Wardrobe/AnchorSkeletonWorker.lua
Core/Wardrobe/AnchorSkeletonSearch.lua
Core/Wardrobe/AnchorSkeletonCache.lua
Core/Wardrobe/AnchorSkeletonApply.lua
Core/Diagnostics/GenerationReports.lua or the current report builders
Core/ZoneStyle/Zone/Debug.lua
Core/ZoneStyle/Zone/DebugExport.lua
QuestChronicle.toc
```

These are planning targets, not a requirement to create empty wrapper files.

Every new module must own a real responsibility.

Every runtime Lua file remains below 500 physical lines.

---

# Implementation strategy

## Step 1: freeze the v1.11.2 baseline

Record exact deterministic fixtures for:

- Traveler anchor candidates and selections;
- Zone Native anchor candidates and selections;
- Class Fantasy anchor candidates and selections;
- Chronicle Echo anchor candidates and selections;
- candidate counts;
- random-call counts;
- beam expansions;
- weapon routes;
- novelty;
- support results;
- scheduler counters;
- Debug reports;
- Zone debug export format 2.

## Step 2: add policy identity and constants

Add:

```text
ZONE_ANCHOR_POLICY_V1
Zone anchor policy format 1
Zone debug export format 3
```

Do not change behavior yet.

## Step 3: harden the shared anchor-policy bridge

Attach the registered mode policy to generation jobs.

Route candidate, pair, skeleton, and novelty callbacks through the shared `AnchorEngine` when a policy exists.

Keep compatibility helpers for Class and Echo.

Run complete Traveler, Zone, Class, and Echo parity before continuing.

## Step 4: implement Zone candidate scoring in shadow fixtures

Build Zone candidate score decomposition without changing runtime selection.

Verify:

- snapshot use;
- affinity v2 use;
- unknown neutrality;
- N/A neutrality;
- favorite preservation;
- one random draw per candidate;
- bounded adjustment.

Shadow evaluation belongs in tests and development fixtures, not as a second expensive live candidate pass.

## Step 5: activate Zone candidate authority

Make the Zone candidate policy score authoritative for anchor-pool priority and retained ordering.

Do not filter candidates based solely on affinity.

## Step 6: add Zone pair support

Preserve shared visual cohesion and hard clashes.

Add only the bounded local-support bonus.

Run deterministic pair and beam fixtures before continuing.

## Step 7: integrate logical weapon-bundle scoring

Score legal weapon bundles through the Zone policy.

Deduplicate linked identical visuals for local affinity.

Preserve route generation and weapon-index behavior.

## Step 8: preserve novelty behavior

Route novelty callbacks through the policy seam while returning the established novelty results.

Add Zone-local evidence comparison diagnostics only.

## Step 9: add context-staleness protection

Record the snapshot fingerprint at action start and verify it before commit.

A changed Zone context fails atomically.

## Step 10: add reports and export format 3

Expose policy identity, score decomposition, pool summaries, logical weapon evidence, and fallback state.

## Step 11: prove support-code neutrality

Verify that support algorithms, thresholds, and repair mechanics remain unchanged.

Document any unavoidable bridge-only edit separately.

## Step 12: complete package and Retail validation

Package only after every automated, static, parity, performance, and hygiene gate passes.

---

# Automated test plan

## Policy registration

Verify:

- Zone registers exactly one anchor policy;
- policy ID is `ZONE_ANCHOR_POLICY_V1`;
- policy format is 1;
- authority is `ACTIVE`;
- Zone still reports implementation `LEGACY`;
- Zone support remains `LEGACY`;
- Traveler remains `SHARED_FRAMEWORK`;
- Class and Echo remain `LEGACY`.

## Shared bridge parity

Before activating Zone scoring, require exact parity for all four modes through the policy bridge.

Verify:

- candidate IDs;
- candidate base scores;
- pair scores;
- hard clashes;
- beam nodes;
- finalist order;
- novelty;
- selected skeleton;
- random-call count.

## Zone candidate fixtures

Use representative candidates for:

- strong local evidence;
- supported local variation;
- weak local evidence;
- known off-zone evidence;
- partial evidence;
- unknown evidence;
- favorite appearances;
- locked appearances;
- missing descriptor channels;
- not-applicable channels.

Require:

```text
strong local > weak local when legacy factors are otherwise equal
known off-zone < neutral when legacy factors are otherwise equal
unknown = no evidence adjustment
favorite remains strongly preferred
locked remains accepted
N/A creates no penalty
```

## Bounded adjustment

Verify:

```text
maximum Zone bonus <= +8 × slot multiplier
maximum Zone penalty >= -6 × slot multiplier
unknown adjustment = 0
confidence 0 adjustment = 0
```

## Random-consumption parity

For identical eligible candidate sets, require the same number of random calls as v1.11.2.

No affinity or pair analysis may call `math.random()`.

## Pair interpretation

Verify:

- visual pair cohesion remains identical;
- hard-clash results remain identical;
- local-support bonus is bounded at +4;
- hard clash cannot be cleared;
- unknown evidence produces no local-support bonus;
- two locally supported pieces may outrank an otherwise equal neutral pair.

## Weapon bundles

Verify:

- all existing legal routes remain legal;
- no new route appears;
- linked identical visuals receive one affinity contribution;
- independent dual weapons receive two contributions;
- two-hand presentations are not double-counted;
- ranged does not leak into melee;
- shields and focuses remain legal only on existing routes;
- weapon-index lifecycle remains unchanged.

## Novelty

Require exact v1.11.2 novelty classifications and repeat penalties for equivalent finalist sets.

## Context staleness

Verify:

- unchanged fingerprint commits;
- timestamp-only differences commit;
- changed zone/profile/provenance fingerprint cancels;
- cancelled actions preserve the previous preview;
- one cancellation result is recorded.

## Locks and hidden slots

Verify:

- locked anchors never change;
- locked low-affinity anchors remain selected;
- hidden shoulders remain hidden;
- hidden anchors do not affect local averages;
- repair cannot mutate locked anchors;
- rerolls preserve locks and hidden state.

## Support boundary

Require exact code and fixture parity for:

- support slot order;
- support pool limits;
- role resolution;
- mismatch allowances;
- budget ledger;
- final thresholds;
- repair caps;
- alternate-skeleton cap;
- support reroll logic.

Changed Zone anchors may produce different support selections in end-to-end tests, but the support algorithm and coefficients must remain unchanged.

## Other-mode parity

Traveler requires exact semantic parity.

Class and Echo require exact selection and random-consumption parity.

## Reports and export

Verify:

- export format is 3;
- `DIAGNOSTIC_ESCAPE_V1` remains active;
- selected anchor score decomposition is present;
- policy and authority are present;
- support remains labeled legacy;
- linked weapon deduplication is visible;
- context-staleness result is visible;
- oversized reports compact safely;
- existing format-2 exports remain understandable as historical text.

## Performance

Require:

```text
No new repeated worker slice above 8 ms
No new individual Zone policy call above 8 ms
0 post-expensive continuations
No extra wardrobe scan
No second full candidate pass
No additional random pass
No repeated phase
No increase in legal weapon-route enumeration
```

Affinity analysis should reuse descriptor and evidence caches where available.

## File and dependency hygiene

Verify:

- all Lua files parse;
- all TOC entries appear exactly once;
- no runtime Lua file reaches 500 lines;
- no circular Generation/ZoneStyle dependency is introduced;
- shared modules do not import Zone profile facts;
- Zone policy does not import Traveler policy;
- no `math.random()` appears in Zone evidence or affinity modules;
- policy coefficients live in one authoritative module;
- JSON and Markdown artifacts remain valid.

---

# Cross-version parity and intentional-difference report

The v1.11.3 handoff must include:

```text
Shared anchor bridge parity
Traveler anchor parity
Class anchor parity
Echo anchor parity
Zone eligibility parity
Zone candidate-count parity
Zone random-consumption parity
Zone legal-weapon parity
Zone lock and hidden-state parity
Zone support-algorithm parity
Zone scheduler parity
Zone cache and report parity
```

Zone selection differences are expected and must be classified as:

```text
ZONE_POLICY_CANDIDATE_WEIGHT
ZONE_POLICY_PAIR_SUPPORT
ZONE_POLICY_WEAPON_WEIGHT
ZONE_POLICY_FINAL_CHOICE
DOWNSTREAM_SUPPORT_FROM_CHANGED_ANCHOR
```

Every difference must identify its first causal policy component.

Unexplained Zone differences block release.

Any Traveler, Class, or Echo semantic difference blocks release.

---

# Retail live-validation plan

## Test 1: architecture identity

Run:

```text
/qc zone debug export
```

Confirm:

```text
Version: 1.11.3
Traveler implementation: SHARED_FRAMEWORK
Zone Native implementation: LEGACY
Zone foundation: CONTEXT_EVIDENCE_V1
Zone anchor policy: ZONE_ANCHOR_POLICY_V1
Zone anchor authority: ACTIVE
Zone support policy: LEGACY
Zone debug export format: 3
Zone affinity format: 2
```

## Test 2: Zone Native generation

In a well-resolved zone such as Netherstorm, perform:

```text
Generate Outfit
Generate Outfit
Reroll Unlocked
```

Confirm:

- every action completes;
- `Fallback: None` unless an explicit policy fallback is explained;
- legal weapon routes;
- locks and hidden slots preserved;
- Zone anchor policy section present;
- snapshot fingerprint present;
- selected anchors show legacy score, affinity, confidence, adjustment, and final score;
- support remains labeled legacy;
- no Lua errors.

## Test 3: local-evidence behavior

Review selected anchors rather than requiring one predetermined outfit.

Confirm:

- locally supported pieces receive positive adjustments;
- known off-zone pieces receive bounded negative adjustments;
- unknown pieces receive zero evidence adjustment;
- low-confidence evidence produces a smaller adjustment;
- visual hard clashes remain rejected;
- an appearance is never called local solely because it is era-valid.

## Test 4: legal weapon bundle

Generate at least one one-hand or linked bundle and one two-hand bundle when available.

Confirm:

- route legality;
- logical affinity deduplication;
- no double local credit for the same linked visual;
- current physical hand labels remain correct.

## Test 5: locks and hidden state

Lock one visible anchor and hide one optional anchor.

Generate and reroll.

Confirm:

- the locked appearance remains unchanged;
- the hidden slot remains hidden;
- the locked anchor is analyzed but not rejected;
- the hidden anchor is excluded from local evidence averages.

## Test 6: context staleness

Begin Zone generation near a meaningful zone boundary and cross that boundary before completion when practical.

Expected:

- action cancels clearly;
- previous preview remains unchanged;
- one cancellation report records the fingerprint change.

If a practical boundary test is not reliable, validate through the packaged deterministic harness and mark the Retail portion not exercised.

## Test 7: Traveler regression

Perform:

```text
Traveler Generate Outfit
Traveler Reroll Unlocked
Traveler contextual support reroll
```

Confirm the v1.10/v1.11 Traveler behavior remains intact.

## Test 8: Class and Echo regression

Generate one outfit in each mode.

Confirm both remain `LEGACY` and no Zone policy fields leak into their reports.

## Test 9: performance

Confirm:

```text
Longest worker slice below 8 ms
Largest Zone policy call below 8 ms
0 post-expensive continuations
No synchronous launch stall
```

## Test 10: export and reload

After Zone generation:

1. run `/qc zone debug export`;
2. copy the complete dossier externally;
3. use `/reload`;
4. run the export again.

Confirm:

- export format 3;
- copy fidelity remains intact;
- selected mode persists;
- preview persists as before;
- report history persists as before;
- no cache reset;
- no duplicate zone suggestion;
- policy identity remains correct.

---

# Acceptance criteria

v1.11.3 becomes package-ready only when:

1. `ZONE_ANCHOR_POLICY_V1` exists as a documented registered policy.
2. The Zone Context Snapshot is captured once per action and remains immutable.
3. The shared anchor bridge invokes mode policy callbacks authoritatively.
4. Traveler remains semantically identical.
5. Class Fantasy remains semantically identical.
6. Chronicle Echo remains semantically identical.
7. Zone candidate preference consumes Affinity v2.
8. Unknown evidence is neutral.
9. `NOT_APPLICABLE` remains neutral and is not missing.
10. Zone evidence adjustments are bounded.
11. Existing favorites, exclusions, era rules, provenance rules, promotion exclusions, and Heritage rules remain authoritative.
12. Shared visual hard clashes remain authoritative.
13. Legal weapon topology remains unchanged.
14. Linked identical weapons receive one logical affinity contribution.
15. Existing novelty classes and penalties remain unchanged.
16. Locks and hidden slots remain sovereign.
17. Context changes invalidate stale work atomically.
18. Zone support algorithms and thresholds remain unchanged.
19. Zone Native truthfully remains `Generation implementation: LEGACY`.
20. Reports truthfully identify `ZONE_ANCHOR_POLICY_V1` as active and support as legacy.
21. Zone debug export format 3 is copy-safe.
22. No new repeatable performance regression appears.
23. No runtime Lua file reaches 500 physical lines.
24. All automated tests and static verifiers pass.
25. Retail validation passes.

---

# Explicit non-goals

v1.11.3 does not:

- promote Zone Native to overall `SHARED_FRAMEWORK`;
- change Zone Context Snapshot format 1;
- change Zone Affinity format 2;
- change canonical Zone profile facts;
- resolve or remove the nine known alias collisions;
- change provenance pools;
- change starting-zone rules;
- change era restrictions;
- change promotional or Heritage exclusions;
- add hard affinity eligibility thresholds;
- rewrite Zone contextual support;
- change support mismatch budgets;
- change completed-outfit validation thresholds;
- add Zone-specific repair rules;
- modernize Zone rerolls;
- add a Zone tuning audit;
- add curated Zone appearance overrides;
- redesign the Outfits UI;
- redesign the Status tab;
- change SavedVariables, Courier, or cache formats;
- repair the deferred legacy individual anchor or weapon-slot reroll path;
- begin Class implementation work.

---

# Principal risks and mitigations

## Risk 1: local evidence overwhelms visual quality

**Failure mode:** Highly local pieces form an incoherent anchor skeleton.

**Mitigation:** Keep shared visual cohesion and hard clashes authoritative; bound candidate and pair adjustments.

## Risk 2: unknown descriptors are punished

**Failure mode:** Older or poorly hydrated appearances disappear from useful candidate pools.

**Mitigation:** Confidence-zero and `UNKNOWN` evidence produce zero adjustment, not a penalty.

## Risk 3: local relevance is confused with provenance legality

**Failure mode:** A broad Outland motif is treated as permission for a source outside the Netherstorm provenance pool.

**Mitigation:** Eligibility and provenance checks run before preference scoring and remain unchanged.

## Risk 4: second-policy integration changes Traveler

**Failure mode:** Shared bridge edits alter Traveler candidate, pair, or weapon scoring.

**Mitigation:** Add bridge parity before activating Zone policy and require exact Traveler fixtures afterward.

## Risk 5: support behavior is accidentally claimed as Zone-native

**Failure mode:** Reports imply that all outfit pieces use the new policy.

**Mitigation:** Display `Zone support policy: LEGACY` in architecture, reports, and export.

## Risk 6: linked weapons receive double Zone credit

**Failure mode:** Two-hand or linked routes dominate because one visual is scored twice.

**Mitigation:** Deduplicate logical visual identities before affinity aggregation and test every route family.

## Risk 7: policy analysis adds random calls

**Failure mode:** Deterministic fixtures drift unpredictably and other mode selections change.

**Mitigation:** Prohibit random use in Zone policy modules and compare random-call counters.

## Risk 8: stale Zone context commits

**Failure mode:** An outfit generated for one zone appears after the player crosses into another.

**Mitigation:** Freeze the snapshot and verify its fingerprint before commit.

## Risk 9: reports exceed the persistence ceiling

**Failure mode:** New policy details cause useful reports to disappear.

**Mitigation:** Store selected decomposition and bounded aggregates; compact raw pool detail first.

---

# Handoff to the next Zone release

After v1.11.3 is live-validated, the next Zone slice should modernize contextual support using the same evidence and the now-proven anchor policy.

Likely next release:

```text
v1.11.4  Zone contextual support policy v1
```

Likely scope:

```text
Zone support-profile construction
Zone support roles
Zone support candidate relevance
Local bridge and accent meaning
Zone mismatch allowances
Shared support-policy second implementation
No final-validation rewrite unless the support evidence proves ready
```

The next release must consume the v1.11.3 anchor profile rather than reconstructing Zone identity independently.

---

# Planned release artifacts

```text
QuestChronicle-v1.11.3.zip
QuestChronicle-v1.11.3-Architecture-and-Development-Plan.md
QuestChronicle-v1.11.3-Live-Validation-Steps.md
QuestChronicle-v1.11.3-Automated-Validation.md
QuestChronicle-v1.11.3-Parity-and-Intentional-Differences.md
QuestChronicle-v1.11.3-Implementation-Conformance.md
QuestChronicle-v1.11.3-Zone-Anchor-Policy-Schema.md
QuestChronicle-v1.11.3-Zone-Anchor-Calibration-Report.md
QuestChronicle-v1.11.3-Release-Notes.md
QuestChronicle-v1.11.3-Validation-Report.md
QuestChronicle-v1.11.3-Handoff-Manifest.md
QuestChronicle-v1.11.3.sha256
```

---

# Planned commit message

```text
feat: Update Quest Chronicle to v1.11.3

Add the first authoritative Zone anchor policy
Use immutable Zone evidence and Affinity v2 to guide anchor preference
Preserve shared visual cohesion, legal weapon routes, novelty, locks, and hidden state
Keep Zone support, validation, repair, and rerolls on their existing legacy behavior
Prepare the v1.11.x train for Zone contextual support policy work
```
