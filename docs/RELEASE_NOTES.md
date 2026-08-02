# Quest Chronicle v1.9.0a8 - Persistent Generation Cache

v1.9.0a8 repairs the cache lifecycle exposed by the v1.9.0a7 Retail test. v1.9.0a7 successfully removed the large weapon and UI frame stalls, and its cache warmed within one session, but an automatic scan after `/reload` rebuilt the source tables and left generation with almost no reusable era or eligibility records.

## Dedicated SavedVariables cache

- Adds a versioned `wardrobe.generationCache` store inside the existing account-level `QuestChronicleDB` SavedVariables database.
- Stores visual-level era evidence independently from the transient source tables rebuilt by each collection scan.
- Stores reusable pre-era and final eligibility records under stable source and generation-context keys.
- Updates the SavedVariables tables as evidence is learned; WoW writes them normally on `/reload`, logout, or exit.
- Keeps SavedVariables schema 2, Courier format 1, and wardrobe cache format 7 unchanged.

## Stable identity and migration

- Keys persistent era evidence to the visual ID, era resolver version, complete visual-source manifest, and complete sibling-item manifest.
- Removes session-local `metadataRevision` and mutable display names from persistent eligibility identity.
- Preserves source-specific safety by retaining representative source ID, item ID, zone preference, player progression, era, provenance, and mode in eligibility keys.
- Migrates resolved, unknown, and pending era evidence already present on v1.9.0a7 wardrobe source records into the dedicated store before the first automatic scan.
- Restores matching evidence while the scan constructs its staging cache rather than depending on the old source table to survive.

## Fail-closed invalidation

- A changed visual-source or sibling-item manifest invalidates the saved evidence and dependent final eligibility records.
- WoW item-data events preserve resolved strong evidence while reopening affected pending or unknown evidence.
- Pending evidence reopens after 30 seconds.
- Persisted unknown evidence remains fail-closed but expires after six hours so newly available Blizzard metadata can be reconsidered.
- Old generation contexts are bounded per visual and pruned by age and least-recently-used order.

## Cache lifecycle diagnostics

The Generation Performance tooltip now reports:

```text
Persistent evidence, precheck, and eligibility entry counts
Entries loaded from SavedVariables for this session
v1.9.0a7 evidence migrated into the dedicated store
Evidence retained through the automatic collection scan
Entries added or invalidated during the current generation
Exact invalidation reasons and counts
```

These diagnostics accompany the existing candidate, era-source-check, cache-hit, weapon-yield, and phase-timing measurements.

## Preserved behavior

- Cooperative armor generation and cooperative weapon routing are unchanged.
- Targeted completion refreshes are unchanged.
- Outfit selection, weighting, locks, hidden slots, linked hands, artifacts, and atomic commits are unchanged.
- Traveler cohesion remains calibrated instrumentation only.
- Quest Chronicle still applies no transmog and spends no gold.
