# Quest Chronicle v1.11.0 Architecture & Development Plan

## Zone Context and Evidence Foundation

## Release purpose

Quest Chronicle v1.11.0 begins the Zone implementation train by giving Zone Native a formal, immutable, versioned context and evidence model.

The current Zone Native mode already contains substantial geographic knowledge:

- 25 broad visual-style profiles;
- 134 provenance and source-pool profiles;
- 30 deterministic starting-zone cases;
- expansion-era restrictions;
- quest-source and boss-drop provenance handling;
- per-zone favorites and exclusions;
- zone-change suggestions;
- legacy weighted source scoring;
- outfit-level motif accumulation;
- legal weapon generation;
- locks and hidden-slot preservation.

What it does not yet have is a stable policy-grade explanation of what the current zone is, how that identity was resolved, which evidence channels support it, how confident those channels are, and how a visual descriptor relates to the zone.

v1.11.0 creates that foundation before Zone selection behavior is changed.

```text
v1.11.0 = Zone context, evidence, profile registry, and diagnostics foundation
Later v1.11.x = Zone anchors, support, validation, rerolls, and tuning
```

The release succeeds only when the new Zone foundation is live-validated while the existing Zone Native generation results remain semantically identical to v1.10.0.

---

# Primary design decision

## v1.11.0 is evidence-first and selection-neutral

v1.11.0 does not yet replace Zone Native's legacy weighted generator.

Zone Native remains:

```text
Generation implementation: LEGACY
```

The release adds an explicit secondary identity:

```text
Zone foundation: CONTEXT_EVIDENCE_V1
```

This is deliberate.

Traveler reached its current maturity by first building calibrated visual instrumentation, then using that instrumentation to guide anchor selection, contextual support, final validation, repair, and tuning. Zone should follow the same evidence-first sequence rather than immediately converting broad keyword profiles into a new shared-framework policy and discovering afterward that the policy encoded the wrong local identity.

The v1.11.0 foundation must therefore be capable of answering these questions without changing a selection:

1. What exact location facts did WoW provide?
2. Which Zone style profile was selected?
3. Which alias, map level, or fallback resolved that profile?
4. Which expansion ceiling applies?
5. Which provenance pool applies?
6. Which cultural, environmental, material, magical, palette, finish, motif, and silhouette signals are explicitly known?
7. Which signals are absent or low-confidence?
8. How does each selected appearance relate to those signals?
9. Which result came from exact evidence, compatibility data, or fallback behavior?
10. Can the future Zone anchor policy consume the snapshot without importing legacy ZoneStyle internals?

Until those answers are stable and live-validated, Zone anchor scoring should not become authoritative.

---

# Starting point

Create v1.11.0 directly from the final live-validated Quest Chronicle v1.10.0 package.

Required baseline:

```text
Quest Chronicle v1.10.0
SHA-256:
0120a5805726c6d55629d3cc12dab84fac1159d8ab1ab495cf7c97741b888511
```

The v1.10.0 Retail validation established:

```text
Traveler        SHARED_FRAMEWORK
Zone Native     LEGACY
Class Fantasy   LEGACY
Chronicle Echo  LEGACY
```

It also live-validated:

- shared Traveler lifecycle routing;
- Generate Outfit;
- Reroll Unlocked;
- contextual support rerolls;
- legal weapon routing;
- Phase D validation and alternate-skeleton repair;
- scheduler integrity;
- weapon-index lifecycle;
- report compaction;
- curated descriptors;
- tuning audit;
- reload persistence;
- locked-slot preservation;
- all three legacy mode adapters.

v1.11.0 must not reopen the v1.10 extraction contract unless a genuine second-policy integration defect is discovered while building the Zone foundation.

---

# Versioning strategy

The Zone rewrite uses the clean numeric v1.11.x train.

```text
v1.11.0  Zone context and evidence foundation
v1.11.x  Continue until Zone is complete and live-validated
```

No alpha, beta, release-candidate, or letter-suffixed versions are used.

Intermediate development checkpoints remain unversioned internal work.

The likely Zone train is:

```text
v1.11.0  Context, evidence, profile registry, and diagnostics foundation
v1.11.x  Zone anchor policy
v1.11.x  Zone contextual support
v1.11.x  Zone final validation and repair
v1.11.x  Zone rerolls and report completion
v1.11.x  Zone tuning, curated corrections, and final promotion
```

The exact number of releases is chosen from implementation and Retail evidence. The train closes only when Zone Native is fully shared-framework-native and live-validated.

Class does not begin until the v1.11.x Zone train is formally closed.

---

# Current Zone Native architecture

## 1. Location detection

The current system reads:

```text
mapID
map name
zone
subzone
parent map trail
```

It normalizes those names and scans ordered alias lists.

## 2. Broad style profiles

The current source contains 25 broad style profiles, including:

```text
Quel'Thalas
Amani Highlands
Harandar Rootways
The Voidstorm
Hallowfall
Khaz Algar
Dragon Isles
Kaldorei Wilds
Zandalar
Kul Tiras
Pandaria
Northrend
Outland
Cataclysm Frontiers
Draenor
Broken Isles
Nazjatar
Fourth War
Shadowlands
Human Kingdoms
Orcish Frontier
Forsaken Marches
Eastern Kingdoms Frontier
Kalimdor Wilds
Azeroth Adventurer
```

Each profile currently supplies:

```text
key
label
seed
location aliases
positive source-name keywords
negative source-name keywords
description
```

## 3. Provenance profiles

The current source contains 134 provenance profiles.

These identify local source pools such as:

```text
Northshire
Dun Morogh
Teldrassil
Durotar
Netherstorm
Hallowfall
The Ringing Deeps
K'aresh
```

A provenance profile currently supplies:

```text
key
label
location aliases
source-origin vocabulary
optional expansion bounds
```

## 4. Starting-zone matrix

Thirty starting-zone cases protect racial and hero-class openings, including shared geographic pools such as:

```text
Dwarf and Gnome      Dun Morogh
Orc and Troll        Durotar
Mag'har and Vulpera  Orgrimmar
```

The matrix also protects later openings such as Mardum, Telogrus Rift, Hall of Awakening, and Harandar.

## 5. Legacy Zone scoring

The current Zone Native score begins with a stable base and adds:

- strong broad-profile keyword affinity;
- profile avoid penalties;
- a small class accent;
- a small Traveler accent;
- a small Chronicle accent;
- slot bonuses for Back and Tabard;
- current-outfit set and motif coherence;
- strong per-zone favorite bonuses;
- stable seeded affinity.

Per-zone exclusions remain hard bans.

The current generator selects armor slots independently in a fixed order, accumulating a loose outfit profile as pieces are chosen. Weapons are generated after the armor silhouette and remain governed by legal equipped topology.

## 6. Current limitations

The legacy system is useful and stable, but its context is not yet suitable as the permanent policy contract for a mature shared-framework Zone mode.

Current limitations include:

- style identity and source provenance are stored as adjacent loose fields rather than one immutable snapshot;
- resolution ancestry is not preserved;
- confidence is not represented;
- broad profile aliases, provenance aliases, era aliases, and fallback behavior are not explained in one place;
- current broad profile scoring depends heavily on item and source names;
- the shared descriptor language is not yet used to explain Zone affinity;
- there is no explicit distinction between native culture, secondary local culture, hostile occupation, climate, terrain, magic, and material craft;
- missing evidence is often indistinguishable from neutral evidence;
- diagnostics cannot show why one profile or provenance pool won over another;
- future Zone policy callbacks would need to import legacy ZoneStyle internals directly.

v1.11.0 resolves those architectural limitations without changing generation outcomes.

---

# Core architectural rules

## Rule 1: facts, evidence, and preference are separate

```text
Location fact:
What WoW reports

Zone evidence:
What those facts imply about the place

Mode preference:
Why a candidate should be selected
```

The context resolver may identify a zone. It must not score an appearance.

The evidence model may describe the zone. It must not select an appearance.

The future Zone policy may consume both. It must not rewrite the facts.

## Rule 2: style identity is not source provenance

A Zone style profile describes the visual language of a place.

A provenance profile describes where an appearance source belongs geographically.

They may align, but they are not interchangeable.

Example:

```text
Style profile: Outland
Provenance pool: Netherstorm
```

The first describes a broad visual vocabulary. The second constrains local source geography.

## Rule 3: explicit evidence outranks inference

Resolution priority is:

```text
exact runtime map identity
exact subzone alias
exact zone alias
exact map-trail alias
explicit regional parent
broad continent or expansion profile
Azeroth fallback
```

A weaker inference may not overwrite stronger evidence.

## Rule 4: missing evidence remains missing

An absent palette, material, culture, or magic signal is not automatically neutral.

The snapshot records:

```text
KNOWN
PARTIAL
UNKNOWN
NOT_APPLICABLE
```

Future policy may decide how to handle missing information. The foundation does not manufacture certainty.

## Rule 5: fallback behavior is visible

Every fallback records:

```text
fallback used
fallback level
reason
source evidence considered
```

The system must never quietly claim an exact local identity when it only resolved a broad continent.

## Rule 6: v1.11.0 cannot consume random values

Context resolution, evidence construction, profile compilation, and diagnostics are deterministic and read-only.

They may not call `math.random()` or perturb generation random order.

## Rule 7: legacy selection remains authoritative in v1.11.0

The new snapshot feeds a compatibility view that reproduces the current context fields exactly.

The existing Zone Native scoring and generation path remain authoritative for this release.

---

# Target architecture

```text
World of Warcraft location APIs
│
├── mapID
├── map name
├── zone
├── subzone
└── parent map trail
        │
        v
Zone Context Resolver
        │
        ├── Zone Profile Registry
        ├── Era Resolver
        ├── Provenance Registry
        ├── Starting-Zone Rules
        └── Fallback Resolver
                │
                v
Immutable Zone Context Snapshot v1
                │
                ├── Legacy Compatibility View
                │       │
                │       v
                │   Existing Zone Native generator
                │   Generation implementation: LEGACY
                │
                ├── Zone Evidence Ledger
                │       │
                │       v
                │   /qc zone debug
                │   Debug History Zone sections
                │
                ├── Shared Visual Language
                │       │
                │       v
                │   Read-only Zone Affinity Analysis
                │
                └── Future Zone Policy Contract
                        │
                        v
                    Later v1.11.x shared-framework work
```

The v1.11.0 release boundary is the immutable snapshot, evidence ledger, compatibility view, and diagnostics.

---

# Zone Context Snapshot v1

Create one immutable context object for every resolved location.

Suggested shape:

```lua
{
    format = 1,
    registryVersion = 1,
    capturedAt = 0,

    location = {
        mapID = 0,
        mapName = "",
        zone = "",
        subzone = "",
        mapTrail = {},
        normalizedText = "",
        zoneKey = "",
        detailKey = "",
    },

    identity = {
        profileKey = "",
        label = "",
        description = "",
        resolutionLevel = "EXACT_ZONE",
        confidence = 0.0,
        evidence = {},
    },

    era = {
        maxExpansionID = 0,
        label = "",
        shortLabel = "",
        resolutionLevel = "EXACT_ZONE",
        confidence = 0.0,
        evidence = {},
    },

    provenance = {
        key = nil,
        label = nil,
        resolutionLevel = "UNRESOLVED",
        confidence = 0.0,
        evidence = {},
    },

    style = {
        culture = {},
        climate = {},
        terrain = {},
        palette = {},
        material = {},
        finish = {},
        motif = {},
        magic = {},
        silhouette = {},
        avoids = {},
        coverage = {},
    },

    restrictions = {
        eraEnabled = true,
        restrictionLabel = "",
        favoriteScopeKey = "",
        exclusionScopeKey = "",
    },

    fallback = {
        used = false,
        level = nil,
        reason = nil,
    },
}
```

The exact field names may evolve during implementation, but the responsibilities must remain explicit.

## Snapshot properties

The snapshot must be:

- immutable after construction;
- deterministic for the same location facts and registry version;
- independent of the current outfit;
- independent of candidate appearances;
- independent of random state;
- safe to attach to an immutable diagnostic report;
- serializable as primitive diagnostic data;
- independent of Lua module paths.

## Snapshot identity

The stable runtime key should include:

```text
mapID
normalized zone
normalized subzone
profile registry version
provenance registry version
era rule version
```

The snapshot may be cached for the current session.

It does not need a SavedVariables cache in v1.11.0.

---

# Zone evidence ledger

Every resolved conclusion should retain its ancestry.

Suggested evidence entry:

```lua
{
    channel = "PROFILE_ALIAS",
    subject = "outland",
    value = "Outland",
    matchedText = "netherstorm outland",
    matchedAlias = "outland",
    sourceLevel = "MAP_TRAIL",
    confidence = 0.80,
    registryKey = "outland",
}
```

Supported channels should include:

```text
MAP_ID
MAP_NAME
SUBZONE_NAME
ZONE_NAME
MAP_TRAIL
PROFILE_ALIAS
ERA_RULE
PROVENANCE_ALIAS
STARTING_ZONE_RULE
PARENT_PROFILE
REGION_FALLBACK
AZEROTH_FALLBACK
PROFILE_DEFINITION
```

Candidate-specific evidence is separate and may include:

```text
VISUAL_DESCRIPTOR
SOURCE_PROVENANCE
SOURCE_METADATA
TRANSMOG_SET
CURATED_ZONE_TAG
```

The context ledger must not contain candidate evidence.

## Initial confidence guidance

Suggested initial confidence values:

```text
Exact map identity           1.00
Exact subzone alias          0.95
Exact zone alias             0.90
Exact map-name alias         0.90
Map-trail alias              0.80
Explicit parent profile      0.70
Regional fallback            0.55
Azeroth fallback             0.25
Unresolved                   0.00
```

These values are diagnostic metadata in v1.11.0. They do not affect selection.

---

# Zone profile registry

Replace the implicit broad-profile table with one validated registry.

Suggested API:

```lua
RegisterZoneProfile(profileKey, definition)
GetZoneProfile(profileKey)
GetZoneProfiles()
ResolveZoneProfile(locationFacts)
ValidateZoneProfile(definition)
GetZoneProfileRegistryVersion()
```

## Required profile fields

```text
key
label
description
seed
location aliases
```

## Optional explicit style fields

```text
parent profile
cultures
climates
terrain
palette
materials
finishes
motifs
magic
silhouette
avoids
legacy keywords
legacy avoid keywords
```

## Compatibility fields

The existing keyword tables remain available as:

```text
legacyKeywords
legacyAvoid
```

They remain authoritative for v1.11.0 legacy scoring.

The new canonical style fields are used only for evidence and diagnostics in this release.

## Migration requirement

All 25 current broad profiles must migrate without changing:

- key;
- label;
- seed;
- alias order;
- keyword values;
- avoid values;
- description;
- profile resolution precedence.

No broad profile may disappear, merge, or change meaning during the migration.

## Profile data quality

Canonical style channels must be explicit.

The implementation may derive a suggested draft from existing keywords during development, but production profile definitions must contain reviewed values rather than runtime keyword-to-vector guessing.

A channel may remain empty when evidence is insufficient.

Empty is preferable to fabricated precision.

---

# Provenance registry

Create one validated registry for the 134 current source pools.

Suggested API:

```lua
RegisterZoneProvenance(profileKey, definition)
GetZoneProvenance(profileKey)
GetZoneProvenanceProfiles()
ResolveZoneProvenance(locationFacts, era)
ValidateZoneProvenance(definition)
GetZoneProvenanceRegistryVersion()
```

Every existing definition must preserve:

```text
key
label
location aliases
origin vocabulary
minimum expansion bound
maximum expansion bound
registration order
```

## Provenance resolution rule

Provenance remains a hard geographic eligibility input where WoW supplies reliable tracked source evidence.

The new registry must not relax the current fail-closed behavior for:

- foreign boss drops;
- foreign tracked quest rewards;
- later-expansion appearances;
- promotional rewards;
- Heritage Armor restrictions;
- known Wandering Isle false-era cases.

## Provenance and style profile relationship

The registry may declare an optional broad style-profile parent:

```lua
styleProfileKey = "outland"
```

This is descriptive only in v1.11.0.

It must not alter current resolution or selection.

---

# Starting-zone registry

The 30 starting-zone cases become validated registry fixtures rather than a loose test-oriented table.

Suggested API:

```lua
RegisterStartingZoneCase(caseID, definition)
GetStartingZoneCases()
ResolveStartingZoneOverride(locationFacts, characterFacts)
ValidateStartingZoneCase(definition)
```

The current cases must remain exact.

Shared geographic pools remain shared.

The registry must not infer race identity from visual appearance or broaden a starting-zone pool beyond its current geographic contract.

---

# Resolution pipeline

## Phase 1: capture location facts

Capture once:

```text
mapID
mapName
zone
subzone
parent map trail
```

Normalize text once.

## Phase 2: resolve exact identity

Evaluate in deterministic order:

1. starting-zone override, when applicable;
2. exact map identity, when registered;
3. subzone alias;
4. zone alias;
5. map-name alias;
6. parent map-trail alias.

## Phase 3: resolve broad fallback

If exact identity is unavailable:

1. explicit parent profile;
2. expansion or continent profile;
3. Azeroth Adventurer.

## Phase 4: resolve era

Use the existing ordered era rules and preserve their outputs exactly.

## Phase 5: resolve provenance

Use the existing ordered provenance profiles, era bounds, and exact alias behavior.

## Phase 6: construct style evidence

Attach the resolved profile's explicit style channels.

Record missing-channel coverage.

## Phase 7: build compatibility context

Compile the snapshot back into the current public context fields:

```text
mapID
mapName
zone
subzone
mapTrail
profileKey
profileLabel
profileDescription
eraMax
eraLabel
eraShortLabel
provenanceKey
provenanceLabel
provenanceResolved
```

## Phase 8: cache and publish

Cache by stable detail key and registry versions.

Publish through the existing ZoneStyle public API.

---

# Legacy compatibility view

The compatibility view is the parity firewall for v1.11.0.

The existing public methods remain valid:

```lua
ZoneStyle.DetectContext()
ZoneStyle.ResolveProfile(context)
ZoneStyle.ResolveEra(context)
ZoneStyle.ResolveProvenance(context)
ZoneStyle.GetCurrentContext()
ZoneStyle.GetCurrentProfile()
ZoneStyle.GetContextRestrictionLabel(context)
```

They may become wrappers over the new resolver, but their externally observable outputs must remain unchanged.

The following systems continue consuming the compatibility view:

- legacy Zone Native generation;
- legacy Class and Echo generation;
- source eligibility;
- per-zone favorites and exclusions;
- restriction labels;
- zone-change suggestions;
- generated names;
- concept state;
- Current Look tooltips.

## Strict parity rule

For every deterministic fixture, the v1.11.0 compatibility view must equal v1.10.0 for:

```text
profile key
profile label
profile description
era ceiling
era labels
provenance key
provenance label
restriction label
favorite scope key
exclusion scope key
suggestion detail key
```

Any difference is semantic and blocks release unless it corrects a separately approved defect.

---

# Shared visual language integration

v1.11.0 introduces read-only Zone affinity analysis using the shared visual language created in v1.10.0.

The analyzer consumes:

```text
Zone Context Snapshot
appearance descriptor
source provenance
slot definition
```

It may evaluate:

```text
palette affinity
material affinity
finish affinity
motif affinity
visual-weight affinity
silhouette affinity
cultural affinity
magic affinity
local provenance affinity
avoid conflicts
descriptor confidence
zone evidence confidence
```

## Important restriction

Zone affinity analysis is observational in v1.11.0.

It may not:

- alter candidate weights;
- filter candidates;
- reorder candidates;
- alter beam search;
- alter weapon selection;
- consume random values;
- trigger repair;
- change a preview.

## Suggested analysis result

```lua
{
    score = 0.0,
    confidence = 0.0,
    components = {
        palette = nil,
        material = nil,
        finish = nil,
        motif = nil,
        weight = nil,
        silhouette = nil,
        culture = nil,
        magic = nil,
        provenance = nil,
        avoids = nil,
    },
    evidence = {},
    missingChannels = {},
    classification = "PARTIAL_EVIDENCE",
}
```

Suggested classifications:

```text
STRONGLY_NATIVE
LOCALLY_COHERENT
SUPPORTED_LOCAL_VARIATION
WEAK_LOCAL_SIGNAL
OFF_ZONE_SIGNAL
PARTIAL_EVIDENCE
UNKNOWN
```

These labels are diagnostics only.

---

# Zone diagnostics foundation

## New command

Add:

```text
/qc zone debug
```

It should print a bounded explanation of:

```text
current location facts
resolved style profile
resolution level and confidence
matched aliases and evidence channels
expansion ceiling
provenance pool
restriction label
fallback state
profile style-channel coverage
current selected outfit's read-only Zone affinity
legacy Zone score summary, when available
```

## Debug History integration

Zone Native generation reports gain additive sections:

```text
Zone Context
Zone Resolution
Zone Evidence Coverage
Zone Affinity Summary
Zone Compatibility Status
```

Suggested headline fields:

```text
Zone foundation: CONTEXT_EVIDENCE_V1
Context format: 1
Profile registry version: 1
Provenance registry version: 1
Resolution: EXACT_ZONE
Confidence: 0.90
Compatibility parity: PASS
Generation implementation: LEGACY
```

## Report-size rule

The report stores compact summaries, not the entire raw registry or every alias considered.

Detailed evidence remains available through `/qc zone debug`.

Report compaction must preserve:

- resolved profile;
- era;
- provenance;
- fallback state;
- compatibility status;
- selected-piece affinity headline;
- warnings.

## No tuning audit yet

v1.11.0 does not add a Zone tuning audit.

The release may identify missing or contradictory profile channels, but it does not collect a persistent tuning batch or create curated overrides.

---

# Mode registry integration

Update the Zone legacy adapter to expose the new foundation without falsely claiming shared generation.

Suggested capabilities:

```lua
{
    generate = true,
    rerollUnlocked = true,
    rerollSlot = true,
    rerollSupportSlot = true,
    cancel = true,

    sharedFramework = false,
    legacy = true,

    zoneContextFormat = 1,
    zoneEvidence = true,
    zoneAffinityDiagnostics = true,
    zoneAnchorPolicy = false,
    zoneSupportPolicy = false,
    zoneFinalValidation = false,
    zoneTuningAudit = false,
}
```

The adapter may expose:

```text
contextPolicy
diagnosticsPolicy
visualLanguage
```

These providers are read-only in v1.11.0.

The adapter must continue using the exact existing generation callbacks.

---

# Suggested runtime modules

## Zone generation policy foundation

```text
Core/Generation/Modes/Zone/Context.lua
Core/Generation/Modes/Zone/Diagnostics.lua
Core/Generation/Modes/Zone/Affinity.lua
```

The existing file remains the generation adapter:

```text
Core/Generation/Modes/ZoneLegacyAdapter.lua
```

## Zone context infrastructure

```text
Core/ZoneStyle/Zone/ProfileSchema.lua
Core/ZoneStyle/Zone/ProfileRegistry.lua
Core/ZoneStyle/Zone/ProvenanceRegistry.lua
Core/ZoneStyle/Zone/StartingZoneRegistry.lua
Core/ZoneStyle/Zone/ContextResolver.lua
Core/ZoneStyle/Zone/ContextSnapshot.lua
Core/ZoneStyle/Zone/EvidenceLedger.lua
Core/ZoneStyle/Zone/Affinity.lua
Core/ZoneStyle/Zone/Debug.lua
Core/ZoneStyle/Zone/Compatibility.lua
```

## Profile definition modules

The 25 broad profiles and 134 provenance profiles should be split into meaningful data modules as required to stay below 500 physical lines.

Possible grouping:

```text
Core/ZoneStyle/Zone/ProfilesAzeroth.lua
Core/ZoneStyle/Zone/ProfilesExpansion.lua
Core/ZoneStyle/Zone/ProfilesModern.lua
Core/ZoneStyle/Zone/ProvenanceAzeroth.lua
Core/ZoneStyle/Zone/ProvenanceExpansion.lua
Core/ZoneStyle/Zone/ProvenanceModern.lua
```

These names are planning targets.

Do not create empty wrapper files.

Every module must own a real responsibility.

All runtime Lua files remain below 500 physical lines.

---

# Public and internal APIs

## Public compatibility API

Existing ZoneStyle APIs remain available and behaviorally stable.

## New internal Zone foundation API

Suggested surface:

```lua
ZoneStyle.BuildZoneContextSnapshot(locationFacts)
ZoneStyle.GetZoneContextSnapshot()
ZoneStyle.ResolveZoneIdentity(locationFacts)
ZoneStyle.GetZoneEvidence(snapshot)
ZoneStyle.GetZoneAffinity(source, definition, snapshot)
ZoneStyle.GetZoneFoundationStatus()
ZoneStyle.BuildLegacyContextView(snapshot)
```

## Future policy boundary

The snapshot must be sufficient for a future Zone policy to implement:

```lua
BuildModeContext
BuildContextSeed
DescribeContext
ValidateContext
EvaluateAnchorCandidate
ScoreAnchorPair
ScoreAnchorSkeleton
BuildSupportProfile
ScoreSupportCandidate
AnalyzeCompletedConfiguration
RankRepairTargets
BuildModeReportSections
```

The future policy must not need to import profile tables directly.

---

# Saved data and cache compatibility

Retain:

```text
SavedVariables schema:          2
Courier format:                 1
Wardrobe cache format:          7
Generation cache:               2
Diagnostic format:              1
Weapon-index format:            1
Traveler tuning audit format:   1
Curated tuning version:         1
```

Add internal, additive versions:

```text
Zone context format:            1
Zone profile registry version:  1
Zone provenance registry:       1
Zone affinity diagnostics:      1
```

No SavedVariables migration is planned.

No wardrobe cache reset is planned.

No generation cache reset is planned.

No new persistent cache is required.

The current snapshot cache is session-only.

Serialized diagnostic reports must remain independent of Lua file paths.

---

# User interface scope

v1.11.0 must not:

- rename Zone Native;
- move the Outfits tab;
- redesign the workbench;
- change mode buttons;
- add scoring controls;
- add profile-editing controls;
- add tuning-audit controls;
- change saved UI preferences;
- automatically generate an outfit on zone entry;
- apply a transmog;
- spend gold;
- alter Blizzard Custom Sets.

Additive UI changes are limited to compact diagnostic or tooltip information when useful.

The existing Zone suggestion behavior remains exact:

- entering a new zone may mark a suggestion ready;
- the suggestion never changes the preview automatically;
- Traveler, Class, and Echo generation do not consume the Zone suggestion;
- Zone Native generation consumes it;
- opening Outfits clears the tab marker but not the ready state.

---

# Development strategy

## Step 1: freeze the v1.10.0 Zone baseline

Before moving data or resolution code, record deterministic fixtures for:

- all 25 broad profiles;
- all 134 provenance profiles;
- all 30 starting-zone cases;
- era resolution;
- provenance resolution;
- fallback behavior;
- restriction labels;
- context detail keys;
- suggestion lifecycle;
- favorites and exclusions;
- generated names;
- Zone Native deterministic selections;
- Zone Native random-consumption count;
- legal weapon routes;
- locks and hidden slots;
- Class and Echo context consumption.

## Step 2: add registry and format constants

Add version constants and schema validators without changing current routing.

Prove that duplicate keys, malformed definitions, unknown parents, invalid weights, and alias collisions fail clearly during development.

## Step 3: migrate broad profiles

Move all 25 current profiles into the validated registry.

Keep exact compatibility fields.

Run profile-resolution parity before continuing.

## Step 4: migrate provenance profiles

Move all 134 current provenance definitions into the validated registry.

Preserve order and era bounds.

Run source-pool parity before continuing.

## Step 5: migrate starting-zone cases

Move all 30 current cases into the validated registry.

Run the complete starting-zone matrix.

## Step 6: build the evidence ledger

Create deterministic evidence entries for profile, era, provenance, and fallback resolution.

Do not change public context yet.

## Step 7: build immutable snapshots in parallel

Construct a new snapshot beside the old context.

Compare them field by field.

No production consumer switches until every fixture matches.

## Step 8: add the compatibility compiler

Compile the snapshot back into the existing public context shape.

Switch `GetCurrentContext()` and related wrappers only after exact parity is proven.

## Step 9: add session snapshot caching

Cache by location detail key and registry versions.

Invalidate on:

```text
map change
zone change
subzone change
registry version change
forced refresh
```

## Step 10: add read-only Zone affinity

Use shared visual descriptors to analyze selected appearances only.

Do not inspect the full candidate pool during normal generation.

Do not change selection.

## Step 11: add `/qc zone debug`

Provide bounded context, evidence, coverage, and current-outfit affinity output.

## Step 12: add immutable report sections

Attach compact Zone foundation sections to Zone Native reports.

Preserve report compaction.

## Step 13: update the Zone legacy adapter

Expose foundation capabilities and providers while retaining:

```text
Generation implementation: LEGACY
```

## Step 14: remove superseded loose data paths

After parity, delete duplicate profile, provenance, and starting-zone tables.

Compatibility wrappers may remain where they preserve public APIs.

Every remaining alias must be documented as:

```text
REMOVE IN v1.11.x
KEEP AS PUBLIC COMPATIBILITY API
LEGACY MODE ONLY
```

## Step 15: full automated and Retail validation

Package only after every parity, performance, report, and hygiene gate passes.

---

# Automated test plan

## Registry validation

Verify:

- every profile registers exactly once;
- every provenance profile registers exactly once;
- every starting-zone case registers exactly once;
- duplicate keys fail;
- unknown parent profiles fail;
- malformed confidence values fail;
- malformed style weights fail;
- invalid expansion bounds fail;
- empty aliases fail;
- registry order remains deterministic.

## Profile migration parity

Require exact equality for all 25 profiles:

```text
key
label
seed
alias order
legacy keywords
legacy avoid values
description
resolution precedence
```

## Provenance migration parity

Require exact equality for all 134 profiles:

```text
key
label
alias order
origin vocabulary
minimum expansion
maximum expansion
resolution precedence
```

## Starting-zone parity

Run all 30 cases.

Require exact:

```text
provenance key
provenance label
era ceiling
shared-pool behavior
```

## Context parity

For every fixture, compare v1.10.0 and v1.11.0:

```text
profile key
profile label
profile description
era maximum
era labels
provenance key
provenance label
restriction label
zone key
detail key
fallback result
```

## Resolution precedence

Verify:

- subzone evidence can outrank broad zone evidence;
- exact zone evidence outranks map-trail fallback;
- map-trail evidence resolves when direct names are unavailable;
- explicit parent profiles resolve before Azeroth fallback;
- provenance era bounds remain enforced;
- registration order breaks otherwise equal alias matches deterministically.

## Snapshot immutability

Verify:

- consumers cannot mutate cached snapshots;
- copied diagnostic snapshots remain stable after zone changes;
- rebuilding the same snapshot produces the same primitive fingerprint;
- runtime outfit changes do not alter the location snapshot.

## Random-state parity

Require zero random calls from:

```text
context resolution
evidence construction
profile compilation
affinity analysis
diagnostics
```

Run deterministic Zone generation before and after the migration and require exact selected source identities.

## Legacy Zone selection parity

Compare exact deterministic results for:

- Generate Outfit;
- Reroll Unlocked;
- individual armor rerolls;
- individual weapon rerolls;
- one-hand routes;
- two-hand routes;
- ranged routes;
- independent shield and holdable routes;
- linked hands;
- locks;
- hidden slots;
- per-zone favorites;
- per-zone exclusions.

## Eligibility parity

Require no change for:

- era ceilings;
- foreign source pools;
- promotional exclusions;
- Heritage Armor restrictions;
- tracked quest sources;
- boss-drop origins;
- Wandering Isle corrections;
- manual preview availability.

## Suggestion parity

Verify:

- the same zone transitions create suggestions;
- no duplicate suggestion appears for the same detail key;
- suggestion markers behave as before;
- only Zone Native generation consumes the suggestion;
- no automatic preview change occurs.

## Affinity diagnostics

Verify:

- all selected pieces can be analyzed without changing state;
- missing channels remain missing;
- low-confidence zone evidence lowers diagnostic confidence;
- curated Traveler descriptors remain exact;
- Orcish Scout Boots remain dark, blue, and steel, never green;
- affinity analysis does not alter random state;
- affinity analysis does not alter selections.

## Report integration

Verify:

- Zone foundation fields appear only where intended;
- Traveler reports remain unchanged except version;
- Class and Echo reports remain unchanged except version;
- compacted Zone reports preserve identity, era, provenance, fallback, and warnings;
- oversized evidence is summarized rather than persisted raw;
- diagnostic format remains 1.

## Cache behavior

Verify:

- one snapshot is reused for the same detail key;
- a real zone or subzone change invalidates it;
- forced refresh rebuilds it;
- no wardrobe scan occurs;
- no generation-cache reset occurs;
- no weapon-index query occurs merely to build Zone context.

## File and dependency hygiene

Verify:

- no circular Zone registry dependencies;
- no shared-generation module imports Zone profile tables;
- no duplicate profile implementations remain;
- all TOC entries appear exactly once;
- all runtime Lua files remain below 500 lines;
- all Lua files parse;
- all JSON remains valid;
- no letter-suffixed version strings exist.

---

# Cross-version parity report

The v1.11.0 handoff must include a parity report with these categories:

```text
Zone context parity
Zone profile parity
Zone provenance parity
Starting-zone parity
Era and eligibility parity
Zone selection parity
Zone random-consumption parity
Zone suggestion parity
Favorites and exclusions parity
Weapon, lock, and hidden-state parity
Traveler parity
Class parity
Echo parity
Report and cache parity
```

Every difference must be classified as:

```text
VERSION_ONLY
MODULE_PATH_ONLY
ADDITIVE_ZONE_DIAGNOSTIC
SEMANTIC
```

Any unexplained semantic difference blocks release.

---

# Performance requirements

v1.11.0 must not introduce a repeatable performance regression.

Required:

```text
No new repeated worker slice above 8 ms
No new individual Zone foundation call above 2 ms
No synchronous generation launch regression
No extra wardrobe scan
No extra eligibility pass
No extra weapon-index query
No full candidate-pool affinity analysis during normal generation
No repeated context snapshot build inside one action
No random consumption from the Zone foundation
```

Additional goals:

```text
Cached context lookup: constant-time
Snapshot construction: one bounded call per real context change
Selected-outfit affinity analysis: at most visible selected slots
/qc zone debug: on-demand only
```

The shared scheduler budgets remain:

```text
Preferred worker budget:               5.5 ms
Soft ceiling:                           7.5 ms
Expensive-call force-yield threshold:   2.0 ms
```

v1.11.0 does not redesign the scheduler.

---

# Retail live-validation plan

## Test 1: version and implementation identity

Confirm:

```text
Version: 1.11.0
Traveler implementation: SHARED_FRAMEWORK
Zone implementation: LEGACY
Zone foundation: CONTEXT_EVIDENCE_V1
Class implementation: LEGACY
Echo implementation: LEGACY
```

The Zone foundation marker may be Debug-only.

## Test 2: current-zone snapshot

In Netherstorm, run:

```text
/qc zone debug
```

Confirm:

- location facts name Netherstorm and Outland ancestry;
- the broad style profile remains Outland;
- the provenance pool remains Netherstorm;
- the era ceiling remains Through TBC;
- resolution ancestry is visible;
- no fallback is falsely reported;
- evidence coverage is bounded and readable.

## Test 3: exact-profile zone

Visit Silvermoon or Eversong.

Confirm:

- the style profile resolves to Quel'Thalas;
- the provenance pool resolves to the correct local pool;
- the era ceiling remains TBC;
- exact alias evidence outranks broader Eastern Kingdoms evidence.

## Test 4: fallback zone

Visit an area without a dedicated broad profile.

Confirm:

- the intended regional or Azeroth fallback appears;
- the fallback level and reason are explicit;
- the UI does not claim exact local evidence.

## Test 5: Zone Native generation parity

Perform:

```text
Generate Outfit
Generate Outfit
Reroll Unlocked
Reroll one armor slot
```

Confirm:

- existing Zone Native behavior remains familiar and stable;
- legal weapon routes remain intact;
- locks and hidden slots remain preserved;
- `Generation implementation: LEGACY` remains truthful;
- additive Zone foundation diagnostics appear;
- no fallback or Lua error appears unexpectedly.

## Test 6: suggestion lifecycle

Cross into a new zone.

Confirm:

- one Zone Native suggestion appears;
- no preview changes automatically;
- Traveler generation does not consume it;
- Zone Native generation consumes it;
- tab and ready-state behavior remain unchanged.

## Test 7: favorites and exclusions

Favor one eligible appearance and exclude another in the current zone.

Confirm:

- the favorite remains strongly weighted;
- the exclusion never generates;
- both remain scoped to the current zone key;
- changing zones does not leak either preference;
- returning restores them.

## Test 8: eligibility and provenance

In an Outland zone:

- inspect a later-expansion appearance;
- inspect a foreign TBC boss or tracked quest source;
- inspect a promotional appearance;
- inspect a manually previewable excluded appearance.

Confirm all current eligibility behavior remains unchanged.

## Test 9: cross-mode isolation

Generate once in:

```text
Traveler
Class Fantasy
Chronicle Echo
```

Confirm:

- Traveler remains `SHARED_FRAMEWORK`;
- Class and Echo remain `LEGACY`;
- no Zone evidence changes their results;
- no Zone suggestion is consumed by those modes.

## Test 10: reload persistence

Use `/reload`.

Confirm:

- selected mode persists;
- preview persists;
- concepts persist;
- favorites and exclusions persist;
- Debug History persists as before;
- no cache reset occurs;
- the Zone context snapshot rebuilds cleanly;
- no duplicate suggestion appears merely because of reload.

---

# Acceptance criteria

v1.11.0 becomes package-ready only when:

1. An immutable Zone Context Snapshot v1 exists.
2. A deterministic Zone evidence ledger exists.
3. All 25 broad profiles live in a validated registry.
4. All 134 provenance profiles live in a validated registry.
5. All 30 starting-zone cases live in a validated registry.
6. The compatibility view reproduces every v1.10.0 context field exactly.
7. Zone Native selection behavior remains semantically identical to v1.10.0.
8. Zone resolution consumes no random values.
9. Read-only descriptor-based Zone affinity diagnostics exist.
10. `/qc zone debug` explains identity, era, provenance, fallback, and evidence coverage.
11. Zone reports include compact additive foundation sections.
12. Zone Native truthfully remains `Generation implementation: LEGACY`.
13. Traveler remains `SHARED_FRAMEWORK` and behaviorally unchanged.
14. Class and Echo remain `LEGACY` and behaviorally unchanged.
15. Era, provenance, promotion, Heritage, and manual-preview rules remain unchanged.
16. Zone suggestions, favorites, and exclusions remain unchanged.
17. Locks, hidden slots, and legal weapon routes remain unchanged.
18. No SavedVariables migration or cache reset is required.
19. No runtime Lua file exceeds 500 lines.
20. All automated tests and static verifiers pass.
21. Cross-version parity contains no unexplained semantic difference.
22. Retail validation passes.
23. No repeatable performance regression appears.

---

# Explicit non-goals

v1.11.0 does not:

- promote Zone Native generation to `SHARED_FRAMEWORK`;
- replace Zone's independent armor selection;
- add Zone anchor beam search;
- add Zone contextual support beam search;
- add Zone mismatch budgets;
- add Zone completed-outfit validation;
- add Zone repair passes;
- add Zone alternate-skeleton fallback;
- modernize Zone support-slot rerolls;
- change Zone candidate weights;
- change Zone source eligibility;
- change Zone random behavior;
- add new broad profile coverage;
- add new provenance pools;
- add Zone curated visual overrides;
- add a Zone tuning audit;
- change Traveler scoring or descriptors;
- change Class or Echo;
- fix the deferred legacy individual weapon-reroll path;
- redesign the Outfits UI;
- move Outfits into the Transmog window;
- change cache formats;
- change Courier;
- rename user-facing modes.

---

# Risk register

## Risk 1: data migration changes resolution order

**Failure mode:** A profile or provenance alias resolves differently after being moved into registries.

**Mitigation:** Preserve registration order exactly and require fixture parity for all aliases and representative context strings.

## Risk 2: diagnostics perturb random generation

**Failure mode:** Read-only analysis changes random consumption and therefore changes generated selections.

**Mitigation:** Prohibit `math.random()` in all Zone foundation modules and compare deterministic output plus random-call counters.

## Risk 3: canonical style fields silently become scoring inputs

**Failure mode:** New profile vectors accidentally affect legacy weights.

**Mitigation:** Keep canonical fields behind an observational API and add a verifier forbidding the legacy generator from reading them.

## Risk 4: snapshot caching becomes stale

**Failure mode:** A subzone or map change continues using the prior identity.

**Mitigation:** Include map, zone, subzone, and registry versions in the cache key; invalidate on all existing zone events and forced refresh.

## Risk 5: report growth causes lost diagnostics

**Failure mode:** Raw evidence exceeds the persistence ceiling.

**Mitigation:** Persist compact summaries only, keep detailed evidence on-demand, and add compaction regression tests.

## Risk 6: broad profile identity is mistaken for exact provenance

**Failure mode:** An Outland style profile is treated as permission for every Outland source in Netherstorm.

**Mitigation:** Keep profile and provenance registries separate and preserve existing hard source-pool checks.

## Risk 7: framework claims outrun implementation

**Failure mode:** Zone reports `SHARED_FRAMEWORK` before anchors, support, validation, and rerolls have migrated.

**Mitigation:** Keep the adapter `LEGACY` and add the separate `CONTEXT_EVIDENCE_V1` foundation marker.

---

# Handoff to the next v1.11.x release

After v1.11.0 is live-validated, the next Zone slice should consume the new snapshot and read-only affinity evidence to define the first behavior-changing Zone policy.

The likely next scope is:

```text
Zone anchor policy contract
Zone-native anchor candidate relevance
Descriptor-to-zone anchor affinity
Zone pair cohesion interpretation
Zone novelty meaning
Legal weapon-bundle scoring
Shared-framework second-policy hardening
No support rewrite unless the evidence proves the boundary is ready
```

The next release should not modify profile facts to make an anchor score look better.

If a profile is wrong, correct the evidence deliberately.

If the policy is wrong, correct the policy deliberately.

The two must remain separable.

---

# Planned release artifacts

```text
QuestChronicle-v1.11.0.zip
QuestChronicle-v1.11.0-Architecture-and-Development-Plan.md
QuestChronicle-v1.11.0-Zone-Context-Schema.md
QuestChronicle-v1.11.0-Zone-Registry-Migration-Report.md
QuestChronicle-v1.11.0-Live-Validation-Steps.md
QuestChronicle-v1.11.0-Automated-Validation.md
QuestChronicle-v1.11.0-Parity-Report.md
QuestChronicle-v1.11.0.sha256
```

---

# Planned commit message

```text
refactor: Update Quest Chronicle to v1.11.0

Add an immutable Zone context and evidence foundation
Migrate existing Zone style, provenance, and starting-zone data into validated registries
Expose read-only Zone affinity diagnostics through the shared visual language
Preserve Zone Native generation behavior behind the legacy adapter
Prepare the v1.11.x train for the first Zone anchor-policy implementation
```
