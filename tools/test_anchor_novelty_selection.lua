QuestChronicle = { Wardrobe = { _Private = {} }, ZoneStyle = { Traveler = {} } }
local P = QuestChronicle.Wardrobe._Private
P.MAIN_WEAPON_SLOT_KEYS = { "ONE_HAND", "TWO_HAND", "RANGED" }
P.GetSourceByID = function() return nil end

dofile("Core/Wardrobe/AnchorSkeletonCache.lua")
dofile("Core/Wardrobe/AnchorSkeletonNovelty.lua")
dofile("Core/Wardrobe/AnchorSkeletonSearch.lua")

local function source(visualID, sourceID)
    return { visualID = visualID, sourceID = sourceID or visualID }
end

local function finalist(score, chest, legs, shoulder, mainHand, offHand, signature)
    local sourceBySlot = {}
    if chest then sourceBySlot.CHEST = { source = source(chest), slotKey = "CHEST" } end
    if legs then sourceBySlot.LEGS = { source = source(legs), slotKey = "LEGS" } end
    if shoulder then sourceBySlot.SHOULDER = { source = source(shoulder), slotKey = "SHOULDER" } end
    return {
        score = score,
        signature = signature or table.concat({ chest or "", legs or "", shoulder or "", mainHand or "", offHand or "" }, ":"),
        armorNode = { sourceBySlot = sourceBySlot },
        mainSource = mainHand and source(mainHand) or nil,
        offSource = offHand and source(offHand) or nil,
    }
end

local function state(chest, legs, shoulder, mainHand, offHand)
    return {
        selections = { CHEST = chest, LEGS = legs, SHOULDER = shoulder, ONE_HAND = mainHand, OFF_HAND = offHand },
        selectionVisuals = { CHEST = chest, LEGS = legs, SHOULDER = shoulder, ONE_HAND = mainHand, OFF_HAND = offHand },
        locks = {}, hidden = {},
    }
end

local current = state(1, 2, 3, 4, 5)
local context = P.BuildAnchorNoveltyContext(current)
assert(context.available and context.currentActiveComponents == 4, "current skeleton should expose four logical anchors")

local repeated = finalist(100, 1, 2, 3, 4, 5, "repeat")
local partial = finalist(96, 1, 20, 3, 4, 5, "partial")
local meaningful = finalist(80, 10, 20, 3, 4, 5, "meaningful")
math.randomseed(3)
local chosen, rank, shortlistSize, details = P.ChooseAnchorSkeleton({ repeated, partial, meaningful }, {
    action = "GENERATE_OUTFIT", noveltyContext = context,
})
assert(chosen.signature == "meaningful", "meaningfully new skeleton must beat repeated and partial choices inside the quality window")
assert(rank == 3 and shortlistSize == 3, "chosen rank should remain the base-score rank within the full quality shortlist")
assert(details.class == "MEANINGFULLY_NEW" and details.changedCount == 2, "meaningful classification should record two changed anchors")
assert(details.repeatPenalty == -18, "repeated Shoulders and weapon bundle should contribute -18")
assert(details.adjustedScore == 62, "adjusted score should reconcile exactly")

math.randomseed(4)
chosen, _, _, details = P.ChooseAnchorSkeleton({ repeated, partial }, {
    action = "GENERATE_OUTFIT", noveltyContext = context,
})
assert(chosen.signature == "partial" and details.class == "PARTIAL_CHANGE", "partial change should win when no meaningful alternative survives")

math.randomseed(5)
chosen, _, _, details = P.ChooseAnchorSkeleton({ repeated }, {
    action = "GENERATE_OUTFIT", noveltyContext = context,
})
assert(chosen.signature == "repeat" and details.class == "EXACT_REPEAT", "exact repeat must remain a legal last resort")
assert(details.repeatPenalty == -46 and details.adjustedScore == 54, "exact repeat penalty must total -46")
assert(details.exactRepeatAccepted and details.exactRepeatReason, "exact repeat fallback must be explained")

local tooWeak = finalist(60, 10, 20, 30, 40, 50, "weak-new")
math.randomseed(6)
chosen, _, shortlistSize, details = P.ChooseAnchorSkeleton({ repeated, tooWeak }, {
    action = "GENERATE_OUTFIT", noveltyContext = context,
})
assert(chosen.signature == "repeat" and shortlistSize == 1, "novelty must never bypass the 28-point quality window")
assert(details.class == "EXACT_REPEAT", "quality-floor fallback should be reported as an exact repeat")

local locked = state(1, 2, 3, 4, 5)
locked.locks.CHEST = true
locked.hidden.SHOULDER = true
local lockedDetails = P.EvaluateAnchorNovelty(finalist(90, 1, 20, 3, 40, 50), P.BuildAnchorNoveltyContext(locked))
assert(lockedDetails.comparedCount == 2, "locked Chest and hidden Shoulders must be excluded from novelty comparison")
assert(lockedDetails.class == "MEANINGFULLY_NEW", "changing Legs and weapons should remain meaningful with locked/hidden anchors")
assert(lockedDetails.repeatPenalty == 0, "ignored anchors must contribute no repeat penalty")

local penaltyCases = {
    { name = "Chest", entry = finalist(90, 1, 20, 30, 40, 50), penalty = -10 },
    { name = "Legs", entry = finalist(90, 10, 2, 30, 40, 50), penalty = -6 },
    { name = "Shoulders", entry = finalist(90, 10, 20, 3, 40, 50), penalty = -8 },
    { name = "Weapon bundle", entry = finalist(90, 10, 20, 30, 4, 5), penalty = -10 },
}
for _, case in ipairs(penaltyCases) do
    local evaluated = P.EvaluateAnchorNovelty(case.entry, context)
    assert(evaluated.repeatPenalty == case.penalty, case.name .. " repeat penalty should match the centralized calibration")
end

local alternateSourceSameVisual = finalist(100, 1, 2, 3, 4, 5, "alternate-sources")
alternateSourceSameVisual.armorNode.sourceBySlot.CHEST.source.sourceID = 999
alternateSourceSameVisual.mainSource.sourceID = 998
local visualDetails = P.EvaluateAnchorNovelty(alternateSourceSameVisual, context)
assert(visualDetails.class == "EXACT_REPEAT", "alternate collected sources for the same visuals must not create false novelty")

local emptyContext = P.BuildAnchorNoveltyContext(state(nil, nil, nil, nil, nil))
local initialA = finalist(100, 1, 2, 3, 4, 5, "initial-a")
local initialB = finalist(94, 10, 20, 30, 40, 50, "initial-b")
math.randomseed(42)
local legacyChosen = P.ChooseAnchorSkeleton({ initialA, initialB })
math.randomseed(42)
local initialChosen, _, _, initialDetails = P.ChooseAnchorSkeleton({ initialA, initialB }, {
    action = "GENERATE_OUTFIT", noveltyContext = emptyContext,
})
assert(initialChosen.signature == legacyChosen.signature, "initial generation must preserve v1.9.0.3 weighted selection parity")
assert(initialDetails.class == "INITIAL" and initialDetails.repeatPenalty == 0, "initial generation should record no novelty penalty")

print("PASS anchor novelty selection: meaningful/partial/exact priority, quality floor, locks, visuals, and initial parity verified")
