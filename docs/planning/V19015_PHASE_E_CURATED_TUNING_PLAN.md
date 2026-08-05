# Quest Chronicle v1.9.0.15 Implementation Plan

## Phase E: Curated Tuning

## Release purpose

Quest Chronicle v1.9.0.15 is the final curated-tuning phase of the Traveler Cohesion Rewrite.

Phase E uses the next live batch of generated Traveler outfits to identify and correct data-quality problems in the visual descriptor layer:

- incorrect palette tags;
- incorrect finish classifications;
- missing secondary accent echoes;
- repeat-offender appearances that need exact curated overrides.

This release tunes the inputs consumed by Phases B, C, and D. It does not rewrite their scoring, thresholds, beam searches, repair limits, scheduler behavior, or weapon routes.

The guiding rule is:

```text
Correct the visual description, not the outcome.
```

Phase E must never force an outfit to pass by directly overriding its mismatch class, score, Phase D status, or repair result.

---

# Starting point

Create v1.9.0.15 directly from the live-validated v1.9.0.14 source.

v1.9.0.14 is the required baseline because Retail validation confirmed:

- completed-outfit final validation;
- genuine one-pass palette-overflow repairs;
- clean Phase D paths;
- warm weapon-index reuse;
- Reroll Unlocked;
- target-isolated support rerolls;
- lock sovereignty;
- atomic report and preview commitment;
- diagnostic report compaction;
- cooperative scheduler integrity.

The live v1.9.0.14 reports are evidence that the tuning workflow is needed, but they are not themselves proof that any particular descriptor is wrong.

For example, Gray Woolen Shirt and Stylish Black Shirt were legitimately selected as palette-overflow repair targets in the live batch. Whether their current tags are visually wrong, incomplete, or simply correct but contextually inconvenient must be decided from screenshots and audited descriptor evidence rather than from the repair count alone.

---

# Release strategy

v1.9.0.15 should be developed in three controlled stages.

## v1.9.0.15a1: Observation build

Add compact local tuning-audit instrumentation.

The observation build must not alter:

- descriptors;
- selected appearances;
- Phase D decisions;
- scoring;
- random consumption;
- scheduler behavior.

Its purpose is to collect the next live batch efficiently without bloating normal Debug reports.

## v1.9.0.15a2: Curated correction build

Apply the approved palette, finish, and echo corrections from the reviewed batch.

Add exact appearance overrides and regression fixtures.

## v1.9.0.15 release candidate

Freeze the curated ledger, remove any temporary failure-injection helpers, run scoped parity, and perform a second live validation batch focused on corrected appearances and unintended side effects.

---

# Phase E boundaries

## Frozen systems

v1.9.0.15 must not change:

- Phase B pair-cohesion weights;
- Phase B profile-cohesion weights;
- Phase B candidate limits, beam widths, shortlist rules, or novelty logic;
- Phase B's 28-point quality window;
- Phase C support roles;
- Phase C pool limit of 32;
- Phase C beam width of 24;
- Phase C shortlist of 6;
- Phase C support-score window;
- Phase C mismatch allowances, reserves, or borrowing;
- Phase D's 2.00 final mismatch budget;
- Phase D's strict 0.72 severity threshold;
- Phase D's three-palette-family limit;
- Phase D's loud zero-echo rule;
- Phase D's two-repair-pass limit;
- Phase D's one-alternate-skeleton limit;
- weapon routes and equipment topology;
- locked and hidden semantics;
- scheduler budgets and force-yield rules;
- cache formats;
- diagnostic format;
- Courier format;
- outfit naming.

## Prohibited shortcuts

Phase E must not add:

- forced mismatch classifications;
- forced `CLEAN` or `REPAIRED` states;
- appearance-specific Phase D exemptions;
- direct selection bans based only on taste;
- arbitrary score bonuses or penalties;
- broad name-only overrides;
- automatic overrides created solely from frequency counts.

A repeat offender is a review candidate, not an automatic conviction.

---

# Observation batch

## Recommended batch size

Collect a minimum of 20 completed Traveler actions.

A target of 30 actions provides a stronger repeat-offender signal.

Natural play is preferred. The batch should include, when practical:

- full Generate Outfit actions;
- Reroll Unlocked actions;
- a few support-slot rerolls;
- both two-handed and one-hand-plus-shield weapon topologies;
- shoulders both visible and hidden;
- at least one locked support piece;
- clean and repaired Phase D outcomes.

The batch does not need to be artificially balanced if normal play naturally produces enough variety.

## User action during the batch

Keep **Verbose diagnostics** enabled.

Generate and reroll Traveler outfits normally.

Capture an outfit screenshot when:

- the overall look appears visually wrong;
- a selected piece appears to have the wrong color family;
- an item appears weathered, plain, polished, ornate, military, primal, or magical in a way the report does not reflect;
- two pieces visibly share an accent but the report shows little or zero echo;
- Phase D repeatedly repairs the same appearance or visual family;
- a piece repeatedly looks like the single shouting outlier.

At the end of the batch, use the tuning export once and return:

1. the compact tuning-audit Markdown;
2. the suspicious outfit screenshots;
3. the corresponding full Debug reports when available.

No screenshot is required for an obviously correct appearance.

---

# Local tuning-audit system

## Purpose

Normal v1.9.0.14 Debug reports already approach the 20 KB persistence ceiling.

Phase E must therefore use a separate compact aggregate rather than adding large descriptor maps to every generation report.

The audit is:

- local only;
- opt-in through the Traveler tuning command;
- not sent anywhere automatically;
- not included in Courier export;
- bounded in size;
- removable with one clear command.

## Commands

Add:

```text
/qc traveler tuning start
/qc traveler tuning status
/qc traveler tuning export
/qc traveler tuning stop
/qc traveler tuning clear
```

### `start`

Begins or resumes the local batch.

### `status`

Reports:

- actions observed;
- unique visual identities;
- repaired appearances;
- zero-echo suspects;
- palette-overflow suspects;
- repeat-offender candidates;
- current storage size.

### `export`

Creates a copyable Markdown tuning report without attaching it to normal immutable generation history.

Use the existing copy-dialog behavior so the user can copy the complete export from the Debug Workbench.

### `stop`

Stops collecting new observations while preserving the batch.

### `clear`

Requires confirmation and removes the local tuning audit.

## Storage

Use an additive SavedVariables field with its own internal format:

```text
travelerTuningAuditFormat = 1
```

Do not change the main SavedVariables schema.

Store aggregate observations by stable visual identity.

Recommended limits:

```text
Maximum visual identities: 300
Maximum sample report IDs per identity: 3
Maximum sampled contexts per identity: 3
Maximum exported suspects: 50
```

When the audit reaches its cap, retain the highest-priority suspects and most recently observed ordinary entries.

---

# Stable appearance identity

## Primary key

Palette, finish, and echo are properties of the visible appearance.

Use this identity order:

```text
visualID
sourceID
itemID
```

The audit groups equivalent sources under `visualID` whenever available.

It still records the source IDs, item IDs, names, and slots seen for that visual.

## Override precedence

Curated corrections apply from broad visual identity to exact source refinement:

```text
visualID override
itemID refinement
sourceID refinement
```

The most specific matching field wins.

Do not use normalized appearance names as runtime override keys.

Name matches are allowed only in human-readable documentation and test descriptions.

---

# Audit record

Each visual identity records compact aggregate data:

```text
visualID
sourceIDs
itemIDs
observed names
observed slots
selected count
anchor count
support count
repair-target count
replacement count
palette-overflow-target count
zero-echo count
severe-outlier count
maximum observed severity
maximum observed mismatch
dominant palette counts
dominant finish counts
descriptor confidence ranges
top echo families requested
top contexts
sample report IDs
```

It also records whether a curated override already exists.

No complete candidate pools, beam nodes, screenshots, or full Debug reports are stored in the audit.

---

# Suspect classification

## Palette suspect

Flag a visual for review when any of the following occurs:

- the user marks its dominant palette as visibly wrong;
- a clearly visible secondary color is absent from both its palette and echo tags;
- the same visual receives conflicting dominant palettes through different sources;
- it repeatedly becomes the unique contributor to a four-family overflow;
- its palette confidence is zero or highly ambiguous and it occupies a prominent slot;
- a Phase D repair replaces it for palette overflow in at least two actions.

Palette-overflow frequency alone does not prove the palette tag is incorrect.

## Finish suspect

Flag a visual when:

- the user marks the finish as visibly wrong;
- different sources of the same visual receive conflicting dominant finishes;
- lexicon evidence produces a finish that contradicts the visible surface;
- the top two finish families are nearly tied and the piece repeatedly influences profile or repair behavior;
- the appearance is repeatedly treated as a finish conflict across different anchor profiles.

A visually correct ornate or magical piece remains correctly classified even when Traveler rejects it in a weathered outfit.

## Missing accent-echo suspect

Flag a relationship when:

- one piece is reported as a loud zero-echo accent;
- another visible piece clearly repeats the same accent color;
- the supporting appearance's descriptor lacks that secondary accent;
- the relationship appears in more than one action or is clearly visible in a screenshot.

The audit records both:

```text
accent owner
potential echo provider
missing palette family
```

## Repeat offender

A visual becomes a repeat-offender candidate when it meets one of these review thresholds:

```text
repair target in at least 2 actions
palette-overflow target in at least 2 actions
zero-echo offender in at least 2 actions
worst unlocked support outlier in at least 2 distinct contexts
selected at least 3 times and repaired away at least twice
```

Equivalent source IDs sharing a visualID count together.

Repeat-offender status only raises the item in the review queue.

---

# Human review ledger

Create:

```text
docs/tuning/V19015_TRAVELER_TUNING_LEDGER.md
```

Each reviewed entry contains:

```text
Stable visual key
Appearance name
Slots observed
Issue category
Current palette vector
Current finish vector
Current echo tags
Observed visual verdict
Approved correction
Evidence count
Screenshot or report references
Override scope
Review status
```

Review states:

```text
UNREVIEWED
CONFIRMED_CORRECT
PALETTE_CORRECTION
FINISH_CORRECTION
ECHO_CORRECTION
MULTI_FIELD_CORRECTION
INSUFFICIENT_EVIDENCE
DEFERRED
```

Every shipped override must have a ledger entry.

---

# Curated override architecture

## New runtime module

Add:

```text
Core/ZoneStyle/Traveler/CuratedOverrides.lua
```

The module contains only exact reviewed corrections.

Suggested structure:

```lua
T.CURATED_TUNING_VERSION = 1

T.CURATED_DESCRIPTOR_OVERRIDES = {
    visual = {
        [visualID] = {
            palette = {
                steel = 0.70,
                earth = 0.30,
            },
            finish = {
                weathered = 1.00,
            },
            echoAdd = {
                red = 0.30,
            },
            loudnessDelta = -0.05,
            visualWeightDelta = 0.00,
            label = "reviewed visual correction",
        },
    },
    item = {},
    source = {},
}
```

Only fields supported by evidence should be present.

## Allowed override fields

### `palette`

An explicit normalized palette vector.

This replaces the lexicon-derived palette for the matching identity.

### `finish`

An explicit normalized finish vector.

This replaces the lexicon-derived finish for the matching identity.

### `echoAdd`

Secondary accent families used only when an appearance supplies echo to another piece.

These tags do not:

- change the dominant palette;
- add a palette family to Phase D's family count;
- move the anchor-profile palette center;
- alter palette cohesion directly.

### `loudnessDelta`

Optional bounded correction for an appearance whose visual impact is consistently over- or understated by name metadata.

Allowed range:

```text
-0.25 through +0.25
```

### `visualWeightDelta`

Optional bounded correction when the visible silhouette is materially lighter or heavier than slot and material inference indicate.

Allowed range:

```text
-0.50 through +0.50
```

## Fields not allowed

Do not support:

```text
forcedMismatchClass
forcedPhaseDStatus
forcedSelection
forcedRepairTarget
forcedCohesion
arbitraryTravelerScore
```

---

# Descriptor application order

The descriptor pipeline becomes:

```text
Load normalized source metadata
Apply the existing palette, material, finish, motif, and loudness lexicons
Infer material from subtype
Apply broad visualID curated correction
Apply itemID refinement
Apply sourceID refinement
Normalize palette, material, finish, and motif maps
Calculate dominant families and confidence
Create default echo palette from the final palette vector
Apply curated echo-only additions
Apply bounded loudness and visual-weight corrections
Cache the completed descriptor
```

Curated replacements receive high confidence:

```text
Palette correction confidence: 0.95
Finish correction confidence: 0.95
```

The descriptor evidence includes one compact marker:

```text
curated Traveler override
```

---

# Secondary accent-echo channel

## Problem

The current echo calculation consumes the descriptor palette map.

Adding a small secondary accent directly to that map can accidentally:

- change the dominant palette;
- create an extra Phase D palette family;
- move the profile center;
- change pair-cohesion scoring.

That is too blunt for a small trim color, gem, glow, or border that should only echo another accent.

## Solution

Add:

```text
descriptor.echoPalette
```

Default behavior:

```text
echoPalette = palette
```

Therefore, every unmodified appearance behaves exactly as it did in v1.9.0.14.

Curated `echoAdd` entries extend `echoPalette` only.

`GetTravelerEchoSupport` reads:

```text
other.descriptor.echoPalette or other.descriptor.palette
```

Phase D palette-family counting continues to use:

```text
dominantPalette
```

Pair and profile palette cohesion continue to use:

```text
palette
```

This lets a mostly steel appearance visibly echo a red trim without becoming a red palette-family member.

---

# Global lexicon changes

Exact visual overrides are the default.

A global palette or finish token may be changed only when:

- at least three distinct reviewed visuals demonstrate the same semantic error;
- the visuals span at least two slots or item families;
- the correction is valid for the token itself rather than only one model;
- automated tests cover both corrected and unaffected uses.

A single misleading item name must not rewrite the global lexicon.

Global relationship matrices remain frozen in v1.9.0.15.

---

# Repeat-offender resolution

For each confirmed repeat offender, use this order:

1. Correct an incorrect palette vector.
2. Correct an incorrect finish vector.
3. Add a missing secondary echo.
4. Correct loudness or visual weight when visibly justified.
5. Confirm that the item is actually a legitimate outlier and leave Phase D to repair it.

A repeat offender with correct descriptors does not receive a suppression override.

Phase E must not hide legitimate Traveler disagreement merely because the same dramatic appearance is often selected by Phase C and repaired by Phase D.

---

# Diagnostics

## Normal generation reports

Do not add full descriptor maps to every report.

For an appearance with a curated correction, add one compact marker:

```text
Curated tags: palette
Curated tags: finish
Curated tags: echo
Curated tags: palette, finish, echo
```

Keep the normal report under the existing persistence compaction system.

## `/qc traveler debug`

Expand the manual debug output for affected appearances:

```text
Palette: steel 70%, earth 30% • curated
Finish: weathered 100% • curated
Echo-only accents: red 30%
Override key: visualID 12345
```

## Tuning export

The compact Markdown export contains four sections:

```text
Palette suspects
Finish suspects
Missing echo suspects
Repeat offenders
```

Each entry includes stable IDs, counts, current tags, confidence, Phase D behavior, and sample report IDs.

---

# Cache and version behavior

Add:

```text
T.CURATED_TUNING_VERSION
```

Include it in the Traveler descriptor fingerprint.

This guarantees descriptors rebuild when curated data changes.

Retain:

```text
SavedVariables schema: 2
Courier format: 1
Wardrobe cache format: 7
Generation cache: 2
Diagnostic format: 1
Weapon-index format: 1
```

No cache reset is required.

The local tuning audit has its own format and can be cleared independently.

---

# Runtime module plan

## New modules

```text
Core/ZoneStyle/Traveler/CuratedOverrides.lua
Core/ZoneStyle/Traveler/TuningAudit.lua
Core/ZoneStyle/Traveler/TuningExport.lua
```

If copy-dialog support requires a UI helper:

```text
UI/TravelerTuningExport.lua
```

## Existing modules expected to change

```text
Core/ZoneStyle/Traveler/StyleLexicon.lua
Core/ZoneStyle/Traveler/Descriptors.lua
Core/ZoneStyle/Traveler/Cohesion.lua
Core/ZoneStyle/Traveler/Debug.lua
Core/Wardrobe/SupportFinalValidation.lua
Core/Diagnostics/SupportSnapshot.lua
Core/Diagnostics/SupportReportFormatter.lua
Core/Chronicle/Commands.lua
QuestChronicle.toc
README.md
RELEASE_NOTES.md
docs/ARCHITECTURE.md
docs/CHANGELOG.md
```

All runtime Lua files must remain under 500 physical lines.

---

# Automated test plan

## Observation-build parity

With tuning audit enabled but no overrides:

- every deterministic v1.9.0.14 selected source remains identical;
- every score remains identical;
- every Phase D result remains identical;
- random consumption remains identical;
- scheduler counters remain identical;
- audit collection does not change report snapshots;
- normal generation reports do not grow materially.

## Audit aggregation

Verify:

- visualID grouping;
- sourceID and itemID fallback;
- equivalent sources aggregate together;
- counts increment exactly once per completed action;
- cancelled or failed actions do not create selected observations;
- repaired-out and repaired-in appearances are recorded correctly;
- report IDs and contexts obey their caps;
- the 300-identity limit prunes deterministically;
- clear and restart behavior works;
- the export order is deterministic.

## Override precedence

Verify:

```text
visualID correction applies
itemID refinement overrides matching visual fields
sourceID refinement overrides matching item and visual fields
unmatched appearances remain unchanged
```

## Palette correction

Verify:

- replacement vectors normalize;
- dominant palette changes as expected;
- confidence becomes 0.95;
- unrelated material, finish, motif, weight, and loudness remain unchanged;
- Phase D family counting uses the corrected dominant palette.

## Finish correction

Verify:

- replacement vectors normalize;
- dominant finish changes as expected;
- confidence becomes 0.95;
- unrelated fields remain unchanged.

## Echo-only correction

Verify:

- default `echoPalette` is behavior-identical to v1.9.0.14;
- `echoAdd` increases echo support;
- dominant palette remains unchanged;
- palette-family count remains unchanged;
- pair palette cohesion remains unchanged;
- profile palette center remains unchanged;
- a previously false zero-echo accent becomes supported when evidence justifies it.

## Bounded adjustments

Verify:

- loudness deltas clamp to the allowed range;
- visual-weight deltas clamp to the allowed range;
- invalid override values fail static verification.

## Descriptor fingerprint

Verify that changing `CURATED_TUNING_VERSION` rebuilds cached descriptors.

## Repeat-offender rules

Verify exact boundary behavior:

```text
1 repair target: not repeat offender
2 repair targets: repeat-offender candidate
3 selections and 1 repair: not repeat offender
3 selections and 2 repairs: repeat-offender candidate
```

## Scoped selection changes

For fixtures containing an approved override:

- changed selections and Phase D decisions must be traceable to corrected descriptor inputs;
- no formula or threshold changes may appear.

For fixtures containing no approved override:

- outputs remain byte-identical to v1.9.0.14, excluding additive audit counters.

## Report size

Verify:

- normal reports remain within the compaction system;
- tuning audit data is not copied into normal snapshots;
- tuning export remains bounded;
- diagnostic history remains visible and copyable.

## Performance

Verify:

```text
Descriptor override lookup is O(1)
No wardrobe scan is added
No eligibility work is repeated
No weapon-index work is added
No new cooperative phase is required
No individual tuning call reaches 8 ms
0 post-expensive continuations
```

## Release hygiene

Verify:

- every Lua file parses;
- every runtime module appears exactly once in the TOC;
- every runtime Lua file remains under 500 lines;
- no orphaned helper references;
- version strings agree;
- JSON remains valid;
- ZIP extracts cleanly.

---

# Batch review workflow

## Step 1: Observation build

Install v1.9.0.15a1.

Run:

```text
/qc traveler tuning start
```

Generate and reroll naturally until the batch reaches at least 20 completed Traveler actions.

## Step 2: Export

Run:

```text
/qc traveler tuning stop
/qc traveler tuning export
```

Return the Markdown export with suspicious screenshots and matching Debug reports.

## Step 3: Curated review

Classify every high-priority suspect in the tuning ledger.

No correction is added without a visual verdict.

## Step 4: Correction build

Build v1.9.0.15a2 with only approved exact corrections.

## Step 5: Focused validation batch

Generate at least 10 additional Traveler outfits.

Confirm:

- corrected appearances now carry the intended tags;
- approved accent echoes are recognized;
- false palette-overflow repairs disappear;
- legitimate palette-overflow repairs still occur;
- correct dramatic outliers are still repairable by Phase D;
- no unrelated appearance behavior changes.

---

# Retail validation

## Audit system

Confirm:

```text
start
status
stop
export
clear
```

all work without altering generated outfits.

## Corrected palette appearance

For each approved palette override:

- inspect the selected appearance;
- run `/qc traveler debug`;
- confirm the corrected palette and curated marker;
- confirm unrelated descriptor fields are unchanged.

## Corrected finish appearance

For each approved finish override:

- confirm the new dominant finish;
- confirm the visible result matches the screenshot verdict;
- confirm no unrelated field changes.

## Missing echo correction

Create or load an outfit containing the accent owner and echo provider.

Confirm:

- the owner no longer reports false zero echo;
- the provider's dominant palette remains unchanged;
- Phase D palette-family count does not increase solely because of the echo tag.

## Repeat offender

Confirm each overridden repeat offender either:

- stops causing the false repair behavior; or
- remains a legitimate outlier with accurate descriptors and is still handled by Phase D.

## Clean-path safety

Generate ordinary outfits containing no curated appearances.

Confirm:

```text
No visible behavior drift
Fallback: None
No duplicate or malformed reports
0 post-expensive continuations
No new repeatable worker-slice regression
```

---

# Acceptance criteria

v1.9.0.15 becomes a release candidate only when:

1. The observation build is behavior-identical to v1.9.0.14.
2. At least 20 completed Traveler actions are audited.
3. Every shipped correction has screenshot-backed human review.
4. Every shipped correction has a tuning-ledger entry.
5. Runtime overrides use stable IDs, never names.
6. Exact visual overrides are preferred over broad lexicon changes.
7. Every global lexicon change has evidence from at least three distinct visuals across two families or slots.
8. Palette corrections do not silently alter finish, motif, material, loudness, or weight.
9. Finish corrections do not silently alter palette or echo.
10. Echo-only tags do not change dominant palette, palette-family count, profile center, or pair palette cohesion.
11. No direct mismatch, score, selection, or Phase D status override exists.
12. Unaffected deterministic fixtures remain byte-identical to v1.9.0.14.
13. Affected behavior changes are traceable to approved descriptor corrections.
14. The tuning audit remains bounded and local.
15. Normal Debug reports remain visible and copyable.
16. No cache, route, scheduler, schema, or Courier regression appears.
17. The focused Retail validation batch confirms corrected behavior.
18. No new repeatable performance regression appears.

---

# Release outcome

Phase E is complete when Quest Chronicle has:

- a reviewed first curated Traveler override set;
- accurate tags for every confirmed palette and finish error in the batch;
- exact secondary echo tags for every confirmed missing accent relationship;
- documented resolution for every repeat offender;
- a reusable local audit workflow for future tuning;
- no change to the core Traveler scoring and repair machinery.

Phase E does not promise that every appearance in World of Warcraft has been hand-tagged.

It establishes a trustworthy, repeatable path for correcting the appearances that live play proves are wrong.

---

# Planned commit message

```text
fix: Update Quest Chronicle to v1.9.0.15

Correct curated Traveler palette and finish descriptors from live outfit evidence
Add exact secondary accent-echo tags without changing dominant palette families
Apply versioned visual overrides to confirmed repeat-offender appearances
Add a bounded local tuning audit and copyable review export
Preserve Phase D thresholds, scoring, repairs, routes, scheduler behavior, and cache formats
```
