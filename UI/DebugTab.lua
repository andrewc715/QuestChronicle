local QC = QuestChronicle
local UI = QC.UI
local D = QC.Diagnostics
UI._Debug = UI._Debug or {}
local P = UI._Debug

function UI.CreateDebugTab(parent)
    local pane = CreateFrame("Frame", nil, parent)
    pane:SetAllPoints(parent)

    UI.CreatePaneTitle(
        pane,
        "Debug Workbench",
        "Inspect immutable generation snapshots, anchor skeletons, beam search, scoring, performance, and cache behavior."
    )

    P.CreateHistoryPanel(pane)
    P.CreateReportPanel(pane)

    local refresh = UI.CreateButton(pane, "Refresh", 82, 24)
    refresh:SetPoint("TOPRIGHT", pane, "TOPRIGHT", -12, -63)
    local copy = UI.CreateButton(pane, "Copy Report", 105, 24)
    copy:SetPoint("RIGHT", refresh, "LEFT", -6, 0)
    local clear = UI.CreateButton(pane, "Clear History", 105, 24)
    clear:SetPoint("RIGHT", copy, "LEFT", -6, 0)
    pane.refreshButton, pane.copyButton, pane.clearButton = refresh, copy, clear

    refresh:SetScript("OnClick", function() pane:Refresh(false) end)
    copy:SetScript("OnClick", function()
        if not P.ShowCopyReport(pane) and UIErrorsFrame then UIErrorsFrame:AddMessage("No diagnostic report is available.", 1, 0.25, 0.25) end
    end)
    clear:SetScript("OnClick", function()
        D.ClearReports()
        pane.selectedReportID = nil
        pane:Refresh(true)
    end)
    UI.SetTooltip(copy, "Copy Selected Report", "Open a read-only report box with all text selected. Press Ctrl+C to copy it.")
    UI.SetTooltip(clear, "Clear Diagnostic History", "Remove only the ten bounded diagnostic snapshots. Chronicle history, concepts, and wardrobe caches are untouched.")
    UI.SetTooltip(refresh, "Refresh Debug View", "Re-read the selected immutable report without changing generation state.")

    function pane:Refresh(resetScroll)
        P.RefreshHistory(self)
        P.RefreshSelectedReport(self, resetScroll ~= false)
        local hasReport = D.GetLatestReport() ~= nil
        copy:SetEnabled(hasReport)
        clear:SetEnabled(hasReport)
    end

    QC.RegisterCallback("DIAGNOSTIC_REPORT_ADDED", pane, function(report)
        pane.selectedReportID = report and report.id or pane.selectedReportID
        if pane:IsShown() then pane:Refresh(true) end
    end)
    QC.RegisterCallback("DIAGNOSTIC_REPORTS_CLEARED", pane, function()
        pane.selectedReportID = nil
        if pane:IsShown() then pane:Refresh(true) end
    end)
    QC.RegisterCallback("PLAYER_READY", pane, function()
        D.InitializeHistory()
        if pane:IsShown() then pane:Refresh(true) end
    end)

    pane:SetScript("OnShow", function(self)
        self.selectedReportID = QC.GetUIState().debugSelectedReportID
        self:Refresh(true)
    end)
    return pane
end
