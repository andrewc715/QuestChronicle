QuestChronicle = {
    Wardrobe = { _Private = {} },
    ZoneStyle = { Traveler = {} },
}
local QC = QuestChronicle
local P = QC.Wardrobe._Private
P.slotByKey = {
    CHEST = { key = "CHEST" }, LEGS = { key = "LEGS" }, SHOULDER = { key = "SHOULDER" },
    ONE_HAND = { key = "ONE_HAND", weaponRole = "ONE_HAND" }, OFF_HAND = { key = "OFF_HAND", weaponRole = "OFF_HAND" },
}
QC.Wardrobe.GetSlotDefinition = function(key) return P.slotByKey[key] end
QC.ZoneStyle.GetTravelerDescriptor = function(source, definition)
    return {
        fingerprint = tostring(source.sourceID) .. ":" .. definition.key,
        loudness = source.loudness or 0.3,
        group = source.group,
    }
end
QC.ZoneStyle.Traveler.GetPairCohesion = function(left, right)
    return left.group == right.group and 0.95 or 0.20, { palette = left.group == right.group and 1 or 0.2 }
end
QC.ZoneStyle.GetSourceCoherence = function() return 0, true end
QC.ZoneStyle.ScoreSource = function(source) return source.score end

dofile("Core/Wardrobe/AnchorSkeletonCache.lua")
dofile("Core/Wardrobe/AnchorSkeletonSearch.lua")
math.randomseed(42)

local function candidate(id, slot, group, score)
    local source = { sourceID = id, visualID = id, group = group, score = score, loudness = 0.3 }
    return P.BuildAnchorCandidate(source, P.slotByKey[slot], "TRAVELER", {})
end

local pools = {
    CHEST = { candidate(1, "CHEST", "A", 20), candidate(2, "CHEST", "B", 24) },
    LEGS = { candidate(3, "LEGS", "A", 20), candidate(4, "LEGS", "B", 24) },
    SHOULDER = { candidate(5, "SHOULDER", "A", 20), candidate(6, "SHOULDER", "C", 32) },
}
local work = P.CreateAnchorBeamWork(pools)
local guard = 0
while not P.StepAnchorBeamWork(work) do guard = guard + 1 assert(guard < 1000) end
assert(#work.beam > 0, "beam should retain candidates")
local best = work.beam[1]
assert(best.sourceBySlot.CHEST.source.group == "A", "cohesion should allow the A chest to beat the higher independent B score")
assert(best.sourceBySlot.LEGS.source.group == "A", "cohesion should retain matching A legs")
assert(best.sourceBySlot.SHOULDER.source.group == "A", "cohesion should retain matching A shoulders")
assert(best.hardClashes == 0, "best beam should not contain a hard clash")
assert(work.expansions.CHEST == 2 and work.expansions.LEGS == 4 and work.expansions.SHOULDER > 0, "beam expansion counters should be populated")

local before = P.GetAnchorPairCacheSnapshot()
P.GetAnchorPairCohesion(pools.CHEST[1].source, pools.LEGS[1].source, P.slotByKey.CHEST, P.slotByKey.LEGS)
P.GetAnchorPairCohesion(pools.CHEST[1].source, pools.LEGS[1].source, P.slotByKey.CHEST, P.slotByKey.LEGS)
local after = P.GetAnchorPairCacheSnapshot()
assert(after.hits > before.hits, "repeated pair scoring should hit the bounded pair cache")
assert(after.size <= P.ANCHOR_PAIR_CACHE_LIMIT, "pair cache should remain bounded")

local chosen, _, shortlistSize = P.ChooseAnchorSkeleton({
    { score = 100, signature = "A" }, { score = 94, signature = "B" }, { score = 40, signature = "C" },
})
assert(chosen.signature ~= "C" and shortlistSize == 2, "weighted selection must stay inside the quality window")

local diversityWork = { pool = {}, poolLimit = 8 }
for index = 1, 8 do
    P.AddAnchorPoolCandidate(diversityWork, {
        source = { sourceID = 200 + index, visualID = 200 + index },
        baseScore = 30 - index, poolPriority = -index, diversityKey = index <= 6 and "SAME" or ("ALT" .. index),
    })
end
P.FinalizeAnchorPool(diversityWork)
local alternateCount = 0
for _, entry in ipairs(diversityWork.pool) do if entry.diversityKey ~= "SAME" then alternateCount = alternateCount + 1 end end
assert(alternateCount == 2, "candidate preparation should retain distinct visual families")

print(string.format("PASS anchor beam search: best %.1f cohesion %.3f expansions %d/%d/%d", best.score, best.meanPairCohesion, work.expansions.CHEST, work.expansions.LEGS, work.expansions.SHOULDER))
