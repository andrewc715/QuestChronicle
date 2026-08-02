# Quest Chronicle v1.9.0a3 — Non-Blocking Foreground Wardrobe Actions

v1.9.0a3 preserves the calibrated Traveler Cohesion instrumentation and cooperative background collection scan from v1.9.0a2. It removes the remaining synchronous Blizzard collection recalculation that could freeze the client when generating an outfit or starting a manual scan.

## Root cause

Three foreground paths still called:

```lua
C_TransmogCollection.UpdateUsableAppearances()
```

The call was made before Quest Chronicle's cooperative work began:

- `Generate Outfit`, while creating the weapon-generation context;
- `Scan Collection`, immediately after applying temporary collection filters;
- equipment and specialization refresh events.

On a collection containing more than 5,000 visuals, Blizzard can execute that global usability recalculation synchronously. The Lua scan worker cannot yield until Blizzard returns, so the game appears frozen even though the later scan stages are cooperative.

## Corrected capability flow

Quest Chronicle no longer forces the global usability index to rebuild.

```text
Equipment/spec change
→ invalidate weapon appearance routes
→ query Blizzard's live slot-and-option APIs
→ repeat once after a short settling delay
```

Weapon Appearance Routes already use current per-hand transmog outfit slots, enabled weapon options, and category permissions. Those live APIs are sufficient for generation and do not require rebuilding the entire collection index.

Collection scans now proceed directly from temporary collection-filter setup into the existing readiness wait and cooperative slot workers.

## Guardrail

The package adds:

```text
tools/verify_no_blocking_usability_refresh.py
```

Packaging fails if runtime Lua reintroduces a call to `UpdateUsableAppearances`.

## Preserved behavior

- Traveler cohesion formulas and calibrated diagnostics are unchanged.
- Traveler outfit selection remains instrumentation-only and unchanged.
- Cooperative scan limits remain 18 appearances or approximately 3 ms per worker step.
- Weapon Appearance Routes, linked hands, era evidence, live metadata updates, concepts, and Custom Sets are unchanged.
- SavedVariables schema remains `2`.
- Courier format remains `1`.
- Wardrobe cache format remains `7`.
- No cache migration or additional rescan is required.
