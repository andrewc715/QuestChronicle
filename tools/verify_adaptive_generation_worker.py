#!/usr/bin/env python3
"""Guard the time-first generation scheduler and cooperative era resolver."""

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
worker = (ROOT / "Core" / "Wardrobe" / "GenerationWorker.lua").read_text(encoding="utf-8")
era = (ROOT / "Core" / "ZoneStyle" / "EraEvidence.lua").read_text(encoding="utf-8")
scoring = (ROOT / "Core" / "ZoneStyle" / "Scoring.lua").read_text(encoding="utf-8")
eligibility_work = (ROOT / "Core" / "ZoneStyle" / "EligibilityWork.lua").read_text(encoding="utf-8")
toc = (ROOT / "QuestChronicle.toc").read_text(encoding="utf-8")

checks = {
    "old rigid candidate batch removed": "GENERATION_CANDIDATE_BATCH" not in worker,
    "time budget retained": "GENERATION_TIME_BUDGET_MS = 2.5" in worker,
    "runaway safety cap present": "GENERATION_OPERATION_SAFETY_CAP" in worker,
    "time checked after operations": "WorkerShouldYield" in worker and "BeginWorkerSlice" in worker,
    "era evidence has resumable work": "function ZoneStyle.CreateSourceEraEvidenceWork" in era,
    "era evidence steps sibling sources": "function ZoneStyle.StepSourceEraEvidenceWork" in era,
    "generation uses cooperative era work": "StepSourceEraEvidenceWork" in worker,
    "eligibility accepts precomputed era evidence": "resolvedEraEvidence" in eligibility_work,
    "scoring accepts precomputed coherence": "coherenceScore, coherent, coherenceReason" in scoring,
    "performance module loads before worker": toc.index("GenerationPerformance.lua") < toc.index("GenerationWorker.lua"),
}

failed = [name for name, passed in checks.items() if not passed]
if failed:
    print("FAIL: adaptive cooperative generation guard failed:")
    for name in failed:
        print(f"  - {name}")
    sys.exit(1)

print("PASS: adaptive time-first generation and resumable era evidence are wired correctly.")
