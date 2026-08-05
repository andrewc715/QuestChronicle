QuestChronicle = { Wardrobe = { _Private = {} } }
local P = QuestChronicle.Wardrobe._Private
P.ANCHOR_FINAL_SHORTLIST = 4
P.ANCHOR_FINAL_SCORE_WINDOW = 28
P.ANCHOR_REPEAT_PENALTIES = { MEANINGFULLY_NEW = 0, PARTIAL_CHANGE = -10, EXACT_REPEAT = -35 }
P.EvaluateAnchorNovelty = function(entry)
    local class = entry.noveltyClass
    local priority = ({ MEANINGFULLY_NEW = 3, PARTIAL_CHANGE = 2, EXACT_REPEAT = 1 })[class]
    return { class = class, classPriority = priority, adjustedScore = entry.score, repeatPenalty = 0,
        comparedComponents = {}, changedComponents = {}, repeatedComponents = {} }
end
dofile("Core/Wardrobe/AnchorSkeletonSearch.lua")
local finalists = {
    { signature = "A", score = 100, noveltyClass = "MEANINGFULLY_NEW" },
    { signature = "B", score = 98, noveltyClass = "MEANINGFULLY_NEW" },
    { signature = "C", score = 96, noveltyClass = "PARTIAL_CHANGE" },
    { signature = "D", score = 70, noveltyClass = "PARTIAL_CHANGE" },
}
local options = { action = "GENERATE_OUTFIT", noveltyContext = { available = true } }
local selected, rank = P.GetNextAnchorSkeleton(finalists, options, { A = true })
assert(selected and selected.signature == "B" and rank == 2, "alternate must prefer an unused skeleton in the winning novelty class")
selected, rank = P.GetNextAnchorSkeleton(finalists, options, { A = true, B = true })
assert(selected and selected.signature == "C" and rank == 3, "alternate must fall through to the next quality-window finalist when the preferred class is exhausted")
selected = P.GetNextAnchorSkeleton(finalists, options, { A = true, B = true, C = true })
assert(selected == nil, "skeleton outside the quality window must not be used")
print("PASS Phase D deterministic alternate-skeleton ordering and quality-window boundary")
