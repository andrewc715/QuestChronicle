local QC = QuestChronicle
local Generation = QC.Generation
local P = QC.Wardrobe._Private

Generation.TravelerValidationPolicy = {
    AnalyzeCompletedConfiguration = function(...) return P.ValidateSupportConfiguration(...) end,
    CompareValidationObjectives = function(...) return P.CompareSupportValidation(...) end,
    RankRepairTargets = function(...) return P.SelectSupportRepairTarget(...) end,
    ApproveLockedOverride = function(validation) return validation and validation.status == "LOCKED_OVERRIDE" end,
    RequestAlternateSkeleton = function(job) return P.ApplyNextAnchorSkeleton(job) end,
}
