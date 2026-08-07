#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
read = lambda rel: (root / rel).read_text(encoding="utf-8")
toc = read("QuestChronicle.toc")
version = read("VERSION.txt").strip()
worker = read("Core/Wardrobe/SupportRerollWorker.lua")
scheduling = read("Core/Wardrobe/SupportRerollScheduling.lua")
scoring = read("Core/Wardrobe/SupportRerollScoring.lua")
eligibility = read("Core/ZoneStyle/GenerationEligibility.lua")
zone_scoring = read("Core/ZoneStyle/Scoring.lua")
eligibility_work = read("Core/ZoneStyle/EligibilityWork.lua")
index = read("Core/Wardrobe/WeaponCandidateIndex.lua")
pipeline = read("Core/Wardrobe/WeaponPipeline.lua")
generation = read("Core/Wardrobe/GenerationWorker.lua")
performance = read("Core/Wardrobe/GenerationPerformance.lua")
formatter = read("Core/Diagnostics/ReportFormatter.lua")

checks = {
    "v1.11.8 metadata": version == "1.11.8" and "## Version: 1.11.8" in toc,
    "shared worker helpers loaded": all(x in toc for x in (
        r"Core\Workers\SliceBudget.lua", r"Core\Workers\AdaptiveBatch.lua")),
    "support scheduling helper loaded": r"Core\Wardrobe\SupportRerollScheduling.lua" in toc,
    "support reroll uses shared elapsed guard": all(x in scheduling for x in (
        "BeginSlice", "ShouldYield", "GetAdaptiveBatchSize")),
    "full generation uses shared elapsed guard": "BeginWorkerSlice" in generation and "WorkerShouldYield" in generation,
    "monolithic diagnostic foundation removed": "rerollDiagnosticFoundation" not in worker,
    "diagnostic work decomposed": all(x in worker for x in (
        "rerollDiagnosticIdentity", "rerollAnchorSummary", "rerollStyleContextInit",
        "rerollStyleContextSeed", "rerollEligibilityContext",
        "rerollSupportSummaryFoundation", "rerollCacheScalarSnapshot")),
    "eligibility is resumable": all(x in eligibility_work for x in (
        "CreateSourceEligibilityWork", "StepSourceEligibilityWork", 'stage = "MARKERS"')),
    "cached eligibility is resumable": all(x in eligibility for x in (
        "CreateCachedSourceEligibilityWork", "StepCachedSourceEligibilityWork")),
    "support reroll consumes eligibility work": all(x in scoring for x in (
        "ELIGIBILITY_INIT", "ELIGIBILITY_STEP", "StepCachedSourceEligibilityWork")),
    "weapon index format is explicit": "P.WEAPON_INDEX_FORMAT = 1" in index,
    "weapon index builds cooperatively": "MaybeYieldWeaponGeneration" in index and '"weaponIndexBuild"' in index,
    "weapon index supports warm reuse": 'index.lastUse = "WARM_REUSE"' in index,
    "weapon index supports bucket repair": "repairingSubtypeKey" in index and "INCREMENTAL_REPAIR" in index,
    "weapon coroutine records exact yield phase": "slowestYieldPhase" in pipeline,
    "weapon index diagnostics are reported": "weaponIndex" in performance and "Weapon index:" in formatter,
    "candidate and finalist caps preserved": "P.SUPPORT_POOL_LIMIT" in scoring and "P.SUPPORT_FINAL_SHORTLIST" in scoring,
    "runtime line limit preserved": all(len(read(rel).splitlines()) < 500 for rel in (
        "Core/Wardrobe/SupportRerollWorker.lua", "Core/Wardrobe/SupportRerollScoring.lua",
        "Core/Wardrobe/WeaponCandidateIndex.lua", "Core/ZoneStyle/Scoring.lua",
        "Core/ZoneStyle/EligibilityWork.lua", "Core/ZoneStyle/GenerationEligibility.lua")),
}

failed = [name for name, ok in checks.items() if not ok]
if failed:
    for name in failed:
        print("FAIL:", name)
    raise SystemExit(1)
print(f"PASS: v1.11.8 Phase C performance closure verification: {len(checks)} checks")
