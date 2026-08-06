#!/usr/bin/env python3
"""Verify the complete v1.11.4 shared-generation extraction contract."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

def fail(message: str) -> None:
    print(f"FAIL: {message}")
    raise SystemExit(1)

version = (ROOT / "VERSION.txt").read_text(encoding="utf-8").strip()
toc = (ROOT / "QuestChronicle.toc").read_text(encoding="utf-8")
if version != "1.11.4" or "## Version: 1.11.4" not in toc:
    fail("package metadata is not the clean numeric v1.11.4 release")
if re.search(r"1\.10\.0(?:a|b|rc)\d*", "\n".join(
    p.read_text(encoding="utf-8", errors="ignore")
    for p in [ROOT / "VERSION.txt", ROOT / "QuestChronicle.toc", ROOT / "RELEASE_NOTES.md"]
), re.I):
    fail("current release metadata contains a prerelease suffix")

required = [
    "Core/Generation/ModePolicy.lua", "Core/Generation/ModeRegistry.lua",
    "Core/Generation/GenerationLifecycle.lua", "Core/Generation/SchedulerEngine.lua",
    "Core/Generation/ContextProvider.lua", "Core/Generation/AnchorEngine.lua",
    "Core/Generation/ValidationEngine.lua", "Core/Generation/RepairEngine.lua",
    "Core/Generation/SupportEngine.lua", "Core/Generation/CandidateEngine.lua",
    "Core/Generation/WeaponEngine.lua", "Core/Generation/CommitEngine.lua",
    "Core/Generation/DiagnosticsEngine.lua", "Core/Generation/RerollEngine.lua",
    "Core/Generation/VisualLanguage.lua", "Core/Generation/GenerationJob.lua",
    "Core/Generation/Modes/Traveler/Context.lua",
    "Core/Generation/Modes/Traveler/AnchorPolicy.lua",
    "Core/Generation/Modes/Traveler/SupportPolicy.lua",
    "Core/Generation/Modes/Traveler/ValidationPolicy.lua",
    "Core/Generation/Modes/Traveler/Diagnostics.lua",
    "Core/Generation/Modes/Traveler/Policy.lua",
    "Core/Generation/Modes/ZoneLegacyAdapter.lua",
    "Core/Generation/Modes/ClassLegacyAdapter.lua",
    "Core/Generation/Modes/EchoLegacyAdapter.lua",
    "Core/Generation/GenerationAPI.lua",
]
for relative in required:
    path = ROOT / relative
    if not path.is_file(): fail(f"missing {relative}")
    if toc.count(relative.replace("/", "\\")) != 1: fail(f"TOC must list {relative} exactly once")

traveler = (ROOT / "Core/Generation/Modes/Traveler/Policy.lua").read_text(encoding="utf-8")
if "IMPLEMENTATION_SHARED_FRAMEWORK" not in traveler or "sharedFramework = true" not in traveler:
    fail("Traveler is not registered as SHARED_FRAMEWORK")
for relative in (
    "Core/Generation/Modes/ZoneLegacyAdapter.lua",
    "Core/Generation/Modes/ClassLegacyAdapter.lua",
    "Core/Generation/Modes/EchoLegacyAdapter.lua",
):
    text = (ROOT / relative).read_text(encoding="utf-8")
    if "CreateLegacyWardrobePolicy" not in text: fail(f"{relative} is not an explicit legacy adapter")

for path in (ROOT / "Core/Generation").glob("*.lua"):
    text = path.read_text(encoding="utf-8")
    if re.search(r"MODE_TRAVELER|ZoneStyle\.Traveler|Traveler[A-Z]", text):
        fail(f"shared engine contains Traveler-specific policy: {path.name}")

worker = (ROOT / "Core/Wardrobe/GenerationWorker.lua").read_text(encoding="utf-8")
for token in ("sharedFrameworkPolicy", "StepSharedGenerationJob", "GetSharedGenerationRuntime"):
    if token not in worker: fail(f"generation worker is missing shared dispatch token {token}")

for relative in ("UI/Outfits/Layout.lua", "UI/Outfits/AppearanceBrowser.lua"):
    text = (ROOT / relative).read_text(encoding="utf-8")
    if re.search(r"Wardrobe\.(?:StartGenerateOutfit|GenerateOutfit|RerollSlot)\s*\(", text):
        fail(f"{relative} still calls a Wardrobe generation action directly")
if "QC.Generation" not in (ROOT / "UI/Outfits/Layout.lua").read_text(encoding="utf-8"):
    fail("Outfits layout does not route through the shared API")

snapshot = (ROOT / "Core/Diagnostics/SnapshotBuilder.lua").read_text(encoding="utf-8")
formatter = (ROOT / "Core/Diagnostics/ReportFormatter.lua").read_text(encoding="utf-8")
if "generationImplementation" not in snapshot or "Generation implementation" not in formatter:
    fail("implementation identity is not preserved in diagnostics")

if "EXTRACTION_BRIDGE" in "\n".join((ROOT / r).read_text(encoding="utf-8") for r in required):
    fail("completed v1.11.4 runtime still contains EXTRACTION_BRIDGE")

print("PASS: v1.11.4 shared framework, Traveler policy, legacy adapters, API routing, diagnostics, and numeric version contract are present.")
