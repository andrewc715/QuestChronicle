# Quest Chronicle v1.11.2 Architecture & Development Plan

## Zone Debug Export Fidelity and Coverage-Aware Affinity Semantics

## Release purpose

Quest Chronicle v1.11.2 is a narrow corrective release for the Zone context-and-evidence foundation introduced in v1.11.0 and made copy-ready in v1.11.1.

The first Retail `/qc zone debug export` successfully proved the major architecture:

- Quest Chronicle reported version `1.11.1`;
- Traveler reported `SHARED_FRAMEWORK`;
- Zone Native reported `LEGACY` with foundation `CONTEXT_EVIDENCE_V1`;
- Class Fantasy and Chronicle Echo reported `LEGACY`;
- all 25 Zone style profiles, 134 provenance pools, and 30 starting-zone cases were available;
- the Netherstorm context resolved exactly to the Outland style profile, Through TBC era ceiling, and Netherstorm provenance;
- compatibility parity reported `PASS`;
- the immutable snapshot contained 12 evidence entries and 0 warnings;
- the current-look affinity analyzer completed observationally without changing the outfit.

The same export exposed two diagnostic-correctness defects:

1. Descriptor and evidence values containing WoW formatting-control sequences were corrupted while passing through the copy EditBox.
2. Canonical channels marked `NOT_APPLICABLE` were rendered as `MISSING` in per-piece affinity diagnostics.

v1.11.2 corrects those defects without changing Zone selection behavior, Zone context resolution, registry data, affinity scores, generation random order, or any shared-framework mechanics.

```text
v1.11.0  Zone context and evidence foundation
v1.11.1  Copy-ready Zone debug export
v1.11.2  Export fidelity and affinity applicability correction
```

The release succeeds only when the pasted external export is lossless and readable, `NOT_APPLICABLE` channels are represented honestly, all v1.11.1 numeric affinity results remain unchanged, and Zone Native remains selection-neutral behind its legacy adapter.

---

# Starting point

Create v1.11.2 directly from the final Quest Chronicle v1.11.1 package.

Required baseline:

```text
Quest Chronicle v1.11.1
SHA-256:
e730107ff53e81aceab876fe054796ca9dc62df5134ca086ea492647e5a03413
```

v1.11.1 remains authoritative for:

- the `/qc zone debug export` command;
- Zone Context Snapshot format 1;
- Zone foundation identity `CONTEXT_EVIDENCE_V1`;
- profile, provenance, starting-zone, and era registries;
- evidence ancestry;
- compatibility compilation;
- selected-look affinity formulas and weights;
- selection-neutral operation;
- the reusable Debug Workbench copy dialog;
- all v1.10.0 Traveler shared-framework behavior;
- all legacy Zone, Class, and Echo generation behavior.

v1.11.2 must not be reconstructed from v1.11.0 or an earlier development tree.

---

# Retail evidence that defines the release

## Confirmed healthy behavior

The first copied export resolved:

```text
Location:       Netherstorm / Ethereum Staging Grounds
Map:            109 • Netherstorm
Style profile:  Outland • EXACT_ZONE • confidence 0.900
Era:            Through TBC • MAP_TRAIL • confidence 0.800
Provenance:     Netherstorm • EXACT_ZONE • confidence 0.900
Fallback:       NO
Evidence:       12 entries • 0 warnings
Compatibility:  PASS
```

The canonical style snapshot correctly marked:

```text
avoids: NOT_APPLICABLE
```

The current-look affinity fixture reported:

```text
Selected pieces: 12
Mean affinity:    0.291
Mean confidence:  0.536
Classifications:  OFF_ZONE_SIGNAL 5
                  PARTIAL_EVIDENCE 2
                  WEAK_LOCAL_SIGNAL 5
```

Those numerical values and classifications become v1.11.2 parity fixtures.

## Defect A: copy transport corrupts diagnostic values

Examples from the external paste include:

```text
Expected: HEAD|Templar Crown...
Pasted:   HEADemplar crown...

Expected: BACK|Royal Cloak...
Pasted:   BACKoyal cloak...

Expected: CHEST|Replica Lightforge...
Pasted:   CHESTeplica lightforge...

Expected: FEET|Heavy Lamellar Boots...
Pasted:   FEETeavy lamellar boots...
```

The missing characters align with WoW text-format control prefixes such as:

```text
|T  texture markup
|H  hyperlink markup
|R  reset markup
```

Markdown escaping such as `\|` does not protect an EditBox from WoW's text parser because the raw pipe remains present.

The working diagnosis is therefore:

```text
The export model is complete before presentation.
Corruption occurs at the WoW text-transport boundary.
```

Retail clipboard behavior is the final authority for this diagnosis.

## Defect B: not-applicable evidence is mislabeled as missing

The snapshot correctly records `avoids = NOT_APPLICABLE`, but each per-piece affinity result currently includes `avoids` in `missingChannels` and prints:

```text
avoids: MISSING
```

That is semantically wrong.

The current calculation already excludes a nil avoidance component from score and confidence denominators, so the observed Netherstorm scores are not expected to change. The defect is in status classification and reporting, not the v1.11.1 arithmetic.

## Explicitly not defects

The following observations do not expand v1.11.2 scope:

- the nine profile-alias collisions are known registry overlaps and remain diagnostic information;
- `No Zone Native generation report is currently available` is valid when Debug History contains no retained Zone Native report;
- a low affinity score for an Imperial or Templar outfit in Netherstorm is plausible observational output;
- Zone Native remains `LEGACY` by design during this foundation stage.

---

# Versioning and format strategy

The project continues to use clean numeric versions only.

```text
v1.11.2
```

No alpha, beta, release-candidate, or letter suffix is permitted.

## Format versions

v1.11.2 retains:

```text
SavedVariables schema:           2
Courier format:                  1
Wardrobe cache format:           7
Diagnostic format:               1
Zone Context Snapshot format:    1
Zone foundation:                 CONTEXT_EVIDENCE_V1
Profile registry:                1
Provenance registry:             1
Starting-zone registry:          1
Era rules:                       1
```

v1.11.2 increments:

```text
Zone affinity format:            1 → 2
Zone debug export format:        1 → 2
```

The affinity format changes because it gains explicit component applicability states.

The export format changes because dynamic values gain a documented copy-safe encoding contract and affinity status output changes.

No SavedVariables migration is required.

Existing format-1 diagnostic reports remain readable through display-time compatibility handling. They are not rewritten in place.

---

# Core architectural rules

## Rule 1: logical data and UI transport are separate

```text
Logical export model:
The diagnostic information Quest Chronicle intends to export

Transport-safe serialization:
The representation that can survive WoW's EditBox and clipboard intact
```

The exporter must not rely on Markdown backslashes to protect WoW control tokens.

The reusable copy dialog remains a presentation surface. It must not become the owner of Zone-specific escaping rules.

## Rule 2: dynamic values must never contain unsafe raw WoW control sequences

Markdown table delimiters may remain literal pipes because they are generated structure.

Arbitrary dynamic values must use one documented reversible encoding before entering the copy EditBox.

The planned encoding is:

```text
Zone diagnostic value encoding: DIAGNOSTIC_ESCAPE_V1

literal backslash  → \\
literal pipe       → \u007C
literal backtick   → \u0060
carriage return    → \r
line feed          → \n
```

This avoids all raw `|T`, `|H`, `|c`, `|r`, and related WoW control-token sequences inside diagnostic values while preserving a lossless, machine-readable representation.

The export must declare the encoding near its header.

Example:

```text
Descriptor: 3153\u007C3795\u007C10168\u007CTemplar Crown...
```

The external pasted text need not reproduce a literal pipe byte inside dynamic values. It must preserve every character through the documented reversible representation.

## Rule 3: applicability is tri-state

Every affinity component has one explicit status:

```text
VALUE
MISSING
NOT_APPLICABLE
```

Definitions:

```text
VALUE:
The channel applies and a numeric component was calculated.

MISSING:
The channel applies, but required Zone or descriptor evidence is unavailable.

NOT_APPLICABLE:
The Zone profile explicitly declares that the channel does not apply.
```

`NOT_APPLICABLE` is neither positive evidence nor missing evidence.

It contributes:

```text
0 score weight
0 confidence weight
0 missing-channel warnings
```

## Rule 4: numeric affinity parity is frozen

v1.11.2 may change labels and schema fields, but it must not change the existing v1.11.1 affinity arithmetic.

For the Netherstorm fixture:

```text
Mean affinity:    0.291
Mean confidence:  0.536
Classification totals unchanged
Per-piece scores unchanged
Per-piece confidence unchanged
```

Comparisons should use exact deterministic equality where possible and a strict floating-point tolerance where serialization introduces representation differences.

## Rule 5: selection neutrality remains absolute

The correction path may not:

- enumerate generation candidates;
- call legacy Zone scoring or selection;
- consume random values;
- generate or reroll an outfit;
- change the current preview;
- change locks or hidden slots;
- consume a Zone suggestion;
- write SavedVariables;
- alter Courier output;
- reset or invalidate caches;
- promote Zone Native to `SHARED_FRAMEWORK`.

## Rule 6: format-1 reports remain readable

A retained v1.11.0 or v1.11.1 report may contain:

```text
components
missingChannels
```

without:

```text
componentStatus
notApplicableChannels
```

The v1.11.2 display and export path must normalize old report data at read time rather than failing, mutating, or discarding it.

---

# Target architecture

```text
Immutable Zone Context Snapshot v1
        │
        ├── canonical coverage states
        │       KNOWN / PARTIAL / UNKNOWN / NOT_APPLICABLE
        │
        v
Coverage-Aware Zone Affinity v2
        │
        ├── numeric components
        ├── componentStatus
        ├── missingChannels
        └── notApplicableChannels
                │
                v
Zone Debug Export Model
        │
        v
Diagnostic Escape Serializer
        │
        ├── Markdown structure remains readable
        ├── dynamic values become transport-safe
        └── unsafe WoW tokens are impossible
                │
                v
Existing Debug Workbench Copy Dialog
                │
                v
External clipboard paste
```

The selection and generation path remains outside this correction pipeline.

---

# Zone affinity format 2

## Required per-piece shape

The v2 result should preserve all v1 fields and add explicit applicability metadata.

Suggested shape:

```lua
{
    format = 2,
    score = 0.0,
    confidence = 0.0,
    classification = "OFF_ZONE_SIGNAL",

    components = {
        palette = 0.6,
        material = 0.6,
        finish = nil,
        motif = 0.0,
        culture = 0.0,
        magic = 0.0,
        avoids = nil,
        provenance = nil,
    },

    componentStatus = {
        palette = "VALUE",
        material = "VALUE",
        finish = "MISSING",
        motif = "VALUE",
        culture = "VALUE",
        magic = "VALUE",
        avoids = "NOT_APPLICABLE",
        provenance = "MISSING",
    },

    missingChannels = {
        "finish",
        "provenance",
    },

    notApplicableChannels = {
        "avoids",
    },

    evidence = {},
    descriptorFingerprint = "",
    profileKey = "",
    provenanceKey = "",
    sourceID = 0,
    visualID = 0,
    slotKey = "",
}
```

The exact field order is not significant in Lua, but diagnostic serialization must use stable component ordering.

## Coverage-aware resolution

For canonical style-backed components:

```text
palette
material
finish
motif
culture
magic
avoids
```

resolve status using the snapshot's coverage map first.

### Coverage is NOT_APPLICABLE

```text
status = NOT_APPLICABLE
value = nil
exclude from score denominator
exclude from confidence denominator
exclude from missingChannels
include in notApplicableChannels
```

### Coverage is KNOWN or PARTIAL

Attempt the existing v1 component calculation.

If a numeric value is produced:

```text
status = VALUE
```

If required descriptor evidence is absent:

```text
status = MISSING
```

### Coverage is UNKNOWN or absent

```text
status = MISSING
```

## Provenance applicability

Provenance is not a canonical style channel and remains governed by source-origin evidence.

```text
Exact or conflicting origin known: VALUE
No usable origin evidence:         MISSING
No resolved Zone provenance:       NOT_APPLICABLE only when the snapshot explicitly says provenance does not apply
```

An unresolved provenance pool should normally remain `MISSING`, not automatically become `NOT_APPLICABLE`.

## Avoidance behavior

When a profile has `avoids = NOT_APPLICABLE`:

```text
componentStatus.avoids = NOT_APPLICABLE
```

When avoidance rules are known and no conflict is found, preserve the v1 behavior:

```text
avoids component = 1.0
status = VALUE
```

When a known avoidance token is present, preserve the v1 conflict calculation.

---

# Debug export format 2

## Header additions

The export must include:

```text
Zone debug export format: 2
Zone affinity format: 2
Dynamic value encoding: DIAGNOSTIC_ESCAPE_V1
Literal pipe representation: \u007C
```

## Serializer responsibilities

Create one small serializer responsible for dynamic diagnostic values.

Suggested API:

```lua
EscapeDiagnosticValue(value)
MarkdownCell(value)
MarkdownCode(value)
ContainsUnsafeWoWControl(value)
```

The serializer owns:

- newline normalization;
- backslash preservation;
- pipe encoding;
- backtick encoding;
- safe insertion into Markdown tables;
- safe insertion into inline code spans;
- deterministic output.

It must not:

- read the current outfit;
- build Zone context;
- evaluate affinity;
- open UI;
- consume random values.

## Table structure

The current-look summary should distinguish missing and not-applicable channels.

Suggested columns:

```text
Slot
Appearance
Source ID
Visual ID
Classification
Score
Confidence
Missing channels
N/A channels
```

## Per-piece structure

Each component prints one of:

```text
palette: 0.600
finish: MISSING
avoids: NOT_APPLICABLE
```

Descriptor fingerprints and evidence values use `DIAGNOSTIC_ESCAPE_V1`.

## Unsafe-token gate

After serialization, no dynamic value may contain an unencoded WoW control prefix.

The verifier should cover at least:

```text
|T  |t
|A  |a
|H  |h
|c  |r
|K  |k
```

Markdown table delimiters are exempt because they are formatter-owned structure, not arbitrary values.

---

# Runtime module plan

## New module

Suggested:

```text
Core/ZoneStyle/Zone/ExportEncoding.lua
```

Responsibilities:

- `DIAGNOSTIC_ESCAPE_V1` implementation;
- stable Markdown value escaping;
- unsafe-token detection used by tests and development assertions;
- no UI or generation dependencies.

## Existing modules to update

```text
Core/ZoneStyle/Zone/Foundation.lua
```

- bump `Zone.AFFINITY_FORMAT` from 1 to 2;
- define or expose component-status constants.

```text
Core/ZoneStyle/Zone/Affinity.lua
```

- add coverage-aware component applicability;
- emit `componentStatus`;
- emit `notApplicableChannels`;
- preserve all v1 numeric calculations.

```text
Core/ZoneStyle/Zone/DebugExport.lua
```

- bump `Zone.DEBUG_EXPORT_FORMAT` from 1 to 2;
- use the dedicated serializer for every dynamic value;
- declare the export encoding;
- print missing and N/A channels separately;
- render component statuses correctly;
- preserve complete evidence ancestry.

```text
Core/Diagnostics/SnapshotBuilder.lua
```

- persist additive affinity-v2 status fields in new Zone reports;
- continue accepting old reports without those fields.

```text
Core/ZoneStyle/Zone/Debug.lua
```

- compact chat output remains compact;
- no change required unless it currently reports per-component missing channels;
- it must continue to show canonical `avoids=NOT_APPLICABLE` coverage accurately.

```text
UI/DebugReport.lua
```

- preferably unchanged;
- the generic copy dialog should continue receiving already-safe text;
- modify only if Retail proves the EditBox requires an additional generic transport step.

This keeps Zone-specific encoding out of the shared Traveler and diagnostic copy surfaces.

## Documentation and metadata

Update:

```text
VERSION.txt
QuestChronicle.toc
README.md
RELEASE_NOTES.md
docs/CHANGELOG.md
docs/ARCHITECTURE.md
docs/DIAGNOSTIC_SNAPSHOT_FORMAT.md
Zone context schema and export-format documentation
```

All runtime Lua files remain below 500 physical lines.

---

# Implementation strategy

## Step 1: freeze the Retail failure fixture

Create a deterministic export fixture containing values that previously corrupted:

```text
HEAD|Templar Crown
BACK|Royal Cloak
CHEST|Replica Lightforge Breastplate
FEET|Heavy Lamellar Boots
|Hitem:123|h[Test]|h
|Ttexture:path|t
|cffffffffColor|r
```

Record the expected `DIAGNOSTIC_ESCAPE_V1` output.

## Step 2: add the serializer

Implement dynamic-value escaping independently of the Zone exporter.

Prove:

- deterministic output;
- reversible representation;
- no unsafe control prefixes;
- Markdown table structure remains intact.

## Step 3: route Zone export dynamic values through the serializer

Replace ad hoc `Cell()` and raw code-span insertion with serializer calls.

Do not change export section order or context content except for:

- format metadata;
- safe value representation;
- N/A affinity fields.

## Step 4: add affinity applicability states

Introduce the tri-state status model and update `missingChannels` construction.

Preserve the existing score and confidence denominator behavior.

## Step 5: add format-1 read compatibility

Normalize old affinity records at display time.

Do not migrate retained reports.

## Step 6: update immutable Zone report snapshots

Include additive affinity-v2 status fields for newly generated Zone Native reports.

## Step 7: run cross-version numeric parity

Compare v1.11.2 against v1.11.1 for all deterministic affinity fixtures.

Only schema and diagnostic-text differences are allowed.

## Step 8: full automated regression

Run every inherited Lua test and Python verifier, then add the new v1.11.2 suites.

## Step 9: exact-package validation

Build `QuestChronicle-v1.11.2.zip`, extract that exact archive into a fresh directory, and rerun syntax, tests, verifiers, TOC, line-limit, and package-integrity gates.

## Step 10: Retail clipboard validation

The external pasted result is the final proof that the WoW EditBox no longer consumes diagnostic characters.

---

# Automated test plan

## Diagnostic encoding tests

Verify:

- literal pipes inside dynamic values become `\u007C`;
- backslashes and backticks remain reversible;
- CR and LF are represented safely;
- table delimiter pipes remain structural;
- dangerous fixtures do not lose characters;
- the serialized export contains no unsafe raw WoW control prefixes inside dynamic values;
- repeated exports are byte-identical except timestamp fields.

## Affinity applicability tests

Verify:

### NOT_APPLICABLE avoidance

```text
coverage.avoids = NOT_APPLICABLE
componentStatus.avoids = NOT_APPLICABLE
avoids absent from missingChannels
avoids present in notApplicableChannels
score unchanged from v1
confidence unchanged from v1
```

### Known avoidance with no conflict

```text
componentStatus.avoids = VALUE
component.avoids = 1.0
```

### Known avoidance with conflict

Require the same v1 numeric conflict result.

### Unknown avoidance evidence

```text
componentStatus.avoids = MISSING
avoids present in missingChannels
```

## Netherstorm Retail-fixture parity

Require:

```text
Selected pieces: 12
Mean affinity: 0.291
Mean confidence: 0.536
OFF_ZONE_SIGNAL: 5
PARTIAL_EVIDENCE: 2
WEAK_LOCAL_SIGNAL: 5
avoids: NOT_APPLICABLE for every piece
```

Per-piece score, confidence, and classification values must match v1.11.1.

## Format compatibility

Verify:

- format-1 affinity records remain displayable;
- missing v2 status fields do not cause Lua errors;
- no retained diagnostic report is discarded;
- new reports identify affinity format 2.

## Selection-neutrality tests

Verify the exporter and affinity analyzer:

- make zero `math.random` calls;
- do not import or call legacy Zone scoring;
- do not enumerate candidates;
- do not call generation or reroll APIs;
- do not mutate preview state;
- do not modify SavedVariables;
- do not create a report merely by exporting.

## Full inherited regression

Require every v1.11.1 test and verifier to remain green.

## Static and package hygiene

Verify:

- all TOC entries appear exactly once;
- all Lua files parse;
- no runtime Lua file reaches 500 lines;
- no circular Zone foundation dependency is introduced;
- the ZIP contains one top-level folder named exactly `QuestChronicle`;
- no letter-suffixed version appears anywhere in the package.

---

# Cross-version parity requirements

Compare v1.11.2 with v1.11.1.

## Must remain identical

```text
Zone context fingerprint
Profile identity and resolution
Era resolution
Provenance resolution
Canonical style evidence
Evidence-entry count and order
Registry counts and order
Compatibility parity
Affinity numeric components
Affinity scores
Affinity confidence
Affinity classifications
Current preview
Zone generation selections
Random consumption
Suggestions
Favorites and exclusions
Legal weapon routes
Locks and hidden state
Traveler shared-framework behavior
Class and Echo legacy behavior
```

## Allowed differences

```text
VERSION_ONLY
EXPORT_ENCODING_ONLY
AFFINITY_STATUS_ONLY
ADDITIVE_FORMAT_METADATA
DOCUMENTATION_ONLY
```

Any unexplained semantic or numeric difference blocks release.

---

# Retail live-validation plan

## Test 1: version and architecture

Confirm:

```text
Version: 1.11.2
Traveler: SHARED_FRAMEWORK
Zone Native: LEGACY
Zone foundation: CONTEXT_EVIDENCE_V1
Class Fantasy: LEGACY
Chronicle Echo: LEGACY
Zone affinity format: 2
Zone debug export format: 2
```

## Test 2: copy fidelity

In Netherstorm, run:

```text
/qc zone debug export
```

Copy with `Ctrl+C` and paste into an external plain-text destination.

Confirm:

- no characters disappear after slot names;
- descriptor fingerprints remain complete;
- dangerous values use `\u007C`;
- item-link, texture, and color-like fixtures are not interpreted by WoW;
- Markdown tables remain structurally intact;
- the complete evidence ledger remains present.

## Test 3: applicability semantics

Confirm canonical evidence still reports:

```text
avoids: NOT_APPLICABLE
```

Confirm every per-piece affinity section reports:

```text
avoids: NOT_APPLICABLE
```

Confirm `avoids` is absent from missing-channel lists and present in N/A-channel lists.

## Test 4: numeric parity

Using the same current outfit and snapshot where possible, confirm the headline affinity and per-piece numbers remain unchanged from the v1.11.1 fixture.

## Test 5: Zone Native report availability

Generate one Zone Native outfit, rerun the export, and confirm the latest Zone Native diagnostic-report section populates.

The report must remain:

```text
Generation implementation: LEGACY
Zone foundation: CONTEXT_EVIDENCE_V1
```

## Test 6: observational neutrality

Before and after exporting, confirm:

- current preview unchanged;
- no generation or reroll starts;
- no new Debug History report is created by export alone;
- locks and hidden slots unchanged;
- no suggestion consumed;
- Courier snapshot unchanged;
- no Lua errors.

## Test 7: reload compatibility

Use `/reload`, rerun the export, and confirm:

- the snapshot reconstructs cleanly;
- old format-1 reports remain viewable;
- the new export identifies affinity format 2;
- no migration or cache reset occurs.

---

# Acceptance criteria

Quest Chronicle v1.11.2 becomes release-ready only when:

1. `/qc zone debug export` produces an externally pasted document with no lost characters.
2. Dynamic values use the documented `DIAGNOSTIC_ESCAPE_V1` representation.
3. No unsafe raw WoW control prefix survives inside serialized dynamic values.
4. Zone debug export format is 2.
5. Zone affinity format is 2.
6. Every affinity component has an explicit `VALUE`, `MISSING`, or `NOT_APPLICABLE` status.
7. `NOT_APPLICABLE` channels are excluded from missing-channel lists.
8. `NOT_APPLICABLE` channels do not affect score or confidence denominators.
9. The v1.11.1 Netherstorm affinity numbers and classifications remain unchanged.
10. Format-1 retained reports remain readable without migration.
11. Zone Context Snapshot format remains 1.
12. Zone foundation remains `CONTEXT_EVIDENCE_V1`.
13. Zone Native remains `LEGACY` and selection-neutral.
14. Traveler remains `SHARED_FRAMEWORK` with no behavior change.
15. Class Fantasy and Chronicle Echo remain unchanged behind legacy adapters.
16. All inherited and new automated tests pass.
17. Every runtime Lua file remains below 500 physical lines.
18. The exact packaged ZIP passes fresh-extraction validation.
19. Retail copy/paste validation passes.
20. No Lua error, cache reset, SavedVariables migration, or Courier change appears.

---

# Explicit non-goals

v1.11.2 does not:

- change Zone profile data;
- resolve or remove profile-alias collisions;
- change provenance pools;
- change starting-zone rules;
- change era restrictions;
- change Zone affinity weights or thresholds;
- reinterpret the low Netherstorm affinity fixture;
- add curated Zone appearance corrections;
- begin Zone anchor scoring;
- move Zone Native to the shared generation framework;
- change independent legacy slot selection;
- change weapon routing;
- add Zone support search, final validation, repair, or rerolls;
- redesign the Status tab;
- change the generic Traveler tuning export unless a shared EditBox defect is independently proven;
- change SavedVariables, Courier, or cache formats.

---

# Handoff to the next Zone release

v1.11.2 closes the diagnostic-fidelity layer of the Zone crawl phase.

After v1.11.2 is live-validated, the next v1.11.x plan may begin Zone's first policy-guided selection slice.

The likely next release is:

```text
v1.11.3  First Zone anchor-policy implementation slice
```

That release should consume:

- immutable Zone Context Snapshot v1;
- complete evidence ancestry;
- canonical style channels;
- coverage-aware Zone Affinity v2;
- existing legal weapon topology;
- shared anchor orchestration.

It must not proceed until the evidence exported from v1.11.2 can be trusted character for character.

---

# Planned release artifacts

```text
QuestChronicle-v1.11.2.zip
QuestChronicle-v1.11.2-Architecture-and-Development-Plan.md
QuestChronicle-v1.11.2-Live-Validation-Steps.md
QuestChronicle-v1.11.2-Automated-Validation.md
QuestChronicle-v1.11.2-Parity-Report.md
QuestChronicle-v1.11.2-Implementation-Conformance.md
QuestChronicle-v1.11.2-Release-Notes.md
QuestChronicle-v1.11.2-Validation-Report.md
QuestChronicle-v1.11.2-Handoff-Manifest.md
QuestChronicle-v1.11.2.sha256
```

---

# Planned commit message

```text
fix: Update Quest Chronicle to v1.11.2

Preserve Zone debug values through the WoW copy surface
Add coverage-aware VALUE, MISSING, and NOT_APPLICABLE affinity states
Keep Zone affinity scores and classifications identical to v1.11.1
Retain Zone Native selection neutrality behind the legacy adapter
Prepare the Zone evidence foundation for the first anchor-policy slice
```
