# Quest Chronicle v1.9.0a10 - Pending Dependency Pipeline

v1.9.0a10 is a focused cache-churn repair built from the v1.9.0a9 diagnostic branch while retaining v1.9.0a8 as the live-validated behavioral baseline. Retail testing showed that v1.9.0a9 correctly preserved the persistent cache but still reopened roughly 814 to 848 pending evidence records and invalidated roughly 1,628 to 1,696 downstream records during each generation. Most callbacks completed item dependencies without changing the final era outcome.

## Exact dependency lifecycle

- Persistent evidence records now use explicit `RESOLVED`, `PENDING_ITEMS`, `TRACKING_ONLY`, `STALE`, and `UNKNOWN` states.
- Item-pending records retain the exact unresolved item IDs rather than a broad pending flag.
- A reverse dependency index maps each pending item ID to only the affected visual evidence records.
- Resolving one dependency leaves the record pending when other item dependencies remain.
- Item completion that leaves only content-tracking work transitions the record to `TRACKING_ONLY` without discarding reusable eligibility.
- The generation-cache store migrates from internal version 1 to version 2 in place. No blanket purge is performed.

## Outcome comparison before invalidation

- Fully satisfied item dependencies queue one cooperative evidence reevaluation.
- The reevaluated evidence is normalized into a generation-relevant outcome fingerprint.
- Presentation details such as names, links, icons, and quality are excluded from the fingerprint.
- If the outcome is unchanged, the persistent record is updated in place and dependent eligibility remains valid.
- If the outcome changes, only final eligibility records derived from that visual are invalidated; era-independent prechecks remain reusable.
- Genuine stable metadata identity changes continue to invalidate item-derived evidence safely.

## Callback coalescing and cooperative resolution

- Duplicate item callbacks are deduplicated before dependency processing.
- The pending resolver uses the existing foreground time budget and processes era siblings incrementally.
- Resolution pauses while collection scanning or foreground outfit generation owns the wardrobe pipeline.
- Failed or incomplete dependencies remain bounded and fail closed instead of entering an immediate reopen loop.

## Diagnostics

The Generation Performance tooltip now distinguishes:

```text
Item callbacks received and coalesced
Exact dependencies examined, still pending, and fully satisfied
Evidence outcomes unchanged and changed
Pending records created
Downstream eligibility records invalidated
Genuine metadata identity changes
```

Weapon diagnostics also retain the slowest cooperative resume phase when an individual resume exceeds the responsiveness guard.

## Preserved behavior

- Armor weighting, random selection order, zone preferences, era restrictions, locks, hidden slots, linked hands, weapon routes, artifacts, and atomic commits are unchanged.
- Traveler cohesion remains calibrated instrumentation only.
- The targeted post-generation UI refresh remains unchanged.
- SavedVariables schema 2, Courier format 1, and wardrobe cache format 7 remain unchanged.
- Quest Chronicle applies no transmog and spends no gold.
