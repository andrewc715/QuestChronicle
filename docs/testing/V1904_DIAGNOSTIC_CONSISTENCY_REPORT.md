# v1.9.0.4 Diagnostic Consistency Report

The Debug snapshot now stores immutable:

```text
Base skeleton score
Repeat penalty
Adjusted selection score
Novelty class
Compared anchors
Changed anchors
Repeated anchors
Exact-repeat reason
```

Previous-run comparison reads these stored fields directly. It does not rescore historical appearances or inspect mutable generation context.

Weapon rows use physical **Main Hand** and **Off Hand** labels. Weapon subtype is separate metadata.

Performance terminology is split into:

```text
Longest worker slice
Largest instrumented call
Largest-call phase
```

`test_diagnostics_v194_consistency.lua` verifies immutable score comparison, physical hand labels, timing terminology, and continued readability of v1.9.0.3 diagnostic reports.
