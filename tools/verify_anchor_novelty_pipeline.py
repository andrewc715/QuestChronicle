#!/usr/bin/env python3
"""Static guard for the v1.9.0.7 anchor-novelty and diagnostic-correction pipeline."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

def fail(message: str) -> None:
    print(f"FAIL: {message}")
    raise SystemExit(1)

toc = (ROOT / "QuestChronicle.toc").read_text(encoding="utf-8")
novelty = (ROOT / "Core/Wardrobe/AnchorSkeletonNovelty.lua").read_text(encoding="utf-8")
search = (ROOT / "Core/Wardrobe/AnchorSkeletonSearch.lua").read_text(encoding="utf-8")
worker = (ROOT / "Core/Wardrobe/AnchorSkeletonWorker.lua").read_text(encoding="utf-8")
snapshot = (ROOT / "Core/Diagnostics/SnapshotBuilder.lua").read_text(encoding="utf-8")
comparison = (ROOT / "Core/Diagnostics/Comparison.lua").read_text(encoding="utf-8")
formatter = (ROOT / "Core/Diagnostics/ReportFormatter.lua").read_text(encoding="utf-8")
performance = (ROOT / "Core/Wardrobe/GenerationPerformance.lua").read_text(encoding="utf-8")

cache_pos = toc.find(r"Core\Wardrobe\AnchorSkeletonCache.lua")
novelty_pos = toc.find(r"Core\Wardrobe\AnchorSkeletonNovelty.lua")
search_pos = toc.find(r"Core\Wardrobe\AnchorSkeletonSearch.lua")
if not (0 <= cache_pos < novelty_pos < search_pos):
    fail("AnchorSkeletonNovelty.lua must load after the cache and before the search engine")

for token in (
    "P.ANCHOR_REPEAT_PENALTIES",
    "function P.BuildAnchorNoveltyContext",
    "function P.EvaluateAnchorNovelty",
    'MEANINGFULLY_NEW',
    'PARTIAL_CHANGE',
    'EXACT_REPEAT',
):
    if token not in novelty:
        fail(f"missing novelty contract: {token}")

for token in (
    'options.action == "GENERATE_OUTFIT"',
    "P.ANCHOR_FINAL_SCORE_WINDOW",
    "choice.novelty.classPriority",
    "exactRepeatReason",
):
    if token not in search:
        fail(f"final selection is missing: {token}")

for token in (
    "currentAnchorNovelty",
    "baseSkeletonScore",
    "adjustedSelectionScore",
    "repeatPenalty",
    "noveltyClass",
):
    if token not in worker:
        fail(f"worker does not preserve novelty diagnostics: {token}")

for token in ('return "Main Hand"', "longestWorkerSliceMs", "largestInstrumentedCallMs"):
    if token not in snapshot: fail(f"snapshot correction missing: {token}")
if "previous.skeleton.baseSkeletonScore" not in comparison or "parentCompletedReportID" not in comparison:
    fail("immutable parent comparison is not wired")

for token in (
    "Longest worker slice",
    "Largest instrumented call",
    "Adjusted selection score",
    "Exact repeat accepted",
):
    if token not in formatter:
        fail(f"report correction missing: {token}")

if "worker slice" not in performance or "largest call" not in performance:
    fail("compact performance status does not distinguish worker slices from calls")

print("PASS: anchor novelty selection, immutable scoring, physical hand labels, and timing terminology are wired in load order.")
