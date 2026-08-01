local QC = QuestChronicle
local UI = QC.UI

function UI.CreateNoteTab(parent)
    local pane = CreateFrame("Frame", nil, parent)
    pane:SetAllPoints(parent)

    UI.CreatePaneTitle(
        pane,
        "Write RP Note",
        "Record an observation with the character, level, time, zone, map, and coordinates captured automatically."
    )

    local locationText = pane:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    locationText:SetPoint("TOPLEFT", pane, "TOPLEFT", 12, -66)
    locationText:SetPoint("RIGHT", pane, "RIGHT", -12, 0)
    locationText:SetJustifyH("LEFT")
    pane.locationText = locationText

    local border = UI.CreateInsetPanel(pane)
    border:SetPoint("TOPLEFT", pane, "TOPLEFT", 12, -94)
    border:SetPoint("BOTTOMRIGHT", pane, "BOTTOMRIGHT", -30, 74)

    local scrollFrame = CreateFrame("ScrollFrame", nil, border, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", border, "TOPLEFT", 8, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", -28, 8)

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetTextInsets(4, 4, 4, 4)
    editBox:SetMaxLetters(4000)
    editBox:SetWidth(600)
    editBox:SetHeight(1200)
    editBox:SetJustifyH("LEFT")
    editBox:SetJustifyV("TOP")
    scrollFrame:SetScrollChild(editBox)
    pane.editBox = editBox

    local countText = pane:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    countText:SetPoint("BOTTOMLEFT", pane, "BOTTOMLEFT", 12, 50)
    pane.countText = countText

    local feedbackText = pane:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    feedbackText:SetPoint("LEFT", countText, "RIGHT", 20, 0)
    feedbackText:SetPoint("RIGHT", pane, "RIGHT", -12, 0)
    feedbackText:SetJustifyH("RIGHT")
    pane.feedbackText = feedbackText

    local clearButton = UI.CreateButton(pane, "Clear", 90, 24)
    clearButton:SetPoint("BOTTOMLEFT", pane, "BOTTOMLEFT", 12, 14)

    local recordCloseButton = UI.CreateButton(pane, "Record & Close", 130, 24)
    recordCloseButton:SetPoint("BOTTOMRIGHT", pane, "BOTTOMRIGHT", -12, 14)

    local recordButton = UI.CreateButton(pane, "Record Note", 120, 24)
    recordButton:SetPoint("RIGHT", recordCloseButton, "LEFT", -8, 0)

    local function GetDraftKey()
        local character = QC.GetCurrentCharacter()
        return character.key or "Unknown"
    end

    local function SaveDraft()
        local state = QC.GetUIState()
        state.noteDrafts[GetDraftKey()] = editBox:GetText() or ""
    end

    local function UpdateCount()
        countText:SetText(string.format("%d / 4000 characters", editBox:GetNumLetters() or 0))
    end

    local function UpdateLocation()
        local character = QC.GetCurrentCharacter()
        local location = QC.GetLocation()
        local parts = {
            character.name or character.key,
            location.zone ~= "" and location.zone or "Unknown zone",
        }
        if location.subZone and location.subZone ~= "" and location.subZone ~= location.zone then
            table.insert(parts, location.subZone)
        end
        table.insert(parts, "Level " .. tostring(UnitLevel("player") or 0))
        locationText:SetText(UI.gold .. table.concat(parts, " • ") .. UI.reset)
    end

    local function Record(closeAfter)
        local text = UI.Trim(editBox:GetText())
        if text == "" then
            feedbackText:SetText(UI.red .. "Write something before recording the note." .. UI.reset)
            return
        end

        local event = QC.RecordNote(text)
        if not event then
            feedbackText:SetText(UI.red .. "The note could not be recorded." .. UI.reset)
            return
        end

        editBox:SetText("")
        SaveDraft()
        feedbackText:SetText(UI.green .. "Recorded RP note #" .. tostring(event.sequence) .. "." .. UI.reset)
        if closeAfter and QC.HideWindow then
            QC.HideWindow()
        end
    end

    editBox:SetScript("OnTextChanged", function()
        SaveDraft()
        UpdateCount()
        feedbackText:SetText("")
    end)
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    editBox:SetScript("OnKeyDown", function(self, key)
        if key == "ENTER" and IsControlKeyDown and IsControlKeyDown() then
            self:SetPropagateKeyboardInput(false)
            Record(false)
        else
            self:SetPropagateKeyboardInput(true)
        end
    end)

    clearButton:SetScript("OnClick", function()
        editBox:SetText("")
        editBox:SetFocus()
        feedbackText:SetText(UI.muted .. "Draft cleared." .. UI.reset)
    end)
    recordButton:SetScript("OnClick", function()
        Record(false)
    end)
    recordCloseButton:SetScript("OnClick", function()
        Record(true)
    end)

    function pane:Refresh()
        UpdateLocation()
        UpdateCount()
    end

    pane:SetScript("OnShow", function()
        local state = QC.GetUIState()
        local draft = state.noteDrafts[GetDraftKey()] or ""
        if editBox:GetText() ~= draft then
            editBox:SetText(draft)
        end
        pane:Refresh()
    end)

    QC.RegisterCallback("PLAYER_READY", pane, function()
        pane:Refresh()
    end)

    return pane
end
