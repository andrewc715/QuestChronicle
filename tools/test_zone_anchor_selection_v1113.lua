local randomCalls = 0
local originalRandom = math.random
math.random = function(...)
    randomCalls = randomCalls + 1
    if select("#", ...) > 0 then return originalRandom(...) end
    return 0.5
end
QuestChronicle = {
    Wardrobe = { _Private = {}, slotDefinitions = {} },
    ZoneStyle = { _Private = {}, Zone = nil },
    Generation = {},
}
local QC = QuestChronicle
local P = QC.Wardrobe._Private
QC.ZoneStyle.GetSourceCoherence = function() return 0, true end
QC.ZoneStyle.ScoreSource = function() return 20, { "Legacy parity" } end
QC.ZoneStyle.GetTravelerDescriptor = function(source)
    return { loudness = 0.2, dominantMaterial = "plate", dominantMotif = "frontier", dominantPalette = source.sourceID == 1 and "purple" or "gold" }
end
QC.ZoneStyle.GetSourcePreference = function(source) return source and source.sourceID == 1 and "favorite" or nil end
P.GetAnchorPairCohesion = function() return 0.75, { palette = 0.75 } end
P.slotByKey = { CHEST = { key = "CHEST" }, LEGS = { key = "LEGS" }, SHOULDER = { key = "SHOULDER" } }
local root = debug.getinfo(1, "S").source:sub(2):gsub("tools/test_zone_anchor_selection_v1113.lua$", "")
local function Load(path) assert(loadfile(root .. path))() end
Load("Core/Wardrobe/AnchorSkeletonCache.lua")
Load("Core/Wardrobe/AnchorSkeletonNovelty.lua")
Load("Core/Wardrobe/AnchorSkeletonSearch.lua")
Load("Core/ZoneStyle/Zone/Foundation.lua")
Load("Core/ZoneStyle/Zone/AnchorScoring.lua")
QC.Generation.ZoneAffinityPolicy = {
    AnalyzeAppearance = function(source)
        if source.sourceID == 1 then return { score = 0.90, confidence = 0.80, classification = "STRONGLY_NATIVE" } end
        return { score = 0.10, confidence = 0.80, classification = "OFF_ZONE_SIGNAL" }
    end,
}
Load("Core/Generation/Modes/Zone/AnchorPolicy.lua")
Load("Core/Wardrobe/AnchorPolicyBridge.lua")
local job = {
    requestedStyleMode = "ZONE_NATIVE", styleMode = "ZONE_NATIVE", styleContext = {}, modeContext = { fingerprint = "ZCTX-test" },
    modePolicy = { capabilities = { zoneAnchorPolicy = true }, anchorPolicy = QC.Generation.ZoneAnchorPolicy },
    anchorPolicy = QC.Generation.ZoneAnchorPolicy,
}
local definition = P.slotByKey.CHEST
local localCandidate = P.EvaluateAnchorCandidateForJob(job, { sourceID = 1, visualID = 1 }, definition, {}, false)
local foreignCandidate = P.EvaluateAnchorCandidateForJob(job, { sourceID = 2, visualID = 2 }, definition, {}, false)
assert(localCandidate.baseScore > foreignCandidate.baseScore, "Zone evidence did not become authoritative over equal legacy relevance")
assert(localCandidate.anchorPolicy.legacyRelevance == foreignCandidate.anchorPolicy.legacyRelevance, "fixture legacy scores diverged")
assert(localCandidate.anchorPolicy.favorite == true and foreignCandidate.anchorPolicy.favorite == false, "favorite state was not recorded")
local locked = P.EvaluateAnchorCandidateForJob(job, { sourceID = 2, visualID = 2 }, definition, {}, true)
assert(locked and locked.anchorPolicy.locked == true, "locked low-affinity anchor was rejected")
assert(randomCalls == 3, "Zone affinity added random calls to candidate evaluation")
local work = { pool = {}, poolLimit = 2 }
P.AddAnchorPoolCandidate(work, foreignCandidate)
P.AddAnchorPoolCandidate(work, localCandidate)
P.FinalizeAnchorPool(work)
assert(work.pool[1].source.sourceID == 1, "local evidence did not change candidate ordering")
math.random = originalRandom
print("PASS v1.11.3 Zone selection authority: equal legacy candidates reorder by evidence with no extra random draws")
