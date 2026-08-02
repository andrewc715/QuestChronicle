# Quest Chronicle v1.9.0a9 - Precise Item-Data Invalidation

v1.9.0a9 is a focused cache-invalidation repair built from the live-validated v1.9.0a8 persistent-cache baseline. Retail testing confirmed that v1.9.0a8 preserved thousands of era and eligibility records across `/reload`, but ordinary `ITEM_DATA_LOAD_RESULT` and `GET_ITEM_INFO_RECEIVED` traffic still invalidated roughly 1,700 records during every generation.

## Relevant pending-item tracking

- Era evidence now records the exact item IDs that were unavailable when a visual entered the `PENDING` state.
- Tracking-only pending evidence is distinguished from item-data pending evidence.
- An item-data callback reopens evidence only when that exact pending item has become available.
- Unknown evidence remains fail-closed under its existing six-hour expiry instead of being reopened by unrelated callbacks.
- Existing v1.9.0a8 records without pending-item details remain compatible and continue to use the existing pending retry window.

## Stable metadata identity

- Adds a compact generation-relevant item fingerprint using item ID, expansion, item type, subtype, equip location, class, and subclass.
- Presentation-only hydration such as names, links, icons, and quality no longer masquerades as a generation-identity change.
- Item-derived era evidence is invalidated when its genuine metadata identity changes.
- Set, tracking, encounter, and curated evidence survive unrelated representative-item metadata changes.

## Event coalescing and targeted refresh

- Duplicate callbacks for the same item are coalesced inside the existing metadata batch.
- Multiple callbacks affecting one visual stop after the first relevant reopening.
- Stable callbacks no longer clear local era, eligibility, or precheck fields.
- UI metadata notifications are emitted only when the representative appearance row actually changed.
- Era-independent prechecks survive item-data reopening.

## Diagnostics

The Generation Performance tooltip now reports:

```text
Item data: <stable ignored> • <pending reopened> • <identity changes> • <coalesced>
```

Exact invalidation reasons distinguish `ITEM_DATA_PENDING_RESOLVED` from `ITEM_METADATA_IDENTITY_CHANGED`.

## Preserved behavior

- Persistent cache format remains backward-compatible; no cache reset is required.
- Cooperative armor generation, cooperative weapon routing, weighted selection, locks, hidden slots, linked hands, artifacts, atomic commits, and targeted UI refreshes are unchanged.
- Traveler cohesion remains calibrated instrumentation only.
- SavedVariables schema 2, Courier format 1, and wardrobe cache format 7 remain unchanged.
- Quest Chronicle still applies no transmog and spends no gold.
