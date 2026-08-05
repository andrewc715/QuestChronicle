# Quest Chronicle v1.9.0.15a1

## Phase E: Curated Tuning Observation Build

Quest Chronicle now includes an opt-in local observation workflow for the first curated Traveler tuning batch.

- Adds `/qc traveler tuning start|status|stop|export|clear confirm`.
- Aggregates completed Traveler actions by stable visual identity, preferring `visualID` and falling back to `sourceID` or `itemID`.
- Tracks selection frequency, anchor/support use, Phase D repair targets and replacements, palette-overflow targets, loud zero-echo incidents, severe outliers, and worst-outlier observations across contexts.
- Records compact dominant palette, finish, confidence, context, and report-ID evidence without copying the audit into normal immutable Debug reports.
- Deduplicates linked weapon hands so one visual block does not inflate selection frequency.
- Keeps the audit local, opt-in, bounded to 300 visual identities, and separate from Courier export.
- Opens a copyable Markdown audit through the Debug Workbench without inserting a synthetic diagnostic report.
- Requires explicit confirmation before clearing the collected batch.
- Failure-isolates audit collection so an observation error cannot block Debug History or a completed generation report.
- Reconciles support-slot rerolls entirely from the current live outfit and reused profile, preventing stale parent-report budget totals from falsely aborting an otherwise valid reroll.
- Adds no curated descriptor overrides yet and preserves v1.9.0.14 selections, scores, Phase D repairs, routes, scheduler behavior, cache formats, and report snapshots.

This alpha is the observation build. Validate the audit controls, then collect at least 20 completed Traveler actions before descriptor corrections are reviewed for v1.9.0.15a2.

Follow `docs/testing/V19015A1_LIVE_VALIDATION_STEPS.md` for the streamlined Retail validation and collection sequence.
