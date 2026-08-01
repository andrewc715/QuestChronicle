# Quest Chronicle v0.7.2: Promo-Free, Cohesive Outfits

Version 0.7.2 keeps generated outfits grounded in the current adventure while coordinating the pieces as a complete look.

## Promotional appearances never generate

Generate Outfit, Reroll Unlocked, and individual slot rerolls now apply a hard promotional gate before any style scoring or weapon validation.

- Blizzard's native Trading Post source type is always excluded.
- Legacy reward families that WoW stores without an acquisition source type are recognized by stable item and set metadata.
- The initial legacy catalog covers Renowned Explorer, Wooly Wendigo, Sprite Darter, Celestial Observer, Eternal Traveler, Fireplume, and the original store helms.
- Native transmog-set names, labels, and descriptions are checked for shop, subscription, promotion, or Recruit-a-Friend origins.

The full wardrobe browser remains intact. Promotional appearances can still be selected deliberately for a manual preview; their rows now say **Promo excluded** and their tooltip explains the generation-only restriction.

## Outfit coherence

Quest Chronicle now builds a style profile while it generates:

1. Locked visible selections establish the starting constraints.
2. Chest, shoulders, legs, and waist establish the major silhouette.
3. Head and smaller armor layers reinforce that foundation.
4. Weapons are chosen last and still must pass Blizzard's equipped-item, category, usability, class, display, source, and hand-slot rules.

Pieces from the same Blizzard transmog set receive the strongest match. When no native set relationship exists, shared material and magic motifs are favored. A dramatic fire, frost, shadow, radiant, arcane, storm, fel, or necrotic accent is rejected when it would become an isolated visual outlier or directly conflict with the established outfit.

Individual slot rerolls build their profile from the rest of the visible Character Preview. This keeps a rerolled helm, cloak, armor piece, or weapon aligned with the existing concept instead of treating the slot as an isolated random choice.

## Safety and compatibility

- A locked weapon incompatibility restores the previous preview instead of leaving a partially regenerated outfit.
- Wardrobe cache format 5 remains valid; no collection rescan is required.
- SavedVariables schema 2 is preserved.
- Courier format 1 and Courier v1.0.0 compatibility are preserved.
- Existing outfit concepts, selections, locks, hidden slots, style modes, and Current Look data remain compatible.
- Quest history, active quests, notes, drafts, settings, and Courier snapshots are unchanged.
- Preview only: no transmog is applied, no gold is spent, and no Blizzard outfit slot is changed.
