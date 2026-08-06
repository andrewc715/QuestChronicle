# Quest Chronicle v1.11.3 Validation Report

## Release purpose

Quest Chronicle v1.11.3 activates `ZONE_ANCHOR_POLICY_V1`, the first authoritative evidence-driven preference policy for Zone Native anchor construction.

The release preserves the mature shared beam, visual-cohesion, hard-clash, novelty, legal-weapon, scheduling, atomic-commit, and diagnostic mechanics. Zone contextual support, final validation, repair, and rerolls remain on their existing legacy behavior.

## Automated validation

```text
Executable Lua regression tests: 91 / 91 PASS
Python static verifiers:          31 / 31 PASS
Runtime Lua syntax:              145 / 145 PASS
TOC runtime modules:             145 / 145 exactly once
Lua files >= 500 lines:            0
```

Largest Lua file:

```text
Core/ZoneStyle/SourceMetadata.lua
499 physical lines
```

## Cross-version boundary

Compared with v1.11.2:

```text
Existing runtime modules:        141
Byte-identical modules:          124
Changed existing modules:         17
New runtime modules:               4
Removed runtime modules:           0
Current runtime modules:          145
```

## Implemented behavior

- Zone Native remains overall `LEGACY`.
- `ZONE_ANCHOR_POLICY_V1` is registered with format 1 and `ACTIVE` authority.
- Zone support remains explicitly `LEGACY`.
- One immutable context snapshot is captured per Zone action.
- Eligible anchor candidates receive a bounded Affinity v2 adjustment.
- Unknown, partial, zero-confidence, and not-applicable evidence remain neutral where specified.
- Visual cohesion and hard clashes remain authoritative.
- Candidate preference reuses the existing random draw.
- Legal weapon bundles are unchanged and linked visuals receive one logical Zone contribution.
- Existing novelty classes and repeat penalties remain unchanged.
- Changed context cancels before live preview commit.
- Debug export format 3 and immutable reports expose policy decomposition and boundaries.

## Protected behavior

```text
Traveler implementation:       SHARED_FRAMEWORK, unchanged
Class Fantasy implementation:  LEGACY, unchanged
Chronicle Echo implementation: LEGACY, unchanged
Zone Context Snapshot:         format 1, unchanged
Zone Affinity:                 format 2, unchanged
Zone support policy:           LEGACY, unchanged
SavedVariables schema:         2
Courier format:                1
Wardrobe cache:                7
Diagnostic format:             1
```

## Result

```text
Automated validation: PASS
Worktree package readiness: PASS
Exact-ZIP validation: PASS
Retail validation: Pending
```
