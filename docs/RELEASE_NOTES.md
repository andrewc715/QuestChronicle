# Quest Chronicle v1.11.10

## Productive cooperative scheduling closure

- Replaced unconditional era fresh-frame admission with demand-aware local and API-headroom admission.
- Prevented cached and local era stages from consuming scheduler frames when no API boundary will be crossed.
- Added explicit API admission, headroom-deferral, fresh-only-deferral, phantom-deferral, and cache-completion diagnostics.
- Added resumable contextual-support candidate scoring with bounded neighbor, bridge, budget, and finalize substeps.
- Prevented partial support-candidate work from mutating beam state before a complete decision exists.
- Preserved the v1.11.9 watchdog execution boundary, synchronous forward-progress guard, scoring semantics, random order, fallback ties, and all persistent formats.
- Added end-to-end Retail latency gates in addition to existing worker-slice gates.

No Zone scoring coefficient, evidence precedence, support score, budget, beam-width, random-consumption, weapon-route, Phase D, SavedVariables, diagnostic-format, or Zone-export-format changes are included.
