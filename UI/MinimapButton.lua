local QC = QuestChronicle

local BUTTON_NAME = "QuestChronicleMinimapButton"
local DEFAULT_ANGLE = 225
local MINIMAP_RADIUS = 80

local function EnsureState()
    local state = QC.GetUIState()
    state.minimap = state.minimap or {}
    if type(state.minimap.angle) ~= "number" then
        state.minimap.angle = DEFAULT_ANGLE
    end
    return state.minimap
end

local function Atan2(y, x)
    if math.atan2 then
        return math.atan2(y, x)
    end
    if _G.atan2 then
        return _G.atan2(y, x)
    end
    if x > 0 then
        return math.atan(y / x)
    elseif x < 0 and y >= 0 then
        return math.atan(y / x) + math.pi
    elseif x < 0 and y < 0 then
        return math.atan(y / x) - math.pi
    elseif x == 0 and y > 0 then
        return math.pi / 2
    elseif x == 0 and y < 0 then
        return -math.pi / 2
    end
    return 0
end

local function PositionButton(button, angle)
    if not button or not Minimap then
        return
    end

    angle = tonumber(angle) or DEFAULT_ANGLE
    local radians = math.rad(angle)
    button:ClearAllPoints()
    button:SetPoint(
        "CENTER",
        Minimap,
        "CENTER",
        math.cos(radians) * MINIMAP_RADIUS,
        math.sin(radians) * MINIMAP_RADIUS
    )
end

local function SaveButtonAngle(button)
    if not button or not Minimap then
        return
    end

    local minimapX, minimapY = Minimap:GetCenter()
    if not minimapX or not minimapY then
        return
    end

    local scale = Minimap:GetEffectiveScale() or 1
    local cursorX, cursorY = GetCursorPosition()
    cursorX = cursorX / scale
    cursorY = cursorY / scale

    local angle = math.deg(Atan2(cursorY - minimapY, cursorX - minimapX))
    EnsureState().angle = angle
    PositionButton(button, angle)
end

local function TooltipAnchor(button)
    local x = button and button.GetCenter and button:GetCenter()
    local width = UIParent and UIParent.GetWidth and UIParent:GetWidth() or 0
    if x and width > 0 and x < width / 2 then
        return "ANCHOR_RIGHT"
    end
    return "ANCHOR_LEFT"
end

local function UpdateVisibility(button)
    if not button then
        return
    end
    button:SetShown(QC.GetSettings().showMinimapButton ~= false)
end

function QC.ResetMinimapButtonPosition()
    local state = EnsureState()
    state.angle = DEFAULT_ANGLE
    if QC.minimapButton and QC.minimapButton:GetParent() == Minimap then
        PositionButton(QC.minimapButton, state.angle)
    end
    if QC.Print then
        QC.Print("Minimap button position reset.")
    end
end

function QC.SetMinimapButtonVisible(visible)
    QC.SetSetting("showMinimapButton", visible ~= false)
    if QC.minimapButton then
        UpdateVisibility(QC.minimapButton)
    end
end

function QC.InitializeMinimapButton()
    if QC.minimapButton then
        UpdateVisibility(QC.minimapButton)
        return QC.minimapButton
    end
    if not Minimap then
        return nil
    end

    local button = CreateFrame("Button", BUTTON_NAME, Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel((Minimap:GetFrameLevel() or 0) + 8)
    button:SetClampedToScreen(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetSize(20, 20)
    background:SetPoint("CENTER", 0, 0)
    button.background = background

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.icon = icon

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT", 0, 0)
    button.border = border

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    highlight:SetBlendMode("ADD")
    highlight:SetAllPoints(button)
    button.highlight = highlight

    button:SetScript("OnClick", function(self, mouseButton)
        if self.wasDragged then
            self.wasDragged = nil
            return
        end

        -- Minimap button organizers commonly reserve Ctrl+Right-click for
        -- returning an icon to the minimap. Do not consume that gesture.
        if mouseButton == "RightButton" and IsControlKeyDown and IsControlKeyDown() then
            return
        end

        if mouseButton == "RightButton" then
            QC.ShowWindow("status")
        else
            QC.ToggleWindow()
        end
    end)

    button:SetScript("OnDragStart", function(self)
        if IsShiftKeyDown and IsShiftKeyDown() then
            return
        end
        self.wasDragged = true
        self:SetScript("OnUpdate", function(dragButton)
            SaveButtonAngle(dragButton)
        end)
    end)

    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        SaveButtonAngle(self)
    end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, TooltipAnchor(self))
        GameTooltip:SetText("Quest Chronicle " .. tostring(QC.version or ""))
        GameTooltip:AddLine("Left-click to open the Chronicle.", 1, 1, 1)
        GameTooltip:AddLine("Right-click to open Status & Maintenance.", 1, 1, 1)
        GameTooltip:AddLine("Drag to move around the minimap.", 0.75, 0.75, 0.75)
        GameTooltip:AddLine("Ctrl+Right-click is left available for minimap button organizers.", 0.65, 0.65, 0.65, true)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    PositionButton(button, EnsureState().angle)
    QC.minimapButton = button
    UpdateVisibility(button)

    QC.RegisterCallback("SETTINGS_CHANGED", button, function(settingName)
        if settingName == "showMinimapButton" then
            UpdateVisibility(button)
        end
    end)

    return button
end
