# Quest Chronicle v1.9.0a Traveler Cohesion Instrumentation Test

1. Install v1.9.0a over the validated v1.8.5 build and `/reload`.
2. Confirm the Status page reports version `1.9.0a`.
3. Generate several Traveler outfits and confirm generation still behaves like v1.8.5.
4. Run `/qc traveler debug` after each outfit.
5. Confirm the output lists:
   - current outfit name and mode
   - profile palette, material, finish, motif, and visual weight
   - anchor cohesion
   - mean existing Traveler score
   - mismatch budget usage
   - every selected piece with cohesion, loudness, echo support, and mismatch class
6. Confirm an obviously isolated loud piece is reported as `POSTAL` or `STRONG`, but remains selected.
7. Confirm a weathered off-piece with a material or palette bridge is reported as `MILD` rather than rejected.
8. Confirm linked and unlinked weapon generation remains unchanged.
9. Confirm Zone, Class, and Chronicle Echo generation remains unchanged.
10. Confirm appearance metadata continues to hydrate live without a click.
