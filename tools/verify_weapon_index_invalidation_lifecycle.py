#!/usr/bin/env python3
"""Verify v1.9.0.13 weapon-index invalidation lifecycle wiring."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
index = (ROOT / "Core/Wardrobe/WeaponCandidateIndex.lua").read_text(encoding="utf-8")
routes = (ROOT / "Core/Wardrobe/EquipmentTopology.lua").read_text(encoding="utf-8")
scan = (ROOT / "Core/Wardrobe/CollectionScanAndPreview.lua").read_text(encoding="utf-8")
events = (ROOT / "Core/Wardrobe/Events.lua").read_text(encoding="utf-8")
comparison = (ROOT / "Core/Diagnostics/Comparison.lua").read_text(encoding="utf-8")
version = (ROOT / "VERSION.txt").read_text(encoding="utf-8").strip()
toc = (ROOT / "QuestChronicle.toc").read_text(encoding="utf-8")

checks = {
    "v1.9.0.13 metadata": version == "1.9.0.13" and "## Version: 1.9.0.13" in toc,
    "session reset initializes the transient index": 'weaponCandidateIndexInvalidationReason or "LOGIN_SESSION_RESET"' in index,
    "action snapshots track invalidation sequence": "invalidationSequence = current.invalidationSequence" in index,
    "warm actions default to NONE": 'local invalidationReason, invalidationUnknownFallback = "NONE", false' in index,
    "cold and partial builds preserve lifecycle reason": "if built > 0 or repaired > 0 then" in index,
    "unrecognized reasons alone fall back to UNKNOWN": 'return "UNKNOWN", true' in index,
    "route invalidation accepts an explicit reason": "function Wardrobe.InvalidateWeaponAppearanceRoutes(reason)" in routes,
    "auto login keeps LOGIN_SESSION_RESET": 'cache.scanTrigger == "AUTO_LOGIN"' in scan and '"LOGIN_SESSION_RESET" or "WARDROBE_CACHE_REPLACED"' in scan,
    "collection changes are canonical": 'indexReason = "APPEARANCE_COLLECTED"' in scan and 'indexReason = "COLLECTION_REVISION_CHANGED"' in scan,
    "capability changes are canonical": events.count('InvalidateWeaponAppearanceRoutes("CHARACTER_CAPABILITY_CHANGED")') >= 2,
    "UNKNOWN alone produces a warning": 'weaponIndex.invalidationReason == "UNKNOWN"' in comparison and "UNKNOWN_WEAPON_INDEX_INVALIDATION" in comparison,
}

failed = [name for name, passed in checks.items() if not passed]
if failed:
    print("FAIL: weapon-index invalidation lifecycle verification failed:")
    for name in failed:
        print(f"- {name}")
    raise SystemExit(1)

print(f"PASS: v1.9.0.13 weapon-index invalidation lifecycle verification: {len(checks)} checks")
