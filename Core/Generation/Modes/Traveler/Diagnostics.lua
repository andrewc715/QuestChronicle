local QC = QuestChronicle
local Generation = QC.Generation

Generation.TravelerDiagnosticsPolicy = {
    BuildOutfitName = function(state, styleEngine, styleMode, styleContext)
        local P = QC.Wardrobe._Private
        return P.RefreshGeneratedOutfitName(state, styleEngine, styleMode, styleContext)
    end,
    BuildModeReportSections = function(report)
        return report and { implementation = "SHARED_FRAMEWORK", mode = "TRAVELER" } or nil
    end,
    BuildModeWarnings = function() return {} end,
    BuildModeComparison = function(previous, current) return previous, current end,
    SupportsTuningAudit = function() return true end,
}
