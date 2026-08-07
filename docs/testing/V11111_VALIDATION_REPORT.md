# Quest Chronicle v1.11.11 Validation Report

## Status

Package-ready for Retail validation. Not yet live-validated.

## Automated gate

- Lua regressions: 121 / 121 PASS
- Python verifiers: 39 / 39 PASS
- Runtime Lua syntax: 158 / 158 PASS
- TOC runtime modules: 158 unique, exactly once
- Runtime Lua files >=500 lines: 0

## Synthetic closure evidence

Anchor worst-case fixture:

- largest pure candidate subphase: 2.20 ms;
- largest synthetic API subphase: 1.40 ms;
- simulated warm worker slice: 5.85 ms;
- maximum slice debt: 0.35 ms;
- post-expensive continuations: 0.

Support bridge worst-case fixture:

- 768 candidate evaluations;
- largest bridge microphase: 0.75 ms;
- prepared descriptor fallbacks: 0;
- fallback tie semantics preserved.

## Runtime boundary from v1.11.10

- inherited runtime modules: 153;
- byte-identical inherited modules: 139;
- changed existing modules: 14;
- new runtime modules: 5;
- removed runtime modules: 0;
- final runtime modules: 158.

The exact ZIP must pass this same wall after fresh extraction before handoff.
