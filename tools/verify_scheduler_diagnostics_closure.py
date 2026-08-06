#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
read = lambda rel: (root / rel).read_text(encoding="utf-8")
toc = read("QuestChronicle.toc")
version = read("VERSION.txt").strip()
slice_budget = read("Core/Workers/SliceBudget.lua")
adaptive = read("Core/Workers/AdaptiveBatch.lua")
setup = read("Core/Wardrobe/GenerationSetupWorker.lua")
generation = read("Core/Wardrobe/GenerationWorker.lua")
reroll = read("Core/Wardrobe/SupportRerollWorker.lua")
cache_diag = read("Core/Wardrobe/GenerationCacheDiagnostics.lua")
cache_counters = read("Core/Wardrobe/GenerationCacheCounters.lua")
index = read("Core/Wardrobe/WeaponCandidateIndex.lua")
performance = read("Core/Wardrobe/GenerationPerformance.lua")
formatter = read("Core/Diagnostics/ReportFormatter.lua")

checks = {
    "v1.11.6 metadata": version == "1.11.6" and "## Version: 1.11.6" in toc,
    "scheduler modules loaded": all(x in toc for x in (
        r"Core\Workers\SliceBudget.lua", r"Core\Workers\AdaptiveBatch.lua",
        r"Core\Wardrobe\GenerationScheduling.lua", r"Core\Wardrobe\GenerationSetupWorker.lua",
        r"Core\Wardrobe\GenerationCacheCounters.lua")),
    "expensive calls force yield": "slice.forceYield = true" in slice_budget and "EXPENSIVE_CALL_MS = 2.0" in slice_budget,
    "phase reservations are enforced": "CanStartPhase" in slice_budget and "preventedTransitions" in slice_budget,
    "adaptive fast lane reaches 32": "local OPTIONS = { 1, 2, 4, 8, 16, 32 }" in adaptive,
    "full setup is decomposed": all(x in setup for x in (
        "generationActionIdentity", "generationStateSnapshot", "generationModeContext",
        "generationEligibilityContext", "generationNoveltyReference", "generationCacheScalarSnapshot")),
    "monolithic setup removed": 'RecordPhase(job, "setup"' not in generation and '"Setup"' not in setup,
    "cache counters are incremental": "AdjustGenerationCacheCountLedger" in cache_counters,
    "cache diagnostics use scalar snapshot": "GetScalarSnapshot" in cache_diag and "GetGenerationCacheScalarSnapshot" in cache_diag and "GetGenerationCacheCountLedger" in cache_counters,
    "old reroll cache aggregation removed": "rerollCacheSummaryFoundation" not in reroll,
    "reroll uses scalar cache phase": "rerollCacheScalarSnapshot" in reroll,
    "weapon index has per-action states": all(x in index for x in (
        "stateBefore", "stateAfter", "bucketsBuilt", "bucketsRepaired", "bucketsReused",
        "examinedThisAction", "yieldsThisAction")),
    "weapon invalidation is canonical": all(x in index for x in (
        "LOGIN_SESSION_RESET", "ELIGIBILITY_OUTCOME_CHANGED", "FORMAT_MISMATCH", "UNKNOWN")),
    "diagnostics expose scheduler and action index": "schedulerDiagnostics" in performance and "stateBefore" in formatter,
    "runtime line limit preserved": all(len(path.read_text(encoding="utf-8").splitlines()) < 500
        for directory in (root / "Core", root / "UI") for path in directory.rglob("*.lua")),
}
failed = [name for name, ok in checks.items() if not ok]
if failed:
    for name in failed: print("FAIL:", name)
    raise SystemExit(1)
print(f"PASS: v1.11.6 scheduler and diagnostics closure verification: {len(checks)} checks")
