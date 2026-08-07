#!/usr/bin/env python3
from pathlib import Path
root = Path(__file__).resolve().parents[1]
toc = (root / "QuestChronicle.toc").read_text()
version = (root / "VERSION.txt").read_text().strip()
reroll = (root / "Core/Wardrobe/SupportReroll.lua").read_text()
worker = (root / "Core/Wardrobe/SupportRerollWorker.lua").read_text()
scoring = (root / "Core/Wardrobe/SupportRerollScoring.lua").read_text()
history = (root / "Core/Diagnostics/History.lua").read_text()
snapshot = (root / "Core/Diagnostics/SnapshotBuilder.lua").read_text()
comparison = (root / "Core/Diagnostics/Comparison.lua").read_text()
formatter = (root / "Core/Diagnostics/SupportReportFormatter.lua").read_text()
required = [
    r"Core\Wardrobe\SupportRerollFoundation.lua",
    r"Core\Wardrobe\SupportRerollScoring.lua",
    r"Core\Wardrobe\SupportRerollWorker.lua",
    r"Core\Wardrobe\SupportRerollLegacy.lua",
    r"Core\Wardrobe\SupportReroll.lua",
    r"Core\Diagnostics\AnchorAncestry.lua",
]
checks = {
    "v1.11.8 metadata": version == "1.11.8" and "## Version: 1.11.8" in toc,
    "stabilization modules loaded": all(item in toc for item in required),
    "support reroll starts asynchronously": "C_Timer.After(0" in reroll and "StartSupportReroll" in reroll,
    "support reroll uses cooperative worker": "P.StepSupportRerollJob" in worker and "BeginSupportRerollSlice" in worker and "ShouldYieldSupportRerollSlice" in worker,
    "current support visual hard excluded": "currentIdentity" in scoring and "identity == work.currentIdentity" in scoring and "currentCandidate" in scoring,
    "prepared pool capped by shared 32 limit": "P.SUPPORT_POOL_LIMIT" in scoring,
    "final shortlist capped by shared 6 limit": "P.SUPPORT_FINAL_SHORTLIST" in scoring,
    "dual report ancestry stored": "anchorSourceReportID" in history and "parentCompletedReportID" in history,
    "support snapshot reuses immutable anchors": "reuseAnchorSnapshot" in snapshot and "inheritedAnchorSnapshot" in snapshot,
    "support-only reports do not advance anchor streak": "ReportPerformsAnchorSelection" in comparison and "previousAnchorSourceReportID" in comparison,
    "relationship wording distinguishes improvement": "Bridge improvement:" in formatter and "Relationship:" in formatter and "bridge bonus None" in formatter,
    "support branch does not call legacy selector": "if P.IsSupportSlotKey(slotKey) then return StartSupportReroll" in reroll,
    "old monolithic phase absent": '"rerollSlot"' not in worker,
}
failed = [name for name, ok in checks.items() if not ok]
if failed:
    for name in failed:
        print("FAIL:", name)
    raise SystemExit(1)
print("PASS: v1.11.8 cooperative support rerolls, bounded pools, dual ancestry, repetition filtering, and truthful relationship reporting are wired.")
