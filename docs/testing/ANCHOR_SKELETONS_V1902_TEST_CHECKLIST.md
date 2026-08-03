# Quest Chronicle v1.9.0.2 Live Test Checklist

Phase B replaces independent Chest, Legs, Shoulders, and weapon generation with a cooperative beam-searched anchor skeleton. This checklist verifies visual quality, mode identity, locks, hidden slots, legal weapon routes, fallback behavior, performance, and compatibility.

## Installation

1. Exit World of Warcraft completely.
2. Replace the complete installed `QuestChronicle` folder with v1.9.0.2.
3. Do **not** delete `QuestChronicleDB` or any SavedVariables.
4. Start Retail and confirm Status & Maintenance reports `Quest Chronicle 1.9.0.2`.
5. Let the automatic wardrobe scan finish before generating.

Expected compatibility:

```text
SavedVariables schema: 2
Courier format:        1
Wardrobe cache format: 7
```

## Test A: Traveler smoke test

1. Select **Traveler**.
2. Use **Generate Outfit**.
3. Capture the generated summary and complete Generation Performance tooltip.
4. Run `/qc skeleton debug` and capture the output.
5. Confirm the preview changes atomically and contains legal appearances.

Record:

- total frames, elapsed time, worst step, and slowest phase;
- Chest, Legs, and Shoulder pool sizes;
- Chest, Legs, and Shoulder beam expansions and retained entries;
- weapon bundles evaluated;
- pair-cache hits and misses;
- chosen rank, shortlist size, score, and mean cohesion;
- fallback reason, if any.

Expected:

- a non-fallback skeleton with at least two active components;
- Chest, Legs, and Shoulders read as one foundation;
- the weapon bundle supports that foundation;
- no Lua errors, visible intermediate preview, or illegal weapon selection;
- normal Quest Chronicle steps remain cooperative, preferably below 8 ms.

## Test B: Traveler diversity

1. Use **Reroll Unlocked** nine times, producing ten Traveler outfits total.
2. Save screenshots or notes for each anchor skeleton.
3. Run `/qc skeleton debug` on any excellent, poor, repeated, or surprising result.

Evaluate:

- whether the same skeleton repeats immediately;
- whether one transmog set or visual family monopolizes the results;
- whether variety remains inside a coherent quality band;
- whether supporting slots reinforce rather than redefine the anchors;
- whether postal-code outliers are less common than with the independent generator.

Expected: rerolls vary while Chest, Legs, Shoulders, and weapons usually remain visibly related.

## Test C: Mode identity

Generate at least five outfits in each remaining mode:

```text
Zone Native
Class Fantasy
Chronicle Echo
```

For representative outfits, capture `/qc skeleton debug` and `/qc traveler debug`.

Expected:

- Zone Native reflects local zone and era signals;
- Class Fantasy emphasizes class silhouette and weapon identity;
- Chronicle Echo reflects recent quest, faction, enemy, and location signals;
- the modes do not collapse into the same rankings or repeated skeletons;
- every mode still honors era, provenance, promotional, progression, and weapon legality gates.

## Test D: locked anchors

1. Generate an outfit.
2. Lock Chest and use **Reroll Unlocked**.
3. Repeat with Legs, Shoulders, and the weapon controls where practical.
4. Test two or more locked anchors together.

Expected:

- each locked anchor remains unchanged;
- the beam searches around the fixed component;
- unlocked anchors and supporting slots still reroll;
- linked and unlinked weapon behavior remains legal;
- no lock is silently ignored.

## Test E: hidden anchors

1. Hide Shoulders and generate.
2. Hide another anchor slot and reroll.
3. Where the UI permits, test a look with fewer than two active anchor components.

Expected:

- hidden anchors are omitted without a mismatch penalty;
- hidden selections remain hidden and are not replaced unexpectedly;
- searches with too few active anchor components fall back safely;
- the legacy fallback preserves locks and hidden states.

## Test F: weapon routes

Exercise the weapon topologies available to the character:

- linked dual wield;
- unlinked dual wield;
- two-handed weapon;
- weapon plus shield or holdable;
- ranged weapon;
- artifact or paired appearance, where available.

Expected:

- the skeleton ranks only bundles already permitted by the existing route engine;
- Main Hand and Off Hand remain physically and visually correct;
- linked-hand exact-visual preference remains intact;
- subtype filters, artifacts, and locked hands remain authoritative;
- Custom Set export still reproduces the complete selected recipe.

## Test G: persistence crossing

1. Warm the pair and generation caches with several rerolls.
2. Use `/reload`.
3. Let the automatic wardrobe scan finish.
4. Generate again and capture the full performance tooltip.

Expected:

- persistent era, precheck, and eligibility caches remain warm;
- no return of the old cold-generation freeze or era-source-check explosion;
- the pairwise anchor cache may warm again because it is intentionally runtime-bounded;
- generation remains cooperative and atomic.

## Test H: manual and concept compatibility

1. Make a deliberate manual appearance selection.
2. Save or update a Quest Chronicle concept.
3. Restore the concept.
4. Save to or update a Blizzard Custom Set.

Expected:

- manual browsing remains unrestricted;
- existing concepts load unchanged;
- generated skeleton metadata does not alter authoritative selected appearances;
- Custom Set source rebinding and slot verification remain correct;
- no transmog is applied and no gold is spent.

## Quality acceptance criteria

Phase B succeeds when:

- Chest, Legs, Shoulders, and weapons usually form a coherent visual backbone;
- supporting armor visibly serves that backbone;
- obvious anchor clashes occur materially less often than before;
- rerolls remain diverse rather than repeating one armor family;
- Zone, Traveler, Class, and Echo retain distinct identities;
- locks, hidden slots, routes, artifacts, and exact-visual behavior remain correct;
- fallback use is rare and explainable;
- no data, concept, Custom Set, Courier, or recorder regression appears.

## Performance targets

```text
Warm generation:                 below 2.0 seconds preferred
Generate after /reload:          below 2.5 seconds preferred
Normal Quest Chronicle step:     below 8 ms preferred
Any beam or weapon stage:        no synchronous freeze
Atomic preview commit:           required
```

Timing targets are calibration goals rather than legality gates. Report the complete tooltip whenever a result exceeds them.

## Failure signals

- Chest, Legs, and Shoulders are still visibly independent most of the time;
- weapons repeatedly clash with otherwise coherent armor;
- one family monopolizes nearly every reroll;
- mode identity disappears;
- a locked anchor changes or vanishes;
- a hidden anchor reappears;
- an illegal or mismatched weapon route is selected;
- fallback occurs during ordinary fully unlocked generation;
- generation exposes partial results before completion;
- persistent generation-cache performance regresses after `/reload`;
- Lua errors, hangs, long frame freezes, concept loss, or Custom Set mismatch.
