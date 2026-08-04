QuestChronicle = { Diagnostics = { _Private = {} } }
local D, P = QuestChronicle.Diagnostics, QuestChronicle.Diagnostics._Private
D.GetReportByID = function() return nil end

dofile("Core/Diagnostics/Comparison.lua")

local unknown = {
    action = "GENERATE_OUTFIT", warnings = {}, skeleton = {},
    performance = { weaponIndex = { invalidationReason = "UNKNOWN" } },
}
P.AttachWarningsAndComparison(unknown)
local found = false
for _, warning in ipairs(unknown.warnings) do
    if warning.key == "UNKNOWN_WEAPON_INDEX_INVALIDATION" then found = true end
end
assert(found, "UNKNOWN fallback did not produce a warning")

local none = {
    action = "GENERATE_OUTFIT", warnings = {}, skeleton = {},
    performance = { weaponIndex = { invalidationReason = "NONE" } },
}
P.AttachWarningsAndComparison(none)
for _, warning in ipairs(none.warnings) do
    assert(warning.key ~= "UNKNOWN_WEAPON_INDEX_INVALIDATION", "NONE produced an invalidation warning")
end

print("PASS v1.9.0.13 weapon-index warning: only genuine UNKNOWN fallback warns")
