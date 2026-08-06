QuestChronicle = { ZoneStyle = { _Private = {} }, Wardrobe = { _Private = {} } }
local root = debug.getinfo(1, "S").source:sub(2):gsub("tools/test_zone_anchor_weapon_dedup_v1113.lua$", "")
local function Load(path) assert(loadfile(root .. path))() end
Load("Core/ZoneStyle/Zone/Foundation.lua")
Load("Core/ZoneStyle/Zone/AnchorScoring.lua")
local Zone = QuestChronicle.ZoneStyle.Zone
local details = {
    legacyRelevance = 15, zoneAffinity = 0.8, zoneConfidence = 0.7,
    zoneClassification = "LOCALLY_COHERENT", zoneAdjustment = 5, finalRelevance = 20,
}
local shared = { slotKey = "TWO_HAND", source = { sourceID = 91, visualID = 900, name = "Linked Blade" }, anchorPolicy = details }
local selected = {
    armorNode = { sourceBySlot = {}, zonePairSupportBonus = 1.5, visualRelationshipBonus = 4 },
    weaponCandidates = { shared, shared },
    linkedVisualDeduplicated = true,
    zonePairSupportBonus = 2,
    visualRelationshipBonus = 5,
    draft = { lastWeaponRoute = { routeFamily = "TWO_HAND" } },
}
local summary = Zone.BuildSelectedAnchorPolicySummary(selected, {}, { modeContextFingerprint = "ZCTX-test" })
assert(#summary.logicalWeapons == 1, "linked visual received duplicate Zone affinity credit")
assert(summary.linkedVisualDeduplicated == true, "linked visual deduplication marker missing")
assert(summary.routeFamily == "TWO_HAND", "legal route identity missing")
assert(summary.snapshotFingerprint == "ZCTX-test", "action snapshot identity missing")
print("PASS v1.11.3 Zone weapon policy: linked visuals score once and legal route identity survives")
