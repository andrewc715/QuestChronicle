# Quest Chronicle v1.11.0 Zone Context Schema

## Purpose

Zone Context Snapshot format 1 is the immutable, deterministic boundary between World of Warcraft location facts, Zone evidence, the v1.10.0 legacy compatibility view, diagnostics, and future Zone policies.

The snapshot is independent of the current outfit, candidate pools, and random state. Public access returns primitive deep copies. The internal cache is session-only and does not alter SavedVariables.

## Format identity

```text
Zone foundation:                 CONTEXT_EVIDENCE_V1
Zone context format:             1
Profile registry version:        1
Provenance registry version:     1
Starting-zone registry version:  1
Era rule version:                1
Zone affinity format:            1
```

## Snapshot structure

```lua
{
    format = 1,
    registryVersion = 1,
    provenanceRegistryVersion = 1,
    eraRuleVersion = 1,
    capturedAt = 0,

    location = {
        mapID = nil,
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
    },

    era = {
        maxExpansionID = 0,
        label = "",
        shortLabel = "",
        resolutionLevel = "EXACT_ZONE",
        confidence = 0.0,
    },

    provenance = {
        key = nil,
        label = "",
        resolutionLevel = "UNRESOLVED",
        confidence = 0.0,
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

    evidence = {
        format = 1,
        entries = {},
    },

    startingZoneCaseID = nil,
    fingerprint = "ZCTX-00000000",
}
```

## Resolution confidence

```text
EXACT_MAP          1.00
EXACT_SUBZONE      0.95
EXACT_ZONE         0.90
EXACT_MAP_NAME     0.90
MAP_TRAIL          0.80
PARENT_PROFILE     0.70
REGION_FALLBACK    0.55
AZEROTH_FALLBACK   0.25
UNRESOLVED         0.00
```

These values are diagnostic metadata only in v1.11.0. They do not affect generation.

## Evidence channels

Context evidence may use:

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

Each evidence entry is primitive data and may contain:

```lua
{
    channel = "PROFILE_ALIAS",
    subject = "zone_profile",
    value = "Outland",
    matchedText = "Netherstorm",
    matchedAlias = "netherstorm",
    sourceLevel = "EXACT_ZONE",
    confidence = 0.90,
    registryKey = "outland",
}
```

Candidate evidence such as `VISUAL_DESCRIPTOR`, `SOURCE_PROVENANCE`, and `CURATED_ZONE_TAG` is produced separately by read-only affinity analysis and is not inserted into the context ledger.

## Style coverage

Every canonical style channel records one of:

```text
KNOWN
PARTIAL
UNKNOWN
NOT_APPLICABLE
```

The v1.11.0 compiler currently marks a populated channel `KNOWN`, an empty ordinary channel `UNKNOWN`, and an empty `avoids` channel `NOT_APPLICABLE`.

## Stable identity and cache

The session cache key includes:

```text
mapID
normalized zone
normalized subzone
profile registry version
provenance registry version
era rule version
```

The stable snapshot fingerprint excludes `capturedAt`. Rebuilding from identical facts and registry versions therefore produces the same fingerprint.

## Compatibility boundary

`Core/ZoneStyle/Zone/Compatibility.lua` compiles the snapshot into the exact legacy context shape consumed by the v1.10.0 Zone Native generator. The compiler preserves field values, suggestion behavior, favorites and exclusions scope, and resolution precedence. Canonical style evidence is not exposed as a legacy scoring input.

## Public access

The public ZoneStyle boundary includes:

```lua
QuestChronicle.ZoneStyle.BuildZoneContextSnapshot(locationFacts)
QuestChronicle.ZoneStyle.GetZoneContextSnapshot()
QuestChronicle.ZoneStyle.GetZoneFoundationStatus()
QuestChronicle.ZoneStyle.GetZoneAffinity(source, definition, snapshot)
QuestChronicle.ZoneStyle.PrintZoneDiagnostics()
```

Mode-facing read-only providers are registered through the Zone legacy adapter. Zone Native remains `LEGACY` and does not claim shared-framework generation capability.
