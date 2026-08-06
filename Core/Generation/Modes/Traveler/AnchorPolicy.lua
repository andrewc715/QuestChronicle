local QC = QuestChronicle
local Generation = QC.Generation
local P = QC.Wardrobe._Private

Generation.TravelerAnchorPolicy = {
    GetAnchorSlots = function() return { "CHEST", "LEGS", "SHOULDER", "WEAPON_BUNDLE" } end,
    GetAnchorSearchConfiguration = function()
        return {
            beamWidth = P.ANCHOR_BEAM_WIDTH,
            finalShortlist = P.ANCHOR_FINAL_SHORTLIST,
            scoreWindow = P.ANCHOR_FINAL_SCORE_WINDOW,
        }
    end,
    EvaluateAnchorCandidate = function(...) return P.BuildAnchorCandidate(...) end,
    ScoreAnchorPair = function(...) return P.ScoreAnchorRelationship(...) end,
    ScoreAnchorSkeleton = function(...) return P.ScoreWeaponBundleForAnchor(...) end,
    BuildNoveltyReference = function(...) return P.BuildAnchorNoveltyContext(...) end,
    ClassifyNovelty = function(...) return P.EvaluateAnchorNovelty(...) end,
}
