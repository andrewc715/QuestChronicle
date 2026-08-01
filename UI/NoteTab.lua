local QC = QuestChronicle
local UI = QC.UI

local CLEAR_DIALOG = "QUEST_CHRONICLE_CLEAR_NOTE_DRAFT"
if StaticPopupDialogs and not StaticPopupDialogs[CLEAR_DIALOG] then
    StaticPopupDialogs[CLEAR_DIALOG] = {
        text = "Clear this unfinished Quest Chronicle note?",
        button1 = YES,
        button2 = NO,
        OnAccept = function(_, pane)
            if pane and pane.ClearDraft then
                pane:ClearDraft()
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end

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
    border:EnableMouse(true)

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

    local placeholder = border:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    placeholder:SetPoint("TOPLEFT", border, "TOPLEFT", 14, -14)
    placeholder:SetPoint("RIGHT", border, "RIGHT", -40, 0)
    placeholder:SetJustifyH("LEFT")
    placeholder:SetJustifyV("TOP")
    placeholder:SetText("Write the character's observation here...")
    pane.placeholder = placeholder

    local countText = pane:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    countText:SetPoint("BOTTOMLEFT", pane, "BOTTOMLEFT", 12, 50)
    pane.countText = countText

    local shortcutText = pane:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    shortcutText:SetPoint("LEFT", countText, "RIGHT", 18, 0)
    shortcutText:SetText(UI.muted .. "Ctrl+Enter records without closing" .. UI.reset)

    local feedbackText = pane:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    feedbackText:SetPoint("LEFT", shortcutText, "RIGHT", 20, 0)
    feedbackText:SetPoint("RIGHT", pane, "RIGHT", -12, 0)
    feedbackText:SetJustifyH("RIGHT")
    pane.feedbackText = feedbackText

    local clearButton = UI.CreateButton(pane, "Clear Draft", 100, 24)
    clearButton:SetPoint("BOTTOMLEFT", pane, "BOTTOMLEFT", 12, 14)

    local recordCloseButton = UI.CreateButton(pane, "Record & Close", 130, 24)
    recordCloseButton:SetPoint("BOTTOMRIGHT", pane, "BOTTOMRIGHT", -12, 14)

    local recordButton = UI.CreateButton(pane, "Record Note", 120, 24)
    recordButton:SetPoint("RIGHT", recordCloseButton, "LEFT", -8, 0)

    UI.SetTooltip(clearButton, "Clear Draft", "Erase the unfinished note stored for this character.")
    UI.SetTooltip(recordButton, "Record Note", "Record the note and keep the Quest Chronicle window open. Ctrl+Enter performs the same action.")
    UI.SetTooltip(recordCloseButton, "Record and Close", "Record the note, clear its draft, and close the Quest Chronicle window.")

    local function GetDraftKey()
        local character = QC.GetCurrentCharacter()
        return character.key or "Unknown"
    end

    local function SaveDraft()
        local state = QC.GetUIState()
        state.noteDrafts[GetDraftKey()] = editBox:GetText() or ""
    end

    local function HasText()
        return UI.Trim(editBox:GetText()) ~= ""
    end

    local function UpdateControls()
        local count = editBox:GetNumLetters() or 0
        local countColor = count >= 3900 and UI.red or (count >= 3500 and UI.orange or UI.white)
        countText:SetText(string.format("%s%d / 4000|r characters", countColor, count))

        local hasText = HasText()
        local recordingEnabled = QC.GetSettings().enabled == true
        clearButton:SetEnabled(hasText)
        recordButton:SetEnabled(hasText and recordingEnabled)
        recordCloseButton:SetEnabled(hasText and recordingEnabled)
        placeholder:SetShown(not hasText and not editBox:HasFocus())
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
        placeholder:SetText("Write " .. (character.name or "the character") .. "'s observation here...")
    end

    local function ResizeEditor()
        local width = math.max(300, scrollFrame:GetWidth() - 12)
        editBox:SetWidth(width)
        editBox:SetHeight(math.max(1200, scrollFrame:GetHeight()))
    end

    local function Record(closeAfter)
        local text = UI.Trim(editBox:GetText())
        if text == "" then
            feedbackText:SetText(UI.red .. "Write something before recording the note." .. UI.reset)
            return
        end
        if not QC.GetSettings().enabled then
            feedbackText:SetText(UI.red .. "Quest Chronicle recording is disabled in Status & Maintenance." .. UI.reset)
            return
        end

        local event = QC.RecordNote(text)
        if not event then
            feedbackText:SetText(UI.red .. "The note could not be recorded." .. UI.reset)
            return
        end

        editBox:SetText("")
        SaveDraft()
        editBox:ClearFocus()
        feedbackText:SetText(UI.green .. "Recorded RP note #" .. tostring(event.sequence) .. "." .. UI.reset)
        UpdateControls()
        if closeAfter and QC.HideWindow then
            QC.HideWindow()
        end
    end

    function pane:ClearDraft()
        editBox:SetText("")
        SaveDraft()
        editBox:SetFocus()
        feedbackText:SetText(UI.muted .. "Draft cleared." .. UI.reset)
        UpdateControls()
    end

    editBox:SetScript("OnTextChanged", function()
        SaveDraft()
        UpdateControls()
        feedbackText:SetText("")
    end)
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    editBox:SetScript("OnEditFocusGained", UpdateControls)
    editBox:SetScript("OnEditFocusLost", UpdateControls)
    editBox:SetScript("OnKeyDown", function(self, key)
        if key == "ENTER" and IsControlKeyDown and IsControlKeyDown() then
            self:SetPropagateKeyboardInput(false)
            Record(false)
        else
            self:SetPropagateKeyboardInput(true)
        end
    end)

    border:SetScript("OnMouseDown", function()
        editBox:SetFocus()
    end)
    scrollFrame:SetScript("OnSizeChanged", ResizeEditor)

    clearButton:SetScript("OnClick", function()
        if not HasText() then
            return
        end
        if QC.GetSettings().confirmClearDraft ~= false and StaticPopup_Show then
            StaticPopup_Show(CLEAR_DIALOG, nil, nil, pane)
        else
            pane:ClearDraft()
        end
    end)
    recordButton:SetScript("OnClick", function()
        Record(false)
    end)
    recordCloseButton:SetScript("OnClick", function()
        Record(true)
    end)

    function pane:Refresh()
        UpdateLocation()
        ResizeEditor()
        UpdateControls()
    end

    pane:SetScript("OnShow", function()
        local state = QC.GetUIState()
        local draft = state.noteDrafts[GetDraftKey()] or ""
        if editBox:GetText() ~= draft then
            editBox:SetText(draft)
        end
        feedbackText:SetText("")
        pane:Refresh()
    end)

    QC.RegisterCallback("SETTINGS_CHANGED", pane, function(settingName)
        if settingName == "enabled" then
            UpdateControls()
        end
    end)
    QC.RegisterCallback("PLAYER_READY", pane, function()
        pane:Refresh()
    end)

    return pane
end
