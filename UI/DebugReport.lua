local QC = QuestChronicle
local UI = QC.UI
local D = QC.Diagnostics
UI._Debug = UI._Debug or {}
local P = UI._Debug

local function CreateCheck(parent, label, x)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetSize(22, 22)
    check:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -65)
    local text = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    text:SetPoint("LEFT", check, "RIGHT", 1, 0)
    text:SetText(label)
    check.label = text
    return check
end

local function CreateCopyDialog(pane)
    local blocker = CreateFrame("Button", nil, pane)
    blocker:SetAllPoints(pane)
    blocker:SetFrameLevel(pane:GetFrameLevel() + 50)
    local shade = blocker:CreateTexture(nil, "BACKGROUND")
    shade:SetAllPoints(blocker)
    shade:SetColorTexture(0, 0, 0, 0.66)
    blocker:Hide()

    local dialog = UI.CreateInsetPanel(pane)
    dialog:SetSize(700, 440)
    dialog:SetPoint("CENTER", pane, "CENTER", 0, 0)
    dialog:SetFrameLevel(pane:GetFrameLevel() + 51)
    dialog:EnableMouse(true)
    dialog:Hide()

    local title = dialog:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", dialog, "TOPLEFT", 14, -12)
    title:SetText("Copy Diagnostic Report")
    local instruction = dialog:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    instruction:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
    instruction:SetText("The complete report is selected. Press Ctrl+C, then close this window.")

    local border = UI.CreateInsetPanel(dialog)
    border:SetPoint("TOPLEFT", dialog, "TOPLEFT", 12, -62)
    border:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -12, 48)
    local scroll = CreateFrame("ScrollFrame", nil, border, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", border, "TOPLEFT", 8, -8)
    scroll:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", -28, 8)
    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject("ChatFontNormal")
    edit:SetWidth(630)
    edit:SetTextInsets(4, 4, 4, 4)
    edit:SetScript("OnEscapePressed", function() dialog:Hide() blocker:Hide() end)
    edit:SetScript("OnTextChanged", function(self)
        self:SetHeight(math.max(scroll:GetHeight(), (self:GetNumLines() or 1) * 15 + 16))
        scroll:UpdateScrollChildRect()
    end)
    scroll:SetScrollChild(edit)

    local close = UI.CreateButton(dialog, "Close", 100, 26)
    close:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -12, 12)
    close:SetScript("OnClick", function() dialog:Hide() blocker:Hide() end)
    blocker:SetScript("OnClick", function() dialog:Hide() blocker:Hide() end)

    pane.copyBlocker, pane.copyDialog, pane.copyEdit = blocker, dialog, edit
    pane.copyTitle, pane.copyInstruction = title, instruction
end

function P.CreateReportPanel(pane)
    local panel = UI.CreateInsetPanel(pane)
    panel:SetPoint("TOPLEFT", pane.historyPanel, "TOPRIGHT", 8, 0)
    panel:SetPoint("BOTTOMRIGHT", pane, "BOTTOMRIGHT", -12, 12)
    pane.reportPanel = panel

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -10)
    title:SetText("Selected Report")
    pane.reportTitle = title

    local scroller = UI.CreateScrollableText(panel, -34, 10)
    pane.reportScroller = scroller
    CreateCopyDialog(pane)

    pane.rawIDs = CreateCheck(pane, "Show raw IDs", 242)
    pane.verbose = CreateCheck(pane, "Verbose diagnostics", 370)
    local uiState = QC.GetUIState()
    pane.rawIDs:SetChecked(uiState.debugRawIDs == true)
    pane.verbose:SetChecked(uiState.debugVerbose == true)
    pane.rawIDs:SetScript("OnClick", function(self)
        QC.GetUIState().debugRawIDs = self:GetChecked() == true
        P.RefreshSelectedReport(pane, false)
    end)
    pane.verbose:SetScript("OnClick", function(self)
        QC.GetUIState().debugVerbose = self:GetChecked() == true
        P.RefreshSelectedReport(pane, false)
    end)
end

function P.RefreshSelectedReport(pane, resetScroll)
    if not pane or not pane.reportScroller then return end
    local report = D.GetReportByID(pane.selectedReportID) or D.GetLatestReport()
    pane.selectedReportID = report and report.id or nil
    if not report then
        pane.reportTitle:SetText("Selected Report")
        pane.reportScroller:SetText("No diagnostic report is selected. Generate or reroll an outfit, then return to this tab.", resetScroll)
        return
    end
    pane.reportTitle:SetText(string.format("%s • %s", D.GetActionLabel(report.action), report.timestamp and date("%H:%M:%S", report.timestamp) or "Unknown time"))
    pane.reportScroller:SetText(D.FormatDisplayReport(report, pane.rawIDs:GetChecked() == true, pane.verbose:GetChecked() == true), resetScroll)
end

function P.ShowCopyText(pane, text, title, instruction)
    if not pane or not pane.copyDialog or type(text) ~= "string" then return false end
    pane.copyTitle:SetText(title or "Copy Diagnostic Report")
    pane.copyInstruction:SetText(instruction or "The complete text is selected. Press Ctrl+C, then close this window.")
    pane.copyBlocker:Show()
    pane.copyDialog:Show()
    pane.copyEdit:SetText(text)
    pane.copyEdit:SetFocus()
    pane.copyEdit:HighlightText()
    return true
end

function P.ShowCopyReport(pane)
    local report = D.GetReportByID(pane and pane.selectedReportID) or D.GetLatestReport()
    if not pane or not report then return false end
    local text = D.FormatCopyReport(report, pane.rawIDs:GetChecked() == true, pane.verbose:GetChecked() == true)
    return P.ShowCopyText(pane, text, "Copy Diagnostic Report", "The complete report is selected. Press Ctrl+C, then close this window.")
end

function QC.ShowTravelerTuningExport(text)
    if type(text) ~= "string" or text == "" then return false end
    if QC.ShowWindow then QC.ShowWindow("debug") end
    local function OpenExport()
        local pane = QC.mainWindow and QC.mainWindow.panes and QC.mainWindow.panes.debug
        return P.ShowCopyText(
            pane, text, "Copy Traveler Tuning Audit",
            "The complete Markdown audit is selected. Press Ctrl+C, save it, then close this window."
        )
    end
    if C_Timer and type(C_Timer.After) == "function" then
        C_Timer.After(0, OpenExport)
        return true
    end
    return OpenExport()
end
