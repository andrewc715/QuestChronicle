from pathlib import Path
root = Path(__file__).resolve().parents[1]
checks = {
    "support eligibility marker batch": (root / "Core/Wardrobe/SupportWorker.lua", "P.SUPPORT_ELIGIBILITY_MARKER_BATCH = 4"),
    "cooperative eligibility creation": (root / "Core/Wardrobe/SupportWorker.lua", "CreateCachedSourceEligibilityWork"),
    "cooperative eligibility step": (root / "Core/Wardrobe/SupportWorker.lua", "StepCachedSourceEligibilityWork"),
    "beam operation description": (root / "Core/Wardrobe/SupportBeam.lua", "DescribeNextSupportBeamOperation"),
    "resumable fallback state": (root / "Core/Wardrobe/SupportBeam.lua", "fallbackWork"),
    "fresh phase helper": (root / "Core/Wardrobe/GenerationScheduling.lua", "CanStartFreshGenerationPhase"),
    "fresh stage deferral": (root / "Core/Wardrobe/SupportWorker.lua", "supportBeamFreshSliceDeferrals"),
    "stage phase label": (root / "Core/Wardrobe/GenerationPerformance.lua", "supportBeamStageFinalize"),
    "performance snapshot": (root / "Core/Diagnostics/SnapshotBuilder.lua", "supportScheduling"),
    "mandatory compaction": (root / "Core/Diagnostics/ReportCompaction.lua", "core.supportScheduling"),
    "emergency compaction": (root / "Core/Diagnostics/ReportEmergencyStub.lua", "CompactSupportScheduling"),
    "format 4 export unchanged": (root / "Core/ZoneStyle/Zone/DebugExport.lua", "Zone debug export format"),
}
for label, (path, token) in checks.items():
    text = path.read_text(encoding="utf-8")
    assert token in text, f"missing {label}: {token}"
assert "5.5, 7.5" in (root / "Core/Wardrobe/GenerationScheduling.lua").read_text(encoding="utf-8")
assert "W.EXPENSIVE_CALL_MS = 2.0" in (root / "Core/Workers/SliceBudget.lua").read_text(encoding="utf-8")
print(f"PASS v1.11.9 support scheduling verification: {len(checks)+2} checks")
