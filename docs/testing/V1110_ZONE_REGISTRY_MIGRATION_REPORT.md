# Quest Chronicle v1.11.0 Zone Registry Migration Report

## Baseline

```text
Source release: Quest Chronicle v1.10.0
SHA-256: 0120a5805726c6d55629d3cc12dab84fac1159d8ab1ab495cf7c97741b888511
```

## Migration totals

```text
Broad style profiles:   25 / 25 migrated
Provenance profiles:   134 / 134 migrated
Starting-zone cases:    30 / 30 migrated
Missing definitions:     0
Duplicate registration:  0
Invalid registry keys:    0
Invalid local aliases:    0
```

## Preserved profile fields

The profile registry preserves:

```text
key
label
seed
registration and selection order
location aliases
positive source-name keywords
negative source-name keywords
description
```

The explicit `Azeroth Adventurer` fallback exists in the registry but remains outside the legacy ordered matching list, preserving v1.10.0 resolution behavior.

## Preserved provenance fields

The provenance registry preserves:

```text
key
label
registration order
location aliases
source-origin vocabulary
minimum expansion bound
maximum expansion bound
```

Broad style identity and local source provenance remain separate registries. For example, Outland may be the style profile while Netherstorm is the provenance pool.

## Preserved starting-zone fields

The starting-zone registry preserves all existing racial and hero-class opening data, including shared geographic cases and later openings such as Mardum, Telogrus Rift, Hall of Awakening, and Harandar.

## Canonical style extension

All 25 broad profiles now contain explicit observational definitions for:

```text
culture
climate
terrain
palette
material
finish
motif
magic
silhouette
avoids
```

These fields are not read by the legacy generator in v1.11.0. They support context explanation, selected-look affinity, and the future Zone policy contract.

## Alias precedence

Intentional alias overlap between different profiles and provenance pools is preserved. The migration keeps the original ordered resolution behavior rather than globally rejecting cross-profile overlap. Duplicate or invalid aliases inside one definition are rejected.

## Executable migration proof

`tools/test_zone_registry_v1110.lua` confirms:

```text
25 profiles
134 provenance pools
30 starting-zone cases
exact compatibility fields
preserved order and fallback behavior
```

`tools/verify_zone_context_foundation_v1110.py` statically confirms registry counts, load order, foundation identity, selection neutrality, and the prohibition on random use.

## Result

```text
Migration status: PASS
Semantic registry differences: None
Selection impact: None
Random-consumption impact: None
SavedVariables migration: Not required
```
