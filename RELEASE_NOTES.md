# Quest Chronicle v1.11.0

## Zone context and evidence foundation

Quest Chronicle v1.11.0 begins the Zone implementation train with a deterministic, immutable, versioned context and evidence model. Zone Native selection remains unchanged behind its existing legacy generator.

### Runtime identity

```text
Traveler        SHARED_FRAMEWORK
Zone Native     LEGACY • CONTEXT_EVIDENCE_V1
Class Fantasy   LEGACY
Chronicle Echo  LEGACY
```

### Zone registries

- Migrates all 25 broad style profiles into a validated ordered registry.
- Migrates all 134 provenance and local source-pool profiles into a separate validated registry.
- Migrates all 30 deterministic starting-zone cases into a validated registry.
- Preserves exact keys, labels, seeds, aliases, keyword order, avoid lists, descriptions, origins, expansion bounds, and starting-zone fields.
- Preserves legacy precedence where aliases overlap across different profiles.

### Immutable Zone Context Snapshot

- Captures map ID, map name, zone, subzone, parent-map trail, normalized identity, and stable zone keys.
- Resolves broad style identity, expansion ceiling, local provenance, restrictions, favorites and exclusions scope, and explicit fallback state.
- Records deterministic evidence ancestry, resolution level, confidence, registry versions, and a stable fingerprint.
- Separates broad visual identity from local source provenance.
- Keeps missing evidence visible through explicit coverage states rather than manufacturing neutral evidence.
- Uses a session-only cache and returns primitive copies so consumers cannot mutate cached state.

### Canonical Zone evidence

Each broad profile now exposes explicit observational channels for:

```text
culture • climate • terrain • palette • material
finish • motif • magic • silhouette • avoids
```

These channels are diagnostic only in v1.11.0. The legacy generator does not read them.

### Diagnostics

- Adds `/qc zone debug` for location facts, profile resolution, era, provenance, restrictions, fallback, evidence coverage, selected-look affinity, registry counts, and bounded evidence ancestry.
- Adds read-only descriptor-based Zone affinity for already selected visible pieces.
- Adds compact Zone foundation sections to immutable Debug History reports.
- Adds `Zone foundation: CONTEXT_EVIDENCE_V1` without falsely promoting Zone Native to the shared framework.

### Selection neutrality and compatibility

- Preserves every v1.10.0 Zone context field through a compatibility compiler.
- Preserves Zone Native candidate weights, eligibility, random consumption, independent slot selection, outfit coherence, weapon generation, suggestions, favorites, exclusions, locks, and hidden slots.
- Preserves Traveler, Class Fantasy, and Chronicle Echo behavior.
- Adds no SavedVariables migration, cache reset, wardrobe rescan, UI redesign, or Courier change.

### Deferred to later v1.11.x releases

- Zone anchor policy and descriptor-driven candidate relevance.
- Shared-framework Zone anchor search.
- Zone contextual support, mismatch budgeting, final validation, repair, rerolls, tuning, and promotion.
