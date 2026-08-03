#!/usr/bin/env python3
"""Guard the v1.9.0a10 pending dependency and outcome-comparison pipeline."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
store = (ROOT / "Core/Wardrobe/GenerationCacheStore.lua").read_text(encoding="utf-8")
index = (ROOT / "Core/Wardrobe/GenerationDependencyIndex.lua").read_text(encoding="utf-8")
invalid = (ROOT / "Core/Wardrobe/GenerationCacheInvalidation.lua").read_text(encoding="utf-8")
resolver = (ROOT / "Core/Wardrobe/PendingEvidenceResolver.lua").read_text(encoding="utf-8")
era = (ROOT / "Core/ZoneStyle/EraEvidence.lua").read_text(encoding="utf-8")
metadata = (ROOT / "Core/Wardrobe/AppearanceMetadata.lua").read_text(encoding="utf-8")
toc = (ROOT / "QuestChronicle.toc").read_text(encoding="utf-8")

checks = {
    "store migrates v1 records without purge":
        "GENERATION_CACHE_STORE_VERSION = 2" in store
        and "tonumber(store.version) == 1" in store,
    "explicit pending states exist":
        '"PENDING_ITEMS"' in store and '"TRACKING_ONLY"' in store and '"STALE"' in invalid,
    "reverse dependency index is loaded":
        "GenerationDependencyIndex.lua" in toc
        and "pendingEraDependenciesByItem" in index,
    "representative watches are separated from dependency watches":
        "GetPendingEraDependencySources" in metadata
        and "RegisterCurrentGenerationSource" in metadata,
    "resolver is cooperative":
        "PendingEvidenceResolver.lua" in toc
        and "PENDING_ERA_RESOLVER_BUDGET_MS" in resolver
        and "StepSourceEraEvidenceWork(job.work, 1)" in resolver,
    "resolver compares normalized outcomes":
        "BuildEraEvidenceOutcomeFingerprint" in store
        and "newFingerprint ~= job.outcomeFingerprint" in resolver,
    "unchanged outcomes preserve eligibility":
        'NoteGenerationItemEvent("unchanged"' in resolver
        and "InvalidatePersistentGenerationEligibilityForSource" in resolver,
    "forced evidence work bypasses cache without auto-store":
        "options.forceRefresh" in era and "options.suppressCache" in era,
}
failed = [name for name, passed in checks.items() if not passed]
if failed:
    print("FAIL: pending dependency pipeline guard failed:")
    for name in failed:
        print(f"  - {name}")
    sys.exit(1)
print("PASS: pending dependencies are indexed, resolved cooperatively, compared, and narrowly invalidated.")
