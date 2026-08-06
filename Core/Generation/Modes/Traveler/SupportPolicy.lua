local QC = QuestChronicle
local Generation = QC.Generation
local P = QC.Wardrobe._Private

Generation.TravelerSupportPolicy = {
    BuildSupportProfile = function(...) return P.BuildContextualSupportProfile(...) end,
    GetSupportSlots = function() return P.SUPPORT_SLOT_ORDER end,
    GetSupportRole = function(slotKey, ...) return P.ResolveSupportRole and P.ResolveSupportRole(slotKey, ...) end,
    EvaluateSupportCandidate = function(...) return P.BuildSupportCandidate(...) end,
    ScoreSupportCandidate = function(...) return P.ScoreSupportCandidate(...) end,
    GetSupportBudgetConfiguration = function()
        return {
            mismatchBudget = P.SUPPORT_FINAL_MISMATCH_BUDGET,
            slotAllowances = P.SUPPORT_SLOT_ALLOWANCE,
        }
    end,
}
