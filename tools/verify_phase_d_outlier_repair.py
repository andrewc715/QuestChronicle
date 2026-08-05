from pathlib import Path

root = Path(__file__).resolve().parents[1]
required = {
    "Core/ZoneStyle/Traveler/MismatchAnalysis.lua": ["GetTravelerOutlierSeverity", "ClassifyTravelerMismatch"],
    "Core/Wardrobe/SupportFinalValidation.lua": ["SUPPORT_FINAL_MISMATCH_BUDGET = 2.00", "SUPPORT_FINAL_SEVERITY_THRESHOLD = 0.72", "SUPPORT_FINAL_PALETTE_LIMIT = 3", "ValidateSupportConfiguration"],
    "Core/Wardrobe/SupportRepair.lua": ["SUPPORT_FINAL_REPAIR_LIMIT", "supportRepairPass1", "supportRepairPass2", 'return "ALTERNATE"'],
    "Core/Wardrobe/SupportWorker.lua": ["CreateSupportFinalizationWork", "StepSupportFinalization"],
    "Core/Wardrobe/GenerationWorker.lua": ["ApplyNextAnchorSkeleton", "supportAlternateSkeleton"],
    "Core/Wardrobe/SupportRerollWorker.lua": ["FINAL_VALIDATE", "FINAL_ALTERNATE"],
    "Core/Diagnostics/SupportSnapshot.lua": ["phaseDInitial", "phaseDFinal", "repairPasses"],
    "Core/Diagnostics/SupportReportFormatter.lua": ["Final validation:", "Repair pass %d"],
}
for relative, needles in required.items():
    text = (root / relative).read_text(encoding="utf-8")
    for needle in needles:
        assert needle in text, f"{relative} is missing {needle!r}"

toc = (root / "QuestChronicle.toc").read_text(encoding="utf-8")
for module in [
    "Core\\ZoneStyle\\Traveler\\MismatchAnalysis.lua",
    "Core\\Wardrobe\\SupportFinalValidation.lua",
    "Core\\Wardrobe\\SupportRepair.lua",
    "Core\\Wardrobe\\SupportRerollFinalValidation.lua",
]:
    assert toc.count(module) == 1, f"TOC must contain {module} exactly once"

repair = (root / "Core/Wardrobe/SupportRepair.lua").read_text(encoding="utf-8")
assert "math.random" not in repair, "Phase D repair must be deterministic"
assert "GetSlotSources" not in repair, "Phase D repair must reuse prepared pools"
assert "GetSourceEligibility" not in repair, "Phase D repair must not repeat eligibility"

print("PASS: Phase D final validation, bounded repair, alternate skeleton, reroll isolation, and diagnostics are wired.")
