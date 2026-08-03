QuestChronicle = { Wardrobe = { _Private = {} }, ZoneStyle = { Traveler = {} } }
local QC, P = QuestChronicle, QuestChronicle.Wardrobe._Private
P.slotByKey = { CHEST = { key = "CHEST" }, LEGS = { key = "LEGS" }, SHOULDER = { key = "SHOULDER" } }
QC.Wardrobe.GetSlotDefinition = function(key) return P.slotByKey[key] end
QC.ZoneStyle.GetTravelerDescriptor = function(source, definition)
    return { fingerprint = source.sourceID .. ":" .. definition.key, loudness = 0.3, group = source.group }
end
QC.ZoneStyle.Traveler.GetPairCohesion = function(left, right) return left.group == right.group and 0.9 or 0.35 end
QC.ZoneStyle.GetSourceCoherence = function() return 0, true end
QC.ZoneStyle.ScoreSource = function(source, _, mode)
    return source.group == mode and 35 or 10
end

dofile("Core/Wardrobe/AnchorSkeletonCache.lua")
dofile("Core/Wardrobe/AnchorSkeletonSearch.lua")

local modes = { "ZONE", "TRAVELER", "CLASS", "ECHO" }
local id = 0
for _, mode in ipairs(modes) do
    local pools = {}
    for _, slot in ipairs(P.ANCHOR_SLOT_ORDER) do
        pools[slot] = {}
        for _, group in ipairs(modes) do
            id = id + 1
            local source = { sourceID = id, visualID = id, group = group }
            pools[slot][#pools[slot] + 1] = P.BuildAnchorCandidate(source, P.slotByKey[slot], mode, {})
        end
    end
    local work = P.CreateAnchorBeamWork(pools)
    while not P.StepAnchorBeamWork(work) do end
    local best = work.beam[1]
    assert(best.sourceBySlot.CHEST.source.group == mode, mode .. " should retain its own chest relevance")
    assert(best.sourceBySlot.LEGS.source.group == mode, mode .. " should retain its own leg relevance")
    assert(best.sourceBySlot.SHOULDER.source.group == mode, mode .. " should retain its own shoulder relevance")
end
print("PASS anchor mode identity: Zone, Traveler, Class, and Echo retain distinct relevance rankings")
