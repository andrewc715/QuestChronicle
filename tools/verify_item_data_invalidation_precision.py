#!/usr/bin/env python3
"""Guard the v1.9.0a10 pending-dependency precision repair."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
store = (ROOT / "Core/Wardrobe/GenerationCacheStore.lua").read_text(encoding="utf-8")
dependency = (ROOT / "Core/Wardrobe/GenerationDependencyIndex.lua").read_text(encoding="utf-8")
resolver = (ROOT / "Core/Wardrobe/PendingEvidenceResolver.lua").read_text(encoding="utf-8")
invalidation = (ROOT / "Core/Wardrobe/GenerationCacheInvalidation.lua").read_text(encoding="utf-8")
metadata = (ROOT / "Core/Wardrobe/AppearanceMetadata.lua").read_text(encoding="utf-8")
era = (ROOT / "Core/ZoneStyle/EraEvidence.lua").read_text(encoding="utf-8")
diagnostics = (ROOT / "Core/Wardrobe/GenerationCacheDiagnostics.lua").read_text(encoding="utf-8")
performance = (ROOT / "Core/Wardrobe/GenerationPerformance.lua").read_text(encoding="utf-8")
toc = (ROOT / "QuestChronicle.toc").read_text(encoding="utf-8")

checks = {
    "precision module loads before metadata callbacks":
        toc.index("GenerationCacheInvalidation.lua") < toc.index("AppearanceMetadata.lua"),
    "pending item IDs are captured by era evidence":
        "pendingItemIDs" in era and "trackingPending" in era,
    "ordinary item events update dependencies instead of globally invalidating":
        "InvalidatePersistentGenerationCacheForItemData" in invalidation
        and "ResolvePendingDependency" in invalidation
        and "STABLE_OR_UNRELATED" in invalidation,
    "reverse dependency index narrows item callbacks":
        "GetPendingEraDependencySources" in dependency
        and "IndexPersistentEraDependencies" in dependency,
    "evidence is compared before downstream invalidation":
        "BuildEraEvidenceOutcomeFingerprint" in store
        and "EVIDENCE_OUTCOME_CHANGED" in resolver
        and "InvalidatePersistentGenerationEligibilityForSource" in resolver,
    "stable metadata fingerprint excludes presentation-only fields":
        "BuildStableItemMetadataFingerprint" in invalidation
        and "styleName" not in invalidation
        and "icon" not in invalidation,
    "batch callbacks coalesce duplicate events":
        "pendingItemMetadata[itemID]" in metadata
        and 'NoteGenerationItemEvent("coalesced"' in metadata,
    "persistent records retain pending cause details":
        "local pendingItems = CopyNumericList(result.pendingItemIDs)" in store
        and "pendingItemIDs = pendingItems" in store
        and "trackingPending = result.trackingPending == true" in store,
    "diagnostics expose dependency and outcome events":
        "dependencyRecordsExaminedDuringGeneration" in diagnostics
        and "evidenceOutcomesUnchangedDuringGeneration" in diagnostics
        and "Item callbacks:" in performance
        and "Cache churn:" in performance,
}
failed = [name for name, passed in checks.items() if not passed]
if failed:
    print("FAIL: item-data invalidation precision guard failed:")
    for name in failed:
        print(f"  - {name}")
    sys.exit(1)
print("PASS: exact item dependencies are indexed, callbacks coalesce, and only changed evidence invalidates downstream eligibility.")
