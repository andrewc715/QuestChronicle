#!/usr/bin/env python3
from pathlib import Path
import hashlib
import re

ROOT = Path(__file__).resolve().parents[1]

def text(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")

def sha(path: str) -> str:
    return hashlib.sha256((ROOT / path).read_bytes()).hexdigest()

frozen_hashes = {
    "Core/ZoneStyle/Traveler/StyleLexicon.lua": "a7d84e72b749ea36e2d9f99ceb1bd8a3b5a56d5067cd9965d4f118f21aa60d5d",
    "Core/ZoneStyle/Scoring.lua": "a3a896498f5a65444c0772fc1c8b19ea6eb3f59adf009277e43d9b7bc4bf7abf",
    "Core/Wardrobe/SupportFinalValidation.lua": "8a3ce9ec3bdc6eb8b66ab8d647dfea240cdd090342b37516c73c4ef0bda75295",
    "Core/Wardrobe/SupportRepair.lua": "87494c9386a7169552587c8d8353372260089c888f770720be9cc14e7c3d8ab9",
    "Core/Wardrobe/AnchorSkeletonSearch.lua": "272f7da1359429f8db1be8a86253fb4f8faf2b29d3437af19507e966289ac28f",
    "Core/Wardrobe/GenerationScheduling.lua": "a523d71b827da1f96dbacd9a605d6a7a2d1a666dc4135f58cc3d05e4d14c4f36",
    "Core/Wardrobe/AppearanceRoutes.lua": "9428bb5e2c091d217a15cef28758485143d28b63ec17c2ea5596bdd49f3562f2",
    "Core/Wardrobe/WeaponPipeline.lua": "652b672fe6401edd473b36913ffa812e19408114e384b23cd7b7742f77f2676b",
}

overrides = text("Core/ZoneStyle/Traveler/CuratedOverrides.lua")
override_data = overrides.split("local function CopyMap", 1)[0]
def visual_block(visual_id: int) -> str:
    match = re.search(rf"^\s*\[{visual_id}\]\s*=\s*\{{(.*?)(?=^\s*\[\d+\]\s*=\s*\{{|^\s*\}},\s*$)", override_data, re.MULTILINE | re.DOTALL)
    return match.group(1) if match else ""
descriptors = text("Core/ZoneStyle/Traveler/Descriptors.lua")
toc = text("QuestChronicle.toc")
checks = {
    "curated module exists": (ROOT / "Core/ZoneStyle/Traveler/CuratedOverrides.lua").is_file(),
    "curated module precedes descriptors": toc.index("Core\\ZoneStyle\\Traveler\\CuratedOverrides.lua") < toc.index("Core\\ZoneStyle\\Traveler\\Descriptors.lua"),
    "exact visual ids present": all(f"[{value}]" in overrides for value in (912, 1208, 1051, 1139, 5237, 12877)),
    "only six visual overrides": len(re.findall(r"^\s*\[(\d+)\]\s*=\s*\{", overrides, re.MULTILINE)) == 6,
    "no item overrides": "item = {}," in overrides,
    "no source overrides": "source = {}," in overrides,
    "no echo additions": "echoAdd =" not in override_data,
    "boots dark not green": "palette = { dark = 0.70, blue = 0.20, steel = 0.10 }" in overrides and "Orcish Scout Boots" in overrides,
    "shirts preserve palette": all("finish =" in visual_block(value) and "palette =" not in visual_block(value) for value in (912, 1208)),
    "descriptor fingerprint includes tuning version": "T.CURATED_TUNING_VERSION" in descriptors,
    "descriptor applies curated replacement before normalization": descriptors.index("T.ApplyCuratedDescriptorOverride") < descriptors.index("NormalizeMap(descriptor.palette)"),
    "curated confidence is explicit": "T.CURATED_CONFIDENCE" in descriptors,
    "echo palette defaults exist": "descriptor.echoPalette" in descriptors,
    "no direct score override language": not any(token in override_data for token in ("mismatchSpent", "selectionScore", "scoreDelta", "repairPass", "forceSelect")),
    "audit remains opt in": "if not audit.enabled or not IsObservableReport(report)" in text("Core/ZoneStyle/Traveler/TuningAudit.lua"),
    "compact report marker exists": "Curated tags:" in text("Core/Diagnostics/ReportFormatter.lua") and "Curated tags:" in text("Core/Diagnostics/SupportReportFormatter.lua"),
}
for path, expected in frozen_hashes.items():
    checks[f"frozen {path}"] = sha(path) == expected

failed = [name for name, ok in checks.items() if not ok]
if failed:
    raise SystemExit("FAIL Phase E curated verifier: " + ", ".join(failed))
print(f"PASS Phase E curated build verifier: {len(checks)} checks")
