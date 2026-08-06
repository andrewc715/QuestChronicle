QuestChronicle = { ZoneStyle = { _Private = {} }, Wardrobe = { _Private = {} } }
local root = debug.getinfo(1, "S").source:sub(2):gsub("tools/test_zone_anchor_policy_v1113.lua$", "")
local function Load(path) assert(loadfile(root .. path))() end
Load("Core/ZoneStyle/Zone/Foundation.lua")
Load("Core/ZoneStyle/Zone/AnchorScoring.lua")
local Zone = QuestChronicle.ZoneStyle.Zone

local unknown = { classification = "UNKNOWN", score = 1, confidence = 1 }
local adjustment = Zone.ComputeAnchorEvidenceAdjustment(unknown, "CHEST")
assert(adjustment == 0, "UNKNOWN evidence must remain neutral")

local strong = { classification = "STRONGLY_NATIVE", score = 1, confidence = 0.65 }
local strongAdjustment = Zone.ComputeAnchorEvidenceAdjustment(strong, "CHEST")
assert(math.abs(strongAdjustment - 8) < 0.0001, "strong local bonus did not cap at +8")
local legsAdjustment = Zone.ComputeAnchorEvidenceAdjustment(strong, "LEGS")
assert(math.abs(legsAdjustment - 7.2) < 0.0001, "Legs multiplier was not applied")
local off = { classification = "OFF_ZONE_SIGNAL", score = 0, confidence = 0.65 }
local offAdjustment = Zone.ComputeAnchorEvidenceAdjustment(off, "CHEST")
assert(math.abs(offAdjustment + 6) < 0.0001, "off-zone penalty did not cap at -6")

local candidate = { baseScore = 20, poolRandomValue = 0.25, scoreReasons = {} }
Zone.ApplyAnchorEvidence(candidate, strong, { key = "CHEST" }, false)
assert(math.abs(candidate.baseScore - 28) < 0.0001, "final candidate relevance is incorrect")
assert(candidate.anchorPolicy.legacyRelevance == 20 and candidate.anchorPolicy.finalRelevance == 28, "score decomposition missing")
assert(candidate.poolPriority == math.log(0.25) / candidate.weight, "candidate priority was not recomputed from the existing draw")

local pairBonus = Zone.ComputeAnchorPairSupport(
    { anchorPolicy = { zoneClassification = "STRONGLY_NATIVE", zoneAffinity = 1, zoneConfidence = 1 } },
    { anchorPolicy = { zoneClassification = "LOCALLY_COHERENT", zoneAffinity = 0.8, zoneConfidence = 0.75 } }
)
assert(math.abs(pairBonus - 3.6) < 0.0001, "bounded local pair support is incorrect")
local neutralPair = Zone.ComputeAnchorPairSupport(
    { anchorPolicy = { zoneClassification = "UNKNOWN", zoneAffinity = 1, zoneConfidence = 1 } },
    { anchorPolicy = { zoneClassification = "STRONGLY_NATIVE", zoneAffinity = 1, zoneConfidence = 1 } }
)
assert(neutralPair == 0, "unknown pair evidence must remain neutral")

print("PASS v1.11.3 Zone anchor policy: bounded evidence, slot prominence, neutral unknowns, and pair support")
