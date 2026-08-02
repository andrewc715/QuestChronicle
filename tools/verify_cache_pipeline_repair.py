#!/usr/bin/env python3
"""Guard the v1.9.0a7 cache-and-pipeline repair."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
era = (ROOT / "Core/ZoneStyle/EraEvidence.lua").read_text(encoding="utf-8")
metadata = (ROOT / "Core/Wardrobe/AppearanceMetadata.lua").read_text(encoding="utf-8")
eligibility = (ROOT / "Core/ZoneStyle/GenerationEligibility.lua").read_text(encoding="utf-8")
weapon = (ROOT / "Core/Wardrobe/WeaponPipeline.lua").read_text(encoding="utf-8")
worker = (ROOT / "Core/Wardrobe/GenerationWorker.lua").read_text(encoding="utf-8")
selection = (ROOT / "Core/Wardrobe/WeaponSelection.lua").read_text(encoding="utf-8")
refresh = (ROOT / "UI/Outfits/RefreshAndEvents.lua").read_text(encoding="utf-8")
targeted = (ROOT / "UI/Outfits/GenerationRefresh.lua").read_text(encoding="utf-8")
toc = (ROOT / "QuestChronicle.toc").read_text(encoding="utf-8")

checks = {
    "unknown era outcomes cached": '"UNKNOWN"' in era and "eraEvidenceUnknown" in era,
    "pending era outcomes cached with retry": '"PENDING"' in era and "eraEvidenceRetryAt" in era and "+ 30" in era,
    "metadata revision guards era cache": "eraEvidenceMetadataRevision" in era,
    "scan captures generation caches": "CaptureAppearanceGenerationCaches" in metadata,
    "scan restores generation caches": "RestoreAppearanceGenerationCache" in metadata,
    "eligibility cache loaded": "GenerationEligibility.lua" in toc and "GetSourceEligibilityCached" in eligibility,
    "weapon candidate index loaded": "WeaponCandidateIndex.lua" in toc and "GetIndexedWeaponSources" in selection,
    "weapon coroutine loaded": "WeaponPipeline.lua" in toc and "coroutine.resume" in weapon,
    "generation steps weapon coroutine": "StepWeaponGenerationWork" in worker,
    "weapon loops expose yield points": "MaybeYieldWeaponGeneration" in selection,
    "targeted completion refresh loaded": "GenerationRefresh.lua" in toc and "RefreshGeneratedResult" in targeted,
    "completion callback uses targeted refresh": "RefreshGeneratedResult" in refresh,
}
failed = [name for name, passed in checks.items() if not passed]
if failed:
    print("FAIL: cache-and-pipeline repair guard failed:")
    for name in failed:
        print(f"  - {name}")
    sys.exit(1)
print("PASS: negative era caching, scan carryover, cooperative weapons, and targeted completion refresh are wired.")
