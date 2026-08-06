#!/usr/bin/env python3
"""Verify the v1.11.6 Zone anchor-policy authority transfer and parity boundary."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
def text(path): return (root / path).read_text(encoding="utf-8")

toc = text("QuestChronicle.toc")
version = text("VERSION.txt").strip()
bridge = text("Core/Wardrobe/AnchorPolicyBridge.lua")
worker = text("Core/Wardrobe/AnchorSkeletonWorker.lua")
search = text("Core/Wardrobe/AnchorSkeletonSearch.lua")
setup = text("Core/Wardrobe/GenerationSetupWorker.lua")
generation = text("Core/Wardrobe/GenerationWorker.lua")
policy = text("Core/Generation/Modes/Zone/AnchorPolicy.lua")
scoring = text("Core/ZoneStyle/Zone/AnchorScoring.lua")
adapter = text("Core/Generation/Modes/ZoneLegacyAdapter.lua")
mode_contract = text("Core/Generation/ModePolicy.lua")
exporter = text("Core/ZoneStyle/Zone/DebugExport.lua")
formatter = text("Core/Diagnostics/ReportFormatter.lua")
snapshot = text("Core/Diagnostics/SnapshotBuilder.lua")

required_modules = [
    r"Core\Wardrobe\AnchorPolicyBridge.lua",
    r"Core\Wardrobe\GenerationJobFactory.lua",
    r"Core\ZoneStyle\Zone\AnchorScoring.lua",
    r"Core\Generation\Modes\Zone\AnchorPolicy.lua",
]
required_callbacks = [
    "GetAnchorSlots", "GetAnchorSearchConfiguration", "EvaluateAnchorCandidate",
    "ScoreAnchorPair", "ScoreAnchorSkeleton", "BuildNoveltyReference", "ClassifyNovelty",
]
checks = {
    "clean numeric v1.11.6 metadata": version == "1.11.6" and "## Version: 1.11.6" in toc,
    "new modules listed once": all(toc.count(path) == 1 for path in required_modules),
    "bridge precedes anchor search": toc.index(required_modules[0]) < toc.index(r"Core\Wardrobe\AnchorSkeletonSearch.lua"),
    "Zone scoring precedes Zone policy": toc.index(required_modules[2]) < toc.index(required_modules[3]),
    "Zone policy precedes adapter": toc.index(required_modules[3]) < toc.index(r"Core\Generation\Modes\ZoneLegacyAdapter.lua"),
    "Zone remains hybrid LEGACY": all(token in adapter for token in [
        "CreateLegacyWardrobePolicy", "sharedFramework = false", "legacy = true",
        "zoneAnchorPolicy = true", "zoneAnchorPolicyVersion = 1", 'zoneAnchorAuthority = "ACTIVE"',
        "zoneSupportPolicy = false", "zoneFinalValidation = false", "zoneTuningAudit = false",
    ]),
    "policy identity is explicit": all(token in scoring for token in [
        'ZONE_ANCHOR_POLICY_V1', 'Zone.ANCHOR_POLICY_FORMAT', 'Zone.ANCHOR_POLICY_AUTHORITY',
    ]),
    "planned constants are present": all(token in scoring for token in [
        "neutralAffinity = 0.35", "affinityScale = 20.00", "maximumBonus = 8.00",
        "maximumPenalty = -6.00", "confidenceFull = 0.65", "maximumPairBonus = 4.00",
        "CHEST = 1.00", "LEGS = 0.90", "WEAPON_BUNDLE = 1.10",
    ]),
    "policy contract is complete": all(name in policy for name in required_callbacks),
    "mode contract rejects incomplete Zone policies": all(name in mode_contract for name in required_callbacks) and "ValidateZoneAnchorPolicy" in mode_contract,
    "one action snapshot is captured": all(token in setup + bridge for token in [
        "CaptureAnchorPolicyContext", "modeContextFingerprint", "ValidateAnchorPolicyContextAtCommit",
    ]),
    "stale context cancels before commit": "Zone context changed while Quest Chronicle was preparing the outfit" in bridge and generation.index("ValidateAnchorPolicyContextAtCommit") < generation.index("job.liveState.selections = job.draft.selections"),
    "candidate callback is authoritative": "EvaluateAnchorCandidateForJob" in worker and "ApplyAnchorEvidence" in policy,
    "pair callback is authoritative": "ScoreAnchorRelationshipForJob" in search and "ComputeAnchorPairSupport" in policy,
    "skeleton callback is authoritative": "ScoreAnchorSkeletonForJob" in worker,
    "novelty callbacks are authoritative": "BuildAnchorNoveltyReferenceForJob" in setup and "ClassifyAnchorNoveltyForOptions" in search,
    "linked weapon affinity is deduplicated": all(token in search + scoring for token in [
        "linkedVisualDeduplicated", "logicalSeen", "visualID",
    ]),
    "unknown evidence remains neutral": "classification == \"UNKNOWN\"" in scoring and "return 0" in scoring,
    "policy adds no random calls": all("math.random" not in value for value in [bridge, policy, scoring]),
    "shared orchestration contains no Zone mode branch": all("ZONE_NATIVE" not in value for value in [bridge, worker, search]),
    "debug export format advances through 4": "Zone.DEBUG_EXPORT_FORMAT = 4" in exporter and "Zone Anchor Policy" in exporter,
    "reports persist policy decomposition": "zoneAnchorPolicyDiagnostics" in snapshot and "Zone Anchor Policy" in formatter,
    "policy performance is visible": "zoneAnchorPolicy" in policy and "Zone anchor policy" in formatter,
    "no prerelease suffix": not re.search(r"1\.11\.3(?:a|b|rc|alpha|beta)", "\n".join(
        p.read_text(errors="ignore") for p in root.rglob("*") if p.is_file() and p.suffix in {".lua", ".toc", ".md", ".txt", ".py"}
    ), re.I),
}
failed = [name for name, ok in checks.items() if not ok]
if failed:
    print("FAIL: v1.11.6 Zone anchor-policy guard failed:")
    for name in failed: print("  -", name)
    raise SystemExit(1)
print(f"PASS: v1.11.6 Zone anchor-policy verification: {len(checks)} checks")
