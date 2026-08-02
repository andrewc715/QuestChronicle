local QC = QuestChronicle
local UI = QC.UI
local Wardrobe = QC.Wardrobe
local ZoneStyle = QC.ZoneStyle
UI._Outfits = UI._Outfits or {}
local P = UI._Outfits

local function NowMilliseconds()
    if type(debugprofilestop) == "function" then return debugprofilestop() end
    if type(GetTimePreciseSec) == "function" then return GetTimePreciseSec() * 1000 end
    if type(GetTime) == "function" then return GetTime() * 1000 end
    return 0
end

P.builders = P.builders or {}
P.builders[#P.builders + 1] = function(C)
    local function UpdateGenerationPerformance(performance)
        C.pane.generationPerformance = performance
        C.pane.generationPerformanceText = performance and Wardrobe.FormatGenerationPerformance
            and Wardrobe.FormatGenerationPerformance(performance)
            or ""
        if C.performanceText then C.performanceText:SetText(C.pane.generationPerformanceText or "") end
    end

    function C.pane:RefreshSourceRow(row, source, slotKey, selected, styleMode, styleContext)
        row.source = source
        row:SetShown(source ~= nil)
        if not source then return end

        row.icon:SetTexture(source.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        row.name:SetText(P.SourceLabel(source))
        local valid, reason = Wardrobe.ValidateSource(source, slotKey)
        local isSelected = selected and selected.sourceID == source.sourceID
        local marker = isSelected and (UI.green .. "Selected|r") or (valid and "Collected" or (UI.red .. "Unavailable|r"))
        local eligible, eligibilityKind = ZoneStyle.GetEligibilitySummary(source, styleMode, styleContext)
        local sourceZonePreference = Wardrobe.GetSourceZonePreference(source, styleContext)
        local generatedMarker = sourceZonePreference == "favorite" and (" • " .. UI.gold .. "Zone favorite|r")
            or (sourceZonePreference == "excluded" and (" • " .. UI.red .. "Zone excluded|r")
            or (eligible and "" or (eligibilityKind == "pending" and " • Loading era" or (eligibilityKind == "promotional" and " • Promo excluded" or (eligibilityKind == "heritage" and " • Heritage locked" or " • Not generated")))))
        row.detail:SetText(string.format("%s • Source %d%s%s", marker, source.sourceID or 0, valid and "" or (" • " .. tostring(reason)), generatedMarker))
        row:SetEnabled(valid)
        P.SetSourceRowBackground(row, isSelected, sourceZonePreference)

        if GameTooltip and GameTooltip.GetOwner and GameTooltip:GetOwner() == row then
            P.ShowAppearanceTooltip(row, source, slotKey)
        end
    end

    function C.pane:RefreshVisibleAppearanceMetadata(payload)
        if not self:IsShown() then return end
        local slotKey = P.GetCurrentSlot()
        local selected = Wardrobe.GetSelectedSource(slotKey)
        local styleMode = ZoneStyle.GetMode()
        local styleContext = ZoneStyle.GetCurrentContext()
        local changedSourceIDs = payload and payload.sourceIDs

        for _, row in ipairs(self.sourceRows or {}) do
            local source = row.source
            if source and (not changedSourceIDs or changedSourceIDs[source.sourceID]) then
                self:RefreshSourceRow(row, source, slotKey, selected, styleMode, styleContext)
            end
        end

        local hidden = Wardrobe.IsSlotHidden(slotKey)
        local locked = Wardrobe.IsSlotLocked(slotKey)
        local selectedLabel = selected and P.GetSourceDisplayName(selected) or "currently equipped appearance"
        C.selectedText:SetText(string.format("Selected: %s%s%s", selectedLabel, locked and " • Locked" or "", hidden and " • Hidden" or ""))
        if C.lookPanel and C.lookPanel:IsShown() then self:RefreshCurrentLook() end
    end

    function C.pane:Refresh(message)
        local cache = Wardrobe.GetCache()
        local slotKey = P.GetCurrentSlot()
        local definition = Wardrobe.GetSlotDefinition(slotKey) or Wardrobe.slotDefinitions[1]
        local sources = P.GetDisplayedSources(slotKey)
        local pageCount = math.max(1, math.ceil(#sources / P.SOURCE_ROWS))
        local page = math.min(P.GetPage(slotKey), pageCount)
        P.SetPage(slotKey, page)

        local styleMode = ZoneStyle.GetMode()
        local styleContext = ZoneStyle.GetCurrentContext()
        local pendingSuggestion = ZoneStyle.GetPendingSuggestion()
        local restrictionLabel = ZoneStyle.GetContextRestrictionLabel(styleContext)
        local chronicleSummary = ZoneStyle.GetChronicleSummary(styleContext)
        local favoriteCount, exclusionCount = Wardrobe.GetZonePreferenceSummary(styleContext)
        local generatedName = Wardrobe.GetGeneratedOutfitName()
        C.modelTitle:SetText(generatedName and ("Character Preview: " .. generatedName) or "Character Preview")
        for modeKey, button in pairs(self.styleButtons) do
            local mode = ZoneStyle.GetModeInfo(modeKey)
            local marker = modeKey == ZoneStyle.MODE_ZONE_NATIVE and pendingSuggestion and " *" or ""
            button:SetText(mode.shortLabel .. marker)

            -- Do not disable the selected mode: disabled buttons do not receive
            -- mouse-enter events, which made the active mode's tooltip vanish.
            -- A locked highlight communicates selection while preserving hover
            -- and allowing the player to click the mode again harmlessly.
            button:SetEnabled(true)
            if modeKey == styleMode then
                if button.LockHighlight then button:LockHighlight() end
            else
                if button.UnlockHighlight then button:UnlockHighlight() end
            end
        end
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

        local weaponOptions, weaponTopology, weaponCapabilities = Wardrobe.GetWeaponGenerationOptions()
        C.weaponSummary:SetText(string.format("%s\nAllowed: %s", tostring(weaponTopology.label or "Unknown layout"), Wardrobe.GetWeaponFilterCountSummary()))
        local optionByFamily = {}
        for _, option in ipairs(weaponOptions) do optionByFamily[option.key] = option end
        for _, familyKey in ipairs(Wardrobe.WEAPON_FAMILY_ORDER) do
            local row = self.weaponFamilyRows[familyKey]
            local option = optionByFamily[familyKey]
            local subtypeOptions = Wardrobe.GetWeaponSubtypeOptions(familyKey)
            local selectedTypes, availableTypes = 0, 0
            for _, subtypeOption in ipairs(subtypeOptions) do
                if subtypeOption.available then availableTypes = availableTypes + 1 end
                if subtypeOption.checked then selectedTypes = selectedTypes + 1 end
            end
            if row and option then
                row.check:SetChecked(option.checked == true)
                row.check.available = option.available
                row.check:SetAlpha(option.available and 1.0 or 0.42)
                row:SetAlpha(option.available and 1.0 or 0.62)
                row.familyLabel:SetText(string.format("%s (%d/%d)", option.label, selectedTypes, availableTypes))
                row.arrow.arrowText:SetTextColor(1, 0.82, 0)
            end
        end
        self.linkWeaponHands:SetChecked(Wardrobe.GetLinkWeaponHands())
        local canLinkHands = weaponTopology.hasWeaponOffHand == true
        self.linkWeaponHands:SetAlpha(canLinkHands and 1.0 or 0.42)
        self.linkWeaponHands.label:SetTextColor(canLinkHands and 1 or 0.55, canLinkHands and 1 or 0.55, canLinkHands and 1 or 0.55)

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
                else
                    if button.UnlockHighlight then button:UnlockHighlight() end
                end
            else
                button:SetEnabled(key ~= slotKey)
                local markers = Wardrobe.IsSlotHidden(key) and " H" or ""
                button:SetText(string.format("%s%s", Wardrobe.GetSlotDefinition(key).label, markers))
                P.SetLockedSlotVisual(button, lockedSlot)
            end
        end

        if definition and definition.weaponRole then
            local subtypeOptions = Wardrobe.GetWeaponSubtypeOptions(slotKey)
            local selectedTypes, availableTypes = 0, 0
            for _, subtypeOption in ipairs(subtypeOptions) do
                if subtypeOption.available then availableTypes = availableTypes + 1 end
                if subtypeOption.checked then selectedTypes = selectedTypes + 1 end
            end
            C.sourceTitle:SetText(string.format("%s Appearances • %d of %d Types", definition.label, selectedTypes, availableTypes))
        else
            C.sourceTitle:SetText((definition and definition.label or "Appearance") .. " Appearances")
        end
        local generating = Wardrobe.IsGenerating and Wardrobe.IsGenerating()
        C.scanButton:SetEnabled(not Wardrobe.IsScanning() and not generating)
        C.scanButton:SetText(Wardrobe.IsScanning() and "Scanning..." or "Scan Collection")
        C.staleHitbox:SetShown(cache.dirty == true and not Wardrobe.IsScanning() and not generating)

        local selected = Wardrobe.GetSelectedSource(slotKey)
        local hidden = Wardrobe.IsSlotHidden(slotKey)
        local locked = Wardrobe.IsSlotLocked(slotKey)
        local selectedLabel = selected and P.GetSourceDisplayName(selected) or "currently equipped appearance"
        C.selectedText:SetText(string.format("Selected: %s%s%s", selectedLabel, locked and " • Locked" or "", hidden and " • Hidden" or ""))
        C.clearSlot:SetEnabled(selected ~= nil or hidden or locked)
        C.clearSlot:SetText((selected or hidden or locked) and "Clear Slot" or "No Selection")
        C.rerollSlot:SetEnabled(not locked and #sources > 0)
        C.lockSlot:SetText(locked and "Unlock Slot" or "Lock Slot")
        C.lockSlot:SetEnabled(true)
        C.hideSlot:SetShown(Wardrobe.IsSlotHideable(slotKey))
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

        local diagnostics = Wardrobe.GetSlotDiagnostics(slotKey)
        C.statusText:SetText(message or P.CacheSummary(cache, diagnostics, #sources))
        C.performanceText:SetText(self.generationPerformanceText or "")

        local canGenerate = not Wardrobe.IsScanning() and not generating and cache.totalVisuals > 0
        C.generateButton:SetEnabled(canGenerate)
        C.rerollUnlocked:SetEnabled(canGenerate)
        C.generateButton:SetText(generating and "Generating..." or "Generate Outfit")
        C.rerollUnlocked:SetText(generating and "Please Wait..." or "Reroll Unlocked")
        local concepts = Wardrobe.GetConcepts()
        C.saveConcept:SetEnabled(next(P.GetState().selections) ~= nil or next(P.GetState().locks) ~= nil or next(P.GetState().hidden) ~= nil)
        C.loadConcept:SetEnabled(#concepts > 0)
        C.loadConcept:SetText(#concepts > 0 and string.format("Concepts (%d)", #concepts) or "Load Concept")

        local startIndex = ((page - 1) * P.SOURCE_ROWS) + 1
        for rowIndex, row in ipairs(self.sourceRows) do
            local source = sources[startIndex + rowIndex - 1]
            self:RefreshSourceRow(row, source, slotKey, selected, styleMode, styleContext)
        end

        C.pageText:SetText(string.format("Page %d of %d", page, pageCount))
        C.previousPage:SetEnabled(page > 1)
        C.nextPage:SetEnabled(page < pageCount)
        local concept = Wardrobe.GetCurrentConcept()
        local conceptText = concept and (" • Concept: " .. tostring(concept.name or "Unnamed")) or ""
        local generatedText = generatedName and (" • Look: " .. generatedName) or ""
        local modeInfo = ZoneStyle.GetModeInfo(styleMode)
        C.subtitle:SetText(string.format("%s appearances for %s • %s • %s%s%s. Preview only; no outfit is applied.", UI.FormatNumber(#sources), definition and definition.label or slotKey, modeInfo.label, styleContext.profileLabel or "Azeroth Adventurer", generatedText, conceptText))
    end

    QC.RegisterCallback("WARDROBE_GENERATION_STARTED", C.pane, function(reroll)
        C.pane.generationPerformance = nil
        C.pane.generationPerformanceText = nil
        if C.performanceText then C.performanceText:SetText("") end
        if not C.pane:IsShown() then return end
        C.generateButton:SetEnabled(false)
        C.rerollUnlocked:SetEnabled(false)
        C.scanButton:SetEnabled(false)
        C.generateButton:SetText(reroll and "Rerolling..." or "Generating...")
        C.rerollUnlocked:SetText("Please Wait...")
        C.statusText:SetText(reroll and "Rerolling unlocked pieces in the background..." or "Preparing outfit in the background...")
    end)
    QC.RegisterCallback("WARDROBE_GENERATION_PROGRESS", C.pane, function(index, total, slotKey)
        if not C.pane:IsShown() then return end
        local definition = Wardrobe.GetSlotDefinition(slotKey)
        C.statusText:SetText(string.format("Preparing outfit %d of %d: %s", index or 0, total or 0, definition and definition.label or tostring(slotKey or "appearance")))
    end)
    QC.RegisterCallback("WARDROBE_GENERATION_COMPLETE", C.pane, function(success, message, performance)
        UpdateGenerationPerformance(performance)
        if not C.pane:IsShown() then return end
        C.generateButton:SetText("Generate Outfit")
        C.rerollUnlocked:SetText("Reroll Unlocked")
        if success then
            local function RefreshAfterPreview()
                if not C.pane:IsShown() then return end
                local refreshStarted = NowMilliseconds()
                if C.pane.RefreshGeneratedResult then
                    C.pane:RefreshGeneratedResult(message)
                else
                    C.pane:Refresh(message)
                end
                if Wardrobe.RecordGenerationPostPhase then
                    Wardrobe.RecordGenerationPostPhase(performance, "uiRefresh", NowMilliseconds() - refreshStarted)
                end
                UpdateGenerationPerformance(performance)
            end
            local function ApplyThenRefresh()
                local previewStarted = NowMilliseconds()
                Wardrobe.ApplyPreview(C.model)
                if Wardrobe.RecordGenerationPostPhase then
                    Wardrobe.RecordGenerationPostPhase(performance, "previewApply", NowMilliseconds() - previewStarted)
                end
                UpdateGenerationPerformance(performance)
                if C_Timer and type(C_Timer.After) == "function" then
                    C_Timer.After(0, RefreshAfterPreview)
                else
                    RefreshAfterPreview()
                end
            end
            if C_Timer and type(C_Timer.After) == "function" then
                C_Timer.After(0, ApplyThenRefresh)
            else
                ApplyThenRefresh()
            end
        else
            local refreshStarted = NowMilliseconds()
            C.pane:Refresh(message)
            if Wardrobe.RecordGenerationPostPhase then
                Wardrobe.RecordGenerationPostPhase(performance, "uiRefresh", NowMilliseconds() - refreshStarted)
            end
            UpdateGenerationPerformance(performance)
        end
    end)

    QC.RegisterCallback("WARDROBE_SCAN_PROGRESS", C.pane, function(index, total, slotKey, count, diagnostics)
        if C.pane:IsShown() then
            local expected = diagnostics and diagnostics.expectedCollected or 0
            C.pane:Refresh(string.format("Scanning %d of %d: %s • %s visuals from %s collected sources", index or 0, total or 0, Wardrobe.GetSlotDefinition(slotKey) and Wardrobe.GetSlotDefinition(slotKey).label or slotKey, UI.FormatNumber(count or 0), UI.FormatNumber(expected or 0)))
        end
    end)
    QC.RegisterCallback("WARDROBE_SCAN_COMPLETE", C.pane, function(cache)
        Wardrobe.ApplyPreview(C.model)
        if C.pane:IsShown() then
            C.pane:Refresh(cache and cache.scanError or "Wardrobe collection scan complete.")
        end
    end)
    QC.RegisterCallback("WARDROBE_CACHE_DIRTY", C.pane, function()
        if C.pane:IsShown() then C.pane:Refresh() end
    end)
    QC.RegisterCallback("WARDROBE_LOGIN_REFRESH_SCHEDULED", C.pane, function()
        if C.pane:IsShown() then C.pane:Refresh("Refreshing the wardrobe once for this login...") end
    end)
    QC.RegisterCallback("WARDROBE_LOGIN_REFRESH_DEFERRED", C.pane, function()
        if C.pane:IsShown() then C.pane:Refresh("Login refresh deferred • use Scan Collection when ready.") end
    end)
    QC.RegisterCallback("WARDROBE_APPEARANCES_RECOVERED", C.pane, function(recovery)
        if C.pane:IsShown() and recovery then
            local recovered = (recovery.previewRecovered or 0) + (recovery.conceptRecovered or 0)
            C.pane:Refresh(string.format("Collection scan complete • %d changed appearance source%s recovered.", recovered, recovered == 1 and "" or "s"))
        end
    end)
    QC.RegisterCallback("WARDROBE_SOURCE_METADATA_UPDATED", C.pane, function(payload)
        C.pane:RefreshVisibleAppearanceMetadata(payload)
    end)
    QC.RegisterCallback("WARDROBE_SELECTION_CHANGED", C.pane, function()
        if C.pane:IsShown() then C.pane:Refresh() end
    end)
    QC.RegisterCallback("WARDROBE_CUSTOM_SET_SYNCED", C.pane, function(_, success, message)
        if C.pane:IsShown() then C.pane:Refresh(message) end
        if C.conceptManager:IsShown() then C.conceptManager:Refresh(message) end
        if not success and UIErrorsFrame then
            UIErrorsFrame:AddMessage(message or "Custom Set verification failed.", 1, 0.25, 0.25)
        end
    end)
    QC.RegisterCallback("WARDROBE_WORKBENCH_CHANGED", C.pane, function()
        if C.pane:IsShown() then C.pane:Refresh() end
    end)
    QC.RegisterCallback("WARDROBE_WEAPON_OPTIONS_CHANGED", C.pane, function()
        if C.pane:IsShown() then
            C.pane:Refresh()
            C.pane:RefreshWeaponTypeFlyout()
        end
    end)
    QC.RegisterCallback("WARDROBE_WEAPON_SUBTYPES_CHANGED", C.pane, function()
        if C.pane:IsShown() then
            C.pane:Refresh()
            C.pane:RefreshWeaponTypeFlyout()
        end
    end)
    QC.RegisterCallback("WARDROBE_WEAPON_CAPABILITIES_CHANGED", C.pane, function()
        if C.pane:IsShown() then
            C.pane:Refresh("Blizzard weapon appearance permissions updated.")
            C.pane:RefreshWeaponTypeFlyout()
        end
    end)
    QC.RegisterCallback("WARDROBE_WEAPON_TOPOLOGY_CHANGED", C.pane, function(topology)
        if C.pane:IsShown() then C.pane:Refresh("Weapon layout changed: " .. tostring(topology and topology.label or "equipment updated") .. ".") end
    end)
    QC.RegisterCallback("WARDROBE_CONCEPTS_CHANGED", C.pane, function()
        if C.pane:IsShown() then
            C.pane:Refresh()
            if C.pane.conceptManager and C.pane.conceptManager:IsShown() then C.pane.conceptManager:Refresh() end
        end
    end)
    QC.RegisterCallback("WARDROBE_ZONE_PREFERENCES_CHANGED", C.pane, function()
        if C.pane:IsShown() then C.pane:Refresh() end
    end)
    QC.RegisterCallback("ZONE_STYLE_MODE_CHANGED", C.pane, function()
        if C.pane:IsShown() then C.pane:Refresh() end
    end)
    QC.RegisterCallback("ZONE_STYLE_SUGGESTION", C.pane, function()
        if C.pane:IsShown() then C.pane:Refresh("A new Zone Native outfit suggestion is ready.") end
    end)
    QC.RegisterCallback("ZONE_STYLE_CONTEXT_CHANGED", C.pane, function()
        if C.pane:IsShown() then C.pane:Refresh() end
    end)
    QC.RegisterCallback("ZONE_STYLE_SUGGESTION_CONSUMED", C.pane, function()
        if C.pane:IsShown() then C.pane:Refresh() end
    end)
    QC.RegisterCallback("EVENT_RECORDED", C.pane, function()
        if C.pane:IsShown() then C.pane:Refresh() end
    end)
    QC.RegisterCallback("ACTIVE_QUESTS_UPDATED", C.pane, function()
        if C.pane:IsShown() then C.pane:Refresh() end
    end)
    QC.RegisterCallback("SETTINGS_CHANGED", C.pane, function(settingName)
        if C.pane:IsShown() and (settingName == "restrictOutfitsToZoneEra" or settingName == "highContrastOutfitStates") then
            C.pane:Refresh()
        end
    end)
    QC.RegisterCallback("PLAYER_READY", C.pane, function()
        if C.model.SetUnit then C.model:SetUnit("player") end
        Wardrobe.ApplyPreview(C.model)
        C.pane:Refresh()
    end)

    C.pane:SetScript("OnShow", function()
        ZoneStyle.AcknowledgeSuggestion()
        Wardrobe.ApplyPreview(C.model)
        C.pane:Refresh()
    end)
end
