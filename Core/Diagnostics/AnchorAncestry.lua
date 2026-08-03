local QC = QuestChronicle
local D = QC.Diagnostics
local P = D._Private

local function IsSupportSlot(slotKey)
    local wardrobe = QC.Wardrobe
    local private = wardrobe and wardrobe._Private
    if private and private.IsSupportSlotKey then return private.IsSupportSlotKey(slotKey) end
    for _, key in ipairs(private and private.SUPPORT_SLOT_ORDER or {}) do if key == slotKey then return true end end
    return false
end

function P.ActionPerformsAnchorSelection(action, slotKey)
    if action == "GENERATE_OUTFIT" or action == "REROLL_UNLOCKED" then return true end
    if action == "REROLL_SLOT" then return not IsSupportSlot(slotKey) end
    return false
end

function P.ReportPerformsAnchorSelection(report)
    if not report then return false end
    if report.performedAnchorSelection ~= nil then return report.performedAnchorSelection == true end
    return P.ActionPerformsAnchorSelection(report.action, report.actionSlotKey)
end

function D.GetLatestAnchorSourceReport(lineageID)
    for _, report in ipairs(D.PeekReports and D.PeekReports() or (D.GetReports and D.GetReports() or {})) do
        local completed = report.result == "COMPLETED" or report.result == "FALLBACK"
        local character = report.character or {}
        local reportLineage = report.lineageID or character.key or (tostring(character.name or "") .. "-" .. tostring(character.realm or ""))
        if completed and (not lineageID or reportLineage == lineageID) and P.ReportPerformsAnchorSelection(report) then return report end
    end
end

function P.ResolveAnchorSourceReport(report)
    if not report then return nil end
    if P.ReportPerformsAnchorSelection(report) then return report end
    local sourceID = report.anchorSourceReportID
    return sourceID and ((D.PeekReportByID and D.PeekReportByID(sourceID)) or (D.GetReportByID and D.GetReportByID(sourceID))) or nil
end
