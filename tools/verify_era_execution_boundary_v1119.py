#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]

def text(rel): return (ROOT / rel).read_text(encoding="utf-8")
def require(cond, msg):
    if not cond:
        raise SystemExit(f"FAIL: {msg}")

execution = text("Core/ZoneStyle/EraExecution.lua")
era = text("Core/ZoneStyle/EraEvidence.lua")
elig = text("Core/ZoneStyle/EligibilityWork.lua")
cached = text("Core/ZoneStyle/GenerationEligibility.lua")
weapon = text("Core/Wardrobe/WeaponStyleOrdering.lua")
toc = text("QuestChronicle.toc")

for mode in ("GENERATION_COOPERATIVE", "SUPPORT_REROLL_COOPERATIVE", "BACKGROUND_TICK", "SYNCHRONOUS"):
    require(mode in execution, f"missing explicit era execution mode {mode}")
require("schedulerOwner" in execution and "work.schedulerOwner" in execution, "era admission does not own its scheduler explicitly")
require("sameSliceDeferredRetries" in execution, "same-slice deferred retry instrumentation missing")
require("ERA_EXECUTION_SYNCHRONOUS" in era, "synchronous era getter does not select synchronous execution mode")
require("StepSourceEraEvidenceWork(work, 1000000)" not in era, "v1.11.11 million-step era drain survived")
require("progressSerial" in era and "AbortSynchronousEraWork" in era, "synchronous forward-progress guard missing")

constructor = cached[cached.index("function ZoneStyle.CreateCachedSourceEligibilityWork"):cached.index("function ZoneStyle.StepCachedSourceEligibilityWork")]
require("GetSourceEraEvidence" not in constructor, "cached eligibility constructor still resolves era evidence synchronously")
require('stage = evidence ~= nil and "CACHE_KEY" or "ERA_INIT"' in constructor, "cached eligibility does not defer missing era evidence to nested work")
require("CreateSourceEraEvidenceWork" in cached and 'status == "DEFERRED"' in cached, "cached eligibility does not propagate nested era deferral")
require("GetSourceEraEvidence" not in elig, "raw eligibility still calls synchronous era getter")
require('"ERA_INIT"' in elig and '"ERA_STEP"' in elig and '"ERA_APPLY"' in elig, "raw eligibility nested-era stages missing")
require("ERA_EXECUTION_GENERATION_COOPERATIVE" in weapon and "schedulerOwner = work.job" in weapon, "weapon style ordering does not pass explicit cooperative ownership")

for rel in [
    "Core/Wardrobe/GenerationWorker.lua",
    "Core/Wardrobe/AnchorSkeletonWorker.lua",
    "Core/Wardrobe/SupportWorker.lua",
]:
    body = text(rel)
    require("ERA_EXECUTION_GENERATION_COOPERATIVE" in body and "schedulerOwner = job" in body, f"{rel} lacks explicit generation era ownership")
    require("GetSourceEraEvidence(source)" not in body, f"{rel} retains synchronous generation-era fallback")
body = text("Core/Wardrobe/SupportRerollScoring.lua")
require("ERA_EXECUTION_SUPPORT_REROLL_COOPERATIVE" in body and "schedulerOwner = job" in body, "support reroll lacks explicit era ownership")
body = text("Core/Wardrobe/PendingEvidenceResolver.lua")
require("ERA_EXECUTION_BACKGROUND_TICK" in body, "background pending resolver lacks isolated execution mode")


performance = text("Core/Wardrobe/GenerationPerformance.lua")
formatter = text("Core/Diagnostics/EraPerformanceFormatter.lua")
exporter = text("Core/ZoneStyle/Zone/DebugExport.lua")
emergency = text("Core/Diagnostics/ReportEmergencyStub.lua")
for token in ("sameSliceDeferredRetries", "synchronousProgressGuardTrips", "deferredReturns", "executionMode"):
    require(token in performance, f"generation performance missing era boundary field {token}")
    require(token in emergency, f"emergency compaction drops era boundary field {token}")
require("Era execution boundary:" in formatter, "Debug History formatter omits era execution-boundary headline")
require("Era execution boundary:" in exporter, "Zone debug export omits era execution-boundary headline")

idx_exec = toc.index("Core\\ZoneStyle\\EraExecution.lua")
idx_era = toc.index("Core\\ZoneStyle\\EraEvidence.lua")
idx_candidate = toc.index("Core\\ZoneStyle\\EraCandidateWork.lua")
require(idx_exec < idx_era < idx_candidate, "TOC execution-contract order is invalid")

print("PASS v1.11.11 era execution boundary: explicit modes, nested eligibility, no eager synchronous getter, and no million-step drain")
