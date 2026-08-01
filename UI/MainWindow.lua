local QC = QuestChronicle
local UI = QC.UI

local DEFAULT_WIDTH = 790
local DEFAULT_HEIGHT = 610
local MIN_WIDTH = 790
local MIN_HEIGHT = 610
local MAX_WIDTH = 1120
local MAX_HEIGHT = 880

local TAB_DEFINITIONS = {
    { key = "chronicle", label = "Chronicle", width = 122, tooltip = "Browse recorded quests, objectives, state changes, removals, and RP notes.", constructor = UI.CreateChronicleTab },
    { key = "active", label = "Active Quests", width = 142, tooltip = "Review the current active quest snapshot and objective progress.", constructor = UI.CreateActiveQuestsTab },
    { key = "note", label = "Write Note", width = 122, tooltip = "Record an RP observation with location and character context.", constructor = UI.CreateNoteTab },
    { key = "status", label = "Status", width = 102, tooltip = "Review recorder health, Courier readiness, settings, and maintenance tools.", constructor = UI.CreateStatusTab },
    { key = "outfits", label = "Outfits", width = 102, tooltip = "Generate, refine, preview, save, and load outfit concepts from collected appearances.", constructor = UI.CreateOutfitsTab },
}

local function Clamp(value, minimum, maximum)
    value = tonumber(value) or minimum
    return math.max(minimum, math.min(maximum, value))
end

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

    if settings.rememberWindowPosition then
        frame:SetSize(
            Clamp(state.width or DEFAULT_WIDTH, MIN_WIDTH, MAX_WIDTH),
            Clamp(state.height or DEFAULT_HEIGHT, MIN_HEIGHT, MAX_HEIGHT)
        )
    else
        frame:SetSize(DEFAULT_WIDTH, DEFAULT_HEIGHT)
    end

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
        "%s%s - %s|r    %s%s events • %s active quests|r",
        UI.gold,
        character.name or "Unknown",
        character.realm or "Unknown Realm",
        UI.muted,
        UI.FormatNumber(status.eventCount),
        UI.FormatNumber(status.activeQuestCount)
    ))
end

local function UpdateResizeGrip(frame)
    if frame.resizeGrip then
        frame.resizeGrip:SetShown(not QC.GetSettings().lockWindow)
    end
end

function QC.ResetWindowPosition()
    local state = QC.GetUIState().window
    for key in pairs(state) do
        state[key] = nil
    end

    local frame = QC.mainWindow
    if frame then
        frame:ClearAllPoints()
        frame:SetSize(DEFAULT_WIDTH, DEFAULT_HEIGHT)
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        SaveWindowPosition(frame)
    end
end

function QC.InitializeUI()
    if QC.mainWindow then
        return QC.mainWindow
    end

    local frame = CreateFrame("Frame", "QuestChronicleMainFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(DEFAULT_WIDTH, DEFAULT_HEIGHT)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:SetResizable(true)
    if frame.SetResizeBounds then
        frame:SetResizeBounds(MIN_WIDTH, MIN_HEIGHT, MAX_WIDTH, MAX_HEIGHT)
    elseif frame.SetMinResize and frame.SetMaxResize then
        frame:SetMinResize(MIN_WIDTH, MIN_HEIGHT)
        frame:SetMaxResize(MAX_WIDTH, MAX_HEIGHT)
    end
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
    tabBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12, 7)
    tabBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -28, 7)
    tabBar:SetHeight(32)
    frame.tabBar = tabBar

    local content = UI.CreateInsetPanel(frame)
    content:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -58)
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 41)
    frame.content = content

    local resizeGrip = CreateFrame("Button", nil, frame)
    resizeGrip:SetSize(16, 16)
    resizeGrip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 3)
    resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeGrip:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" and not QC.GetSettings().lockWindow then
            frame:StartSizing("BOTTOMRIGHT")
        end
    end)
    resizeGrip:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        SaveWindowPosition(frame)
    end)
    UI.SetTooltip(resizeGrip, "Resize Quest Chronicle", "Drag to resize the window. The size is saved with its position.", "ANCHOR_TOPLEFT")
    frame.resizeGrip = resizeGrip

    frame.tabs = {}
    frame.panes = {}
    local previousButton

    for _, definition in ipairs(TAB_DEFINITIONS) do
        local button = CreateFrame("Button", nil, tabBar, "PanelTabButtonTemplate")
        button:SetSize(definition.width or 120, 32)
        button:SetText(definition.label)
        if previousButton then
            button:SetPoint("LEFT", previousButton, "RIGHT", 1, 0)
        else
            button:SetPoint("BOTTOMLEFT", tabBar, "BOTTOMLEFT", 0, 0)
        end
        button.key = definition.key
        button:SetScript("OnClick", function(self)
            frame:SelectTab(self.key)
        end)
        UI.SetTooltip(button, definition.label, definition.tooltip)
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
            local tab = self.tabs[tabKey]
            if selected then
                if PanelTemplates_SelectTab then
                    PanelTemplates_SelectTab(tab)
                else
                    tab:LockHighlight()
                    tab:SetEnabled(false)
                end
            else
                if PanelTemplates_DeselectTab then
                    PanelTemplates_DeselectTab(tab)
                else
                    tab:UnlockHighlight()
                    tab:SetEnabled(true)
                end
            end
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
        UpdateResizeGrip(self)
        self:SelectTab(QC.GetUIState().lastTab or "chronicle")
    end)

    RestoreWindowPosition(frame)
    UpdateResizeGrip(frame)
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
        elseif settingName == "lockWindow" then
            UpdateResizeGrip(frame)
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
    GameTooltip:SetText("Quest Chronicle " .. tostring(QC.version or ""))
    GameTooltip:AddLine("Left-click to open the Chronicle.", 1, 1, 1)
    GameTooltip:AddLine("Right-click to open Status & Maintenance.", 1, 1, 1)
    GameTooltip:Show()
end

function QuestChronicle_OnAddonCompartmentLeave()
    GameTooltip:Hide()
end
