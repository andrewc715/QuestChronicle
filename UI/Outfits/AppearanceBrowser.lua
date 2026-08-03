local QC = QuestChronicle
local UI = QC.UI
local Wardrobe = QC.Wardrobe
local ZoneStyle = QC.ZoneStyle
UI._Outfits = UI._Outfits or {}
local P = UI._Outfits

P.builders = P.builders or {}
P.builders[#P.builders + 1] = function(C)
    C.statusHitbox = CreateFrame("Button", nil, C.sourcePanel)
    C.statusHitbox:SetPoint("TOPLEFT", C.statusText, "TOPLEFT", -2, 2)
    C.statusHitbox:SetPoint("BOTTOMRIGHT", C.statusText, "BOTTOMRIGHT", 2, -2)
    C.statusHitbox:RegisterForClicks()
    C.statusHitbox:SetScript("OnEnter", function(self)
        local cache = Wardrobe.GetCache()
        local slotKey = P.GetCurrentSlot()
        local diagnostics = Wardrobe.GetSlotDiagnostics(slotKey)
        local sources = P.GetDisplayedSources(slotKey)
        local selected = Wardrobe.GetSelectedSource(slotKey)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Wardrobe Scan Details", 1, 0.82, 0)
        GameTooltip:AddLine(P.BuildDiagnosticsTooltip(cache, diagnostics, #sources, selected), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    C.statusHitbox:SetScript("OnLeave", function() GameTooltip:Hide() end)
    C.pane.statusHitbox = C.statusHitbox

    C.rerollSlot = UI.CreateButton(C.sourcePanel, "Reroll Slot", 90, 22)
    C.rerollSlot:SetPoint("TOPLEFT", C.sourcePanel, "TOPLEFT", 10, -63)
    C.lockSlot = UI.CreateButton(C.sourcePanel, "Lock Slot", 82, 22)
    C.lockSlot:SetPoint("LEFT", C.rerollSlot, "RIGHT", 5, 0)
    C.hideSlot = UI.CreateButton(C.sourcePanel, "Hide Slot", 82, 22)
    C.hideSlot:SetPoint("LEFT", C.lockSlot, "RIGHT", 5, 0)
    C.favoriteSource = UI.CreateButton(C.sourcePanel, "Favor in Zone", 92, 22)
    C.favoriteSource:SetPoint("TOPLEFT", C.sourcePanel, "TOPLEFT", 10, -88)
    C.excludeSource = UI.CreateButton(C.sourcePanel, "Exclude in Zone", 100, 22)
    C.excludeSource:SetPoint("LEFT", C.favoriteSource, "RIGHT", 5, 0)
    C.pane.rerollSlot = C.rerollSlot
    C.pane.lockSlot = C.lockSlot
    C.pane.hideSlot = C.hideSlot
    C.pane.favoriteSource = C.favoriteSource
    C.pane.excludeSource = C.excludeSource

    UI.SetTooltip(C.rerollSlot, "Reroll Selected Slot", "Choose another cached appearance. Weapon rerolls must be valid for the currently equipped item.")
    UI.SetTooltip(C.lockSlot, "Lock Selected Slot", "Locked slots survive Generate Outfit and Reroll Unlocked.")
    UI.SetTooltip(C.hideSlot, "Toggle Slot Visibility", "Hide or show helm, cloak, shirt, or tabard while preserving its selected appearance.")
    UI.SetTooltip(C.favoriteSource, "Favorite for This Zone", "Strongly favor the selected visual when generating outfits in this zone. Favorites still obey era, provenance, promotion, coherence, and weapon rules.")
    UI.SetTooltip(C.excludeSource, "Exclude for This Zone", "Never generate the selected visual in this zone. You can still browse and preview it manually.")

    C.rerollSlot:SetScript("OnClick", function()
        local slotKey = P.GetCurrentSlot()
        local ok, message = Wardrobe.RerollSlot(slotKey)
        if ok and not Wardrobe.IsGenerating() then Wardrobe.ApplyPreview(C.model) end
        C.pane:Refresh(message)
    end)
    C.lockSlot:SetScript("OnClick", function()
        local ok, message = Wardrobe.ToggleSlotLocked(P.GetCurrentSlot())
        if ok then Wardrobe.ApplyPreview(C.model) end
        C.pane:Refresh(message)
    end)
    C.hideSlot:SetScript("OnClick", function()
        local ok, message = Wardrobe.ToggleSlotHidden(P.GetCurrentSlot())
        if ok then Wardrobe.ApplyPreview(C.model) end
        C.pane:Refresh(message)
    end)
    C.favoriteSource:SetScript("OnClick", function()
        local selected = Wardrobe.GetSelectedSource(P.GetCurrentSlot())
        local ok, message = Wardrobe.ToggleZoneFavorite(P.GetCurrentSlot(), selected and selected.sourceID, ZoneStyle.GetCurrentContext())
        if not ok and UIErrorsFrame then UIErrorsFrame:AddMessage(message or "Unable to favorite this appearance.", 1, 0.25, 0.25) end
        C.pane:Refresh(message)
    end)
    C.excludeSource:SetScript("OnClick", function()
        local selected = Wardrobe.GetSelectedSource(P.GetCurrentSlot())
        local ok, message = Wardrobe.ToggleZoneExclusion(P.GetCurrentSlot(), selected and selected.sourceID, ZoneStyle.GetCurrentContext())
        if not ok and UIErrorsFrame then UIErrorsFrame:AddMessage(message or "Unable to exclude this appearance.", 1, 0.25, 0.25) end
        C.pane:Refresh(message)
    end)

    C.pane.sourceRows = {}
    for index = 1, P.SOURCE_ROWS do
        local row = CreateFrame("Button", nil, C.sourcePanel)
        row:SetHeight(P.SOURCE_ROW_HEIGHT)
        row:SetPoint("LEFT", C.sourcePanel, "LEFT", 10, 0)
        row:SetPoint("RIGHT", C.sourcePanel, "RIGHT", -10, 0)
        if index == 1 then
            row:SetPoint("TOP", C.sourcePanel, "TOP", 0, -166)
        else
            row:SetPoint("TOP", C.pane.sourceRows[index - 1], "BOTTOM", 0, -P.SOURCE_ROW_SPACING)
        end

        local background = row:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints(row)
        background:SetColorTexture(0.08, 0.08, 0.08, 0.72)
        row.background = background

        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(28, 28)
        icon:SetPoint("LEFT", row, "LEFT", 5, 0)
        icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        row.icon = icon

        local name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 7, -1)
        name:SetPoint("RIGHT", row, "RIGHT", -5, 0)
        name:SetJustifyH("LEFT")
        name:SetWordWrap(false)
        row.name = name

        local detail = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        detail:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 7, 1)
        detail:SetPoint("RIGHT", row, "RIGHT", -5, 0)
        detail:SetJustifyH("LEFT")
        detail:SetWordWrap(false)
        row.detail = detail

        row:SetScript("OnClick", function(self)
            if self.source then
                local ok, reason = Wardrobe.SelectSource(P.GetCurrentSlot(), self.source.sourceID)
                if ok then
                    Wardrobe.ApplyPreview(C.model)
                else
                    UIErrorsFrame:AddMessage(reason or "Appearance cannot be previewed.", 1, 0.25, 0.25)
                end
                -- WARDROBE_SELECTION_CHANGED refreshes the workbench. Avoid a
                -- second full refresh from the click handler.
            end
        end)
        row:SetScript("OnEnter", function(self)
            if self.source then
                self.background:SetColorTexture(0.13, 0.13, 0.13, 0.9)
                P.ShowAppearanceTooltip(self, self.source, P.GetCurrentSlot())
            end
        end)
        row:SetScript("OnLeave", function(self)
            local selected = Wardrobe.GetSelectedSource(P.GetCurrentSlot())
            local isSelected = self.source and selected and selected.sourceID == self.source.sourceID
            local preference = self.source and Wardrobe.GetSourceZonePreference(self.source, ZoneStyle.GetCurrentContext())
            P.SetSourceRowBackground(self, isSelected, preference)
            GameTooltip:Hide()
        end)
        C.pane.sourceRows[index] = row
    end

    C.lookPanel = UI.CreateInsetPanel(C.sourcePanel)
    C.lookPanel:SetAllPoints(C.sourcePanel)
    C.lookPanel:SetFrameLevel(C.sourcePanel:GetFrameLevel() + 30)
    C.lookPanel:Hide()
    C.pane.lookPanel = C.lookPanel

    C.lookTitle = C.lookPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    C.lookTitle:SetPoint("TOPLEFT", C.lookPanel, "TOPLEFT", 14, -14)
    C.lookTitle:SetText("Current Character Preview")
    C.lookSubtitle = C.lookPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    C.lookSubtitle:SetPoint("TOPLEFT", C.lookTitle, "BOTTOMLEFT", 0, -4)
    C.lookSubtitle:SetPoint("RIGHT", C.lookPanel, "RIGHT", -90, 0)
    C.lookSubtitle:SetJustifyH("LEFT")
    C.lookSubtitle:SetText("Selected appearances override equipped gear. Hidden layers remain listed.")
    C.closeLook = UI.CreateButton(C.lookPanel, "Close", 66, 22)
    C.closeLook:SetPoint("TOPRIGHT", C.lookPanel, "TOPRIGHT", -10, -10)
    C.closeLook:SetScript("OnClick", function() C.lookPanel:Hide() end)

    C.pane.lookRows = {}
    for index = 1, 14 do
        local row = CreateFrame("Button", nil, C.lookPanel)
        row:SetHeight(39)
        local column = index > 7 and 2 or 1
        local rowIndex = column == 2 and index - 7 or index
        if column == 1 then
            row:SetPoint("TOPLEFT", C.lookPanel, "TOPLEFT", 12, -64 - ((rowIndex - 1) * 42))
            row:SetPoint("RIGHT", C.lookPanel, "CENTER", -4, 0)
        else
            row:SetPoint("TOPLEFT", C.lookPanel, "TOP", 4, -64 - ((rowIndex - 1) * 42))
            row:SetPoint("RIGHT", C.lookPanel, "RIGHT", -12, 0)
        end
        local background = row:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints(row)
        background:SetColorTexture(0.07, 0.07, 0.07, 0.88)
        row.background = background
        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(30, 30)
        icon:SetPoint("LEFT", row, "LEFT", 5, 0)
        row.icon = icon
        local slot = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        slot:SetPoint("TOPLEFT", icon, "TOPRIGHT", 7, -1)
        slot:SetWidth(76)
        slot:SetJustifyH("LEFT")
        row.slot = slot
        local name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        name:SetPoint("TOPLEFT", slot, "TOPRIGHT", 3, 0)
        name:SetPoint("RIGHT", row, "RIGHT", -5, 0)
        name:SetJustifyH("LEFT")
        name:SetWordWrap(false)
        row.name = name
        local detail = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        detail:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 7, 1)
        detail:SetPoint("RIGHT", row, "RIGHT", -5, 0)
        detail:SetJustifyH("LEFT")
        row.detail = detail
        row:SetScript("OnEnter", function(self)
            if not self.entry then return end
            self.background:SetColorTexture(0.13, 0.13, 0.13, 0.95)
            if self.entry.source then
                local previewState = self.entry.kind or "Selected"
                if self.entry.locked then previewState = previewState .. " • Locked" end
                if self.entry.hidden then previewState = previewState .. " • Hidden" end
                P.ShowAppearanceTooltip(self, self.entry.source, self.entry.slotKey, "Current preview: " .. previewState .. ".")
            else
                GameTooltip:SetOwner(self, "ANCHOR_LEFT")
                GameTooltip:SetText(self.entry.name or (self.entry.label .. " equipment"), 1, 0.82, 0)
                GameTooltip:AddLine("Currently equipped in the " .. tostring(self.entry.label) .. " slot.", 1, 1, 1, true)
                if self.entry.itemID then GameTooltip:AddLine("Item ID: " .. tostring(self.entry.itemID), 0.65, 0.65, 0.65) end
                GameTooltip:AddLine("No collected appearance is overriding this slot in the preview.", 0.65, 0.65, 0.65, true)
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function(self)
            self.background:SetColorTexture(0.07, 0.07, 0.07, 0.88)
            GameTooltip:Hide()
        end)
        C.pane.lookRows[index] = row
    end

    function C.pane:RefreshCurrentLook()
        local manifest = Wardrobe.GetPreviewManifest()
        local generatedName = Wardrobe.GetGeneratedOutfitName()
        C.lookTitle:SetText(generatedName and ("Current Preview: " .. generatedName) or "Current Character Preview")
        for index, row in ipairs(self.lookRows) do
            local entry = manifest[index]
            row.entry = entry
            row:SetShown(entry ~= nil)
            if entry then
                row.icon:SetTexture(entry.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
                if row.icon.SetDesaturated then row.icon:SetDesaturated(entry.hidden == true) end
                row.slot:SetText(entry.label)
                row.name:SetText(entry.name)
                local detail = entry.kind
                if entry.locked then detail = detail .. " • Locked" end
                if entry.hidden then detail = detail .. " • Hidden" end
                row.detail:SetText(detail)
            end
        end
        return manifest
    end

    C.currentLookButton:SetScript("OnClick", function()
        if C.lookPanel:IsShown() then
            C.lookPanel:Hide()
        else
            C.pane:RefreshCurrentLook()
            C.lookPanel:Show()
        end
    end)

    C.previousPage = UI.CreateButton(C.sourcePanel, "Previous", 78, 23)
    C.previousPage:SetPoint("BOTTOMLEFT", C.sourcePanel, "BOTTOMLEFT", 10, 10)
    C.pageText = C.sourcePanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    C.pageText:SetPoint("BOTTOM", C.sourcePanel, "BOTTOM", 0, 16)
    C.pageText:SetWidth(120)
    C.pageText:SetJustifyH("CENTER")
    C.pane.pageText = C.pageText
    C.nextPage = UI.CreateButton(C.sourcePanel, "Next", 78, 23)
    C.nextPage:SetPoint("BOTTOMRIGHT", C.sourcePanel, "BOTTOMRIGHT", -10, 10)

    C.previousPage:SetScript("OnClick", function()
        local slotKey = P.GetCurrentSlot()
        P.SetPage(slotKey, P.GetPage(slotKey) - 1)
        C.pane:Refresh()
    end)
    C.nextPage:SetScript("OnClick", function()
        local slotKey = P.GetCurrentSlot()
        P.SetPage(slotKey, P.GetPage(slotKey) + 1)
        C.pane:Refresh()
    end)
    C.clearSlot:SetScript("OnClick", function()
        Wardrobe.ClearSelection(P.GetCurrentSlot())
        Wardrobe.ApplyPreview(C.model)
        C.pane:Refresh()
    end)

    C.sourcePanel:EnableMouseWheel(true)
    C.sourcePanel:SetScript("OnMouseWheel", function(_, delta)
        local slotKey = P.GetCurrentSlot()
        local sources = P.GetDisplayedSources(slotKey)
        local pageCount = math.max(1, math.ceil(#sources / P.SOURCE_ROWS))
        local page = P.GetPage(slotKey)
        if delta > 0 and page > 1 then
            P.SetPage(slotKey, page - 1)
            C.pane:Refresh()
        elseif delta < 0 and page < pageCount then
            P.SetPage(slotKey, page + 1)
            C.pane:Refresh()
        end
    end)

    C.scanButton:SetScript("OnClick", function()
        local started, message = Wardrobe.Scan(true)
        if message then
            C.statusText:SetText(message)
        elseif started then
            C.statusText:SetText("Wardrobe scan started.")
        else
            C.statusText:SetText("Unable to scan.")
        end
        C.pane:Refresh()
    end)

    function C.pane:GetSuggestedConceptName()
        local concept = Wardrobe.GetCurrentConcept()
        if concept and concept.name then
            return concept.name
        end
        local generatedName = Wardrobe.GetGeneratedOutfitName()
        if generatedName and generatedName ~= "" then return generatedName end
        return "Outfit Concept " .. tostring(#Wardrobe.GetConcepts() + 1)
    end

    function C.pane:SaveConcept(name)
        local ok, message, concept = Wardrobe.SaveConcept(name)
        self:Refresh(message)
        if not ok and UIErrorsFrame then
            UIErrorsFrame:AddMessage(message or "Unable to save outfit concept.", 1, 0.25, 0.25)
        end
        return ok, message, concept
    end

    function C.pane:LoadConcept(conceptID)
        local ok, message, concept = Wardrobe.LoadConcept(conceptID)
        if ok then
            Wardrobe.ApplyPreview(C.model)
        elseif UIErrorsFrame then
            UIErrorsFrame:AddMessage(message or "Unable to load outfit concept.", 1, 0.25, 0.25)
        end
        self:Refresh(message)
        return ok, message, concept
    end
end
