# Quest Chronicle v1.9.0.13 Implementation Plan

## Release purpose

Quest Chronicle v1.9.0.13 is a narrowly scoped diagnostics-correctness release for the session-only weapon candidate index.

The release will make every weapon-index lifecycle transition carry a canonical invalidation reason, while ensuring that each completed generation action reports only the invalidation that action actually processed.

This is not a scheduler, selection, scoring, routing, cache-performance, or outfit-generation release.

## Starting point

Create the implementation branch directly from the live-validated v1.9.0.12 source.

The previously assembled v1.9.0.13 package is treated only as an implementation spike and reference. It is not the accepted release branch until the planned work is reapplied or verified from the v1.9.0.12 baseline, passes parity testing, and completes Retail live validation.

## Problem statement

v1.9.0.12 correctly identifies that the transient weapon candidate index begins a new login session because of `LOGIN_SESSION_RESET`. However, index-level lifecycle state and action-level report state are not fully separated.

That creates two diagnostic errors:

1. A warm action can inherit and repeat an older lifecycle reason even though no invalidation occurred during that action.
2. Some lifecycle transitions can fall through to `UNKNOWN` or the older `UNSPECIFIED` label even though the addon already knows the cause.

The generation machinery is otherwise operating within the intended scheduler rails. The defect is the dashboard label, not the engine beneath it.

## Required behavior

### Index-level lifecycle cause

The active lifecycle cause remains attached to the transient weapon index while buckets belonging to that lifecycle are constructed.

Example after login or `/reload`:

```text
First required bucket:       COLD_BUILD    + LOGIN_SESSION_RESET
Later required bucket:       PARTIAL_BUILD + LOGIN_SESSION_RESET
Already constructed bucket:  WARM_REUSE    + NONE
```

An intervening warm reuse must not erase the index-level cause. If another missing bucket is constructed later in the same lifecycle, that partial build must still report the original canonical cause.

### Action-level invalidation report

Each completed generation action reports the reason it actually processed:

- A cold build reports the active lifecycle cause.
- A partial build reports the active lifecycle cause.
- An incremental repair reports the cause that triggered the repair.
- A warm reuse reports `NONE` when no new invalidation occurred.
- An action that performs no index work reports `NONE`.
- A missing or unrecognized cause reports `UNKNOWN` and sets the unknown-fallback diagnostic flag.

Historical index state must never be copied blindly into a warm action report.

## Canonical invalidation reasons

| Reason | Required use |
|---|---|
| `NONE` | No invalidation was processed by the completed action. |
| `LOGIN_SESSION_RESET` | The session-only index was recreated after login or `/reload`, including the automatic login wardrobe refresh. |
| `FORMAT_MISMATCH` | The existing transient index uses an incompatible internal format. |
| `WARDROBE_CACHE_REPLACED` | A manual collection scan or equivalent full wardrobe-cache replacement changes index identity. |
| `COLLECTION_REVISION_CHANGED` | The transmog collection changed without a more specific collected-appearance cause. |
| `APPEARANCE_COLLECTED` | A source-added event indicates that a new appearance was collected. |
| `METADATA_REVISION_CHANGED` | Weapon metadata or a subtype bucket changed and requires rebuilding or repair. |
| `CHARACTER_CAPABILITY_CHANGED` | Character identity, specialization, equipment topology, talent configuration, or another weapon-capability input changed. |
| `EVIDENCE_OUTCOME_CHANGED` | A generation-evidence result changed and invalidated dependent index work. |
| `ELIGIBILITY_OUTCOME_CHANGED` | An eligibility result changed and invalidated dependent index work. |
| `MANUAL_DEBUG_RESET` | An explicit internal or debug reset deliberately invalidated the index. |
| `UNKNOWN` | A caller omitted the cause or supplied an unrecognized cause. This is the only warning-producing fallback. |

`UNSPECIFIED` is not a valid normal result in v1.9.0.13.

## Lifecycle mapping

The implementation must assign canonical reasons at all production entry points:

| Lifecycle transition | Canonical result |
|---|---|
| Addon/session initialization | `LOGIN_SESSION_RESET` |
| Automatic login wardrobe refresh | `LOGIN_SESSION_RESET` |
| Manual **Scan Collection** replacement | `WARDROBE_CACHE_REPLACED` |
| Newly collected transmog source | `APPEARANCE_COLLECTED` |
| Removed source or general collection mutation | `COLLECTION_REVISION_CHANGED` |
| Equipment, specialization, talent, trait, topology, or character change | `CHARACTER_CAPABILITY_CHANGED` |
| Internal index-format mismatch | `FORMAT_MISMATCH` |
| Cache identity changes without an explicit caller reason | Infer `WARDROBE_CACHE_REPLACED` or `CHARACTER_CAPABILITY_CHANGED` from the changed identity field. |
| Subtype metadata or bucket invalidation | `METADATA_REVISION_CHANGED` |
| Explicit debug reset | `MANUAL_DEBUG_RESET` |
| Missing or unrecognized caller reason | `UNKNOWN` |

## Implementation design

### 1. Central canonicalization

Maintain one canonical-reason registry in the weapon candidate index module.

Provide two distinct normalization paths:

- **Lifecycle normalization:** missing or invalid input becomes `UNKNOWN` and marks the fallback.
- **Action normalization:** absence of a new invalidation becomes `NONE`; an explicitly supplied invalid reason still becomes `UNKNOWN`.

This distinction prevents ordinary warm reuse from being mistaken for an unclassified invalidation.

### 2. Explicit invalidation sequence

Track a monotonically increasing invalidation sequence for the transient index.

An action snapshot records the sequence at its start. Completion compares the starting and ending sequence so the report can determine whether a new invalidation occurred during the action.

The sequence is diagnostic state only. It must not affect candidate ordering, scoring, selection, routing, scheduling, or cache contents.

### 3. Separate lifecycle and action diagnostics

Keep the active cause on the index object for cold, partial, and repair work.

Build the completed action diagnostic from deltas between the starting and ending snapshots:

- bucket-build delta;
- repair delta;
- reuse delta;
- examined-candidate delta;
- cooperative-yield delta;
- invalidation-sequence delta.

Determine the action first, then assign its report reason:

```text
COLD_BUILD / PARTIAL_BUILD / INCREMENTAL_REPAIR
    -> active or newly processed canonical cause

WARM_REUSE / NONE
    -> NONE, unless a new invalidation genuinely occurred during the action
```

### 4. Defensive identity inference

When the current index identity no longer matches the wardrobe-cache identity, infer the cause from the exact field that changed:

- format changed -> `FORMAT_MISMATCH`;
- character key changed -> `CHARACTER_CAPABILITY_CHANGED`;
- scan completion or collected-visual identity changed -> `WARDROBE_CACHE_REPLACED`.

Only a mismatch that cannot be classified may fall back to `UNKNOWN`.

### 5. Warning gate

`UNKNOWN_WEAPON_INDEX_INVALIDATION` is emitted only when the final action report contains:

```text
Weapon index invalidation: UNKNOWN
```

The following must never produce that warning:

- `NONE`;
- `LOGIN_SESSION_RESET`;
- any other recognized canonical reason;
- historical unknown state that was not processed by the current action.

### 6. Production call-site audit

Audit every call to the weapon-index or weapon-route invalidation functions.

Every production call must provide a canonical reason. Compatibility translation may normalize known legacy or test labels to the appropriate canonical reason, but production code must not depend on that translation.

## Files expected to change

Primary runtime files:

- `Core/Wardrobe/WeaponCandidateIndex.lua`
- `Core/Wardrobe/CollectionScanAndPreview.lua`
- `Core/Wardrobe/Events.lua`
- `Core/Diagnostics/Comparison.lua`

Release and architecture documentation:

- `README.md`
- `RELEASE_NOTES.md`
- `docs/CHANGELOG.md`
- `docs/ARCHITECTURE.md`
- `docs/DIAGNOSTIC_SNAPSHOT_FORMAT.md`
- `docs/testing/V19013_LIVE_TEST_CHECKLIST.md`

Version references and manifests may change only as required to identify v1.9.0.13.

## Explicit non-goals

v1.9.0.13 must not change:

- appearance eligibility;
- era evidence;
- anchor selection;
- support selection;
- palette, material, finish, provenance, silhouette, novelty, bridge, or mismatch scoring;
- weapon subtype selection;
- weapon route or topology decisions;
- hidden or locked-slot behavior;
- reroll ancestry;
- report commit or preview application order;
- beam widths or candidate limits;
- scheduler phases;
- cooperative-yield cadence;
- worker slice budgets;
- cache schemas or migration formats;
- background wardrobe-scan cadence;
- persisted generation-cache behavior;
- user-facing controls.

No scheduler surgery is permitted in this release.

## Automated test plan

### Lifecycle sequence harness

Simulate a fresh session and verify:

```text
Initial snapshot       -> STALE/PARTIAL state with LOGIN_SESSION_RESET available
First bucket build     -> COLD_BUILD + LOGIN_SESSION_RESET
Second missing bucket  -> PARTIAL_BUILD + LOGIN_SESSION_RESET
Reused bucket          -> WARM_REUSE + NONE
```

Also verify this interleaving:

```text
COLD_BUILD + LOGIN_SESSION_RESET
WARM_REUSE + NONE
PARTIAL_BUILD + LOGIN_SESSION_RESET
WARM_REUSE + NONE
```

The warm action must not erase the lifecycle cause needed by a later partial build.

### Canonical transition harnesses

Verify the expected action report after:

- manual wardrobe-cache replacement;
- appearance collection;
- general collection revision;
- character capability change;
- format mismatch;
- metadata/bucket repair;
- evidence outcome change;
- eligibility outcome change;
- manual debug reset.

### Unknown fallback harness

Verify that:

- a missing reason becomes `UNKNOWN`;
- an unrecognized reason becomes `UNKNOWN`;
- `invalidationUnknownFallback` is true;
- `UNKNOWN_WEAPON_INDEX_INVALIDATION` is emitted;
- a later recognized invalidation does not inherit the old warning;
- a later warm reuse reports `NONE` without a warning.

### Static verification

Add or update static checks to confirm:

- every production invalidation entry point supplies a canonical reason;
- automatic login refresh uses `LOGIN_SESSION_RESET`;
- manual cache replacement uses `WARDROBE_CACHE_REPLACED`;
- collection events use `APPEARANCE_COLLECTED` or `COLLECTION_REVISION_CHANGED`;
- capability events use `CHARACTER_CAPABILITY_CHANGED`;
- warm actions default to `NONE`;
- warning generation is gated exclusively on `UNKNOWN`;
- `UNSPECIFIED` is not emitted by runtime code.

### v1.9.0.12 parity suite

Run all shared deterministic harnesses against v1.9.0.12 and v1.9.0.13.

Required parity:

- identical selected appearance IDs;
- identical anchor and support scores;
- identical weapon routes and topology;
- identical profile and budget reconciliation;
- identical hidden and locked-slot results;
- identical fallback decisions;
- identical scheduler phase order, counters, and cooperative-yield decisions;
- identical atomic preview and report commit behavior.

Expected differences are limited to:

- weapon-index invalidation reason;
- unknown-fallback flag;
- unknown-warning presence;
- release version and documentation;
- nondeterministic wall-clock benchmark measurements.

Any other deterministic output difference blocks the release.

## Retail live-validation plan

### Installation

1. Exit World of Warcraft completely.
2. Install the v1.9.0.13 candidate over the existing addon folder.
3. Preserve `QuestChronicleDB` and the wardrobe cache.
4. Launch Retail and confirm `/qc status` reports v1.9.0.13.
5. Allow the automatic login wardrobe refresh to complete.
6. Clear only diagnostic report history when a clean report sequence is useful.

### Required post-reload sequence

Generate three times and copy every report.

Expected progression, depending on the number of weapon subtype buckets required by the character:

```text
Cold build:
Weapon index use: COLD_BUILD
Weapon index invalidation: LOGIN_SESSION_RESET
At least one bucket built

Additional bucket construction, when required:
Weapon index use: PARTIAL_BUILD
Weapon index invalidation: LOGIN_SESSION_RESET
At least one additional bucket built

Warm reuse:
Weapon index use: WARM_REUSE
Weapon index invalidation: NONE
0 buckets built
0 buckets repaired
0 candidates examined for fully reused buckets
```

A character whose first action constructs every required bucket may move directly from `COLD_BUILD` to `WARM_REUSE`.

### Manual cache replacement

1. Use **Scan Collection**.
2. Generate Outfit.
3. Copy the report.

Expected:

```text
Weapon index use: COLD_BUILD or PARTIAL_BUILD
Weapon index invalidation: WARDROBE_CACHE_REPLACED
```

### Character capability transition

1. Change specialization, equipped weapon layout, or active talent configuration.
2. Generate Outfit.
3. Copy the report.

Expected when affected weapon work is rebuilt:

```text
Weapon index invalidation: CHARACTER_CAPABILITY_CHANGED
```

### Normal-path warning gate

Across all ordinary reports:

```text
No UNKNOWN_WEAPON_INDEX_INVALIDATION warning
No Weapon index invalidation: UNKNOWN
No Weapon index invalidation: UNSPECIFIED
```

### Preservation check

Using the same character state, locks, hidden slots, era, and seed where practical, compare v1.9.0.13 with v1.9.0.12 for:

- selected appearances;
- anchor and support scores;
- weapon routes and topology;
- profile and budget reconciliation;
- hidden and locked-slot behavior;
- scheduler counters and phase boundaries;
- atomic preview and report completion.

## Acceptance criteria

v1.9.0.13 is ready for a release candidate only when:

1. Every production invalidation transition has a canonical reason.
2. Post-reload cold and partial builds report `LOGIN_SESSION_RESET`.
3. Warm reuse with no new invalidation reports `NONE`.
4. `UNKNOWN` appears only for deliberately missing or unrecognized causes.
5. Only `UNKNOWN` produces `UNKNOWN_WEAPON_INDEX_INVALIDATION`.
6. Runtime reports never use `UNSPECIFIED` as the normal reason.
7. All Lua harnesses, Python verifiers, syntax checks, manifest checks, and configuration audits pass.
8. Shared deterministic outputs preserve v1.9.0.12 behavior outside the approved diagnostic differences.
9. Retail live testing confirms the cold/partial/warm sequence and the manual-scan and capability-change transitions.
10. No scheduler, selection, scoring, routing, or commit regression is observed.

The release remains a candidate until Retail live validation is complete.

## Implementation order

1. Create a clean v1.9.0.13 branch from v1.9.0.12.
2. Add failing lifecycle, warm-`NONE`, and unknown-warning tests.
3. Add centralized canonical-reason handling.
4. Separate index-level lifecycle cause from action-level reporting.
5. Add invalidation-sequence tracking and action-delta diagnostics.
6. Assign explicit reasons at every production call site.
7. Gate the warning exclusively on final action `UNKNOWN`.
8. Run focused lifecycle tests.
9. Run the complete automated suite.
10. Run cross-version deterministic parity against v1.9.0.12.
11. Package the release candidate with reports and the Retail checklist.
12. Complete Retail live validation before promotion.

## Planned release handoff

```text
fix: Update Quest Chronicle to v1.9.0.13

Assign canonical reasons across the weapon-index invalidation lifecycle
Preserve LOGIN_SESSION_RESET through cold and partial index builds
Report NONE for warm reuse without a new invalidation
Warn only when an invalidation genuinely falls back to UNKNOWN
Preserve v1.9.0.12 selections, scores, routes, and scheduler behavior
```
