#!/usr/bin/env python3
"""Guard the cooperative anchor-skeleton generation pipeline in v1.9.0.7."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
toc = (ROOT / "QuestChronicle.toc").read_text(encoding="utf-8")
version = (ROOT / "VERSION.txt").read_text(encoding="utf-8").strip()
cache = (ROOT / "Core/Wardrobe/AnchorSkeletonCache.lua").read_text(encoding="utf-8")
search = (ROOT / "Core/Wardrobe/AnchorSkeletonSearch.lua").read_text(encoding="utf-8")
worker = (ROOT / "Core/Wardrobe/AnchorSkeletonWorker.lua").read_text(encoding="utf-8")
generation = (ROOT / "Core/Wardrobe/GenerationWorker.lua").read_text(encoding="utf-8")
performance = (ROOT / "Core/Wardrobe/GenerationPerformance.lua").read_text(encoding="utf-8")
concepts = (ROOT / "UI/Outfits/ConceptManager.lua").read_text(encoding="utf-8")
snapshots = (ROOT / "Core/Diagnostics/SnapshotBuilder.lua").read_text(encoding="utf-8")
commands = (ROOT / "Core/Chronicle/Commands.lua").read_text(encoding="utf-8")
foundation = (ROOT / "Core/Wardrobe/Foundation.lua").read_text(encoding="utf-8")

checks = {
    "version is v1.9.0.7": version == "1.9.0.7" and "## Version: 1.9.0.7" in toc,
    "anchor modules load in TOC": all(name in toc for name in (
        "AnchorSkeletonCache.lua", "AnchorSkeletonSearch.lua", "AnchorSkeletonWorker.lua")),
    "anchor slot order is explicit": 'P.ANCHOR_SLOT_ORDER = { "CHEST", "LEGS", "SHOULDER" }' in cache,
    "support slots are conditioned after anchors": "SUPPORTING_ARMOR_GENERATION_ORDER" in cache
        and "job.armorOrder = P.SUPPORTING_ARMOR_GENERATION_ORDER" in worker,
    "pair cohesion cache is bounded": "ANCHOR_PAIR_CACHE_LIMIT = 4096" in cache
        and "TrimPairCache" in cache,
    "beam search is bounded and quality-windowed": "ANCHOR_BEAM_WIDTH" in search
        and "ANCHOR_FINAL_SCORE_WINDOW" in search
        and "ChooseAnchorSkeleton" in search,
    "generation begins with anchor phase": 'phase = P.AdvanceAnchorGenerationPhase and "ANCHORS" or "ARMOR"' in generation
        and 'job.phase == "ANCHORS"' in generation,
    "weapon expansion reuses cooperative route engine": "CreateWeaponGenerationWork" in worker
        and "StepWeaponGenerationWork" in worker,
    "legacy fallback remains available": 'return "FALLBACK"' in worker
        and "job.armorOrder = P.ARMOR_GENERATION_ORDER" in worker,
    "locked unavailable anchors force fallback": "requiredMissing" in worker
        and "locked %s source is unavailable" in worker,
    "shoulders can be deliberately hidden": 'key = "SHOULDER"' in foundation
        and 'slotName = "SHOULDERSLOT", hideable = true' in foundation,
    "anchor diagnostics reach Debug snapshots": "GetAnchorSkeletonPerformanceLines" in performance
        and "anchorDiagnostics" in snapshots and "anchorStats" in snapshots
        and "Open the Debug tab" in concepts,
    "skeleton debug command is wired": "/qc skeleton debug" in commands
        and "PrintAnchorSkeletonDiagnostics" in commands,
}
failed = [name for name, passed in checks.items() if not passed]
if failed:
    print("FAIL: anchor-skeleton pipeline guard failed:")
    for name in failed:
        print(f"  - {name}")
    sys.exit(1)
print("PASS: anchor pools, bounded beam search, cooperative weapons, conditioned support slots, fallback, and diagnostics are wired.")
