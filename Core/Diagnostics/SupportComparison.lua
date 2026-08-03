local QC = QuestChronicle
local D = QC.Diagnostics
local P = D._Private

local function Identity(decision)
    return decision and tostring(decision.visualID or decision.sourceID or "") or ""
end

local function BySlot(support)
    local result = {}
    for _, decision in ipairs(support and support.decisions or {}) do result[decision.slotKey] = decision end
    return result
end

local function Contains(values, text)
    for _, value in ipairs(values or {}) do if value == text then return true end end
    return false
end

function P.AttachSupportComparison(report, previous, comparison)
    local currentSupport, oldSupport = report.support, previous and previous.support
    if not currentSupport or not oldSupport then return end
    local current, old = BySlot(currentSupport), BySlot(oldSupport)
    comparison.supportChanged, comparison.supportUnchanged, comparison.supportExcluded = {}, {}, {}
    for _, slotKey in ipairs(QC.Wardrobe and QC.Wardrobe._Private and QC.Wardrobe._Private.SUPPORT_SLOT_ORDER or {}) do
        local definition = QC.Wardrobe.GetSlotDefinition(slotKey)
        local label = definition and definition.label or slotKey
        if Contains(currentSupport.excluded, label .. " (Hidden)") then comparison.supportExcluded[#comparison.supportExcluded + 1] = label .. " (Hidden)"
        elseif Contains(currentSupport.excluded, label .. " (Locked)") then comparison.supportExcluded[#comparison.supportExcluded + 1] = label .. " (Locked)"
        elseif Contains(currentSupport.excluded, label .. " (Unavailable)") then comparison.supportExcluded[#comparison.supportExcluded + 1] = label .. " (Unavailable)"
        elseif current[slotKey] and old[slotKey] and Identity(current[slotKey]) == Identity(old[slotKey]) then comparison.supportUnchanged[#comparison.supportUnchanged + 1] = label
        elseif current[slotKey] then comparison.supportChanged[#comparison.supportChanged + 1] = label end
    end
    comparison.previousMismatch = (oldSupport.lockedCommitment or 0) + (oldSupport.generatedSpend or 0)
    comparison.mismatch = (currentSupport.lockedCommitment or 0) + (currentSupport.generatedSpend or 0)
    comparison.previousWholeOutfitCohesion = oldSupport.wholeOutfitCohesion
    comparison.wholeOutfitCohesion = currentSupport.wholeOutfitCohesion
    comparison.previousOutliers = oldSupport.outliers or 0
    comparison.outliers = currentSupport.outliers or 0
end
