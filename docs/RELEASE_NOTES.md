# Quest Chronicle v1.9.0a7 - Cache and Pipeline Repair

## Corrected package metadata

- The runtime version displayed by Status now reads the authoritative TOC metadata.
- Corrected a stale internal fallback that displayed `1.9.0a5` even while the `1.9.0a7` modules were loaded.
- Added an automated version-consistency guard covering the TOC, `VERSION.txt`, and runtime fallback.

v1.9.0a7 addresses the bottlenecks identified by v1.9.0a6's live phase telemetry. The scheduler itself was yielding correctly, but generation repeatedly recomputed fail-closed era evidence, routed weapons in one synchronous operation, and rebuilt the complete Outfits workbench after committing the result.

## Era and eligibility caching

- Caches resolved, unknown, and temporarily pending era-evidence results on the visual representative.
- Unknown results remain fail-closed until source metadata or the visual manifest changes.
- Pending results remain fail-closed and retry after 30 seconds, or sooner when WoW reports item-data changes.
- Keys evidence to the resolver version, visual ID, visual-source manifest, and metadata revision.
- Preserves valid evidence while a successful wardrobe scan replaces its source objects.
- Migrates positive v1.9.0a6 evidence that predates the new explicit result-state and manifest-signature fields.
- Adds reusable pre-era and full eligibility records keyed to the player, zone preferences, era limit, provenance, settings, metadata, and evidence result.

## Cooperative weapon pipeline

- Keeps the existing weapon-route algorithm and weighted ordering intact.
- Runs that synchronous logic inside a resumable coroutine and yields between route, candidate, eligibility, scoring, permission, appearance, and source-validation operations.
- Adds a reusable weapon-subtype candidate index so generation does not rebuild the same category lists for every route.
- Preserves linked hands, exact-visual preference, same-subtype fallback, companion shields/foci, locked weapons, artifact routes, and atomic bundle commits.

## Targeted completion refresh

- Replaces the final complete workbench refresh with a generation-specific refresh.
- Updates the preview manifest, slot icons, current selection, visible appearance rows, generated name, action states, result text, and performance line.
- Refreshes the consumed Zone Native suggestion state while leaving weapon filter matrices, pagination, and unrelated workbench structures alone.

## Diagnostics

The performance tooltip now also reports:

```text
Era-cache hits
Eligibility-cache hits
Weapon-pipeline yields
```

## Compatibility

- SavedVariables schema remains 2.
- Courier format remains 1.
- Wardrobe cache format remains 7.
- No destructive migration or forced manual rescan is required.
- Traveler cohesion remains calibrated instrumentation only.
- No transmog is applied and no gold is spent.
