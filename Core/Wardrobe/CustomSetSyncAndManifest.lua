local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private
function P.FinishCustomSetSync(success, message, customSetID, report)
    local request = P.pendingCustomSetSync
    if not request then return end
    local store = P.EnsureConceptStore()
    local concept = store[request.conceptID]
    if concept then
        concept.customSetSyncPendingAt = nil
        if customSetID then
            -- Keep the link even when verification finds missing slots. The set
            -- exists and the Update Custom Set action is the repair path.
            concept.blizzardCustomSetID = tonumber(customSetID)
            concept.blizzardCustomSetName = request.name
            concept.blizzardCustomSetIcon = request.icon
        end
        concept.customSetVerification = report
        concept.customSetVerifiedAt = report and report.verifiedAt or time()
        if request.resolvedSources then
            concept.customSetResolvedSources = request.resolvedSources
        end
        if success and customSetID then
            concept.customSetSyncedAt = time()
            concept.customSetSyncError = nil
        else
            concept.customSetSyncError = message
        end
    end
    P.pendingCustomSetSync = nil
    if not success then P.PrintVerificationReport(report) end
    if QC.Notify then
        QC.Notify("WARDROBE_CUSTOM_SET_SYNCED", concept, success, message, report)
        QC.Notify("WARDROBE_CONCEPTS_CHANGED", concept)
    end
end

function P.TryVerifyPendingCustomSet(finalAttempt)
    local request = P.pendingCustomSetSync
    if not request then return false, false end
    local customSetID = request.customSetID
    if not customSetID then
        local info = P.FindCustomSetByName(request.name)
        customSetID = info and info.customSetID
    end
    if not customSetID then
        return false, false
    end

    local actual = P.SafeCall(C_TransmogCollection.GetCustomSetItemTransmogInfoList, tonumber(customSetID))
    if type(actual) ~= "table" then
        return false, false
    end

    local report = P.CompareCustomSetSlots(actual, request.expectedSlots)
    local message = P.FormatVerificationMessage(report)
    if report.success then
        P.FinishCustomSetSync(true, message, customSetID, report)
        return true, true, message
    elseif finalAttempt then
        P.FinishCustomSetSync(false, message, customSetID, report)
        return true, false, message
    end
    return false, false, message
end

function Wardrobe.IsCustomSetSavingSupported()
    return C_TransmogCollection
        and type(C_TransmogCollection.GetCustomSets) == "function"
        and type(C_TransmogCollection.NewCustomSet) == "function"
        and type(C_TransmogCollection.ModifyCustomSet) == "function"
        and type(C_TransmogCollection.GetCustomSetItemTransmogInfoList) == "function"
end

function Wardrobe.GetConceptCustomSetStatus(concept)
    if not concept then return "local", "Quest Chronicle only" end
    if P.pendingCustomSetSync and P.pendingCustomSetSync.conceptID == concept.id then
        return "pending", "Saving Custom Set..."
    end
    if concept.blizzardCustomSetID then
        local info = P.GetCustomSetInfo(concept.blizzardCustomSetID)
        if not info then return "missing", "Linked Custom Set missing" end
        local report = concept.customSetVerification
        if concept.customSetSyncError and report then
            return "error", string.format("Custom Set mismatch: %d/%d slots", report.matched or 0, report.expected or 0)
        end
        return "synced", "Custom Set: " .. tostring(info.name)
    end
    if concept.customSetSyncError then return "error", "Custom Set save failed" end
    return "local", "Quest Chronicle only"
end

function Wardrobe.SaveConceptToCustomSet(conceptID, mode, targetCustomSetID)
    P.LoadTransmogSupport()
    if not Wardrobe.IsCustomSetSavingSupported() then
        return false, "World of Warcraft's Custom Sets API is unavailable on this client."
    end
    if P.pendingCustomSetSync then
        return false, "Another Custom Set save is still awaiting confirmation."
    end
    if InCombatLockdown and InCombatLockdown() then
        return false, "Custom Sets cannot be changed during combat."
    end

    local store = P.EnsureConceptStore()
    local concept = store[conceptID]
    if not concept then return false, "That outfit concept is no longer available." end
    local name = tostring(concept.name or ""):match("^%s*(.-)%s*$") or ""
    if name == "" then return false, "Give the concept a name before saving it to Custom Sets." end
    if C_TransmogCollection.IsValidCustomSetName and P.SafeCall(C_TransmogCollection.IsValidCustomSetName, name) ~= true then
        return false, "World of Warcraft does not allow that Custom Set name. Rename the concept and try again."
    end

    mode = mode or "auto"
    local customSetID = tonumber(targetCustomSetID)
    if mode == "auto" then
        customSetID = tonumber(concept.blizzardCustomSetID)
        if customSetID and P.GetCustomSetInfo(customSetID) then
            mode = "update"
        else
            local sameName = P.FindCustomSetByName(name)
            if sameName then
                customSetID = sameName.customSetID
                mode = "replace"
            else
                customSetID = nil
                mode = "new"
            end
        end
    elseif mode == "replace" then
        if not customSetID or not P.GetCustomSetInfo(customSetID) then
            return false, "Choose an existing Custom Set to replace."
        end
    elseif mode == "update" then
        customSetID = tonumber(concept.blizzardCustomSetID)
        if not customSetID or not P.GetCustomSetInfo(customSetID) then
            return false, "The linked Custom Set is missing. Use Save as New or Replace Existing."
        end
    elseif mode ~= "new" then
        return false, "Unknown Custom Set save mode."
    end

    if mode == "new" then
        local count = #Wardrobe.GetCustomSets()
        local maximum = tonumber(P.SafeCall(C_TransmogCollection.GetNumMaxCustomSets)) or 0
        if maximum > 0 and count >= maximum then
            return false, "All WoW Custom Set slots are full. Choose Replace Existing instead."
        end
    end

    local list, populated, expectedSlots, resolvedSources, buildError = P.BuildConceptCustomSetList(concept)
    if not list then return false, buildError or "Unable to build the Custom Set slot list." end
    if populated == 0 then return false, "This concept has no selected appearances to save." end
    local icon = P.GetConceptOutfitIcon(concept)

    if mode == "replace" then
        local previousInfo = P.GetCustomSetInfo(customSetID)
        local previousList = P.SafeCall(C_TransmogCollection.GetCustomSetItemTransmogInfoList, customSetID)
        if previousInfo and type(previousList) == "table" then
            concept.customSetReplacementBackups = concept.customSetReplacementBackups or {}
            table.insert(concept.customSetReplacementBackups, {
                customSetID = customSetID,
                name = previousInfo.name,
                icon = previousInfo.icon,
                itemTransmogInfoList = previousList,
                backedUpAt = time(),
            })
            while #concept.customSetReplacementBackups > 5 do table.remove(concept.customSetReplacementBackups, 1) end
        end
    end

    local ok, result
    if mode == "new" then
        ok, result = P.TryCall(C_TransmogCollection.NewCustomSet, name, icon, list)
        if ok then customSetID = tonumber(result) end
    else
        ok, result = P.TryCall(C_TransmogCollection.ModifyCustomSet, customSetID, list)
        if ok and C_TransmogCollection.RenameCustomSet then
            local renameOK, renameError = P.TryCall(C_TransmogCollection.RenameCustomSet, customSetID, name)
            if not renameOK then return false, "The appearances were saved, but WoW rejected the Custom Set name: " .. tostring(renameError) end
        end
    end
    if not ok then return false, "World of Warcraft rejected the Custom Set save: " .. tostring(result) end

    P.pendingCustomSetSync = {
        conceptID = concept.id,
        customSetID = customSetID,
        name = name,
        icon = icon,
        mode = mode,
        itemTransmogInfoList = list,
        expectedSlots = expectedSlots,
        resolvedSources = resolvedSources,
        startedAt = time(),
    }
    concept.customSetSyncPendingAt = time()
    concept.customSetSyncError = nil
    concept.customSetVerification = nil

    local resolved, verified, verificationMessage = P.TryVerifyPendingCustomSet(false)
    if resolved then
        return verified, verificationMessage
    end

    if C_Timer and C_Timer.After then
        local request = P.pendingCustomSetSync
        C_Timer.After(P.CUSTOM_SET_SYNC_TIMEOUT, function()
            if P.pendingCustomSetSync == request then
                local finished = P.TryVerifyPendingCustomSet(true)
                if not finished and P.pendingCustomSetSync == request then
                    P.FinishCustomSetSync(false, "World of Warcraft did not return the saved Custom Set for verification.", customSetID)
                end
            end
        end)
    end
    return true, mode == "update" and "Updating linked Custom Set and verifying every selected slot..." or "Saving to WoW Custom Sets and verifying every selected slot..."
end

function Wardrobe.GetSelectedSource(slotKey)
    local state = P.EnsurePreviewState()
    local sourceID = state.selections[slotKey]
    if not sourceID then
        return nil
    end
    return P.GetSourceByID(slotKey, sourceID)
end

function P.GetEquippedManifestDetails(definition)
    local slotID = definition and P.SafeCall(GetInventorySlotInfo, definition.slotName)
    if not slotID then return nil end
    local itemID = P.SafeCall(GetInventoryItemID, "player", slotID)
    local itemLink = P.SafeCall(GetInventoryItemLink, "player", slotID)
    if not itemID and not itemLink then return nil end
    local name = itemID and P.SafeCall(C_Item and C_Item.GetItemNameByID, itemID)
    if not name and itemID then name = P.SafeCall(C_Item and C_Item.GetItemInfo, itemID) end
    if not name and itemLink then name = P.SafeCall(C_Item and C_Item.GetItemInfo, itemLink) end
    local icon = P.SafeCall(GetInventoryItemTexture, "player", slotID) or P.GetItemIcon(itemID)
    return {
        itemID = itemID,
        itemLink = itemLink,
        name = name or itemLink or "Equipped gear",
        icon = icon,
    }
end

function Wardrobe.GetPreviewManifest()
    local state = P.EnsurePreviewState()
    local manifest = {}
    local selectedWeaponMode
    for _, slotKey in ipairs(P.MAIN_WEAPON_SLOT_KEYS) do
        if state.selections[slotKey] then
            selectedWeaponMode = slotKey
            break
        end
    end

    for _, definition in ipairs(Wardrobe.slotDefinitions) do
        local include = not definition.weaponRole
        local displayLabel = definition.label
        if definition.weaponRole then
            if selectedWeaponMode then
                if definition.key == selectedWeaponMode then
                    include = true
                    displayLabel = "Main Hand"
                elseif definition.key == "OFF_HAND" then
                    -- A secondary weapon is stored in OFF_HAND regardless of
                    -- whether the active route is One-Hand or Two-Hand. Preserve
                    -- the existing One-Hand companion behavior, while also
                    -- listing generated Fury Two-Hand pairs explicitly.
                    include = state.selections.OFF_HAND ~= nil or selectedWeaponMode == "ONE_HAND"
                    displayLabel = "Off Hand"
                else
                    include = false
                end
            else
                include = definition.key == "ONE_HAND" or definition.key == "OFF_HAND"
                if definition.key == "ONE_HAND" then
                    displayLabel = "Main Hand"
                elseif definition.key == "OFF_HAND" then
                    displayLabel = "Off Hand"
                end
            end
        end

        if include then
            local source = P.GetSourceByID(definition.key, state.selections[definition.key])
            local equipped = not source and P.GetEquippedManifestDetails(definition) or nil
            if not definition.weaponRole or source or equipped then
                local hidden = state.hidden[definition.key] == true
                local kind = source and "Selected" or (equipped and "Equipped" or "Empty")
                table.insert(manifest, {
                    slotKey = definition.key,
                    label = displayLabel,
                    name = source and (source.name or ("Appearance " .. tostring(source.sourceID))) or (equipped and equipped.name or "Empty"),
                    icon = source and source.icon or equipped and equipped.icon,
                    sourceID = source and source.sourceID,
                    source = source,
                    itemID = source and source.itemID or equipped and equipped.itemID,
                    itemLink = source and source.styleItemLink or equipped and equipped.itemLink,
                    kind = kind,
                    hidden = hidden,
                    locked = state.locks[definition.key] == true,
                })
            end
        end
    end
    return manifest
end

function Wardrobe.ValidateSource(source, slotKey)
    if type(source) ~= "table" then
        return false, "Appearance data is unavailable."
    end
    if source.sourceIsCollected ~= true then
        return false, "The visual is unlocked, but this particular preview source is not collected. Rescan the wardrobe to bind a collected source."
    end
    if not source.isCollected and not source.appearanceIsCollected then
        return false, "This appearance is not collected."
    end
    if source.appearanceCanDisplayOnPlayer == false then
        return false, "This character cannot display the appearance."
    end
    if source.isHideVisual then
        return false, "Hidden-slot visuals are not included in the appearance browser."
    end
    if not source.itemID then
        return false, "WoW did not provide an item for this appearance."
    end
    if slotKey and source.slotKey and source.slotKey ~= slotKey then
        return false, "The appearance belongs to another preview slot."
    end
    return true, "Compatible"
end

function P.NormalizeSource(source, appearance, slotKey, categoryID)
    local sourceID = source and source.sourceID or appearance and appearance.sourceID
    if not sourceID then
        return nil
    end

    local itemID = P.GetSourceItemID(sourceID, source)
    local sourceIsCollected = P.IsSourceCollected(sourceID, source)
    local appearanceIsCollected = appearance and appearance.isCollected == true
    local normalized = {
        sourceID = sourceID,
        -- GetCategoryAppearances is already Blizzard's collapsed visual catalog.
        -- Its visualID is the identity of this row. Source-level appearance IDs
        -- are a different namespace and must never be used to key the catalog.
        visualID = appearance and appearance.visualID or nil,
        itemID = itemID,
        name = source and source.name or nil,
        quality = source and source.quality or nil,
        sourceType = source and source.sourceType or nil,
        inventoryType = source and source.invType or nil,
        categoryID = source and source.categoryID or categoryID,
        slotKey = slotKey,
        -- Collection and display eligibility belong to Blizzard's collapsed
        -- appearance row. A source can be individually unknown or unusable
        -- while another source has already unlocked the same visual.
        isCollected = appearanceIsCollected,
        appearanceIsCollected = appearanceIsCollected,
        sourceIsCollected = sourceIsCollected,
        isHideVisual = source and source.isHideVisual == true or appearance and appearance.isHideVisual == true,
        isUsable = appearance and appearance.isUsable,
        appearanceCanDisplayOnPlayer = appearance and appearance.canDisplayOnPlayer,
        playerCanCollect = source and source.playerCanCollect,
        isValidSourceForPlayer = source and source.isValidSourceForPlayer,
        canDisplayOnPlayer = source and source.canDisplayOnPlayer,
        meetsTransmogPlayerCondition = source and source.meetsTransmogPlayerCondition,
        useError = source and source.useError,
        icon = P.GetItemIcon(itemID) or appearance and appearance.icon,
    }

    normalized.visualID = normalized.visualID or sourceID
    if normalized.canDisplayOnPlayer == nil and appearance then
        normalized.canDisplayOnPlayer = appearance.canDisplayOnPlayer
    end
    if normalized.isUsable == nil and appearance then
        normalized.isUsable = appearance.isUsable
    end
    if not normalized.name and appearance then
        normalized.name = appearance.name
    end
    if not normalized.name and itemID and C_Item and C_Item.GetItemNameByID then
        normalized.name = P.SafeCall(C_Item.GetItemNameByID, itemID)
    end
    normalized.name = normalized.name or ("Appearance " .. tostring(sourceID))
    return normalized
end

function P.BetterSource(candidate, current)
    if not current then
        return true
    end
    if candidate.sourceIsCollected ~= current.sourceIsCollected then
        return candidate.sourceIsCollected == true
    end
    if (candidate.useError == nil) ~= (current.useError == nil) then
        return candidate.useError == nil
    end
    if candidate.canDisplayOnPlayer ~= current.canDisplayOnPlayer then
        return candidate.canDisplayOnPlayer ~= false
    end
    if candidate.isValidSourceForPlayer ~= current.isValidSourceForPlayer then
        return candidate.isValidSourceForPlayer ~= false
    end
    if candidate.meetsTransmogPlayerCondition ~= current.meetsTransmogPlayerCondition then
        return candidate.meetsTransmogPlayerCondition ~= false
    end
    if candidate.quality ~= current.quality then
        return (candidate.quality or 0) > (current.quality or 0)
    end
    return (candidate.sourceID or 0) < (current.sourceID or 0)
end
