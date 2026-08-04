QuestChronicle = { Diagnostics = { _Private = {} } }
local D, P = QuestChronicle.Diagnostics, QuestChronicle.Diagnostics._Private
D.GetReportByID = function() return nil end

dofile("Core/Diagnostics/Comparison.lua")

local function HasUnknownWarning(reason)
    local report = {
        action = "GENERATE_OUTFIT",
        warnings = {},
        skeleton = {},
        performance = { weaponIndex = { invalidationReason = reason } },
    }
    P.AttachWarningsAndComparison(report)
    for _, warning in ipairs(report.warnings) do
        if warning.key == "UNKNOWN_WEAPON_INDEX_INVALIDATION" then return true end
    end
    return false
end

assert(HasUnknownWarning("UNKNOWN"), "UNKNOWN fallback did not produce its warning")
for _, reason in ipairs({
    "NONE",
    "FORMAT_MISMATCH",
    "WARDROBE_CACHE_REPLACED",
    "COLLECTION_REVISION_CHANGED",
    "METADATA_REVISION_CHANGED",
    "CHARACTER_CAPABILITY_CHANGED",
    "APPEARANCE_COLLECTED",
    "EVIDENCE_OUTCOME_CHANGED",
    "ELIGIBILITY_OUTCOME_CHANGED",
    "LOGIN_SESSION_RESET",
    "MANUAL_DEBUG_RESET",
}) do
    assert(not HasUnknownWarning(reason), reason .. " incorrectly produced UNKNOWN_WEAPON_INDEX_INVALIDATION")
end

print("PASS v1.9.0.13 weapon-index warning gate: only final UNKNOWN reports warn")
