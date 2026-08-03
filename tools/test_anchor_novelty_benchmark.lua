QuestChronicle = { Wardrobe = { _Private = {} }, ZoneStyle = { Traveler = {} } }
local P = QuestChronicle.Wardrobe._Private
P.MAIN_WEAPON_SLOT_KEYS = { "ONE_HAND", "TWO_HAND", "RANGED" }
P.GetSourceByID = function() return nil end

dofile("Core/Wardrobe/AnchorSkeletonCache.lua")
dofile("Core/Wardrobe/AnchorSkeletonNovelty.lua")
dofile("Core/Wardrobe/AnchorSkeletonSearch.lua")

local function source(id) return { visualID = id, sourceID = id } end
local function entry(score, offset)
    return {
        score = score, signature = tostring(offset),
        armorNode = { sourceBySlot = {
            CHEST = { source = source(1 + offset) },
            LEGS = { source = source(2 + offset) },
            SHOULDER = { source = source(3 + offset) },
        } },
        mainSource = source(4 + offset), offSource = source(5 + offset),
    }
end
local state = {
    selections = { CHEST = 1, LEGS = 2, SHOULDER = 3, ONE_HAND = 4, OFF_HAND = 5 },
    selectionVisuals = { CHEST = 1, LEGS = 2, SHOULDER = 3, ONE_HAND = 4, OFF_HAND = 5 },
    locks = {}, hidden = {},
}
local context = P.BuildAnchorNoveltyContext(state)
local iterations = 10000
local started = os.clock()
math.randomseed(119)
for _ = 1, iterations do
    local finalists = { entry(150, 0), entry(145, 10), entry(138, 20), entry(130, 30) }
    local selected = P.ChooseAnchorSkeleton(finalists, { action = "GENERATE_OUTFIT", noveltyContext = context })
    assert(selected, "novelty benchmark should always choose a skeleton")
end
local elapsedMs = (os.clock() - started) * 1000
local averageMs = elapsedMs / iterations
assert(averageMs < 0.5, string.format("novelty selection averaged %.4f ms, above the 0.5 ms acceptance target", averageMs))
print(string.format("PASS anchor novelty benchmark: %d four-finalist selections averaged %.4f ms", iterations, averageMs))
