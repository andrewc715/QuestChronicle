# Quest Chronicle v1.9.0a2 — Cooperative Wardrobe Refresh

v1.9.0a2 preserves the calibrated Traveler Cohesion instrumentation from v1.9.0a1 and repairs a severe login and `/reload` performance regression in the wardrobe refresh pipeline. Traveler generation and all cohesion results remain unchanged.

## Root cause

The automatic login refresh was performing the same metadata work up to three times:

1. hydrating and indexing the previous 5,000+ appearance cache immediately on `PLAYER_ENTERING_WORLD`;
2. hydrating each source again while rebuilding the collection cache;
3. clearing the completed index and hydrating every new source again after the scan.

The era-evidence rebuild also requested metadata for every sibling item source during the scan, producing a large burst of item API work. A large equipment slot was still processed as one uninterrupted Lua loop.

## Corrected pipeline

The login path now performs one metadata lifecycle:

```text
Begin scan
→ clear metadata watches once
→ discover and hydrate each representative source once
→ preserve broad sibling-source manifests without requesting every sibling immediately
→ finalize sorting without a second hydration pass
```

If the login scan is deferred or fails, Quest Chronicle restores the lightweight item-to-source watch index without calling item-information APIs.

## Cooperative slot scanning

Large slots now yield throughout the scan:

```text
maximum appearances per step: 18
maximum addon work per step: approximately 3 ms
```

The next batch resumes on a later timer frame. This changes scheduling only; source validation, diagnostics, visual deduplication, era manifests, and final cache contents use the same rules.

## Traveler instrumentation

The v1.9.0a1 calibration is retained unchanged:

- linked matching weapons count as one analysis block;
- slot prominence scales visual impact;
- strongly echoed variations cost zero mismatch budget;
- mismatch costs are fractional;
- `/qc traveler debug` reports evidence-based bridges and clashes.

Traveler generation remains instrumentation-only and is still byte-for-byte unchanged from the validated v1.8.5 generation path.

## Compatibility

- Addon version: `1.9.0a2`
- SavedVariables schema: `2`
- Courier format: `1`
- Wardrobe cache format: `7`
- No wardrobe rescan or migration is required beyond the normal automatic login refresh
- Every runtime Lua file remains below 500 lines
