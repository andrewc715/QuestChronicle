# Quest Chronicle v1.9.0.9 Profile-Integrity Report

## Scope

v1.9.0.9 repairs the intermittent Phase C state drift observed in v1.9.0.8, where a hidden Shoulder appearance could re-enter a support-only reroll profile even though the physical anchor snapshot remained hidden.

## Implementation

- Added `Core/Wardrobe/SupportProfileIdentity.lua` before profile derivation in the runtime TOC.
- Created one canonical logical mask for Chest, Legs, Shoulders, and the weapon bundle.
- Made explicit Hidden and Unavailable states override stored source and visual identities.
- Persisted stable Profile IDs, profile-source report IDs, mask signatures, aggregate descriptors, tolerance, confidence, cohesion, and relationship data.
- Reused immutable version-2 profiles for support-only rerolls when their mask matches the inherited anchor snapshot.
- Repaired legacy or malformed profiles exactly once with an explicit repair reason.
- Routed Head, Back, Waist, Hands, and other support relationship endpoints through the canonical profile mask.
- Reconstructed and validated the mismatch ledger on one profile basis before atomic commit.
- Split pre-worker preparation, cooperative execution, and commit/presentation timing domains.
- Omitted redundant per-entry descriptor copies from persistent profile snapshots while preserving immutable scoring inputs.

## Automated evidence

- Hidden-Shoulder drift simulation retained exactly three active anchors across repeated rerolls.
- The inherited Profile ID remained stable and Head used Chest alone rather than the hidden Shoulder.
- Legacy profile migration completed once and produced a valid canonical mask.
- Synthetic timing separated 7.1 ms of pre-worker preparation from a 2.9 ms cooperative worker slice.
- Maximum-detail persisted Phase C snapshot: 14,170 approximate bytes, below the 20,480-byte report limit.
- All 49 Lua regression harnesses passed.
- All 18 static verification tools passed.
- All 129 Lua files passed syntax validation.
- All 80 runtime Lua modules appear exactly once in the TOC.
