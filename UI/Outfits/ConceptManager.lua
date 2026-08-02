local QC = QuestChronicle
local UI = QC.UI
local Wardrobe = QC.Wardrobe
local ZoneStyle = QC.ZoneStyle
UI._Outfits = UI._Outfits or {}
local P = UI._Outfits

P.builders = P.builders or {}
P.builders[#P.builders + 1] = function(C)
    C.managerTitle = C.conceptManager:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    C.managerTitle:SetPoint("TOPLEFT", C.conceptManager, "TOPLEFT", 14, -13)
    C.managerTitle:SetText("Outfit Concepts")

    C.managerClose = UI.CreateButton(C.conceptManager, "X", 26, 24)
    C.managerClose:SetPoint("TOPRIGHT", C.conceptManager, "TOPRIGHT", -9, -8)

    C.nameLabel = C.conceptManager:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    C.nameLabel:SetPoint("TOPLEFT", C.conceptManager, "TOPLEFT", 15, -47)
    C.nameLabel:SetText("Concept Name")

    C.conceptName = CreateFrame("EditBox", nil, C.conceptManager, "InputBoxTemplate")
    C.conceptName:SetSize(278, 26)
    C.conceptName:SetPoint("TOPLEFT", C.nameLabel, "BOTTOMLEFT", 2, -3)
    C.conceptName:SetAutoFocus(false)
    C.conceptName:SetMaxLetters(48)
    C.pane.conceptName = C.conceptName

    C.saveCurrent = UI.CreateButton(C.conceptManager, "Save / Update", 122, 25)
    C.saveCurrent:SetPoint("LEFT", C.conceptName, "RIGHT", 11, 0)
    UI.SetTooltip(C.saveCurrent, "Save Current Preview", "Save or update the concept inside Quest Chronicle only. Native Custom Sets are managed separately with the buttons below.")

    C.managerStatus = C.conceptManager:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    C.managerStatus:SetPoint("TOPLEFT", C.conceptManager, "TOPLEFT", 15, -89)
    C.managerStatus:SetPoint("RIGHT", C.conceptManager, "RIGHT", -15, 0)
    C.managerStatus:SetHeight(20)
    C.managerStatus:SetJustifyH("LEFT")
    C.managerStatus:SetWordWrap(false)

    C.conceptManager.rows = {}
    for index = 1, P.CONCEPT_ROWS do
        local row = CreateFrame("Button", nil, C.conceptManager)
        row:SetHeight(43)
        row:SetPoint("LEFT", C.conceptManager, "LEFT", 15, 0)
        row:SetPoint("RIGHT", C.conceptManager, "RIGHT", -15, 0)
        if index == 1 then
            row:SetPoint("TOP", C.conceptManager, "TOP", 0, -112)
        else
            row:SetPoint("TOP", C.conceptManager.rows[index - 1], "BOTTOM", 0, -4)
        end

        local background = row:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints(row)
        background:SetColorTexture(0.07, 0.07, 0.07, 0.92)
        row.background = background

        local name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        name:SetPoint("TOPLEFT", row, "TOPLEFT", 9, -6)
        name:SetPoint("RIGHT", row, "RIGHT", -9, 0)
        name:SetJustifyH("LEFT")
        name:SetWordWrap(false)
        row.name = name

        local detail = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        detail:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 9, 6)
        detail:SetPoint("RIGHT", row, "RIGHT", -9, 0)
        detail:SetJustifyH("LEFT")
        detail:SetWordWrap(false)
        row.detail = detail

        row:SetScript("OnClick", function(self)
            if self.concept then
                C.conceptManager.selectedConceptID = self.concept.id
                C.conceptManager.pendingDeleteID = nil
                C.conceptName:SetText(self.concept.name or "")
                C.conceptManager:Refresh()
            end
        end)
        row:SetScript("OnEnter", function(self)
            if self.concept then
                self.background:SetColorTexture(0.18, 0.14, 0.06, 0.96)
            end
        end)
        row:SetScript("OnLeave", function(self)
            local selected = self.concept and self.concept.id == C.conceptManager.selectedConceptID
            self.background:SetColorTexture(selected and 0.20 or 0.07, selected and 0.15 or 0.07, selected and 0.05 or 0.07, 0.92)
        end)
        C.conceptManager.rows[index] = row
    end

    -- Native Custom Set actions occupy their own row. Keeping them separate
    -- from paging and local concept actions prevents the footer from exceeding
    -- the manager width at the minimum Quest Chronicle window size.
    C.syncSelected = UI.CreateButton(C.conceptManager, "Save to Custom Sets", 150, 23)
    C.syncSelected:SetPoint("BOTTOMLEFT", C.conceptManager, "BOTTOMLEFT", 151, 43)
    C.saveAsNew = UI.CreateButton(C.conceptManager, "Save as New", 108, 23)
    C.saveAsNew:SetPoint("LEFT", C.syncSelected, "RIGHT", 8, 0)
    C.replaceExisting = UI.CreateButton(C.conceptManager, "Replace Existing", 124, 23)
    C.replaceExisting:SetPoint("LEFT", C.saveAsNew, "RIGHT", 8, 0)

    -- Paging remains on the lower-left; local load/delete actions remain on the
    -- lower-right. These groups no longer compete for the same horizontal run.
    C.previousConcepts = UI.CreateButton(C.conceptManager, "<", 28, 23)
    C.previousConcepts:SetPoint("BOTTOMLEFT", C.conceptManager, "BOTTOMLEFT", 15, 12)
    C.conceptPage = C.conceptManager:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    C.conceptPage:SetPoint("LEFT", C.previousConcepts, "RIGHT", 6, 0)
    C.conceptPage:SetWidth(72)
    C.conceptPage:SetJustifyH("CENTER")
    C.nextConcepts = UI.CreateButton(C.conceptManager, ">", 28, 23)
    C.nextConcepts:SetPoint("LEFT", C.conceptPage, "RIGHT", 6, 0)

    C.deleteSelected = UI.CreateButton(C.conceptManager, "Delete", 92, 23)
    C.deleteSelected:SetPoint("BOTTOMRIGHT", C.conceptManager, "BOTTOMRIGHT", -15, 12)
    C.loadSelected = UI.CreateButton(C.conceptManager, "Load Selected", 118, 23)
    C.loadSelected:SetPoint("RIGHT", C.deleteSelected, "LEFT", -8, 0)
    UI.SetTooltip(C.syncSelected, "Save to Custom Sets", "Create a new WoW Custom Set for this concept, or update its linked Custom Set. Quest Chronicle remains the authoritative backup and nothing is applied to your character.")
    UI.SetTooltip(C.saveAsNew, "Save as New Custom Set", "Create another WoW Custom Set from the selected Quest Chronicle concept without replacing its currently linked set.")
    UI.SetTooltip(C.replaceExisting, "Replace Existing Custom Set", "Choose an existing WoW Custom Set and replace its appearance recipe. Quest Chronicle keeps the original concept as the authoritative backup.")
    UI.SetTooltip(C.loadSelected, "Load Selected Concept", "Restore the selected appearances, locks, hidden slots, and weapon configuration to the preview.")
    UI.SetTooltip(C.deleteSelected, "Delete Selected Concept", "Requires a second confirmation click. Deleting a concept does not delete its linked WoW Custom Set.")

    C.customSetBlocker = CreateFrame("Button", nil, C.conceptManager)
    C.customSetBlocker:SetAllPoints(C.conceptManager)
    C.customSetBlocker:SetFrameLevel(C.conceptManager:GetFrameLevel() + 10)
    C.customSetShade = C.customSetBlocker:CreateTexture(nil, "BACKGROUND")
    C.customSetShade:SetAllPoints(C.customSetBlocker)
    C.customSetShade:SetColorTexture(0, 0, 0, 0.62)
    C.customSetBlocker:Hide()

    C.customSetPicker = UI.CreateInsetPanel(C.conceptManager)
    C.customSetPicker:SetSize(450, 315)
    C.customSetPicker:SetPoint("CENTER", C.conceptManager, "CENTER", 0, 0)
    C.customSetPicker:SetFrameLevel(C.conceptManager:GetFrameLevel() + 11)
    C.customSetPicker:Hide()
    C.customSetPicker.page = 1

    C.pickerTitle = C.customSetPicker:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    C.pickerTitle:SetPoint("TOPLEFT", C.customSetPicker, "TOPLEFT", 14, -13)
    C.pickerTitle:SetText("Replace Existing Custom Set")
    C.pickerClose = UI.CreateButton(C.customSetPicker, "X", 26, 24)
    C.pickerClose:SetPoint("TOPRIGHT", C.customSetPicker, "TOPRIGHT", -9, -8)
    C.pickerStatus = C.customSetPicker:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    C.pickerStatus:SetPoint("TOPLEFT", C.customSetPicker, "TOPLEFT", 15, -47)
    C.pickerStatus:SetPoint("RIGHT", C.customSetPicker, "RIGHT", -15, 0)
    C.pickerStatus:SetJustifyH("LEFT")
    C.pickerStatus:SetText("Select the native Custom Set whose appearances should be replaced.")

    C.customSetPicker.rows = {}
    for index = 1, P.CUSTOM_SET_ROWS do
        local row = CreateFrame("Button", nil, C.customSetPicker)
        row:SetHeight(38)
        row:SetPoint("LEFT", C.customSetPicker, "LEFT", 15, 0)
        row:SetPoint("RIGHT", C.customSetPicker, "RIGHT", -15, 0)
        if index == 1 then row:SetPoint("TOP", C.customSetPicker, "TOP", 0, -72)
        else row:SetPoint("TOP", C.customSetPicker.rows[index - 1], "BOTTOM", 0, -4) end
        local background = row:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints(row)
        background:SetColorTexture(0.07, 0.07, 0.07, 0.94)
        row.background = background
        local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        label:SetPoint("LEFT", row, "LEFT", 9, 0)
        label:SetPoint("RIGHT", row, "RIGHT", -9, 0)
        label:SetJustifyH("LEFT")
        row.label = label
        row:SetScript("OnClick", function(self)
            C.customSetPicker.selectedCustomSetID = self.customSet and self.customSet.customSetID or nil
            C.customSetPicker:Refresh()
        end)
        C.customSetPicker.rows[index] = row
    end

    C.pickerPrevious = UI.CreateButton(C.customSetPicker, "<", 28, 23)
    C.pickerPrevious:SetPoint("BOTTOMLEFT", C.customSetPicker, "BOTTOMLEFT", 15, 12)
    C.pickerPage = C.customSetPicker:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    C.pickerPage:SetPoint("LEFT", C.pickerPrevious, "RIGHT", 6, 0)
    C.pickerPage:SetWidth(72)
    C.pickerPage:SetJustifyH("CENTER")
    C.pickerNext = UI.CreateButton(C.customSetPicker, ">", 28, 23)
    C.pickerNext:SetPoint("LEFT", C.pickerPage, "RIGHT", 6, 0)
    C.pickerReplace = UI.CreateButton(C.customSetPicker, "Replace Selected", 125, 23)
    C.pickerReplace:SetPoint("BOTTOMRIGHT", C.customSetPicker, "BOTTOMRIGHT", -15, 12)

    function C.customSetPicker:Refresh(message)
        local sets = Wardrobe.GetCustomSets()
        local pageCount = math.max(1, math.ceil(#sets / P.CUSTOM_SET_ROWS))
        self.page = math.max(1, math.min(self.page or 1, pageCount))
        local startIndex = ((self.page - 1) * P.CUSTOM_SET_ROWS) + 1
        for rowIndex, row in ipairs(self.rows) do
            local info = sets[startIndex + rowIndex - 1]
            row.customSet = info
            row:SetShown(info ~= nil)
            if info then
                local selected = info.customSetID == self.selectedCustomSetID
                row.label:SetText((selected and UI.gold or UI.white) .. tostring(info.name or "Unnamed Custom Set") .. UI.reset)
                row.background:SetColorTexture(selected and 0.20 or 0.07, selected and 0.15 or 0.07, selected and 0.05 or 0.07, 0.94)
            end
        end
        C.pickerPrevious:SetEnabled(self.page > 1)
        C.pickerNext:SetEnabled(self.page < pageCount)
        C.pickerPage:SetText(string.format("%d / %d", self.page, pageCount))
        C.pickerReplace:SetEnabled(self.selectedCustomSetID ~= nil)
        C.pickerStatus:SetText(message or (#sets > 0 and "Select the native Custom Set whose appearances should be replaced." or "No WoW Custom Sets are available to replace."))
    end

    function C.CloseCustomSetPicker()
        C.customSetPicker:Hide()
        C.customSetBlocker:Hide()
    end
    C.pickerClose:SetScript("OnClick", C.CloseCustomSetPicker)
    C.pickerPrevious:SetScript("OnClick", function() C.customSetPicker.page = C.customSetPicker.page - 1; C.customSetPicker.selectedCustomSetID = nil; C.customSetPicker:Refresh() end)
    C.pickerNext:SetScript("OnClick", function() C.customSetPicker.page = C.customSetPicker.page + 1; C.customSetPicker.selectedCustomSetID = nil; C.customSetPicker:Refresh() end)
    C.pickerReplace:SetScript("OnClick", function()
        if not C.conceptManager.selectedConceptID or not C.customSetPicker.selectedCustomSetID then return end
        local ok, message = Wardrobe.SaveConceptToCustomSet(C.conceptManager.selectedConceptID, "replace", C.customSetPicker.selectedCustomSetID)
        if ok then C.CloseCustomSetPicker() end
        C.conceptManager:Refresh(message)
        if not ok and UIErrorsFrame then UIErrorsFrame:AddMessage(message or "Unable to replace the Custom Set.", 1, 0.25, 0.25) end
    end)

    function C.conceptManager:Refresh(message)
        local concepts = Wardrobe.GetConcepts()
        local pageCount = math.max(1, math.ceil(#concepts / P.CONCEPT_ROWS))
        self.page = math.max(1, math.min(tonumber(self.page) or 1, pageCount))

        local selectedExists = false
        for _, concept in ipairs(concepts) do
            if concept.id == self.selectedConceptID then
                selectedExists = true
                break
            end
        end
        if not selectedExists then
            self.selectedConceptID = nil
            self.pendingDeleteID = nil
        end

        local startIndex = ((self.page - 1) * P.CONCEPT_ROWS) + 1
        for rowIndex, row in ipairs(self.rows) do
            local concept = concepts[startIndex + rowIndex - 1]
            row.concept = concept
            row:SetShown(concept ~= nil)
            if concept then
                local selected = concept.id == self.selectedConceptID
                row.name:SetText((selected and UI.gold or UI.white) .. tostring(concept.name or "Unnamed Concept") .. UI.reset)
                row.detail:SetText(P.ConceptDetail(concept))
                row.background:SetColorTexture(selected and 0.20 or 0.07, selected and 0.15 or 0.07, selected and 0.05 or 0.07, 0.92)
            end
        end

        local canSave = next(P.GetState().selections) ~= nil or next(P.GetState().locks) ~= nil or next(P.GetState().hidden) ~= nil
        C.saveCurrent:SetEnabled(canSave)
        local selectedConcept
        if self.selectedConceptID then
            for _, concept in ipairs(concepts) do if concept.id == self.selectedConceptID then selectedConcept = concept break end end
        end
        local customSetSupported = Wardrobe.IsCustomSetSavingSupported()
        local linked = selectedConcept and selectedConcept.blizzardCustomSetID ~= nil
        C.syncSelected:SetText(linked and "Update Custom Set" or "Save to Custom Sets")
        C.syncSelected:SetEnabled(selectedConcept ~= nil and customSetSupported)
        C.saveAsNew:SetEnabled(selectedConcept ~= nil and customSetSupported)
        C.replaceExisting:SetEnabled(selectedConcept ~= nil and customSetSupported and #Wardrobe.GetCustomSets() > 0)
        C.loadSelected:SetEnabled(self.selectedConceptID ~= nil)
        C.deleteSelected:SetEnabled(self.selectedConceptID ~= nil)
        C.deleteSelected:SetText(self.pendingDeleteID == self.selectedConceptID and "Confirm Delete" or "Delete")
        C.previousConcepts:SetEnabled(self.page > 1)
        C.nextConcepts:SetEnabled(self.page < pageCount)
        C.conceptPage:SetText(string.format("%d / %d", self.page, pageCount))
        C.managerStatus:SetText(message or (#concepts > 0 and string.format("%d saved concept%s for this character.", #concepts, #concepts == 1 and "" or "s") or "No concepts saved yet. Name the current preview and save it."))
    end

    function C.conceptManager:Open(forSaving)
        local concepts = Wardrobe.GetConcepts()
        local current = Wardrobe.GetCurrentConcept()
        self.selectedConceptID = current and current.id or (not forSaving and concepts[1] and concepts[1].id or nil)
        self.pendingDeleteID = nil
        self.page = 1
        if self.selectedConceptID then
            for index, concept in ipairs(concepts) do
                if concept.id == self.selectedConceptID then
                    self.page = math.ceil(index / P.CONCEPT_ROWS)
                    break
                end
            end
        end
        C.conceptName:SetText(current and current.name or (forSaving and C.pane:GetSuggestedConceptName() or (concepts[1] and concepts[1].name or C.pane:GetSuggestedConceptName())))
        C.conceptBlocker:Show()
        self:Show()
        self:Refresh()
        if forSaving then
            C.conceptName:SetFocus()
            C.conceptName:HighlightText()
        else
            C.conceptName:ClearFocus()
        end
    end

    function C.CloseConceptManager()
        C.conceptName:ClearFocus()
        C.conceptManager:Hide()
        C.conceptBlocker:Hide()
    end

    C.managerClose:SetScript("OnClick", C.CloseConceptManager)
    C.conceptManager:SetScript("OnHide", function()
        C.conceptBlocker:Hide()
    end)
    C.conceptName:SetScript("OnEscapePressed", C.CloseConceptManager)
    C.conceptName:SetScript("OnEnterPressed", function()
        C.saveCurrent:Click()
    end)
    C.previousConcepts:SetScript("OnClick", function()
        C.conceptManager.page = C.conceptManager.page - 1
        C.conceptManager.selectedConceptID = nil
        C.conceptManager.pendingDeleteID = nil
        C.conceptManager:Refresh()
    end)
    C.nextConcepts:SetScript("OnClick", function()
        C.conceptManager.page = C.conceptManager.page + 1
        C.conceptManager.selectedConceptID = nil
        C.conceptManager.pendingDeleteID = nil
        C.conceptManager:Refresh()
    end)
    C.saveCurrent:SetScript("OnClick", function()
        local ok, message, concept = C.pane:SaveConcept(C.conceptName:GetText())
        if ok and concept then
            C.conceptManager.selectedConceptID = concept.id
            C.conceptManager.pendingDeleteID = nil
            C.conceptManager.page = 1
            C.conceptName:SetText(concept.name or "")
            C.conceptName:ClearFocus()
        end
        C.conceptManager:Refresh(message)
    end)
    C.syncSelected:SetScript("OnClick", function()
        if not C.conceptManager.selectedConceptID then return end
        local ok, message = Wardrobe.SaveConceptToCustomSet(C.conceptManager.selectedConceptID, "auto")
        if not ok and UIErrorsFrame then UIErrorsFrame:AddMessage(message or "Unable to save the Custom Set.", 1, 0.25, 0.25) end
        C.conceptManager:Refresh(message)
    end)
    C.saveAsNew:SetScript("OnClick", function()
        if not C.conceptManager.selectedConceptID then return end
        local ok, message = Wardrobe.SaveConceptToCustomSet(C.conceptManager.selectedConceptID, "new")
        if not ok and UIErrorsFrame then UIErrorsFrame:AddMessage(message or "Unable to create the Custom Set.", 1, 0.25, 0.25) end
        C.conceptManager:Refresh(message)
    end)
    C.replaceExisting:SetScript("OnClick", function()
        if not C.conceptManager.selectedConceptID then return end
        C.customSetPicker.selectedCustomSetID = nil
        C.customSetPicker.page = 1
        C.customSetBlocker:Show()
        C.customSetPicker:Show()
        C.customSetPicker:Refresh()
    end)
    C.loadSelected:SetScript("OnClick", function()
        if C.conceptManager.selectedConceptID then
            local ok = C.pane:LoadConcept(C.conceptManager.selectedConceptID)
            if ok then
                C.CloseConceptManager()
            end
        end
    end)
    C.deleteSelected:SetScript("OnClick", function()
        local conceptID = C.conceptManager.selectedConceptID
        if not conceptID then return end
        if C.conceptManager.pendingDeleteID ~= conceptID then
            C.conceptManager.pendingDeleteID = conceptID
            C.conceptManager:Refresh("Click Confirm Delete to permanently remove the selected concept.")
            return
        end
        local ok, message = Wardrobe.DeleteConcept(conceptID)
        if ok then
            C.conceptManager.selectedConceptID = nil
            C.conceptManager.pendingDeleteID = nil
            C.pane:Refresh(message)
        elseif UIErrorsFrame then
            UIErrorsFrame:AddMessage(message or "Unable to delete outfit concept.", 1, 0.25, 0.25)
        end
        C.conceptManager:Refresh(message)
    end)

    C.saveConcept:SetScript("OnClick", function()
        C.conceptManager:Open(true)
    end)
    C.loadConcept:SetScript("OnClick", function()
        C.conceptManager:Open(false)
    end)

    C.scanButton = UI.CreateButton(C.sourcePanel, "Scan Collection", 125, 24)
    C.scanButton:SetPoint("TOPRIGHT", C.sourcePanel, "TOPRIGHT", -10, -8)
    C.pane.scanButton = C.scanButton
    UI.SetTooltip(C.scanButton, "Scan Collection", "Refresh the local cache of collected, previewable appearances. Keep Blizzard's Wardrobe and Transmogrify windows closed during the scan.", "ANCHOR_LEFT")

    C.staleHitbox = CreateFrame("Button", nil, C.sourcePanel)
    C.staleHitbox:SetPoint("TOPRIGHT", C.scanButton, "TOPLEFT", -8, 0)
    C.staleHitbox:SetSize(132, 24)
    C.staleHitbox:Hide()
    C.pane.staleHitbox = C.staleHitbox

    C.staleText = C.staleHitbox:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    C.staleText:SetAllPoints(C.staleHitbox)
    C.staleText:SetJustifyH("RIGHT")
    C.staleText:SetText("Collection may be stale")
    C.staleText:SetTextColor(1.0, 0.55, 0.12)
    C.pane.staleText = C.staleText
    UI.SetTooltip(C.staleHitbox, "Collection May Be Stale", "WoW reported a transmog collection change after the last scan. Quest Chronicle will not rescan automatically during this session; click Scan Collection when convenient.", "ANCHOR_LEFT")

    C.sourceTitle = C.sourcePanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    C.sourceTitle:SetPoint("TOPLEFT", C.sourcePanel, "TOPLEFT", 10, -10)
    C.sourceTitle:SetPoint("RIGHT", C.staleHitbox, "LEFT", -8, 0)
    C.sourceTitle:SetJustifyH("LEFT")
    C.pane.sourceTitle = C.sourceTitle

    C.clearSlot = UI.CreateButton(C.sourcePanel, "Clear Slot", 82, 22)
    C.clearSlot:SetPoint("TOPRIGHT", C.sourcePanel, "TOPRIGHT", -10, -37)
    C.pane.clearSlot = C.clearSlot

    C.selectedText = C.sourcePanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    C.selectedText:SetPoint("TOPLEFT", C.sourcePanel, "TOPLEFT", 10, -40)
    C.selectedText:SetPoint("RIGHT", C.clearSlot, "LEFT", -8, 0)
    C.selectedText:SetJustifyH("LEFT")
    C.selectedText:SetWordWrap(false)
    C.pane.selectedText = C.selectedText

    C.statusText = C.sourcePanel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    C.statusText:SetPoint("TOPLEFT", C.sourcePanel, "TOPLEFT", 10, -116)
    C.statusText:SetPoint("RIGHT", C.sourcePanel, "RIGHT", -10, 0)
    C.statusText:SetHeight(28)
    C.statusText:SetJustifyH("LEFT")
    C.statusText:SetJustifyV("TOP")
    C.statusText:SetWordWrap(true)
    if C.statusText.SetMaxLines then C.statusText:SetMaxLines(2) end
    C.pane.statusText = C.statusText
end
