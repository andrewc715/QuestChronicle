# Quest Chronicle v1.9.0.5 Stabilization Report

This release preserves v1.9.0.4 selection and scoring behavior while repairing three live-test findings:

1. Hidden and locked anchors now use explicit excluded comparison states.
2. Diagnostic reports reserve stable identities and immutable parent ancestry, with duplicate insertion protection.
3. Wardrobe scans prewarm weapon appearance and collected-source metadata so anchor finalists reuse cached validation instead of repeating synchronous collection queries.

Automated selection parity is required against v1.9.0.4 for the anchor beam, mode identity, novelty selection, legacy armor selection, and cooperative weapon route harnesses.
