local QC = QuestChronicle
local UI = QC.UI

local TAB_DEFINITIONS = {
    { key = "chronicle", label = "Chronicle", constructor = UI.CreateChronicleTab },
    { key = "active", label = "Active Quests", constructor = UI.CreateActiveQuestsTab },
    { key = "note", label = "Write Note", constructor = UI.CreateNoteTab },
    { key = "status", label = "Status", constructor = UI.CreateStatusTab },
}

local function SaveWindowPosition(frame)
    local settings = QC.GetSettings()
    if not settings.rememberWindowPosition then
        return
    end

    local point, _, relativePoint, x, y = frame:GetPoint(1)
    local state = QC.GetUIState().window
    state.point = point
    state.relativePoint = relativePoint
    state.x = x
    state.y = y
    state.width = frame:GetWidth()
    state.height = frame:GetHeight()
end

local function RestoreWindowPosition(frame)
    local settings = QC.GetSettings()
    local state = QC.GetUIState().window
    frame:ClearAllPoints()

    if settings.rememberWindowPosition and state.point then
        frame:SetPoint(state.point, UIParent, state.relativePoint or state.point, state.x or 0, state.y or 0)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
end

local function UpdateHeader(frame)
    local character = QC.GetCurrentCharacter()
    local status = QC.GetStatus()
    frame.characterText:SetText(string.format(
        "%s%s - %s|r    %s%d events • %d active quests|r",
        UI.gold,
        character.name or "Unknown",
        character.realm or "Unknown Realm",
        UI.muted,
        status.eventCount,
        status.activeQuestCount
    ))
end

function QC.InitializeUI()
    if QC.mainWindow then
        return QC.mainWindow
    end

    local frame = CreateFrame("Frame", "QuestChronicleMainFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(790, 610)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:Hide()
    frame:SetScript("OnDragStart", function(self)
        if not QC.GetSettings().lockWindow then
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveWindowPosition(self)
    end)
    frame:SetScript("OnHide", function(self)
        SaveWindowPosition(self)
    end)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 34, 0)
    frame.title:SetText("Quest Chronicle")

    local icon = frame:CreateTexture(nil, "OVERLAY")
    icon:SetSize(20, 20)
    icon:SetPoint("LEFT", frame.TitleBg, "LEFT", 8, 0)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
    frame.icon = icon

    local characterText = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    characterText:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -36)
    characterText:SetPoint("RIGHT", frame, "RIGHT", -18, 0)
    characterText:SetJustifyH("LEFT")
    frame.characterText = characterText

    local tabBar = CreateFrame("Frame", nil, frame)
    tabBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -58)
    tabBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -58)
    tabBar:SetHeight(30)
    frame.tabBar = tabBar

    local content = UI.CreateInsetPanel(frame)
    content:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -92)
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 12)
    frame.content = content

    frame.tabs = {}
    frame.panes = {}
    local previousButton

    for _, definition in ipairs(TAB_DEFINITIONS) do
        local button = UI.CreateButton(tabBar, definition.label, 135, 26)
        if previousButton then
            button:SetPoint("LEFT", previousButton, "RIGHT", 6, 0)
        else
            button:SetPoint("LEFT", tabBar, "LEFT", 0, 0)
        end
        button.key = definition.key
        button:SetScript("OnClick", function(self)
            frame:SelectTab(self.key)
        end)
        frame.tabs[definition.key] = button
        previousButton = button

        local pane = definition.constructor(content)
        pane:Hide()
        frame.panes[definition.key] = pane
    end

    function frame:SelectTab(key)
        if not self.panes[key] then
            key = "chronicle"
        end

        for tabKey, pane in pairs(self.panes) do
            local selected = tabKey == key
            pane:SetShown(selected)
            self.tabs[tabKey]:SetEnabled(not selected)
        end

        self.selectedTab = key
        QC.GetUIState().lastTab = key
        UpdateHeader(self)
        local pane = self.panes[key]
        if pane and pane.Refresh then
            pane:Refresh()
        end
    end

    frame:SetScript("OnShow", function(self)
        UpdateHeader(self)
        self:SelectTab(QC.GetUIState().lastTab or "chronicle")
    end)

    RestoreWindowPosition(frame)
    frame:SelectTab(QC.GetUIState().lastTab or "chronicle")

    QC.mainWindow = frame
    table.insert(UISpecialFrames, frame:GetName())

    QC.RegisterCallback("EVENT_RECORDED", frame, function()
        if frame:IsShown() then
            UpdateHeader(frame)
        end
    end)
    QC.RegisterCallback("ACTIVE_QUESTS_UPDATED", frame, function()
        if frame:IsShown() then
            UpdateHeader(frame)
        end
    end)
    QC.RegisterCallback("SETTINGS_CHANGED", frame, function(settingName)
        if settingName == "rememberWindowPosition" and not QC.GetSettings().rememberWindowPosition then
            RestoreWindowPosition(frame)
        end
    end)
    QC.RegisterCallback("PLAYER_READY", frame, function()
        UpdateHeader(frame)
    end)

    return frame
end

function QC.ShowWindow(tabKey)
    local frame = QC.InitializeUI()
    if tabKey then
        QC.GetUIState().lastTab = tabKey
    end
    frame:Show()
    frame:Raise()
    frame:SelectTab(tabKey or QC.GetUIState().lastTab or "chronicle")
end

function QC.HideWindow()
    if QC.mainWindow then
        QC.mainWindow:Hide()
    end
end

function QC.ToggleWindow(tabKey)
    local frame = QC.InitializeUI()
    if frame:IsShown() then
        frame:Hide()
    else
        QC.ShowWindow(tabKey)
    end
end

function QuestChronicle_OnAddonCompartmentClick(_, buttonName)
    if buttonName == "RightButton" then
        QC.ShowWindow("status")
    else
        QC.ToggleWindow()
    end
end

function QuestChronicle_OnAddonCompartmentEnter(frame)
    GameTooltip:SetOwner(frame, "ANCHOR_LEFT")
    GameTooltip:SetText("Quest Chronicle")
    GameTooltip:AddLine("Left-click to open the Chronicle.", 1, 1, 1)
    GameTooltip:AddLine("Right-click to open Status & Maintenance.", 1, 1, 1)
    GameTooltip:Show()
end

function QuestChronicle_OnAddonCompartmentLeave()
    GameTooltip:Hide()
end
