local QC = QuestChronicle
local UI = QC.UI
local Wardrobe = QC.Wardrobe
local ZoneStyle = QC.ZoneStyle
UI._Outfits = UI._Outfits or {}
local P = UI._Outfits

P.builders = P.builders or {}
P.builders[#P.builders + 1] = function(C)
    function C.pane:RefreshGeneratedResult(message)
        local slotKey = P.GetCurrentSlot()
        local definition = Wardrobe.GetSlotDefinition(slotKey) or Wardrobe.slotDefinitions[1]
        local sources = P.GetDisplayedSources(slotKey)
        local styleMode = ZoneStyle.GetMode()
        local styleContext = ZoneStyle.GetCurrentContext()
        local pendingSuggestion = ZoneStyle.GetPendingSuggestion()
        local generatedName = Wardrobe.GetGeneratedOutfitName()
        C.modelTitle:SetText(generatedName and ("Character Preview: " .. generatedName) or "Character Preview")

        for modeKey, button in pairs(self.styleButtons) do
            local mode = ZoneStyle.GetModeInfo(modeKey)
            button:SetText(mode.shortLabel .. (modeKey == ZoneStyle.MODE_ZONE_NATIVE and pendingSuggestion and " *" or ""))
            button:SetEnabled(true)
            if modeKey == styleMode then
                if button.LockHighlight then button:LockHighlight() end
            elseif button.UnlockHighlight then
                button:UnlockHighlight()
            end
        end
        local restrictionLabel = ZoneStyle.GetContextRestrictionLabel(styleContext)
        local chronicleSummary = ZoneStyle.GetChronicleSummary(styleContext)
        local favoriteCount, exclusionCount = Wardrobe.GetZonePreferenceSummary(styleContext)
        C.styleInfo:SetText(string.format(
            "%s • %s\n%s%s\n%s • %d favored • %d excluded",
            styleContext.profileLabel or "Azeroth Adventurer",
            styleContext.provenanceLabel or styleContext.zone or "Unknown Zone",
            restrictionLabel,
            pendingSuggestion and " • Suggestion ready" or "",
            chronicleSummary,
            favoriteCount,
            exclusionCount
        ))

        local manifest = self:RefreshCurrentLook()
        local manifestBySlot = {}
        for _, entry in ipairs(manifest) do manifestBySlot[entry.slotKey] = entry end
        C.currentLookButton:SetText(string.format("Current Look (%d)", #manifest))
        for key, button in pairs(self.slotButtons) do
            local lockedSlot = Wardrobe.IsSlotLocked(key)
            local previewEntry = manifestBySlot[key]
            button.previewEntry = previewEntry
            local hasIcon = previewEntry and previewEntry.icon ~= nil
            button.previewIconBackground:SetShown(hasIcon)
            button.previewIcon:SetShown(hasIcon)
            if hasIcon then
                button.previewIcon:SetTexture(previewEntry.icon)
                if button.previewIcon.SetDesaturated then button.previewIcon:SetDesaturated(previewEntry.hidden == true) end
            end
            if button.isWeaponFamilyRow then
                button:SetEnabled(true)
                button.lockIcon:SetShown(lockedSlot)
                if key == slotKey then
                    if button.LockHighlight then button:LockHighlight() end
                elseif button.UnlockHighlight then
                    button:UnlockHighlight()
                end
            else
                button:SetEnabled(key ~= slotKey)
                local markers = Wardrobe.IsSlotHidden(key) and " H" or ""
                button:SetText(string.format("%s%s", Wardrobe.GetSlotDefinition(key).label, markers))
                P.SetLockedSlotVisual(button, lockedSlot)
            end
        end

        local selected = Wardrobe.GetSelectedSource(slotKey)
        local hidden = Wardrobe.IsSlotHidden(slotKey)
        local locked = Wardrobe.IsSlotLocked(slotKey)
        local selectedLabel = selected and P.GetSourceDisplayName(selected) or "currently equipped appearance"
        C.selectedText:SetText(string.format("Selected: %s%s%s", selectedLabel, locked and " • Locked" or "", hidden and " • Hidden" or ""))
        C.clearSlot:SetEnabled(selected ~= nil or hidden or locked)
        C.clearSlot:SetText((selected or hidden or locked) and "Clear Slot" or "No Selection")
        C.rerollSlot:SetEnabled(not locked and #sources > 0)
        C.lockSlot:SetText(locked and "Unlock Slot" or "Lock Slot")
        C.hideSlot:SetText(hidden and "Show Slot" or "Hide Slot")

        local sourcePreference = selected and Wardrobe.GetSourceZonePreference(selected, styleContext)
        C.favoriteSource:SetEnabled(selected ~= nil)
        C.excludeSource:SetEnabled(selected ~= nil)
        C.favoriteSource:SetText(sourcePreference == "favorite" and "Unfavor" or "Favor in Zone")
        C.excludeSource:SetText(sourcePreference == "excluded" and "Allow in Zone" or "Exclude in Zone")
        if sourcePreference == "favorite" then
            UI.SetTooltip(C.favoriteSource, "Remove Zone Favorite", "Stop favoring the selected visual when generating outfits in this zone.")
        else
            UI.SetTooltip(C.favoriteSource, "Favorite for This Zone", "Strongly favor the selected visual when generating outfits in this zone. Favorites still obey era, provenance, promotion, coherence, and weapon rules.")
        end
        if sourcePreference == "excluded" then
            UI.SetTooltip(C.excludeSource, "Allow in This Zone", "Remove the zone exclusion so this visual can be generated here again when it passes the other outfit rules.")
        else
            UI.SetTooltip(C.excludeSource, "Exclude for This Zone", "Never generate the selected visual in this zone. You can still browse and preview it manually.")
        end

        local page = P.GetPage(slotKey)
        local startIndex = ((page - 1) * P.SOURCE_ROWS) + 1
        for rowIndex, row in ipairs(self.sourceRows) do
            self:RefreshSourceRow(row, sources[startIndex + rowIndex - 1], slotKey, selected, styleMode, styleContext)
        end

        C.statusText:SetText(message or "Outfit generation complete.")
        C.performanceText:SetText(self.generationPerformanceText or "")
        C.scanButton:SetEnabled(not Wardrobe.IsScanning())
        C.scanButton:SetText(Wardrobe.IsScanning() and "Scanning..." or "Scan Collection")
        local canGenerate = not Wardrobe.IsScanning() and Wardrobe.GetCache().totalVisuals > 0
        C.generateButton:SetEnabled(canGenerate)
        C.rerollUnlocked:SetEnabled(canGenerate)
        C.generateButton:SetText("Generate Outfit")
        C.rerollUnlocked:SetText("Reroll Unlocked")
        C.saveConcept:SetEnabled(next(P.GetState().selections) ~= nil or next(P.GetState().locks) ~= nil or next(P.GetState().hidden) ~= nil)

        local concept = Wardrobe.GetCurrentConcept()
        local conceptText = concept and (" • Concept: " .. tostring(concept.name or "Unnamed")) or ""
        local generatedText = generatedName and (" • Look: " .. generatedName) or ""
        local modeInfo = ZoneStyle.GetModeInfo(styleMode)
        C.subtitle:SetText(string.format(
            "%s appearances for %s • %s • %s%s%s. Preview only; no outfit is applied.",
            UI.FormatNumber(#sources), definition and definition.label or slotKey,
            modeInfo.label, styleContext.profileLabel or "Azeroth Adventurer", generatedText, conceptText
        ))
    end
end
