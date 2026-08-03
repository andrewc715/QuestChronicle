# Quest Chronicle v1.9.0.7 Phase C Implementation Report

## Release purpose

Phase C replaces independent generation of Waist, Hands, Feet, Head, Back, Wrists, Shirt, and Tabard with one contextual support configuration built after the Phase B anchor skeleton is committed.

## Pipeline

```text
Phase B anchor selection
Contextual profile derivation
Locked-support commitments
Bounded support candidate pools
Cooperative support beam
Mismatch-budget evaluation
Final support selection
Atomic preview commit
Immutable diagnostic snapshot
```

Phase C never feeds support information back into Phase B. Chest, Legs, Shoulders, weapon routes, anchor novelty, and anchor scores remain the v1.9.0.5 source of truth.

## Context model

The profile retains the approved anchor weights:

```text
Chest          34%
Legs           24%
Shoulders      18%
Weapon bundle  24%
```

Hidden or unavailable anchors contribute zero and their weight is redistributed across active anchors. Unlinked weapon hands divide the logical bundle weight without increasing the logical anchor count.

Profile distance uses the established descriptor weights:

```text
Palette        40%
Material       22%
Finish         14%
Visual weight  10%
Motif           9%
Provenance      5%
```

Anchor spread creates per-dimension tolerances. Candidate mismatch cost applies only to descriptor distance beyond those tolerances and is moderated by recorded descriptor confidence.

## Mismatch ledger

A fully visible support pass begins with 10.75 mismatch points. Hidden and unavailable support slots contribute no allowance. Locked support pieces remain sovereign, are recorded as fixed decisions, and spend from a separate locked commitment before unlocked generation begins.

Each candidate is classified as Within Budget, Borrowed, or Over Budget. Future-slot reserves prevent an early high-prominence choice from exhausting the ledger. The beam can use a lowest-cost slot-local fallback rather than discarding the complete anchor skeleton.

## Support beam

```text
Prepared candidates per slot  32 maximum
Retained support nodes         24 maximum
Final shortlist                 6 maximum
Final score window             20 points
```

The support order is Waist, Hands, Feet, Head, Back, Wrists, Shirt, and Tabard. Nodes store only compact selected candidates, decisions, budget state, score, mismatch usage, and fallback count. Visual identities deduplicate both prepared pools and retained beam states.

## Contextual scoring

Support scoring combines:

- existing mode relevance;
- anchor-profile compatibility;
- already committed contextual neighbors;
- bridge improvement;
- slot-role fulfillment;
- controlled-accent behavior;
- mismatch and reserve pressure;
- loudness-aware outlier penalties;
- Generate Outfit soft repeat pressure.

Unlocked support slots do not consult stale support selections from the previous preview. Only anchors, locked support pieces, and support pieces already committed in the current beam node may influence neighbor scoring.

## Action behavior

- **Generate Outfit** uses soft support-repeat pressure.
- **Reroll Unlocked** hard-excludes current unlocked support visuals where alternatives exist.
- **Reroll Slot** keeps every unrelated slot fixed and selects one contextual replacement.
- Rerolling an anchor or weapon route rebuilds unlocked support around the new foundation while preserving locked support.

## Diagnostics

Diagnostic format 1 remains compatible and gains optional Phase C fields:

- active anchors, profile centers, tolerance, and confidence;
- starting budget, locked commitment, generated spend, borrowing, overrun, and remainder;
- support pools, expansions, retained nodes, deduplication, and budget rejections;
- one immutable decision per selected support slot;
- bridge target and before/after relationship;
- mismatch, budget, outlier, repeat, lock, and fallback state;
- support configuration score and whole-outfit cohesion;
- immutable previous-run support comparisons.

The maximum-detail synthetic copy report is 6,216 bytes, below the 20 KB persistence ceiling.

## Automated evidence

```text
Contextual profile test       4 logical anchors, 10.75 full budget
Cooperative worker test       8 selected slots in 4 synthetic frames
Stress benchmark              256 prepared candidates
                              5,408 beam expansions
                              78 synthetic frames
                              2.60 ms maximum slice
                              chosen rank 3/6
Contextual reroll test        isolated slot replacement and locked preservation
Locked/hidden state test      hidden allowance omitted and locked mismatch committed
Report-size test              8 decisions, 6,216 bytes
```

## Compatibility

```text
SavedVariables schema   2
Courier format          1
Wardrobe cache format   7
Generation cache        2
Diagnostic format       1
```

No database or cache reset is required.
