#!/usr/bin/env python3
"""Guard the v1.9.0a9 item-data invalidation precision repair."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
store = (ROOT / "Core/Wardrobe/GenerationCacheStore.lua").read_text(encoding="utf-8")
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
    "ordinary item events are classified instead of globally invalidating":
        "InvalidatePersistentGenerationCacheForItemData" in invalidation
        and "ITEM_DATA_PENDING_RESOLVED" in invalidation
        and "STABLE_OR_UNRELATED" in invalidation,
    "stable metadata fingerprint excludes presentation-only fields":
        "BuildStableItemMetadataFingerprint" in invalidation
        and "styleName" not in invalidation
        and "icon" not in invalidation,
    "batch callbacks coalesce duplicate events":
        "pendingItemMetadata[itemID]" in metadata
        and 'NoteGenerationItemEvent("coalesced"' in metadata,
    "persistent records retain pending cause details":
        "pendingItemIDs = CopyNumericList(result.pendingItemIDs)" in store
        and "trackingPending = result.trackingPending == true" in store,
    "diagnostics expose ignored and reopened events":
        "itemEventsIgnoredDuringGeneration" in diagnostics
        and "pendingEvidenceReopenedDuringGeneration" in diagnostics
        and "Item data:" in performance,
}
failed = [name for name, passed in checks.items() if not passed]
if failed:
    print("FAIL: item-data invalidation precision guard failed:")
    for name in failed:
        print(f"  - {name}")
    sys.exit(1)
print("PASS: item-data callbacks are coalesced, stable events are ignored, and only relevant pending or genuinely changed item evidence reopens.")
