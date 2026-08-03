# Quest Chronicle v1.9.0.2 - Phase B: Anchor Skeletons

v1.9.0.2 begins the active generation phase of the Traveler Cohesion Rewrite. Chest, Legs, Shoulders, and weapons are no longer chosen independently. Quest Chronicle now builds a coherent anchor skeleton first, then asks the remaining armor slots to support that foundation.

The implementation is built on the live-validated v1.9.0a10 cache, dependency, cooperative weapon, and atomic-generation baseline.

## Beam-searched armor foundations

- Prepares bounded, diversity-balanced candidate pools for Chest, Legs, and Shoulders.
- Expands the pools through a cooperative beam search rather than evaluating the full cross-product.
- Retains the strongest 32 partial skeletons after each armor stage.
- Uses a quality-windowed weighted finalist selection so rerolls remain varied without selecting a dramatically weaker result.
- Penalizes immediate repetition of the previous skeleton.

## Active cohesion scoring

- Activates the calibrated Traveler palette, material, finish, motif, visual-weight, provenance, and loudness relationships during anchor selection.
- Reuses mode-specific Zone Native, Traveler, Class Fantasy, and Chronicle Echo relevance scores.
- Adds a bounded pairwise cohesion cache keyed to stable descriptor identity.
- Limits visual-family saturation in each prepared candidate pool.

## Weapon bundle integration

- Expands the strongest four armor skeletons through the existing cooperative weapon-route engine.
- Treats each legal Main Hand and Off Hand result as one logical weapon bundle for skeleton scoring.
- Preserves physical topology, per-hand Blizzard permissions, linked hands, exact visuals, artifacts, subtype filters, and locked weapons.
- Does not allow cohesion scoring to override weapon legality.

## Supporting armor

- Generates Waist, Head, Hands, Feet, Wrists, Back, Shirt, and Tabard after the skeleton is chosen.
- Rebuilds the generation context around the selected skeleton so supporting pieces reinforce it.
- Preserves the private draft and atomic preview commit.

## Locks, hidden slots, and fallback

- Locked Chest, Legs, and Shoulders become fixed beam components.
- Shoulders can now be deliberately hidden; hidden anchors are omitted without a cohesion penalty.
- Missing or generation-ineligible locked anchors force the preserved legacy generator.
- Searches with fewer than two active legal anchor components fall back safely.
- Existing selections remain untouched until a complete generated draft commits.

## Diagnostics

The Generation Performance tooltip now reports:

```text
Chest, Legs, and Shoulder pool sizes
Beam expansions and retained entries per stage
Legal weapon bundles evaluated
Pairwise cohesion cache hits and misses
Chosen skeleton rank, score, and mean cohesion
Fallback reason, when applicable
```

`/qc skeleton debug` prints the latest anchor composition and beam summary.

## Compatibility

- SavedVariables schema remains 2.
- Courier format remains 1.
- Wardrobe cache format remains 7.
- Existing concepts, Custom Set links, selections, locks, hidden slots, preferences, and persistent generation caches remain valid.
- Quest Chronicle applies no transmog and spends no gold.
