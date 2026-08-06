local QC = QuestChronicle
local UI = QC.UI
local Wardrobe = QC.Wardrobe
local ZoneStyle = QC.ZoneStyle
UI._Outfits = UI._Outfits or {}
local P = UI._Outfits

P.builders = P.builders or {}
P.builders[#P.builders + 1] = function(C)
    C.pane = CreateFrame("Frame", nil, C.parent)
    C.pane:SetAllPoints(C.parent)

    local _
    _, C.subtitle = UI.CreatePaneTitle(
        C.pane,
        "Outfits",
        "Browse collected appearances and assemble a manual character preview. Nothing is applied to your equipped transmog."
    )
    C.pane.subtitle = C.subtitle

    C.slotPanel = UI.CreateInsetPanel(C.pane)
    C.slotPanel:SetPoint("TOPLEFT", C.pane, "TOPLEFT", 12, -56)
    C.slotPanel:SetPoint("BOTTOMLEFT", C.pane, "BOTTOMLEFT", 12, 12)
    C.slotPanel:SetWidth(148)

    C.modelPanel = UI.CreateInsetPanel(C.pane)
    C.modelPanel:SetPoint("TOPLEFT", C.slotPanel, "TOPRIGHT", 8, 0)
    C.modelPanel:SetPoint("BOTTOM", C.pane, "BOTTOM", 0, 12)
    C.modelPanel:SetWidth(300)

    C.sourcePanel = UI.CreateInsetPanel(C.pane)
    C.sourcePanel:SetPoint("TOPLEFT", C.modelPanel, "TOPRIGHT", 8, 0)
    C.sourcePanel:SetPoint("BOTTOMRIGHT", C.pane, "BOTTOMRIGHT", -12, 12)
    C.lookPanel = nil
    C.slotTitle = C.slotPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    C.slotTitle:SetPoint("TOP", C.slotPanel, "TOP", 0, -10)
    C.slotTitle:SetText("Equipment Slot")

    C.pane.slotButtons = {}
    C.pane.weaponFamilyRows = {}
    C.previous = nil
    for _, definition in ipairs(Wardrobe.slotDefinitions) do
        if not definition.weaponRole then
            local button = UI.CreateButton(C.slotPanel, definition.label, 128, 22)
            P.CreateLockedSlotVisual(button)
            if C.previous then
                button:SetPoint("TOP", C.previous, "BOTTOM", 0, -3)
            else
                button:SetPoint("TOP", C.slotTitle, "BOTTOM", 0, -9)
            end
            button.slotKey = definition.key
            button:SetScript("OnClick", function(self)
                P.GetState().selectedSlot = self.slotKey
                if C.pane.weaponTypePanel then C.pane.weaponTypePanel:Hide() end
                C.pane:Refresh()
            end)
            button:SetScript("OnEnter", function(self)
                local entry = self.previewEntry
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                local slotDefinition = Wardrobe.GetSlotDefinition(self.slotKey)
                GameTooltip:SetText((slotDefinition and slotDefinition.label or self.slotKey) .. " Slot", 1, 0.82, 0)
                if entry then
                    GameTooltip:AddLine(entry.name or "Empty", 1, 1, 1, true)
                    local stateText = entry.kind or "Preview"
                    if entry.locked then stateText = stateText .. " • Locked" end
                    if entry.hidden then stateText = stateText .. " • Hidden" end
                    GameTooltip:AddLine(stateText, entry.hidden and 0.65 or 0.2, entry.hidden and 0.65 or 1, entry.hidden and 0.65 or 0.2)
                else
                    GameTooltip:AddLine("Not active in the current preview.", 0.65, 0.65, 0.65, true)
                end
                GameTooltip:AddLine(string.format("%s cached appearances", UI.FormatNumber(#(Wardrobe.GetSlotSources(self.slotKey) or {}))), 0.65, 0.65, 0.65)
                GameTooltip:AddLine("Click to browse this slot.", 1, 1, 1, true)
                GameTooltip:Show()
            end)
            button:SetScript("OnLeave", function() GameTooltip:Hide() end)
            C.pane.slotButtons[definition.key] = button
            C.previous = button
        end
    end

    C.weaponSectionTitle = C.slotPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    C.weaponSectionTitle:SetPoint("TOP", C.previous, "BOTTOM", 0, -8)
    C.weaponSectionTitle:SetText("Weapon Appearances")
    C.pane.weaponSectionTitle = C.weaponSectionTitle

    C.previousWeapon = nil
    for _, familyKey in ipairs(Wardrobe.WEAPON_FAMILY_ORDER) do
        local family = Wardrobe.weaponFamilyDefinitions[familyKey]
        local row = UI.CreateButton(C.slotPanel, "", 128, 24)
        row.isWeaponFamilyRow = true
        row.slotKey = familyKey
        if C.previousWeapon then
            row:SetPoint("TOP", C.previousWeapon, "BOTTOM", 0, -3)
        else
            row:SetPoint("TOP", C.weaponSectionTitle, "BOTTOM", 0, -6)
        end

        local check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        check:SetSize(20, 20)
        check:SetPoint("LEFT", row, "LEFT", 1, 0)
        check.familyKey = familyKey
        row.check = check

        local previewBackground = row:CreateTexture(nil, "BORDER")
        previewBackground:SetSize(18, 18)
        previewBackground:SetPoint("LEFT", row, "LEFT", 23, 0)
        previewBackground:SetColorTexture(0.02, 0.02, 0.02, 0.9)
        previewBackground:Hide()
        row.previewIconBackground = previewBackground
        local previewIcon = row:CreateTexture(nil, "ARTWORK")
        previewIcon:SetSize(16, 16)
        previewIcon:SetPoint("CENTER", previewBackground, "CENTER")
        previewIcon:Hide()
        row.previewIcon = previewIcon

        local label = row:GetFontString()
        label:ClearAllPoints()
        label:SetPoint("LEFT", row, "LEFT", 42, 0)
        label:SetPoint("RIGHT", row, "RIGHT", -20, 0)
        label:SetJustifyH("CENTER")
        label:SetText(family.label)
        row.familyLabel = label

        local lockIcon = row:CreateTexture(nil, "OVERLAY")
        lockIcon:SetSize(12, 12)
        lockIcon:SetPoint("RIGHT", row, "RIGHT", -17, 0)
        lockIcon:SetTexture("Interface\\Buttons\\LockButton-Locked-Up")
        lockIcon:SetVertexColor(1, 0.82, 0.12)
        lockIcon:Hide()
        row.lockIcon = lockIcon

        local arrow = CreateFrame("Button", nil, row)
        arrow:SetSize(18, 22)
        arrow:SetPoint("RIGHT", row, "RIGHT", -1, 0)
        local arrowText = arrow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        arrowText:SetAllPoints(arrow)
        arrowText:SetText(">")
        arrow.arrowText = arrowText
        row.arrow = arrow

        row:SetScript("OnClick", function(self)
            P.GetState().selectedSlot = self.slotKey
            C.pane:Refresh()
        end)
        check:SetScript("OnClick", function(self)
            local ok, message = Wardrobe.SetWeaponFamilyEnabled(self.familyKey, self:GetChecked() == true)
            if not ok and UIErrorsFrame then UIErrorsFrame:AddMessage(message or "That weapon family is unavailable.", 1, 0.25, 0.25) end
            C.pane:Refresh(message)
        end)
        row:SetScript("OnEnter", function(self)
            local options, topology = Wardrobe.GetWeaponGenerationOptions()
            local option
            for _, candidate in ipairs(options) do if candidate.key == self.slotKey then option = candidate break end end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText((option and option.label or family.label) .. " Appearances", 1, 0.82, 0)
            GameTooltip:AddLine(option and option.reason or "Weapon appearance family.", 1, 1, 1, true)
            GameTooltip:AddLine("Current physical layout: " .. tostring(topology and topology.label or "Unknown"), 0.65, 0.65, 0.65, true)
            GameTooltip:AddLine("Click the row to browse. Use the checkbox to include this family in generation. Use > to configure exact weapon types.", 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        check:SetScript("OnEnter", function()
            local handler = row:GetScript("OnEnter")
            if handler then handler(row) end
        end)
        check:SetScript("OnLeave", function() GameTooltip:Hide() end)
        arrow:SetScript("OnClick", function()
            C.pane:ShowWeaponTypeFlyout(familyKey)
        end)
        UI.SetTooltip(arrow, family.label .. " Types", "Choose the exact Blizzard-compatible weapon types available to Generate Outfit and Reroll Unlocked.", "ANCHOR_RIGHT")

        C.pane.slotButtons[familyKey] = row
        C.pane.weaponFamilyRows[familyKey] = row
        C.previousWeapon = row
    end

    C.linkHands = CreateFrame("CheckButton", nil, C.slotPanel, "UICheckButtonTemplate")
    C.linkHands:SetSize(20, 20)
    C.linkHands:SetPoint("TOPLEFT", C.previousWeapon, "BOTTOMLEFT", 1, -5)
    C.linkLabel = C.slotPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    C.linkLabel:SetPoint("LEFT", C.linkHands, "RIGHT", 1, 0)
    C.linkLabel:SetText("Link weapon hands")
    C.linkHands.label = C.linkLabel
    C.linkHands:SetScript("OnClick", function(self)
        local ok, message = Wardrobe.SetLinkWeaponHands(self:GetChecked() == true)
        if not ok and UIErrorsFrame then UIErrorsFrame:AddMessage(message or "Unable to change hand linking.", 1, 0.25, 0.25) end
        C.pane:Refresh(message)
    end)
    UI.SetTooltip(C.linkHands, "Link Weapon Hands", "When two weapon hands are equipped, use the same visual in both hands whenever Blizzard permits it. If that exact visual is unavailable, remain within the same exact weapon type. Quest Chronicle will not substitute an unrelated type while linking is enabled.", "ANCHOR_RIGHT")
    C.pane.linkWeaponHands = C.linkHands

    C.currentLookButton = UI.CreateButton(C.slotPanel, "Current Look", 128, 24)
    C.currentLookButton:SetPoint("BOTTOM", C.slotPanel, "BOTTOM", 0, 10)
    UI.SetTooltip(C.currentLookButton, "Current Character Preview", "Show every selected, equipped, hidden, and locked layer currently represented by the embedded model.")

    C.weaponTypePanel = UI.CreateInsetPanel(C.pane)
    C.weaponTypePanel:SetSize(330, 340)
    C.weaponTypePanel:SetPoint("TOPLEFT", C.slotPanel, "TOPRIGHT", 6, -292)
    C.weaponTypePanel:SetFrameLevel(C.pane:GetFrameLevel() + 35)
    C.weaponTypePanel:EnableMouse(true)
    C.weaponTypePanel:Hide()
    C.pane.weaponTypePanel = C.weaponTypePanel

    C.flyoutTitle = C.weaponTypePanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    C.flyoutTitle:SetPoint("TOPLEFT", C.weaponTypePanel, "TOPLEFT", 12, -12)
    C.flyoutTitle:SetPoint("RIGHT", C.weaponTypePanel, "RIGHT", -38, 0)
    C.flyoutTitle:SetJustifyH("LEFT")
    C.pane.weaponTypeTitle = C.flyoutTitle

    C.flyoutClose = UI.CreateButton(C.weaponTypePanel, "X", 28, 24)
    C.flyoutClose:SetPoint("TOPRIGHT", C.weaponTypePanel, "TOPRIGHT", -8, -8)
    C.flyoutClose:SetScript("OnClick", function() C.weaponTypePanel:Hide() end)

    C.flyoutSubtitle = C.weaponTypePanel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    C.flyoutSubtitle:SetPoint("TOPLEFT", C.weaponTypePanel, "TOPLEFT", 12, -38)
    C.flyoutSubtitle:SetPoint("RIGHT", C.weaponTypePanel, "RIGHT", -12, 0)
    C.flyoutSubtitle:SetHeight(30)
    C.flyoutSubtitle:SetJustifyH("LEFT")
    C.flyoutSubtitle:SetWordWrap(true)
    C.pane.weaponTypeSubtitle = C.flyoutSubtitle

    C.pane.weaponSubtypeChecks = {}
    for index = 1, 8 do
        local check = CreateFrame("CheckButton", nil, C.weaponTypePanel, "UICheckButtonTemplate")
        check:SetSize(21, 21)
        check:SetPoint("TOPLEFT", C.weaponTypePanel, "TOPLEFT", 10, -66 - ((index - 1) * 24))
        local label = C.weaponTypePanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        label:SetPoint("LEFT", check, "RIGHT", 2, 0)
        label:SetWidth(190)
        label:SetJustifyH("LEFT")
        local count = C.weaponTypePanel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        count:SetPoint("RIGHT", C.weaponTypePanel, "RIGHT", -12, 0)
        count:SetPoint("CENTER", check, "CENTER", 0, 0)
        count:SetJustifyH("RIGHT")
        check.label = label
        check.count = count
        check:SetScript("OnClick", function(self)
            local ok, message = Wardrobe.SetWeaponSubtypeEnabled(self.subtypeKey, self:GetChecked() == true)
            if not ok and UIErrorsFrame then UIErrorsFrame:AddMessage(message or "That weapon type is unavailable.", 1, 0.25, 0.25) end
            C.pane:Refresh(message)
            C.pane:RefreshWeaponTypeFlyout()
        end)
        check:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.option and self.option.label or "Weapon Type", 1, 0.82, 0)
            GameTooltip:AddLine(self.option and self.option.reason or "Weapon type option.", 1, 1, 1, true)
            if self.option and self.option.physical then GameTooltip:AddLine("This is the physically equipped item type.", 0.4, 0.8, 1, true) end
            GameTooltip:Show()
        end)
        check:SetScript("OnLeave", function() GameTooltip:Hide() end)
        C.pane.weaponSubtypeChecks[index] = check
    end

    C.allTypes = UI.CreateButton(C.weaponTypePanel, "All Compatible", 112, 23)
    C.allTypes:SetPoint("BOTTOMLEFT", C.weaponTypePanel, "BOTTOMLEFT", 10, 38)
    C.equippedType = UI.CreateButton(C.weaponTypePanel, "Equipped Type", 112, 23)
    C.equippedType:SetPoint("LEFT", C.allTypes, "RIGHT", 6, 0)
    C.clearTypes = UI.CreateButton(C.weaponTypePanel, "Clear", 58, 23)
    C.clearTypes:SetPoint("LEFT", C.equippedType, "RIGHT", 6, 0)
    C.doneTypes = UI.CreateButton(C.weaponTypePanel, "Done", 72, 23)
    C.doneTypes:SetPoint("BOTTOMRIGHT", C.weaponTypePanel, "BOTTOMRIGHT", -10, 9)
    C.pane.equippedTypeButton = C.equippedType

    C.allTypes:SetScript("OnClick", function()
        local ok, message = Wardrobe.SetAllCompatibleWeaponSubtypes(C.pane.activeWeaponFamily, true)
        C.pane:Refresh(message)
        C.pane:RefreshWeaponTypeFlyout()
    end)
    C.equippedType:SetScript("OnClick", function()
        local ok, message = Wardrobe.SetEquippedWeaponSubtypeOnly(C.pane.activeWeaponFamily)
        if not ok and UIErrorsFrame then UIErrorsFrame:AddMessage(message or "Equipped type unavailable.", 1, 0.25, 0.25) end
        C.pane:Refresh(message)
        C.pane:RefreshWeaponTypeFlyout()
    end)
    C.clearTypes:SetScript("OnClick", function()
        local ok, message = Wardrobe.SetAllCompatibleWeaponSubtypes(C.pane.activeWeaponFamily, false)
        C.pane:Refresh(message)
        C.pane:RefreshWeaponTypeFlyout()
    end)
    C.doneTypes:SetScript("OnClick", function() C.weaponTypePanel:Hide() end)

    function C.pane:RefreshWeaponTypeFlyout()
        if not C.weaponTypePanel:IsShown() or not self.activeWeaponFamily then return end
        local family = Wardrobe.weaponFamilyDefinitions[self.activeWeaponFamily]
        local options, capabilities = Wardrobe.GetWeaponSubtypeOptions(self.activeWeaponFamily)
        C.flyoutTitle:SetText((family and family.label or self.activeWeaponFamily) .. " Types")
        C.flyoutSubtitle:SetText("Blizzard decides which types the equipped hand may display. Checked types form the generation and browser pool.")
        local physicalAvailable = false
        for index, check in ipairs(self.weaponSubtypeChecks) do
            local option = options[index]
            check.option = option
            check.subtypeKey = option and option.key or nil
            check:SetShown(option ~= nil)
            if option then
                check:SetChecked(option.checked == true)
                check:SetAlpha(option.available and 1 or 0.42)
                check.label:SetText(option.label .. (option.physical and "  |cff66ccff(Equipped)|r" or ""))
                check.label:SetTextColor(option.available and 1 or 0.55, option.available and 1 or 0.55, option.available and 1 or 0.55)
                check.count:SetText(tostring(option.count or 0))
                if option.physical and option.available then physicalAvailable = true end
            end
        end
        C.equippedType:SetEnabled(physicalAvailable)
    end

    function C.pane:ShowWeaponTypeFlyout(familyKey)
        self.activeWeaponFamily = familyKey
        C.weaponTypePanel:Show()
        self:RefreshWeaponTypeFlyout()
    end

    C.modelTitle = C.modelPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    C.modelTitle:SetPoint("TOPLEFT", C.modelPanel, "TOPLEFT", 8, -10)
    C.modelTitle:SetPoint("RIGHT", C.modelPanel, "RIGHT", -8, 0)
    C.modelTitle:SetJustifyH("CENTER")
    C.modelTitle:SetWordWrap(false)
    C.modelTitle:SetText("Character Preview")

    C.pane.styleButtons = {}
    C.previousStyleButton = nil
    for _, mode in ipairs(ZoneStyle.modes) do
        local button = UI.CreateButton(C.modelPanel, mode.shortLabel, 67, 22)
        if C.previousStyleButton then
            button:SetPoint("LEFT", C.previousStyleButton, "RIGHT", 3, 0)
        else
            button:SetPoint("TOPLEFT", C.modelPanel, "TOPLEFT", 8, -29)
        end
        button.modeKey = mode.key
        button:SetScript("OnClick", function(self)
            ZoneStyle.SetMode(self.modeKey)
            C.pane:Refresh("Generation mode changed to " .. ZoneStyle.GetModeInfo(self.modeKey).label .. ".")
        end)
        UI.SetTooltip(button, mode.label, mode.description)
        C.pane.styleButtons[mode.key] = button
        C.previousStyleButton = button
    end

    C.styleInfo = C.modelPanel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    C.styleInfo:SetPoint("TOPLEFT", C.modelPanel, "TOPLEFT", 8, -54)
    C.styleInfo:SetPoint("RIGHT", C.modelPanel, "RIGHT", -8, 0)
    C.styleInfo:SetHeight(40)
    C.styleInfo:SetJustifyH("CENTER")
    C.styleInfo:SetWordWrap(true)
    C.pane.styleInfo = C.styleInfo

    C.weaponSummary = C.modelPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    C.weaponSummary:SetPoint("TOPLEFT", C.modelPanel, "TOPLEFT", 10, -96)
    C.weaponSummary:SetPoint("RIGHT", C.modelPanel, "RIGHT", -10, 0)
    C.weaponSummary:SetHeight(28)
    C.weaponSummary:SetJustifyH("CENTER")
    C.weaponSummary:SetJustifyV("TOP")
    C.weaponSummary:SetWordWrap(true)
    C.weaponSummary:SetText("Weapons")
    C.pane.weaponSummary = C.weaponSummary

    C.model = CreateFrame("DressUpModel", nil, C.modelPanel)
    C.model:SetPoint("TOPLEFT", C.modelPanel, "TOPLEFT", 8, -126)
    C.model:SetPoint("BOTTOMRIGHT", C.modelPanel, "BOTTOMRIGHT", -8, 112)
    C.model:SetUnit("player")
    if C.model.SetFacing then C.model:SetFacing(0) end
    C.pane.model = C.model

    C.rotateLeft = UI.CreateButton(C.modelPanel, "Rotate Left", 88, 23)
    C.rotateLeft:SetPoint("BOTTOMLEFT", C.modelPanel, "BOTTOMLEFT", 8, 78)
    C.rotateRight = UI.CreateButton(C.modelPanel, "Rotate Right", 88, 23)
    C.rotateRight:SetPoint("LEFT", C.rotateLeft, "RIGHT", 6, 0)
    C.resetModel = UI.CreateButton(C.modelPanel, "Reset View", 88, 23)
    C.resetModel:SetPoint("LEFT", C.rotateRight, "RIGHT", 6, 0)

    C.rotateLeft:SetScript("OnClick", function()
        if C.model.SetFacing and C.model.GetFacing then C.model:SetFacing((C.model:GetFacing() or 0) - 0.35) end
    end)
    C.rotateRight:SetScript("OnClick", function()
        if C.model.SetFacing and C.model.GetFacing then C.model:SetFacing((C.model:GetFacing() or 0) + 0.35) end
    end)
    C.resetModel:SetScript("OnClick", function()
        if C.model.SetFacing then C.model:SetFacing(0) end
        Wardrobe.ApplyPreview(C.model)
    end)

    C.generateButton = UI.CreateButton(C.modelPanel, "Generate Outfit", 128, 24)
    C.generateButton:SetPoint("BOTTOMLEFT", C.modelPanel, "BOTTOMLEFT", 18, 44)
    C.rerollUnlocked = UI.CreateButton(C.modelPanel, "Reroll Unlocked", 128, 24)
    C.rerollUnlocked:SetPoint("BOTTOMRIGHT", C.modelPanel, "BOTTOMRIGHT", -18, 44)

    C.saveConcept = UI.CreateButton(C.modelPanel, "Save Concept", 88, 24)
    C.saveConcept:SetPoint("BOTTOMLEFT", C.modelPanel, "BOTTOMLEFT", 8, 10)
    C.loadConcept = UI.CreateButton(C.modelPanel, "Load Concept", 88, 24)
    C.loadConcept:SetPoint("LEFT", C.saveConcept, "RIGHT", 4, 0)
    C.clearAll = UI.CreateButton(C.modelPanel, "Reset Outfit", 100, 24)
    C.clearAll:SetPoint("LEFT", C.loadConcept, "RIGHT", 4, 0)

    UI.SetTooltip(C.generateButton, "Generate Outfit", "Build a promo-free weighted outfit in the selected style. Checked weapon families form the allowed generation pool, then the equipped hand layout removes impossible combinations. Locked and hidden choices are preserved.")
    UI.SetTooltip(C.rerollUnlocked, "Reroll Unlocked", "Replace every unlocked choice using the selected weapon families and the same promo-free, set-aware, motif-coherent rules.")
    UI.SetTooltip(C.saveConcept, "Save Concept", "Open the Outfit Concepts manager to name and save the current selections, locks, hidden slots, and weapon configuration.")
    UI.SetTooltip(C.loadConcept, "Outfit Concepts", "Open the Outfit Concepts manager to inspect, load, overwrite, or delete this character's saved concepts.")
    UI.SetTooltip(C.clearAll, "Reset Outfit", "Clear selections, locks, and hidden-slot choices, returning the preview to currently equipped gear.")

    local function StartGeneration(reroll)
        local generation = QC.Generation
        local starter = reroll and generation and generation.RerollUnlockedCurrentMode
            or generation and generation.GenerateCurrentMode
        local ok, message, deferred
        if starter then
            ok, message, deferred = starter({ modeID = ZoneStyle.GetMode() })
        else
            ok, message, deferred = false, "Quest Chronicle generation routing is unavailable. Try /reload."
        end
        if not ok then
            C.pane:Refresh(message)
        elseif not deferred then
            Wardrobe.ApplyPreview(C.model)
            C.pane:Refresh(message)
        end
    end
    C.generateButton:SetScript("OnClick", function() StartGeneration(false) end)
    C.rerollUnlocked:SetScript("OnClick", function() StartGeneration(true) end)
    C.clearAll:SetScript("OnClick", function()
        Wardrobe.ClearAllSelections()
        Wardrobe.ApplyPreview(C.model)
        C.pane:Refresh("Outfit preview reset to currently equipped gear.")
    end)

    -- A self-contained manager replaces the fragile popup/context-menu pair.
    -- It stays inside Quest Chronicle's frame strata and exposes the complete
    -- concept lifecycle: save, overwrite by name, select, load, and delete.
    C.conceptBlocker = CreateFrame("Button", nil, C.pane)
    C.conceptBlocker:SetAllPoints(C.pane)
    C.conceptBlocker:SetFrameLevel(C.pane:GetFrameLevel() + 40)
    C.blockerShade = C.conceptBlocker:CreateTexture(nil, "BACKGROUND")
    C.blockerShade:SetAllPoints(C.conceptBlocker)
    C.blockerShade:SetColorTexture(0, 0, 0, 0.58)
    C.conceptBlocker:Hide()

    C.conceptManager = UI.CreateInsetPanel(C.pane)
    C.conceptManager:SetSize(690, 420)
    C.conceptManager:SetPoint("CENTER", C.pane, "CENTER", 0, -4)
    C.conceptManager:SetFrameLevel(C.pane:GetFrameLevel() + 41)
    C.conceptManager:EnableMouse(true)
    C.conceptManager:Hide()
    C.pane.conceptManager = C.conceptManager
end
