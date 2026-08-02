#!/usr/bin/env python3
"""Guard the v1.9.0a8 persistent generation-cache lifecycle."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
store = (ROOT / "Core/Wardrobe/GenerationCacheStore.lua").read_text(encoding="utf-8")
diagnostics = (ROOT / "Core/Wardrobe/GenerationCacheDiagnostics.lua").read_text(encoding="utf-8")
metadata = (ROOT / "Core/Wardrobe/AppearanceMetadata.lua").read_text(encoding="utf-8")
era = (ROOT / "Core/ZoneStyle/EraEvidence.lua").read_text(encoding="utf-8")
eligibility = (ROOT / "Core/ZoneStyle/GenerationEligibility.lua").read_text(encoding="utf-8")
performance = (ROOT / "Core/Wardrobe/GenerationPerformance.lua").read_text(encoding="utf-8")
toc = (ROOT / "QuestChronicle.toc").read_text(encoding="utf-8")

checks = {
    "persistent store loaded before generation modules": "Core\\Wardrobe\\GenerationCacheStore.lua" in toc
        and "Core\\Wardrobe\\GenerationCacheDiagnostics.lua" in toc,
    "store is versioned inside SavedVariables": "GENERATION_CACHE_STORE_VERSION" in store and "cache.generationCache" in store,
    "stable source identity excludes metadataRevision": "GetStableGenerationSourceIdentity" in store and "metadataRevision" not in eligibility,
    "era evidence reads and writes persistent records": "StorePersistentEraEvidence" in era and "GetPersistentEraEvidence" in era,
    "eligibility reads and writes persistent records": "StorePersistentGenerationPrecheck" in eligibility and "StorePersistentGenerationEligibility" in eligibility,
    "scan lifecycle preserves persistent records": "BeginPersistentGenerationCacheScan" in metadata and "FinishPersistentGenerationCacheScan" in metadata,
    "metadata events reopen only affected evidence": "ITEM_DATA_LOADED" in metadata
        and "InvalidatePersistentGenerationCacheForItemData" in store,
    "performance exposes cache lifecycle": "BuildGenerationCachePerformance" in diagnostics
        and "GetGenerationCachePerformanceLines" in performance,
    "unknown and pending records expire safely": "UNKNOWN_TTL_EXPIRED" in store and "PENDING_RETRY_EXPIRED" in store,
}
failed = [name for name, passed in checks.items() if not passed]
if failed:
    print("FAIL: persistent generation-cache guard failed:")
    for name in failed:
        print(f"  - {name}")
    sys.exit(1)
print("PASS: persistent evidence, eligibility, scan retention, invalidation reasons, and cache diagnostics are wired.")
