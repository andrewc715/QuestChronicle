#!/usr/bin/env python3
"""Verify independent, phase-aware cooperative-generation telemetry wiring."""

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
concepts = (ROOT / "UI" / "Outfits" / "ConceptManager.lua").read_text(encoding="utf-8")
browser = (ROOT / "UI" / "Outfits" / "AppearanceBrowser.lua").read_text(encoding="utf-8")
refresh = (ROOT / "UI" / "Outfits" / "RefreshAndEvents.lua").read_text(encoding="utf-8")
performance = (ROOT / "Core" / "Wardrobe" / "GenerationPerformance.lua").read_text(encoding="utf-8")

checks = {
    "dedicated performance font string": 'C.performanceText = C.sourcePanel:CreateFontString' in concepts,
    "persistent performance object": 'C.pane.generationPerformance = performance' in refresh,
    "persistent performance text": 'C.pane.generationPerformanceText' in refresh,
    "refresh renders independent performance line": 'C.performanceText:SetText(self.generationPerformanceText or "")' in refresh,
    "completion does not concatenate result message": 'Prepared across' not in refresh,
    "phase-aware formatter": 'function Wardrobe.FormatGenerationPerformance' in performance,
    "slowest phase shown": 'slowest %s %.1f ms' in performance,
    "preview application measured": 'RecordGenerationPostPhase(performance, "previewApply"' in refresh,
    "final UI refresh measured": 'RecordGenerationPostPhase(performance, "uiRefresh"' in refresh,
    "new generation clears prior measurement": 'C.pane.generationPerformance = nil' in refresh,
    "phase tooltip": 'Wardrobe.GetGenerationPerformanceDetails(performance)' in concepts,
    "appearance rows reserve performance-line space": 'row:SetPoint("TOP", C.sourcePanel, "TOP", 0, -166)' in browser,
}

failed = [name for name, passed in checks.items() if not passed]
if failed:
    print("FAIL: generation performance status wiring is incomplete:")
    for name in failed:
        print(f"  - {name}")
    sys.exit(1)

print("PASS: generation result and phase-aware performance status use independent persistent UI fields.")
