# Quest Chronicle v1.11.3 Parity and Intentional Differences

## Baseline

```text
Baseline: Quest Chronicle v1.11.2
Target:   Quest Chronicle v1.11.3
```

## Runtime boundary

```text
v1.11.2 runtime modules:      141
Byte-identical modules:       124
Changed existing modules:      17
New runtime modules:             4
Removed runtime modules:         0
v1.11.3 runtime modules:       145
```

New runtime modules:

```text
Core/Generation/Modes/Zone/AnchorPolicy.lua
Core/Wardrobe/AnchorPolicyBridge.lua
Core/Wardrobe/GenerationJobFactory.lua
Core/ZoneStyle/Zone/AnchorScoring.lua
```

## Exact semantic parity required

The following modes and systems permit no semantic difference:

```text
Traveler anchor, support, validation, repair, reroll, scheduler, and report behavior
Class Fantasy selection and random consumption
Chronicle Echo selection and random consumption
Zone eligibility and provenance
Zone era, promotion, Heritage, favorite, and exclusion rules
Legal weapon-route construction
Novelty classifications and repeat penalties
Locks and hidden-slot sovereignty
Support order, candidate limits, roles, budgets, thresholds, repair caps, and rerolls
SavedVariables, Courier, wardrobe cache, generation cache, diagnostic format, and weapon index
```

## Intentional Zone differences

Zone Native anchor preference may differ from v1.11.2 because the immutable Zone Context Snapshot and Affinity v2 now participate authoritatively in anchor relevance and bounded pair support.

Every expected difference must identify its first causal component:

```text
ZONE_POLICY_CANDIDATE_WEIGHT
ZONE_POLICY_PAIR_SUPPORT
ZONE_POLICY_WEAPON_WEIGHT
ZONE_POLICY_FINAL_CHOICE
DOWNSTREAM_SUPPORT_FROM_CHANGED_ANCHOR
```

A downstream support selection may differ only because the committed Zone anchor skeleton changed. The support algorithm itself remains byte-identical.

## Frozen mechanics

Zone evidence remains preference rather than eligibility:

- ineligible appearances never reach policy preference;
- unknown and zero-confidence evidence are neutral;
- `NOT_APPLICABLE` remains neutral and is not missing;
- hard clashes remain authoritative;
- locked anchors remain accepted;
- hidden anchors remain excluded visually;
- legal weapon topology remains unchanged;
- linked presentations of one visual receive one logical Zone contribution;
- no additional random draw or second candidate pass is introduced.

## Protected byte-identical modules

```text
Core/ZoneStyle/Scoring.lua
Core/ZoneStyle/Zone/Affinity.lua
Core/Wardrobe/SupportProfile.lua
Core/Wardrobe/SupportBudget.lua
Core/Wardrobe/SupportRoleResolver.lua
Core/Wardrobe/SupportScoring.lua
Core/Wardrobe/SupportBeam.lua
Core/Wardrobe/SupportFinalValidation.lua
Core/Wardrobe/SupportRepair.lua
Core/Wardrobe/SupportReroll.lua
Core/Wardrobe/AppearanceRoutes.lua
Core/Wardrobe/WeaponPipeline.lua
Core/Wardrobe/GenerationScheduling.lua
Core/Generation/Modes/Traveler/AnchorPolicy.lua
Core/Generation/Modes/Traveler/SupportPolicy.lua
Core/Generation/Modes/Traveler/ValidationPolicy.lua
```

## Automated parity results

```text
Shared anchor bridge compatibility: PASS
Traveler semantic parity:          PASS
Class semantic parity:             PASS
Echo semantic parity:              PASS
Zone eligibility parity:           PASS
Zone random-consumption parity:    PASS
Zone legal-weapon parity:          PASS
Zone locks and hidden state:       PASS
Zone support-algorithm parity:     PASS
Zone scheduler boundary:           PASS
Zone cache and format parity:      PASS
Intentional Zone preference tests: PASS
```

## Result

```text
Automated parity: PASS
Retail intentional-difference review: Pending
```
