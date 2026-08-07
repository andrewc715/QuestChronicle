from pathlib import Path
root = Path(__file__).resolve().parents[1]
checks = {
    "candidate state machine module": (root / "Core/ZoneStyle/EraCandidateWork.lua", "StepEraCandidateResolutionWork"),
    "candidate operation descriptor": (root / "Core/ZoneStyle/EraCandidateWork.lua", "DescribeNextEraCandidateOperation"),
    "fresh SET_LIST": (root / "Core/ZoneStyle/EraCandidateWork.lua", 'stage == "SET_LIST"'),
    "fresh TRACKING": (root / "Core/ZoneStyle/EraCandidateWork.lua", 'stage == "TRACKING"'),
    "fresh ENCOUNTER_LIST": (root / "Core/ZoneStyle/EraCandidateWork.lua", 'stage == "ENCOUNTER_LIST"'),
    "fresh ITEM_METADATA": (root / "Core/ZoneStyle/EraCandidateWork.lua", 'stage == "ITEM_METADATA"'),
    "stable fragment cache": (root / "Core/ZoneStyle/EraCandidateWork.lua", "eraCandidateFragmentCache"),
    "pending fragment exclusion": (root / "Core/ZoneStyle/EraCandidateWork.lua", "work.candidatePending or work.trackingPending or work.itemPending"),
    "nested aggregate work": (root / "Core/ZoneStyle/EraEvidence.lua", "work.candidateWork"),
    "separate aggregate finalization": (root / "Core/ZoneStyle/EraEvidence.lua", '"AGGREGATE_FINALIZE"'),
    "support reroll fresh admission": (root / "Core/Wardrobe/SupportRerollScheduling.lua", "CanStartFreshSupportRerollPhase"),
    "pending resolver bounded stepping": (root / "Core/Wardrobe/PendingEvidenceResolver.lua", "StepSourceEraEvidenceWork"),
    "era performance snapshot": (root / "Core/Wardrobe/GenerationPerformance.lua", "eraScheduling"),
    "era formatter": (root / "Core/Diagnostics/EraPerformanceFormatter.lua", "Largest era subphase"),
    "adaptive mandatory core": (root / "Core/Diagnostics/ReportCompaction.lua", "core.eraScheduling"),
    "adaptive emergency core": (root / "Core/Diagnostics/ReportEmergencyStub.lua", "CompactEraScheduling"),
    "format-4 additive export": (root / "Core/ZoneStyle/Zone/DebugExport.lua", "Largest era subphase"),
    "item invalidation": (root / "Core/Wardrobe/AppearanceMetadata.lua", "InvalidateEraCandidateFragmentsForItem"),
    "manifest invalidation": (root / "Core/Wardrobe/AppearanceMetadata.lua", "ClearEraCandidateFragmentCache"),
}
for label, (path, token) in checks.items():
    text = path.read_text(encoding="utf-8")
    assert token in text, f"missing {label}: {token}"

# Every cooperative generation caller must record the bounded era operation rather than
# hiding it behind a monolithic timing bucket.
for rel in [
    "Core/Wardrobe/GenerationWorker.lua",
    "Core/Wardrobe/AnchorSkeletonWorker.lua",
    "Core/Wardrobe/SupportWorker.lua",
    "Core/Wardrobe/SupportRerollScoring.lua",
]:
    text = (root / rel).read_text(encoding="utf-8")
    assert "StepSourceEraEvidenceWork" in text, f"{rel} lost cooperative era stepping"
    assert "RecordEraSchedulingOperation" in text, f"{rel} does not record era operation timing"
    create_at = text.find("CreateSourceEraEvidenceWork")
    sync_at = text.find("GetSourceEraEvidence")
    assert create_at >= 0 and (sync_at < 0 or create_at < sync_at), f"{rel} does not prefer cooperative era work"

# Frozen budgets and formats.
assert "5.5, 7.5" in (root / "Core/Wardrobe/GenerationScheduling.lua").read_text(encoding="utf-8")
assert "W.EXPENSIVE_CALL_MS = 2.0" in (root / "Core/Workers/SliceBudget.lua").read_text(encoding="utf-8")
era = (root / "Core/ZoneStyle/EraEvidence.lua").read_text(encoding="utf-8")
assert "P.ERA_EVIDENCE_VERSION = 2" in era and "P.ERA_MANIFEST_VERSION = 3" in era
export = (root / "Core/ZoneStyle/Zone/DebugExport.lua").read_text(encoding="utf-8")
assert "Zone debug export format" in export and "DEBUG_EXPORT_FORMAT = 4" in export

toc = (root / "QuestChronicle.toc").read_text(encoding="utf-8")
assert toc.count("Core\\ZoneStyle\\EraCandidateWork.lua") == 1
assert toc.count("Core\\Diagnostics\\EraPerformanceFormatter.lua") == 1
print(f"PASS v1.11.10 era scheduling verification: {len(checks) + 4*3 + 6} checks")
