# Quest Chronicle v1.11.3 Zone Anchor Policy Schema

## Identity

```text
Policy ID: ZONE_ANCHOR_POLICY_V1
Policy format: 1
Authority: ACTIVE
Support policy: LEGACY
```

## Candidate calculation

For an eligible anchor candidate:

```text
raw adjustment = (affinity - 0.35) × 20
bounded adjustment = clamp(raw adjustment, -6, +8)
confidence factor = clamp(confidence / 0.65, 0, 1)
Zone adjustment = bounded adjustment × confidence factor × slot multiplier
final relevance = legacy relevance + Zone adjustment
```

Slot multipliers:

| Anchor | Multiplier |
|---|---:|
| Chest | 1.00 |
| Legs | 0.90 |
| Shoulders | 1.00 |
| One-Hand | 1.10 |
| Two-Hand | 1.10 |
| Ranged | 1.10 |
| Off-Hand companion | 1.10 |
| Logical Weapon Bundle | 1.10 |

`UNKNOWN` classification or confidence `0` produces exactly zero adjustment.

## Candidate diagnostic record

Each policy-evaluated candidate may carry:

```text
policyID
policyFormat
authority
legacyRelevance
zoneAffinity
zoneConfidence
zoneClassification
zoneAdjustment
slotMultiplier
rawAdjustment
boundedAdjustment
confidenceFactor
finalRelevance
favorite
locked
reasons
```

`favorite` and `locked` are diagnostic flags. Existing favorite behavior remains authoritative before and around the policy; a locked candidate remains accepted regardless of local affinity.

## Pair calculation

Visual cohesion and hard-clash analysis remain the shared authoritative pair channel.

For two candidates with known, non-partial local evidence at or above the neutral point:

```text
candidate support = affinity × confidence
shared local support = min(left support, right support)
Zone pair bonus = clamp(shared local support × 6, 0, 4)
```

The report keeps these channels separate:

```text
Visual relationship bonus
Zone pair-support bonus
```

A hard clash remains a hard clash regardless of Zone pair support.

## Weapon semantics

Existing legal bundle construction remains authoritative.

- linked identical visuals contribute one logical Zone affinity record;
- a two-handed presentation of one visual contributes once;
- distinct weapon visuals may contribute independently;
- the report records route family and whether a linked visual was deduplicated.

## Action context record

```text
modeContext
modeContextFingerprint
zoneContextCurrentFingerprint
zoneContextStaleAtCommit
zoneAnchorPolicyFallback
zoneAnchorPolicyFallbackReason
```

The original action fingerprint is immutable. A different commit-time fingerprint cancels before live-state mutation.

## Candidate-pool aggregate

Per anchor slot, bounded diagnostics may include:

```text
slotKey
prepared
eligible
retained
unknown
offZone
weakLocal
supportedLocal
strongLocal
meanAffinity
meanConfidence
meanAdjustment
minimumAdjustment
maximumAdjustment
```

These are observational summaries of the existing candidate pass. They do not initiate a second scan.

## Selected-policy summary

```text
policyID
policyFormat
authority
supportPolicy
snapshotFingerprint
contextStaleAtCommit
currentFingerprint
fallback
fallbackReason
selected[]
pools[]
armorPairSupport
weaponPairSupport
visualArmorRelationshipBonus
visualWeaponRelationshipBonus
logicalWeapons[]
linkedVisualDeduplicated
routeFamily
```

## Format compatibility

```text
Zone Context Snapshot: 1, unchanged
Zone affinity: 2, unchanged
Zone debug export: 3
Diagnostic format: 1, unchanged
SavedVariables schema: 2, unchanged
```
