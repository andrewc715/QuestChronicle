local QC = QuestChronicle
local UI = QC.UI
local D = QC.Diagnostics
UI._Debug = UI._Debug or {}
local P = UI._Debug

local function CreateHistoryRow(parent, index)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(42)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -34 - ((index - 1) * 45))
    row:SetPoint("RIGHT", parent, "RIGHT", -8, 0)
    local background = row:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(row)
    background:SetColorTexture(0.06, 0.06, 0.06, 0.76)
    row.background = background
    local highlight = row:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(row)
    highlight:SetColorTexture(0.50, 0.36, 0.10, 0.22)
    local title = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    title:SetPoint("TOPLEFT", row, "TOPLEFT", 6, -5)
    title:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    title:SetJustifyH("LEFT")
    row.title = title
    local detail = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    detail:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 6, 5)
    detail:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    detail:SetJustifyH("LEFT")
    row.detail = detail
    row:SetScript("OnClick", function(self)
        if not self.reportID then return end
        P.SelectReport(parent.ownerPane, self.reportID)
    end)
    row:Hide()
    return row
end

function P.CreateHistoryPanel(pane)
    local panel = UI.CreateInsetPanel(pane)
    panel:SetPoint("TOPLEFT", pane, "TOPLEFT", 12, -96)
    panel:SetPoint("BOTTOMLEFT", pane, "BOTTOMLEFT", 12, 12)
    panel:SetWidth(212)
    panel.ownerPane = pane
    pane.historyPanel = panel

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 9, -10)
    title:SetText("Generation History")

    panel.rows = {}
    for index = 1, D.MAX_REPORTS do panel.rows[index] = CreateHistoryRow(panel, index) end

    local empty = panel:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    empty:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -48)
    empty:SetPoint("RIGHT", panel, "RIGHT", -12, 0)
    empty:SetJustifyH("LEFT")
    empty:SetJustifyV("TOP")
    empty:SetText("No generation reports yet. Generate or reroll an outfit to create the first diagnostic snapshot.")
    panel.empty = empty
    return panel
end

function P.SelectReport(pane, reportID)
    if not pane then return end
    local report = D.GetReportByID(reportID)
    if not report then report = D.GetLatestReport() end
    pane.selectedReportID = report and report.id or nil
    QC.GetUIState().debugSelectedReportID = pane.selectedReportID
    P.RefreshHistory(pane)
    if P.RefreshSelectedReport then P.RefreshSelectedReport(pane, true) end
end

function P.RefreshHistory(pane)
    if not pane or not pane.historyPanel then return end
    local reports = D.GetReports()
    local selectedID = pane.selectedReportID or QC.GetUIState().debugSelectedReportID
    if selectedID and not D.GetReportByID(selectedID) then selectedID = nil end
    if not selectedID and reports[1] then selectedID = reports[1].id end
    pane.selectedReportID = selectedID
    QC.GetUIState().debugSelectedReportID = selectedID

    pane.historyPanel.empty:SetShown(#reports == 0)
    for index, row in ipairs(pane.historyPanel.rows) do
        local report = reports[index]
        row:SetShown(report ~= nil)
        if report then
            row.reportID = report.id
            local action = D.GetActionLabel(report.action)
            local clock = report.timestamp and date("%H:%M:%S", report.timestamp) or "--:--:--"
            row.title:SetText(clock .. "  " .. action)
            local performance = report.performance or {}
            row.detail:SetText(string.format("%s • %s • %.1f sec%s", D.GetModeLabel(report.mode), D.GetResultLabel(report.result), (tonumber(performance.elapsedMs) or 0) / 1000, report.skeleton and report.skeleton.chosenRank and (" • Rank " .. tostring(report.skeleton.chosenRank) .. "/" .. tostring(report.skeleton.shortlistSize or 0)) or ""))
            local selected = report.id == selectedID
            row.background:SetColorTexture(selected and 0.26 or 0.06, selected and 0.20 or 0.06, selected and 0.08 or 0.06, selected and 0.92 or 0.76)
        else
            row.reportID = nil
        end
    end
end
